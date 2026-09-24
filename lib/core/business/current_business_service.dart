import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/business/domain/models/business.dart';
import '../config/app_preferences_service.dart';

class CurrentBusinessService extends ChangeNotifier {
  CurrentBusinessService({this.client});

  final SupabaseClient? client;

  static final CurrentBusinessService instance = CurrentBusinessService();

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String? _currentBusinessId;
  Business? _currentBusiness;
  String? _currentLocationId;
  bool _isCreatingBusiness = false;

  String? get currentBusinessId => _currentBusinessId;
  Business? get currentBusiness => _currentBusiness;
  String? get currentLocationId => _currentLocationId;

  void setCurrentLocationId(String? id) {
    if (id == null || id.isEmpty || id == 'none') {
      _currentLocationId = null;
      return;
    }
    _currentLocationId = id;
  }

  void setCurrentBusinessId(String? id) {
    if (_currentBusinessId != id) {
      _currentBusinessId = id;
      AppPreferencesService.instance.setCurrentBusinessId(id);
      notifyListeners();
    }
  }

  void setCurrentBusiness(Business business) {
    _currentBusinessId = business.id;
    _currentBusiness = business;
    AppPreferencesService.instance.setCurrentBusinessId(business.id);
    notifyListeners();
  }

  /// Purges in-memory business state and clears cached selection.
  void clear() {
    _currentBusinessId = null;
    _currentBusiness = null;
    _currentLocationId = null;
    _isCreatingBusiness = false;
    notifyListeners();
  }

  /// Normalizes location range strings to match database check constraint:
  /// check (location_range in ('1', '2-5', '6-20', '20+'))
  static String normalizeLocationRange(String? input) {
    if (input == null) return '1';
    final trimmed = input.replaceAll(' ', '').trim();
    if (trimmed == '1' ||
        trimmed == '2-5' ||
        trimmed == '6-20' ||
        trimmed == '20+') {
      return trimmed;
    }
    return '1';
  }

  /// Resolves the current business ID from Supabase using strict server-authoritative precedence:
  /// 1. Persisted last_business_id — revalidated against Supabase (must be owner or active member).
  ///    Stale/suspended IDs are rejected and cleared.
  /// 2. Active memberships (where memberships.status == 'active').
  /// 3. Owned completed businesses.
  /// 4. Incomplete owned onboarding business.
  /// 5. Otherwise returns null (no business).
  ///
  /// CRITICAL: Startup must NEVER create a business automatically.
  Future<String?> resolveCurrentBusinessId({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _currentBusinessId != null &&
        _currentBusinessId!.isNotEmpty) {
      return _currentBusinessId;
    }

    final sb = _resolvedClient;
    if (sb == null) return _currentBusinessId;

    final user = sb.auth.currentUser;
    if (user == null) {
      clear();
      return null;
    }

    final currentUserId = user.id;

    try {
      // 1. Revalidate persisted last_business_id if present
      final persistedId = AppPreferencesService.instance.currentBusinessId;
      if (persistedId != null && persistedId.isNotEmpty) {
        // Check if user is owner of persisted business
        final ownedRow = await sb
            .from('businesses')
            .select()
            .eq('id', persistedId)
            .eq('owner_user_id', currentUserId)
            .maybeSingle();

        if (ownedRow != null) {
          final biz = Business.fromJson(Map<String, dynamic>.from(ownedRow));
          _currentBusiness = biz;
          _currentBusinessId = biz.id;
          notifyListeners();
          return biz.id;
        }

        // Check if user is an active member of persisted business
        final memberRow = await sb
            .from('memberships')
            .select('business_id, status, businesses(*)')
            .eq('business_id', persistedId)
            .eq('user_id', currentUserId)
            .eq('status', 'active')
            .maybeSingle();

        if (memberRow != null) {
          final bizData = memberRow['businesses'];
          if (bizData is Map) {
            final biz = Business.fromJson(Map<String, dynamic>.from(bizData));
            _currentBusiness = biz;
            _currentBusinessId = biz.id;
            notifyListeners();
            return biz.id;
          } else {
            final bRow = await sb
                .from('businesses')
                .select()
                .eq('id', persistedId)
                .maybeSingle();
            if (bRow != null) {
              final biz = Business.fromJson(Map<String, dynamic>.from(bRow));
              _currentBusiness = biz;
              _currentBusinessId = biz.id;
              notifyListeners();
              return biz.id;
            }
          }
        }

        // Persisted business ID is not authorized or membership suspended/deleted
        debugPrint(
          '[CurrentBusinessService] Persisted business $persistedId is no longer authorized. Purging.',
        );
        await AppPreferencesService.instance.setCurrentBusinessId(null);
      }

      // 2. Query active memberships for this user
      final memberRows = await sb
          .from('memberships')
          .select('business_id, businesses(*)')
          .eq('user_id', currentUserId)
          .eq('status', 'active');

      if (memberRows.isNotEmpty) {
        for (final row in memberRows) {
          final bizData = row['businesses'];
          if (bizData is Map) {
            final biz = Business.fromJson(Map<String, dynamic>.from(bizData));
            _currentBusiness = biz;
            _currentBusinessId = biz.id;
            await AppPreferencesService.instance.setCurrentBusinessId(biz.id);
            notifyListeners();
            return biz.id;
          } else {
            final bId = row['business_id'] as String?;
            if (bId != null) {
              final bRow = await sb
                  .from('businesses')
                  .select()
                  .eq('id', bId)
                  .maybeSingle();
              if (bRow != null) {
                final biz = Business.fromJson(Map<String, dynamic>.from(bRow));
                _currentBusiness = biz;
                _currentBusinessId = biz.id;
                await AppPreferencesService.instance.setCurrentBusinessId(biz.id);
                notifyListeners();
                return biz.id;
              }
            }
          }
        }
      }

      // 3. Query businesses owned by this user
      final ownedRows = await sb
          .from('businesses')
          .select()
          .eq('owner_user_id', currentUserId)
          .order('created_at', ascending: false);

      if (ownedRows.isNotEmpty) {
        final bizIds = ownedRows
            .map((r) => r['id'] as String)
            .toList();

        // Check onboarding completion for owned businesses
        final sessions = await sb
            .from('onboarding_sessions')
            .select('business_id, status')
            .inFilter('business_id', bizIds);

        final completedBizIds = <String>{};
        for (final s in sessions) {
          if (s['status'] == 'complete') {
            completedBizIds.add(s['business_id'] as String);
          }
        }

        // 3a. Prefer completed owned business
        for (final row in ownedRows) {
          final id = row['id'] as String;
          if (completedBizIds.contains(id)) {
            final biz = Business.fromJson(Map<String, dynamic>.from(row));
            _currentBusiness = biz;
            _currentBusinessId = biz.id;
            await AppPreferencesService.instance.setCurrentBusinessId(biz.id);
            notifyListeners();
            return biz.id;
          }
        }

        // 4. Incomplete owned onboarding business
        final firstRow = ownedRows.first;
        final biz = Business.fromJson(Map<String, dynamic>.from(firstRow));
        _currentBusiness = biz;
        _currentBusinessId = biz.id;
        await AppPreferencesService.instance.setCurrentBusinessId(biz.id);
        notifyListeners();
        return biz.id;
      }

      // 5. User has no accessible businesses
      debugPrint(
        '[CurrentBusinessService] No accessible businesses found for user: $currentUserId',
      );
      _currentBusiness = null;
      _currentBusinessId = null;
      await AppPreferencesService.instance.setCurrentBusinessId(null);
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('[CurrentBusinessService] Error resolving business ID: $e');
      return null;
    }
  }

  /// Creates or updates the business row in public.businesses for the authenticated owner,
  /// and establishes the owner membership in public.memberships.
  Future<Business> createOrUpdateBusinessForOwner({
    required String legalName,
    required String businessType,
    required String countryCode,
    required String currencyCode,
    required String locationRange,
    String? existingBusinessId,
  }) async {
    if (_isCreatingBusiness) {
      debugPrint(
        '[CurrentBusinessService] Business creation already in progress. Waiting...',
      );
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    _isCreatingBusiness = true;

    try {
      final sb = _resolvedClient;
      final normalizedLocation = normalizeLocationRange(locationRange);
      final normalizedCountry = countryCode.trim().toUpperCase();
      final normalizedCurrency = currencyCode.trim().toUpperCase();
      final cleanLegalName = legalName.trim();
      final cleanBusinessType = businessType.trim();

      if (cleanLegalName.isEmpty) {
        throw ArgumentError('Enter a business name.');
      }
      if (cleanBusinessType.isEmpty) {
        throw ArgumentError('Select a business type.');
      }
      if (!RegExp(r'^[A-Z]{2}$').hasMatch(normalizedCountry)) {
        throw ArgumentError('Invalid country code: $countryCode');
      }
      if (!RegExp(r'^[A-Z]{3}$').hasMatch(normalizedCurrency)) {
        throw ArgumentError('Invalid currency code: $currencyCode');
      }

      if (sb == null) {
        final fallbackBusiness = Business(
          id: existingBusinessId ??
              'biz_${DateTime.now().millisecondsSinceEpoch}',
          ownerUserId: 'mock_owner',
          legalName: cleanLegalName,
          businessType: cleanBusinessType,
          countryCode: normalizedCountry,
          currencyCode: normalizedCurrency,
          locationRange: normalizedLocation,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        setCurrentBusiness(fallbackBusiness);
        return fallbackBusiness;
      }

      final user = sb.auth.currentUser;
      if (user == null) {
        throw StateError(
          'Cannot create business: Unauthenticated. Please sign in first.',
        );
      }

      var targetId = existingBusinessId ??
          _currentBusinessId ??
          AppPreferencesService.instance.currentBusinessId;
      Business? business;

      if (targetId == null || targetId.isEmpty || targetId.startsWith('biz_')) {
        final existingOwned = await sb
            .from('businesses')
            .select()
            .eq('owner_user_id', user.id)
            .order('created_at', ascending: false);

        if (existingOwned.isNotEmpty) {
          final firstOwned = Map<String, dynamic>.from(existingOwned.first);
          targetId = firstOwned['id'] as String?;
        }
      }

      if (targetId != null &&
          targetId.isNotEmpty &&
          !targetId.startsWith('biz_')) {
        final response = await sb
            .from('businesses')
            .update({
              'legal_name': cleanLegalName,
              'business_type': cleanBusinessType,
              'country_code': normalizedCountry,
              'currency_code': normalizedCurrency,
              'location_range': normalizedLocation,
            })
            .eq('id', targetId)
            .eq('owner_user_id', user.id)
            .select()
            .maybeSingle();

        if (response != null) {
          business = Business.fromJson(response);
        }
      }

      if (business == null) {
        final response = await sb
            .from('businesses')
            .insert({
              'owner_user_id': user.id,
              'legal_name': cleanLegalName,
              'business_type': cleanBusinessType,
              'country_code': normalizedCountry,
              'currency_code': normalizedCurrency,
              'location_range': normalizedLocation,
            })
            .select()
            .single();

        business = Business.fromJson(response);
      }

      // Ensure onboarding_sessions row is linked
      try {
        final existingSession = await sb
            .from('onboarding_sessions')
            .select('status')
            .eq('business_id', business.id)
            .maybeSingle();

        if (existingSession == null ||
            existingSession['status'] != 'complete') {
          await sb.from('onboarding_sessions').upsert({
            'business_id': business.id,
            'user_id': user.id,
            'current_step': 1,
            'status': 'in_progress',
          }, onConflict: 'business_id,user_id');
        }
      } catch (oe) {
        debugPrint(
          '[CurrentBusinessService] Notice syncing onboarding_session: $oe',
        );
      }

      setCurrentBusiness(business);
      return business;
    } on PostgrestException catch (pe) {
      debugPrint(
        '[CurrentBusinessService] PostgrestException [table: businesses]: '
        'code=${pe.code}, message=${pe.message}, details=${pe.details}',
      );
      rethrow;
    } catch (e, st) {
      debugPrint(
        '[CurrentBusinessService] Unexpected error creating/updating business: $e\n$st',
      );
      rethrow;
    } finally {
      _isCreatingBusiness = false;
    }
  }

  @visibleForTesting
  void resetForTesting() {
    clear();
  }
}
