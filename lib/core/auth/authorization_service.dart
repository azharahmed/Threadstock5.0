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

  /// Full standard catalog of permission codes defined in Migration 020.
  static const Set<String> allCatalogPermissions = {
    'inventory.view',
    'inventory.create',
    'inventory.edit',
    'inventory.adjust',
    'inventory.count',
    'sales.view',
    'sales.create',
    'sales.discount',
    'sales.refund',
    'purchasing.view',
    'purchasing.create',
    'transfers.view',
    'transfers.create',
    'transfers.receive',
    'customers.view',
    'customers.manage',
    'team.view',
    'team.manage',
    'insights.view',
    'settings.view',
    'settings.manage',
  };

  /// Checks if current user has permission for the specified code.
  /// Owners have full catalog permissions.
  bool can(String permissionCode) {
    if (_isOwner) return allCatalogPermissions.contains(permissionCode);
    return _permissions.contains(permissionCode);
  }

  /// Clears in-memory authorization state on logout or tenant switch.
  void clear() {
    _isOwner = false;
    _roleName = null;
    _roleId = null;
    _teamMemberId = null;
    _membershipStatus = null;
    _permissions.clear();
    _isLoading = false;
    notifyListeners();
  }

  /// Loads real role and permission context from Supabase for the current business.
  Future<void> refreshAuthorization({
    String? businessId,
    SupabaseClient? overrideClient,
  }) async {
    final sb = overrideClient ?? _resolvedClient;
    if (sb == null) {
      clear();
      return;
    }

    final user = sb.auth.currentUser;
    final targetBizId =
        businessId ?? CurrentBusinessService.instance.currentBusinessId;

    if (user == null || targetBizId == null || targetBizId.isEmpty) {
      clear();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _permissions.clear();
      _isOwner = false;
      _roleName = null;
      _roleId = null;
      _teamMemberId = null;
      _membershipStatus = null;

      // 1. Check if user is business owner
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
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. Fetch membership status
      final memberRow = await sb
          .from('memberships')
          .select('status')
          .eq('business_id', targetBizId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (memberRow != null) {
        _membershipStatus = memberRow['status'] as String?;
      }

      if (_membershipStatus != 'active') {
        // Inactive or suspended members have no permissions
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 3. Fetch team_member entry with role and permissions
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
            _permissions.addAll(allCatalogPermissions);
            _isLoading = false;
            notifyListeners();
            return;
          }
        }

        // 4. Fetch permissions assigned to this role
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
      notifyListeners();
    }
  }

  @visibleForTesting
  void setPermissionsForTesting({
    bool isOwner = false,
    String? roleName,
    Set<String>? permissions,
  }) {
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
