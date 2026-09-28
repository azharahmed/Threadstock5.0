import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/business/domain/models/business.dart';
import '../auth/authorization_service.dart';
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
    final nextId = (id == null || id.isEmpty || id == 'none') ? null : id;
    if (_currentLocationId != nextId) {
      _currentLocationId = nextId;
      if (_currentBusinessId != null && _currentBusinessId!.isNotEmpty) {
        AppPreferencesService.instance
            .setCurrentLocationId(_currentBusinessId!, nextId);
      }
      notifyListeners();
    }
  }

  void setCurrentBusinessId(String? id) {
    if (_currentBusinessId != id) {
      _currentBusinessId = id;
      _currentLocationId = id != null
          ? AppPreferencesService.instance.getCurrentLocationId(id)
          : null;
      AppPreferencesService.instance.setCurrentBusinessId(id);
      AuthorizationService.instance.refreshAuthorization(businessId: id);
      notifyListeners();
    }
  }

  void setCurrentBusiness(Business business) {
    _currentBusinessId = business.id;
    _currentBusiness = business;
    _currentLocationId =
        AppPreferencesService.instance.getCurrentLocationId(business.id);
    AppPreferencesService.instance.setCurrentBusinessId(business.id);
    AuthorizationService.instance.refreshAuthorization(businessId: business.id);
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

  /// Validates standard 8-4-4-4-12 UUID format.
  /// Used to verify persisted or user-provided business IDs before passing to Supabase/PostgREST.
  static bool isValidUuid(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.length != 36) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(trimmed);
  }

  void _logDiagnostics({
    required String? persistedId,
    required bool isPersistedValid,
    required int accessibleCount,
  }) {
    debugPrint(
      '==========================================================\n'
      '[CurrentBusinessResolution Diagnostics]\n'
      '  persisted business ID: $persistedId\n'
      '  persisted ID valid UUID?: $isPersistedValid\n'
      '  accessible business count: $accessibleCount\n'
      '  selected current business ID: $_currentBusinessId\n'
      '  current location ID: $_currentLocationId\n'
      '==========================================================',
    );
  }

  /// Resolves the current business ID from Supabase using strict server-authoritative precedence:
  /// 1. Persisted last_business_id — validated UUID and revalidated against Supabase.
  ///    Malformed or invalid UUIDs are discarded immediately without throwing.
  /// 2. Active memberships (where memberships.status == 'active').
  /// 3. Owned completed businesses.
  /// 4. Incomplete owned onboarding business.
  /// 5. Otherwise returns null (no business).
  ///
  /// CRITICAL: Startup must NEVER create a business automatically.
  Future<String?> resolveCurrentBusinessId({bool forceRefresh = false}) async {
    final persistedId = AppPreferencesService.instance.currentBusinessId;
    final isPersistedValid = isValidUuid(persistedId);

    // If persisted ID is malformed (e.g. legacy demo/synthetic ID), clear it immediately
    if (persistedId != null && persistedId.isNotEmpty && !isPersistedValid) {
      debugPrint(
        '[CurrentBusinessService] Discarding malformed cached business ID "$persistedId". Purging stale preference.',
      );
      await AppPreferencesService.instance.setCurrentBusinessId(null);
    }

    if (!isValidUuid(_currentBusinessId)) {
      _currentBusinessId = null;
      _currentBusiness = null;
    }

    if (!forceRefresh &&
        _currentBusinessId != null &&
        _currentBusinessId!.isNotEmpty &&
        isValidUuid(_currentBusinessId)) {
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
      debugPrint(
        '[CurrentBusinessService] Starting business resolution...\n'
        '  persisted business ID: $persistedId\n'
        '  persisted ID valid UUID?: $isPersistedValid',
      );

      // 1. Revalidate persisted last_business_id if present and valid UUID
      if (persistedId != null && persistedId.isNotEmpty && isPersistedValid) {
        try {
          // Check if user is owner of persisted business
          final ownedRow = await sb
              .from('businesses')
              .select()
              .eq('id', persistedId)
              .eq('owner_user_id', currentUserId)
              .maybeSingle();

          if (ownedRow != null) {
            // Check onboarding status of persisted business
            final sessionRow = await sb
                .from('onboarding_sessions')
                .select('status')
                .eq('business_id', persistedId)
                .maybeSingle();
            final isPersistedComplete =
                sessionRow != null && sessionRow['status'] == 'complete';

            if (!isPersistedComplete) {
              // Persisted business is incomplete. Check if user has an owned COMPLETED business.
              // A completed business ALWAYS takes precedence over an abandoned/in-progress onboarding.
              final allOwned = await sb
                  .from('businesses')
                  .select()
                  .eq('owner_user_id', currentUserId)
                  .order('created_at', ascending: false);

              if (allOwned.isNotEmpty) {
                final allBizIds = allOwned
                    .map((r) => r['id'] as String)
                    .where((id) => isValidUuid(id))
                    .toList();
                if (allBizIds.isNotEmpty) {
                  final completedSessions = await sb
                      .from('onboarding_sessions')
                      .select('business_id, status')
                      .inFilter('business_id', allBizIds)
                      .eq('status', 'complete');

                  if (completedSessions.isNotEmpty) {
                    final completedIdSet = completedSessions
                        .map((s) => s['business_id'] as String)
                        .toSet();
                    // Prioritize: 1. LaunchGrid 2. First owned business that is completed
                    final completedRow = allOwned.firstWhere(
                      (r) =>
                          (r['legal_name'] as String?)?.toLowerCase() ==
                              'launchgrid' &&
                          completedIdSet.contains(r['id']),
                      orElse: () => allOwned.firstWhere(
                        (r) => completedIdSet.contains(r['id']),
                      ),
                    );
                    final completedBiz = Business.fromJson(
                      Map<String, dynamic>.from(completedRow),
                    );
                    _currentBusiness = completedBiz;
                    _currentBusinessId = completedBiz.id;
                    await AppPreferencesService.instance
                        .setCurrentBusinessId(completedBiz.id);
                    notifyListeners();
                    _logDiagnostics(
                      persistedId: persistedId,
                      isPersistedValid: isPersistedValid,
                      accessibleCount: allOwned.length,
                    );
                    return completedBiz.id;
                  }
                }
              }
            }

            final biz = Business.fromJson(Map<String, dynamic>.from(ownedRow));
            _currentBusiness = biz;
            _currentBusinessId = biz.id;
            notifyListeners();
            _logDiagnostics(
              persistedId: persistedId,
              isPersistedValid: isPersistedValid,
              accessibleCount: 1,
            );
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
              _logDiagnostics(
                persistedId: persistedId,
                isPersistedValid: isPersistedValid,
                accessibleCount: 1,
              );
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
                _logDiagnostics(
                  persistedId: persistedId,
                  isPersistedValid: isPersistedValid,
                  accessibleCount: 1,
                );
                return biz.id;
              }
            }
          }

          // Persisted business ID is not authorized or membership suspended/deleted
          debugPrint(
            '[CurrentBusinessService] Persisted business $persistedId is no longer authorized. Purging.',
          );
          await AppPreferencesService.instance.setCurrentBusinessId(null);
        } catch (persistedError) {
          debugPrint(
            '[CurrentBusinessService] Error validating persisted business $persistedId: $persistedError. Clearing and continuing discovery.',
          );
          await AppPreferencesService.instance.setCurrentBusinessId(null);
        }
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
            _logDiagnostics(
              persistedId: persistedId,
              isPersistedValid: isPersistedValid,
              accessibleCount: memberRows.length,
            );
            return biz.id;
          } else {
            final bId = row['business_id'] as String?;
            if (bId != null && isValidUuid(bId)) {
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
                _logDiagnostics(
                  persistedId: persistedId,
                  isPersistedValid: isPersistedValid,
                  accessibleCount: memberRows.length,
                );
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
            .where((id) => isValidUuid(id))
            .toList();

        final completedBizIds = <String>{};
        if (bizIds.isNotEmpty) {
          // Check onboarding completion for owned businesses
          final sessions = await sb
              .from('onboarding_sessions')
              .select('business_id, status')
              .inFilter('business_id', bizIds);

          for (final s in sessions) {
            if (s['status'] == 'complete') {
              completedBizIds.add(s['business_id'] as String);
            }
          }
        }

        final totalAccessible = memberRows.length + ownedRows.length;

        // 3a. Prefer completed owned business (prefer LaunchGrid if present)
        final completedRows = ownedRows
            .where((r) => completedBizIds.contains(r['id']))
            .toList();
        if (completedRows.isNotEmpty) {
          final targetRow = completedRows.firstWhere(
            (r) =>
                (r['legal_name'] as String?)?.toLowerCase() == 'launchgrid',
            orElse: () => completedRows.first,
          );
          final biz = Business.fromJson(Map<String, dynamic>.from(targetRow));
          _currentBusiness = biz;
          _currentBusinessId = biz.id;
          await AppPreferencesService.instance.setCurrentBusinessId(biz.id);
          notifyListeners();
          _logDiagnostics(
            persistedId: persistedId,
            isPersistedValid: isPersistedValid,
            accessibleCount: totalAccessible,
          );
          return biz.id;
        }

        // 4. Incomplete owned onboarding business
        final firstRow = ownedRows.first;
        final biz = Business.fromJson(Map<String, dynamic>.from(firstRow));
        _currentBusiness = biz;
        _currentBusinessId = biz.id;
        await AppPreferencesService.instance.setCurrentBusinessId(biz.id);
        notifyListeners();
        _logDiagnostics(
          persistedId: persistedId,
          isPersistedValid: isPersistedValid,
          accessibleCount: totalAccessible,
        );
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
      _logDiagnostics(
        persistedId: persistedId,
        isPersistedValid: isPersistedValid,
        accessibleCount: 0,
      );
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

      final currentBizId = _currentBusinessId ?? _currentBusiness?.id;
      final onboardingBizId = existingBusinessId;

      // Fail closed if IDs conflict
      if (currentBizId != null &&
          onboardingBizId != null &&
          currentBizId.isNotEmpty &&
          onboardingBizId.isNotEmpty &&
          currentBizId != onboardingBizId) {
        debugPrint(
          '[CurrentBusinessService] Business ID mismatch: '
          'currentBusinessId=$currentBizId vs onboardingBusinessId=$onboardingBizId. Failing closed.',
        );
        throw StateError(
          'Business ID mismatch: current context ($currentBizId) does not match onboarding session ($onboardingBizId).',
        );
      }

      if (sb == null) {
        final targetBizId = (currentBizId != null && isValidUuid(currentBizId))
            ? currentBizId
            : (onboardingBizId != null && isValidUuid(onboardingBizId))
                ? onboardingBizId
                : '00000000-0000-0000-0000-000000000001';
        final fallbackBusiness = Business(
          id: targetBizId,
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

      final authUserId = user.id;

      // The save target business ID MUST be authoritative:
      // Prefer currentBusinessId from active context, fallback to onboardingBizId
      String? targetId = currentBizId ?? onboardingBizId;

      // If targetId is malformed, reject it
      if (targetId != null && !isValidUuid(targetId)) {
        debugPrint(
          '[CurrentBusinessService] Discarding invalid target business ID "$targetId".',
        );
        targetId = null;
      }

      // CRITICAL DUPLICATE BUSINESS PREVENTION:
      // If targetId is not specified, check if user ALREADY owns any businesses in database.
      // An existing user must NEVER insert a duplicate business simply because bootstrap failed.
      if (targetId == null || targetId.isEmpty) {
        try {
          final ownedExisting = await sb
              .from('businesses')
              .select('id')
              .eq('owner_user_id', authUserId)
              .order('created_at', ascending: false);

          if (ownedExisting.isNotEmpty) {
            final discoveredBizId = ownedExisting.first['id'] as String;
            debugPrint(
              '[CurrentBusinessService] Discovered existing owned business $discoveredBizId for user $authUserId. '
              'Switching operation from insert_business to update_business to prevent duplicate creation.',
            );
            targetId = discoveredBizId;
          }
        } catch (findErr) {
          debugPrint(
            '[CurrentBusinessService] Notice checking existing owned business: $findErr',
          );
        }
      }

      final isUpdate =
          targetId != null && targetId.isNotEmpty && isValidUuid(targetId);

      debugPrint(
        '==========================================================\n'
        '[BusinessSaveTrace]\n'
        '  auth user id: $authUserId\n'
        '  current business id: $currentBizId\n'
        '  onboarding business id: $onboardingBizId\n'
        '  save target business id: $targetId\n'
        '  operation: ${isUpdate ? "update_business" : "insert_business"}\n'
        '==========================================================',
      );

      Business? business;

      if (isUpdate) {
        // Existing business: strictly use UPDATE, NEVER insert a duplicate row
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
        } else {
          debugPrint(
            'Business update failed\n'
            'operation: update_business\n'
            'business_id: $targetId\n'
            'postgres_code: NOT_FOUND_OR_UNAUTHORIZED\n'
            'message: Existing business record not found or not owned by current user.',
          );
          throw PostgrestException(
            message: 'Existing business update failed: record $targetId not found or not owned by current user.',
            code: 'UPDATE_FAILED',
          );
        }
      } else {
        // Brand new merchant without existing business row: strictly INSERT
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

      // Ensure onboarding_sessions row is linked without resetting completed sessions
      try {
        final existingSession = await sb
            .from('onboarding_sessions')
            .select('status, current_step')
            .eq('business_id', business.id)
            .maybeSingle();

        final isAlreadyComplete = existingSession != null &&
            (existingSession['status'] == 'complete' ||
             (existingSession['current_step'] as num?)?.toInt() == 6);

        if (existingSession == null) {
          await sb.from('onboarding_sessions').upsert({
            'business_id': business.id,
            'user_id': user.id,
            'current_step': 1,
            'status': 'in_progress',
          }, onConflict: 'business_id,user_id');
        } else if (!isAlreadyComplete) {
          await sb.from('onboarding_sessions').update({
            'user_id': user.id,
            'current_step': 1,
            'status': 'in_progress',
          }).eq('business_id', business.id);
        } else {
          debugPrint(
            '[CurrentBusinessService] Business ${business.id} onboarding is already complete. Preserving status=complete.',
          );
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
        'Business save failed\n'
        'operation: update_business\n'
        'business_id: ${_currentBusinessId ?? existingBusinessId ?? "unknown"}\n'
        'postgres_code: ${pe.code ?? "UNKNOWN"}\n'
        'message: ${pe.message}\n'
        'details: ${pe.details ?? "none"}\n'
        'hint: ${pe.hint ?? "none"}',
      );
      rethrow;
    } catch (e, st) {
      debugPrint(
        'Business save failed\n'
        'operation: update_business\n'
        'business_id: ${_currentBusinessId ?? existingBusinessId ?? "unknown"}\n'
        'message: $e\n'
        'stackTrace: $st',
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
