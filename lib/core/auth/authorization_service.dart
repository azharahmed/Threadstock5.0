import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../business/current_business_service.dart';

/// Application Authorization Context for UX and Navigation.
///
/// NOTE: The Flutter authorization layer is for UX and navigation convenience only.
/// It is NOT a security boundary. Database RLS policies and server-authoritative
/// RPCs enforce actual security boundaries.
class AuthorizationService extends ChangeNotifier {
  AuthorizationService({this.client});

  final SupabaseClient? client;

  static final AuthorizationService instance = AuthorizationService();

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  bool _isOwner = false;
  String? _roleName;
  String? _roleId;
  String? _teamMemberId;
  String? _membershipStatus;
  final Set<String> _permissions = <String>{};
  bool _isLoading = false;

  bool get isOwner => _isOwner;
  String? get roleName => _roleName;
  String? get roleId => _roleId;
  String? get teamMemberId => _teamMemberId;
  String? get membershipStatus => _membershipStatus;
  Set<String> get permissions => Set.unmodifiable(_permissions);
  bool get isLoading => _isLoading;

  /// Full standard catalog of permission codes defined in Migration 020 / 021.
  static const Set<String> allCatalogPermissions = {
    'customers.manage',
    'customers.view',
    'insights.export',
    'insights.view',
    'inventory.adjust',
    'inventory.import',
    'inventory.manage',
    'inventory.view',
    'purchasing.manage',
    'purchasing.receive',
    'purchasing.view',
    'sales.create',
    'sales.hold',
    'sales.refund',
    'sales.view',
    'settings.manage',
    'settings.view',
    'team.manage',
    'team.view',
    'transfers.manage',
    'transfers.view',
  };

  /// Legacy permission aliases mapped to authoritative database catalog codes.
  static const Map<String, String> _legacyPermissionAliases = {
    'purchasing.create': 'purchasing.manage',
    'transfers.create': 'transfers.manage',
    'transfers.receive': 'transfers.manage',
    'sales.discount': 'sales.create',
  };

  bool _testExplicitlyConfigured = false;

  /// Checks if current user has permission for the specified code.
  /// Owners have full catalog permissions.
  bool can(String permissionCode) {
    final effectiveCode = _legacyPermissionAliases[permissionCode] ?? permissionCode;
    if (_testExplicitlyConfigured) {
      if (_isOwner) return allCatalogPermissions.contains(effectiveCode);
      return _permissions.contains(effectiveCode);
    }
    final sb = _resolvedClient;
    final user = sb?.auth.currentUser;
    if (sb != null && user != null) {
      // Authoritative owner check: cached state or current business owner context
      final currentBiz = CurrentBusinessService.instance.currentBusiness;
      final isOwnerByBiz = currentBiz != null &&
          currentBiz.ownerUserId.isNotEmpty &&
          currentBiz.ownerUserId == user.id;

      if (_isOwner || isOwnerByBiz) {
        return allCatalogPermissions.contains(effectiveCode);
      }
      return _permissions.contains(effectiveCode);
    }
    return true;
  }

  String? _inFlightBusinessId;
  Future<void>? _inFlightRefresh;
  String? _lastRefreshedBusinessId;
  String? _lastRefreshedUserId;
  DateTime? _lastRefreshedTime;

  /// Clears in-memory authorization state on logout or tenant switch.
  void clear() {
    _testExplicitlyConfigured = true;
    _isOwner = false;
    _roleName = null;
    _roleId = null;
    _teamMemberId = null;
    _membershipStatus = null;
    _permissions.clear();
    _isLoading = false;
    _inFlightBusinessId = null;
    _inFlightRefresh = null;
    _lastRefreshedBusinessId = null;
    _lastRefreshedUserId = null;
    _lastRefreshedTime = null;
    notifyListeners();
  }

  /// Loads real role and permission context from Supabase for the current business.
  Future<void> refreshAuthorization({
    String? businessId,
    SupabaseClient? overrideClient,
    bool forceRefresh = false,
  }) async {
    // If running in test mode with explicitly configured permissions and no client, preserve test configuration
    if (_testExplicitlyConfigured && overrideClient == null && _resolvedClient == null) {
      return;
    }
    _testExplicitlyConfigured = false;
    final sb = overrideClient ?? _resolvedClient;
    if (sb == null) {
      clear();
      return;
    }

    final user = sb.auth.currentUser;
    final targetBizId =
        businessId ?? CurrentBusinessService.instance.currentBusinessId;

    if (user == null ||
        targetBizId == null ||
        targetBizId.isEmpty ||
        !CurrentBusinessService.isValidUuid(targetBizId)) {
      clear();
      return;
    }

    // Deduplication check: if refresh for the same business is already in flight, await it
    if (_inFlightBusinessId == targetBizId && _inFlightRefresh != null) {
      debugPrint(
        '[AuthorizationService] Awaiting already in-flight authorization refresh for $targetBizId',
      );
      await _inFlightRefresh;
      return;
    }

    // Idempotency check: if refreshed within last 3 seconds for same user and business, reuse
    if (!forceRefresh &&
        _lastRefreshedBusinessId == targetBizId &&
        _lastRefreshedUserId == user.id &&
        _lastRefreshedTime != null &&
        DateTime.now().difference(_lastRefreshedTime!) < const Duration(seconds: 3)) {
      debugPrint(
        '[AuthorizationService] Reusing fresh authorization for $targetBizId (idempotent no-op)',
      );
      return;
    }

    _inFlightBusinessId = targetBizId;
    final completer = Completer<void>();
    _inFlightRefresh = completer.future;

    _isLoading = true;
    notifyListeners();

    try {
      _permissions.clear();
      _isOwner = false;
      _roleName = null;
      _roleId = null;
      _teamMemberId = null;
      _membershipStatus = null;

      // 1. Authoritative check from current business context if already in memory
      final activeBiz = CurrentBusinessService.instance.currentBusiness;
      if (activeBiz != null &&
          activeBiz.id == targetBizId &&
          activeBiz.ownerUserId.isNotEmpty &&
          activeBiz.ownerUserId == user.id) {
        _isOwner = true;
        _roleName = 'Owner';
        _membershipStatus = 'active';
        _permissions.addAll(allCatalogPermissions);
        return;
      }

      // 2. Check if user is business owner in database
      final bizRow = await sb
          .from('businesses')
          .select('id, owner_user_id')
          .eq('id', targetBizId)
          .maybeSingle();

      if (bizRow != null && bizRow['owner_user_id'] == user.id) {
        _isOwner = true;
        _roleName = 'Owner';
        _membershipStatus = 'active';
        _permissions.addAll(allCatalogPermissions);
        return;
      }

      // 3. Fetch membership status
      final memberRow = await sb
          .from('memberships')
          .select('status')
          .eq('business_id', targetBizId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (memberRow != null) {
        _membershipStatus = memberRow['status'] as String?;
      }

      // Explicitly suspended or inactive members have no permissions
      if (memberRow != null && _membershipStatus != 'active') {
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 4. Fetch team_member entry with role and permissions
      final tmRow = await sb
          .from('team_members')
          .select('id, role_id, status, roles(id, name, is_system)')
          .eq('business_id', targetBizId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (tmRow != null && tmRow['status'] == 'active') {
        _teamMemberId = tmRow['id'] as String?;
        _roleId = tmRow['role_id'] as String?;
        final rolesData = tmRow['roles'];

        if (rolesData is Map) {
          _roleName = rolesData['name'] as String?;
          if (_roleName == 'Owner') {
            _isOwner = true;
            _membershipStatus = 'active';
            _permissions.addAll(allCatalogPermissions);
            _isLoading = false;
            notifyListeners();
            return;
          }
        }

        // 5. Fetch permissions assigned to this role
        if (_roleId != null) {
          final rpRows = await sb
              .from('role_permissions')
              .select('permissions(code)')
              .eq('role_id', _roleId!);

          for (final row in rpRows) {
            final pData = row['permissions'];
            if (pData is Map) {
              final code = pData['code'] as String?;
              if (code != null) {
                _permissions.add(code);
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[AuthorizationService] Error loading authorization: $e');
    } finally {
      _isLoading = false;
      _lastRefreshedBusinessId = targetBizId;
      _lastRefreshedUserId = user.id;
      _lastRefreshedTime = DateTime.now();
      _inFlightBusinessId = null;
      _inFlightRefresh = null;
      if (!completer.isCompleted) completer.complete();
      debugPrint(
        '[AuthorizationService] Authorization refreshed: '
        'businessId=$targetBizId, isOwner=$_isOwner, role=$_roleName, permissionCount=${_permissions.length}',
      );
      notifyListeners();
    }
  }

  @visibleForTesting
  void setPermissionsForTesting({
    bool isOwner = false,
    String? roleName,
    Set<String>? permissions,
  }) {
    _testExplicitlyConfigured = true;
    _isOwner = isOwner;
    _roleName = roleName ?? (isOwner ? 'Owner' : 'Staff');
    _permissions.clear();
    if (isOwner) {
      _permissions.addAll(allCatalogPermissions);
    } else if (permissions != null) {
      _permissions.addAll(permissions);
    }
    notifyListeners();
  }
}
