import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/onboarding_progress.dart';
import '../domain/onboarding_completion_evaluator.dart';
import '../../../core/business/current_business_service.dart';
import '../../../core/config/app_preferences_service.dart';
import '../../business/domain/models/business.dart';
import '../../inventory/data/location_repository.dart';

class OnboardingRepository {
  final SupabaseClient? client;

  OnboardingRepository({this.client}) {
    // Start with a blank, safe state. Do NOT load stale disk cache here.
    // The authoritative state is always fetched from Supabase via
    // loadProgressForBusiness(). The disk cache is only a hint — and only
    // valid when its businessId matches the currently active business.
    _progress = const OnboardingProgress();
  }

  static final OnboardingRepository instance = OnboardingRepository();

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  late OnboardingProgress _progress;

  OnboardingProgress get currentProgress => _progress;

  static File? _resolveCacheFile([String? businessId]) {
    try {
      final configDir = Directory('config');
      if (!configDir.existsSync()) {
        configDir.createSync(recursive: true);
      }
      final bizId = businessId ??
          CurrentBusinessService.instance.currentBusinessId ??
          AppPreferencesService.instance.currentBusinessId;
      if (bizId != null && bizId.isNotEmpty) {
        return File('config/onboarding_progress_$bizId.json');
      }
      return File('config/onboarding_progress.json');
    } catch (_) {
      return null;
    }
  }

  /// Loads progress from disk cache ONLY if it belongs to the currently
  /// active business (matched by businessId). If the cached businessId
  /// does not match the persisted current business, the cache is discarded
  /// to prevent cross-business state contamination.
  ///
  /// This is a fast synchronous path used as a warm-up hint. The authoritative
  /// state must always be confirmed via [loadProgressForBusiness].
  OnboardingProgress loadProgressSync() {
    try {
      final targetBizId =
          CurrentBusinessService.instance.currentBusinessId ??
          AppPreferencesService.instance.currentBusinessId;

      final file = _resolveCacheFile(targetBizId);
      if (file == null || !file.existsSync()) {
        // Fallback: check legacy un-scoped cache only if its businessId matches targetBizId
        final legacyFile = File('config/onboarding_progress.json');
        if (legacyFile.existsSync()) {
          final content = legacyFile.readAsStringSync();
          if (content.isNotEmpty) {
            final json = jsonDecode(content) as Map<String, dynamic>;
            final cached = OnboardingProgress.fromJson(json);
            if (targetBizId == null ||
                targetBizId.isEmpty ||
                cached.businessId == targetBizId) {
              _progress = cached;
              return _progress;
            }
          }
        }
        _progress = const OnboardingProgress();
        return _progress;
      }

      final content = file.readAsStringSync();
      if (content.isEmpty) {
        _progress = const OnboardingProgress();
        return _progress;
      }

      final json = jsonDecode(content) as Map<String, dynamic>;
      final cached = OnboardingProgress.fromJson(json);

      // If the cache does not belong to the currently active business,
      // discard it entirely. This prevents Business B's incomplete
      // onboarding from contaminating Business A's (completed) state.
      if (targetBizId != null &&
          targetBizId.isNotEmpty &&
          cached.businessId != null &&
          cached.businessId!.isNotEmpty &&
          cached.businessId != targetBizId) {
        debugPrint(
          '[OnboardingRepository] Disk cache businessId=${cached.businessId} '
          'does not match active business=$targetBizId. Discarding stale cache.',
        );
        _progress = const OnboardingProgress();
        return _progress;
      }

      _progress = cached;
      return _progress;
    } catch (e) {
      debugPrint('Error loading onboarding progress cache: $e');
      _progress = const OnboardingProgress();
      return _progress;
    }
  }

  /// Clears in-memory progress and disk cache on sign out or account switch.
  void clearCache() {
    _progress = const OnboardingProgress();
    try {
      final file = _resolveCacheFile();
      if (file != null && file.existsSync()) {
        file.deleteSync();
      }
      final legacy = File('config/onboarding_progress.json');
      if (legacy.existsSync()) {
        legacy.deleteSync();
      }
    } catch (e) {
      debugPrint('[OnboardingRepository] Error clearing onboarding cache: $e');
    }
  }

  /// Clears the cache for the specified business. Used when switching
  /// businesses to ensure the old business's progress does not leak into
  /// the newly selected business's context.
  void clearCacheForBusiness(String businessId) {
    if (_progress.businessId == businessId) {
      _progress = const OnboardingProgress();
    }
    try {
      final file = _resolveCacheFile(businessId);
      if (file != null && file.existsSync()) {
        file.deleteSync();
      }
      final legacy = File('config/onboarding_progress.json');
      if (legacy.existsSync()) {
        try {
          final content = legacy.readAsStringSync();
          final json = jsonDecode(content) as Map<String, dynamic>;
          if (json['businessId'] == businessId) {
            legacy.deleteSync();
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[OnboardingRepository] Error clearing cache for business $businessId: $e');
    }
  }

  /// Authoritative server evaluation of the 6 onboarding milestones for a business.
  Future<OnboardingEvaluation> evaluateOnboardingState(String businessId) async {
    return OnboardingCompletionEvaluator(client: _resolvedClient)
        .evaluateOnboardingState(businessId);
  }

  /// Loads onboarding progress for an explicitly resolved business.
  ///
  /// This is the AUTHORITATIVE path. It always queries Supabase and the
  /// result completely overwrites any locally-cached state.
  Future<OnboardingProgress> loadProgressForBusiness(String businessId) async {
    // Eagerly reset in-memory progress to blank for this business before
    // any async work. This prevents the caller from reading stale progress
    // from a different business if they access currentProgress before this
    // method completes.
    if (_progress.businessId != businessId) {
      _progress = const OnboardingProgress();
    }

    final supabase = _resolvedClient;
    if (supabase == null) {
      if (_progress.businessId == businessId) return _progress;
      _progress = _progress.copyWith(businessId: businessId);
      _saveToDiskCache(_progress);
      return _progress;
    }

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return _progress;

      // 1. Fetch business metadata
      final bizRow = await supabase
          .from('businesses')
          .select()
          .eq('id', businessId)
          .maybeSingle();

      Business? business;
      if (bizRow != null) {
        business = Business.fromJson(Map<String, dynamic>.from(bizRow));
        CurrentBusinessService.instance.setCurrentBusiness(business);
      } else {
        CurrentBusinessService.instance.setCurrentBusinessId(businessId);
      }

      // 2. Authoritative evaluation of all 6 milestones
      final evaluation = await evaluateOnboardingState(businessId);

      // 3. Fetch onboarding session for THIS BUSINESS ONLY.
      final sessionRow = await supabase
          .from('onboarding_sessions')
          .select()
          .eq('business_id', businessId)
          .maybeSingle();

      if (sessionRow != null) {
        final currentStep =
            (sessionRow['current_step'] as num?)?.toInt() ?? 1;
        final status = sessionRow['status'] as String? ?? 'in_progress';

        final bool isComplete = evaluation.canEnterDashboard;

        // RECONCILE INVALID COMPLETE STATE:
        // If database says status == 'complete' or current_step == 6, but
        // required milestones are incomplete, reconcile immediately in DB!
        if ((status == 'complete' || currentStep == 6) && !isComplete) {
          debugPrint(
            '[OnboardingRepository] Business $businessId has status=$status in database, '
            'but required prerequisites are INCOMPLETE (first incomplete step: ${evaluation.firstIncompleteStep} - ${evaluation.firstIncompleteStepName}). '
            'RECONCILING database to status=in_progress, current_step=${evaluation.firstIncompleteStep}, completed_at=null.',
          );
          try {
            await supabase.from('onboarding_sessions').update({
              'status': 'in_progress',
              'current_step': evaluation.firstIncompleteStep,
              'completed_at': null,
            }).eq('business_id', businessId);
          } catch (e) {
            debugPrint('[OnboardingRepository] Error writing reconciliation: $e');
          }
        } else if (currentStep < evaluation.firstIncompleteStep && !isComplete) {
          try {
            await supabase.from('onboarding_sessions').update({
              'status': 'in_progress',
              'current_step': evaluation.firstIncompleteStep,
            }).eq('business_id', businessId);
          } catch (e) {
            debugPrint(
              '[OnboardingRepository] Error advancing current_step to first incomplete step: $e',
            );
          }
        }

        final inventoryMethod =
            sessionRow['inventory_start_method'] as String?;

        _progress = _progress.copyWith(
          businessId: businessId,
          businessName: business?.legalName ?? _progress.businessName,
          businessType: business?.businessType ?? _progress.businessType,
          countryCode: business?.countryCode ?? _progress.countryCode,
          currencyCode: business?.currencyCode ?? _progress.currencyCode,
          locationRange: business?.locationRange ?? _progress.locationRange,
          isBusinessCompleted: evaluation.isBusinessSaved,
          isLocationCompleted: evaluation.isLocationSaved,
          isCommerceCompleted: evaluation.isCommerceSaved,
          isInventoryCompleted: evaluation.isInventoryResolved,
          isTeamCompleted: evaluation.isTeamResolved,
          isOnboardingCompleted: evaluation.canEnterDashboard,
          inventoryStartMethod:
              inventoryMethod ?? _progress.inventoryStartMethod,
        );
        _saveToDiskCache(_progress);
      } else {
        // Business exists but no onboarding session recorded yet.
        _progress = _progress.copyWith(
          businessId: businessId,
          businessName: business?.legalName ?? _progress.businessName,
          businessType: business?.businessType ?? _progress.businessType,
          countryCode: business?.countryCode ?? _progress.countryCode,
          currencyCode: business?.currencyCode ?? _progress.currencyCode,
          locationRange: business?.locationRange ?? _progress.locationRange,
          isBusinessCompleted: evaluation.isBusinessSaved,
          isLocationCompleted: evaluation.isLocationSaved,
          isCommerceCompleted: evaluation.isCommerceSaved,
          isInventoryCompleted: evaluation.isInventoryResolved,
          isTeamCompleted: evaluation.isTeamResolved,
          isOnboardingCompleted: evaluation.canEnterDashboard,
        );
        _saveToDiskCache(_progress);
      }
    } catch (e) {
      debugPrint(
        '[OnboardingRepository] Error loading progress for business $businessId: $e',
      );
    }

    return _progress;
  }

  Future<OnboardingProgress> loadProgress() async {
    // Warm up from disk cache only if it matches the active business.
    loadProgressSync();

    final supabase = _resolvedClient;
    if (supabase == null) return _progress;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return _progress;

      final resolvedBizId =
          await CurrentBusinessService.instance.resolveCurrentBusinessId();
      if (resolvedBizId != null && resolvedBizId.isNotEmpty) {
        return await loadProgressForBusiness(resolvedBizId);
      } else {
        // True new user with 0 businesses.
        _progress = const OnboardingProgress();
        _saveToDiskCache(_progress);
        return _progress;
      }
    } catch (e) {
      debugPrint('Error fetching onboarding session from Supabase: $e');
    }

    return _progress;
  }

  void _saveToDiskCache(OnboardingProgress progress) {
    try {
      final file = _resolveCacheFile(progress.businessId);
      if (file == null) return;
      file.writeAsStringSync(jsonEncode(progress.toJson()), flush: true);
    } catch (e) {
      debugPrint('Error saving onboarding progress cache: $e');
    }
  }

  Future<void> saveProgress(OnboardingProgress progress) async {
    _progress = progress;
    _saveToDiskCache(progress);

    final supabase = _resolvedClient;
    if (supabase == null) return;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final bizId =
          progress.businessId ??
          CurrentBusinessService.instance.currentBusinessId;

      if (bizId != null && bizId.isNotEmpty) {
        // REPLACE BLANKET RULE:
        // if complete AND persisted prerequisites valid: remain complete
        // if complete BUT persisted prerequisites invalid: reconcile to first incomplete milestone
        final sessionRow = await supabase
            .from('onboarding_sessions')
            .select('status, current_step')
            .eq('business_id', bizId)
            .maybeSingle();

        final isAlreadyComplete = sessionRow != null &&
            (sessionRow['status'] == 'complete' ||
             (sessionRow['current_step'] as num?)?.toInt() == 6);

        if (isAlreadyComplete) {
          final eval = await evaluateOnboardingState(bizId);
          if (eval.canEnterDashboard) {
            debugPrint(
              '[OnboardingRepository] Business $bizId onboarding is genuinely complete in database with all prerequisites valid. '
              'Remaining complete.',
            );
            _progress = _progress.copyWith(
              isOnboardingCompleted: true,
              isBusinessCompleted: true,
              isLocationCompleted: true,
              isCommerceCompleted: true,
              isInventoryCompleted: true,
              isTeamCompleted: true,
            );
            _saveToDiskCache(_progress);
            return;
          } else {
            debugPrint(
              '[OnboardingRepository] Business $bizId has status=complete in database, '
              'but persisted prerequisites are INVALID (first incomplete step: ${eval.firstIncompleteStep} - ${eval.firstIncompleteStepName}). '
              'Reconciling to in_progress at step ${eval.firstIncompleteStep}.',
            );
          }
        }

        int currentStep = 2;
        if (progress.isOnboardingCompleted) {
          currentStep = 6;
        } else if (progress.isTeamCompleted) {
          currentStep = 6;
        } else if (progress.isInventoryCompleted) {
          currentStep = 6;
        } else if (progress.isCommerceCompleted) {
          currentStep = 5;
        } else if (progress.isLocationCompleted) {
          currentStep = 4;
        } else if (progress.isBusinessCompleted) {
          currentStep = 3;
        } else {
          currentStep = 2;
        }

        final status =
            progress.isOnboardingCompleted ? 'complete' : 'in_progress';

        await supabase.from('onboarding_sessions').upsert({
          'business_id': bizId,
          'user_id': user.id,
          'current_step': currentStep,
          'status': status,
          if (progress.isOnboardingCompleted)
            'completed_at': DateTime.now().toIso8601String(),
          if (!progress.isOnboardingCompleted)
            'completed_at': null,
          if (progress.inventoryStartMethod != null)
            'inventory_start_method': progress.inventoryStartMethod,
        }, onConflict: 'business_id,user_id');
      }
    } on PostgrestException catch (pe) {
      debugPrint(
        'Onboarding session update failed\n'
        'operation: update_onboarding_session\n'
        'postgres_code: ${pe.code ?? "UNKNOWN"}\n'
        'message: ${pe.message}\n'
        'details: ${pe.details ?? "none"}\n'
        'hint: ${pe.hint ?? "none"}',
      );
      rethrow;
    } catch (e) {
      debugPrint('Error syncing onboarding session to Supabase: $e');
      rethrow;
    }
  }

  Future<OnboardingProgress> markStepComplete(
    int step, {
    Map<String, dynamic>? data,
  }) async {
    final supabase = _resolvedClient;
    OnboardingProgress updated = _progress;

    switch (step) {
      case 1:
        final name =
            (data?['businessName'] as String?)?.trim() ??
            updated.businessName?.trim() ??
            '';
        final type =
            (data?['businessType'] as String?)?.trim() ??
            updated.businessType?.trim() ??
            '';
        final country =
            (data?['countryCode'] as String?)?.trim() ??
            updated.countryCode?.trim() ??
            '';
        final currency =
            (data?['currencyCode'] as String?)?.trim() ??
            updated.currencyCode?.trim() ??
            '';
        final locRange = CurrentBusinessService.normalizeLocationRange(
          (data?['locationRange'] as String?)?.trim() ??
              updated.locationRange?.trim() ??
              '1',
        );

        final currentBizId = CurrentBusinessService.instance.currentBusinessId ??
            CurrentBusinessService.instance.currentBusiness?.id;
        final targetBizId = currentBizId ?? updated.businessId;

        String? createdBizId = targetBizId;
        if (name.isNotEmpty &&
            type.isNotEmpty &&
            country.isNotEmpty &&
            currency.isNotEmpty) {
          try {
            final business = await CurrentBusinessService.instance
                .createOrUpdateBusinessForOwner(
                  legalName: name,
                  businessType: type,
                  countryCode: country,
                  currencyCode: currency,
                  locationRange: locRange,
                  existingBusinessId: targetBizId,
                );
            createdBizId = business.id;
          } catch (e) {
            debugPrint(
              '[OnboardingRepository] Error persisting Step 1 business: $e',
            );
            rethrow;
          }
        }

        updated = updated.copyWith(
          isBusinessCompleted: true,
          businessId: createdBizId ?? updated.businessId,
          businessName: name,
          businessType: type,
          countryCode: country,
          currencyCode: currency,
          locationRange: locRange,
        );
        break;
      case 2:
        if (!updated.isBusinessCompleted) {
          debugPrint(
            '[OnboardingRepository] Cannot mark Step 2 complete: Step 1 is incomplete.',
          );
          return _progress;
        }
        final locs = data?['configuredLocations'] as List<dynamic>?;
        updated = updated.copyWith(
          isLocationCompleted: true,
          configuredLocations: locs != null
              ? locs.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : updated.configuredLocations,
        );
        break;
      case 3:
        if (!updated.isLocationCompleted) {
          debugPrint(
            '[OnboardingRepository] Cannot mark Step 3 complete: Step 2 is incomplete.',
          );
          return _progress;
        }
        final channels = data?['selectedSalesChannels'] as Iterable?;
        final paymentTerms = (data?['paymentTerms'] as String?)?.trim() ??
            updated.paymentTerms ??
            'Net 30';
        final taxSystem = (data?['taxSystem'] as String?)?.trim() ?? 'GST — India';

        final currentBizId = CurrentBusinessService.instance.currentBusinessId ??
            CurrentBusinessService.instance.currentBusiness?.id;
        final targetBizId = currentBizId ?? updated.businessId;

        if (supabase != null && targetBizId != null) {
          try {
            final channelStrings = channels?.map((c) {
              if (c == 0) return 'In-Store Retail';
              if (c == 1) return 'Wholesale';
              if (c == 2) return 'Online Store';
              if (c == 3) return 'Social Commerce';
              return c.toString();
            }).toList() ?? ['In-Store Retail'];

            String normalizedTaxSystem = 'Country tax system';
            if (taxSystem.isNotEmpty) {
              final lower = taxSystem.toLowerCase();
              if (lower.contains('gst') || lower.contains('india')) {
                normalizedTaxSystem = 'GST — India';
              } else if (lower.contains('vat')) {
                normalizedTaxSystem = 'VAT';
              } else if (lower.contains('sales tax')) {
                normalizedTaxSystem = 'Sales Tax';
              }
            }

            await supabase.from('business_commerce_profiles').upsert({
              'business_id': targetBizId,
              'sales_channels': channelStrings.isNotEmpty ? channelStrings : ['In-Store Retail'],
              'preferred_payment_terms': paymentTerms.isNotEmpty ? paymentTerms : 'Net 30',
              'tax_system': normalizedTaxSystem,
            }, onConflict: 'business_id');
          } catch (e) {
            debugPrint('[OnboardingRepository] Error persisting commerce profile: $e');
            rethrow;
          }
        }

        updated = updated.copyWith(
          isCommerceCompleted: true,
          selectedSalesChannels: channels != null
              ? channels
                  .map((e) => e is int ? e : int.tryParse(e.toString()) ?? 0)
                  .toSet()
              : updated.selectedSalesChannels,
          paymentTerms: paymentTerms,
        );
        break;
      case 4:
        if (!updated.isCommerceCompleted) {
          debugPrint(
            '[OnboardingRepository] Cannot mark Step 4 complete: Step 3 is incomplete.',
          );
          return _progress;
        }
        final status = data?['inventorySetupStatus'] as String? ?? 'completed';
        final isCompleted = status == 'completed' || status == 'skipped';
        final method = data != null && data.containsKey('inventoryStartMethod')
            ? data['inventoryStartMethod'] as String?
            : updated.inventoryStartMethod;
        updated = updated.copyWith(
          isInventoryCompleted: isCompleted,
          inventoryStartMethod: method,
          inventorySetupStatus: status,
        );
        break;
      case 5:
        if (!updated.isInventoryCompleted) {
          debugPrint(
            '[OnboardingRepository] Cannot mark Step 5 complete: Step 4 is incomplete.',
          );
          return _progress;
        }
        final invites = data?['savedTeamInvites'] as List<dynamic>?;
        updated = updated.copyWith(
          isTeamCompleted: true,
          savedTeamInvites: invites != null
              ? invites.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : updated.savedTeamInvites,
        );
        break;
      case 6:
        updated = updated.copyWith(
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: true,
          isInventoryCompleted: true,
          isTeamCompleted: true,
          isOnboardingCompleted: true,
          inventoryStartMethod:
              data?['inventoryStartMethod'] as String? ??
              updated.inventoryStartMethod,
        );
        break;
    }

    await saveProgress(updated);

    final resolvedBizId = updated.businessId ??
        CurrentBusinessService.instance.currentBusinessId ??
        CurrentBusinessService.instance.currentBusiness?.id;
    if (resolvedBizId != null && resolvedBizId.isNotEmpty && _resolvedClient != null) {
      try {
        final freshProgress = await loadProgressForBusiness(resolvedBizId);
        return freshProgress;
      } catch (e) {
        debugPrint('[OnboardingRepository] Error refreshing progress for business $resolvedBizId: $e');
      }
    }

    return updated;
  }

  Future<OnboardingProgress> invalidateFrom(int step) async {
    // If onboarding is already completed, never invalidate or reset!
    if (_progress.isOnboardingCompleted) {
      debugPrint(
        '[OnboardingRepository] Refusing to invalidate steps: onboarding is already COMPLETE.',
      );
      return _progress;
    }

    OnboardingProgress updated = _progress;

    if (step <= 1) {
      updated = updated.copyWith(
        isBusinessCompleted: false,
        isLocationCompleted: false,
        isCommerceCompleted: false,
        isInventoryCompleted: false,
        isTeamCompleted: false,
        isOnboardingCompleted: false,
      );
    } else if (step <= 2) {
      updated = updated.copyWith(
        isLocationCompleted: false,
        isCommerceCompleted: false,
        isInventoryCompleted: false,
        isTeamCompleted: false,
        isOnboardingCompleted: false,
      );
    } else if (step <= 3) {
      updated = updated.copyWith(
        isCommerceCompleted: false,
        isInventoryCompleted: false,
        isTeamCompleted: false,
        isOnboardingCompleted: false,
      );
    } else if (step <= 4) {
      updated = updated.copyWith(
        isInventoryCompleted: false,
        inventorySetupStatus: 'not_started',
        isTeamCompleted: false,
        isOnboardingCompleted: false,
      );
    } else if (step <= 5) {
      updated = updated.copyWith(
        isTeamCompleted: false,
        isOnboardingCompleted: false,
      );
    } else if (step <= 6) {
      updated = updated.copyWith(isOnboardingCompleted: false);
    }

    await saveProgress(updated);
    return updated;
  }

  /// Checks whether onboarding for the given business is complete.
  /// Checks in-memory progress first, then verifies disk cache.
  /// Location and Commerce are MANDATORY.
  bool isBusinessComplete(String businessId) {
    if (businessId.isEmpty) return false;
    if (_progress.businessId == businessId &&
        _progress.isOnboardingCompleted &&
        _progress.isLocationCompleted &&
        _progress.isCommerceCompleted) {
      return true;
    }
    try {
      final file = _resolveCacheFile(businessId);
      if (file != null && file.existsSync()) {
        final content = file.readAsStringSync();
        if (content.isNotEmpty) {
          final json = jsonDecode(content) as Map<String, dynamic>;
          if (json['businessId'] == businessId &&
              json['isOnboardingCompleted'] == true &&
              json['isLocationCompleted'] == true &&
              json['isCommerceCompleted'] == true) {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  /// Authoritative skip & go to dashboard method (Requirement 5).
  /// Location is MANDATORY: skip cannot bypass mandatory steps.
  Future<OnboardingProgress> skipToDashboard({
    String? businessId,
    String? inventoryStartMethod,
  }) async {
    final targetBizId = businessId ??
        CurrentBusinessService.instance.currentBusinessId ??
        _progress.businessId;

    // Verify location is saved before allowing skip!
    int locCount = 0;
    final supabase = _resolvedClient;
    if (supabase != null && targetBizId != null && targetBizId.isNotEmpty) {
      try {
        final locRows = await supabase
            .from('locations')
            .select('id')
            .eq('business_id', targetBizId)
            .eq('status', 'active');
        locCount = (locRows as List).length;
      } catch (_) {}
    }
    if (locCount == 0 && targetBizId != null) {
      final locs = await LocationRepository(client: supabase).getLocations(businessId: targetBizId);
      locCount = locs.length;
    }
    if (locCount == 0 && _progress.isLocationCompleted) {
      locCount = 1;
    }
    if (locCount == 0) {
      throw StateError(
        'Cannot skip to dashboard: at least one location must be configured.',
      );
    }

    final updated = _progress.copyWith(
      isBusinessCompleted: true,
      isLocationCompleted: true,
      isCommerceCompleted: true,
      isInventoryCompleted: true,
      isTeamCompleted: true,
      isOnboardingCompleted: true,
      inventorySetupStatus: 'skipped',
      inventoryStartMethod:
          inventoryStartMethod ?? _progress.inventoryStartMethod,
      businessId: targetBizId,
    );
    _progress = updated;
    _saveToDiskCache(updated);

    if (supabase != null && targetBizId != null && targetBizId.isNotEmpty) {
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase.from('onboarding_sessions').upsert({
          'business_id': targetBizId,
          'user_id': user.id,
          'current_step': 6,
          'status': 'complete',
          'completed_at': DateTime.now().toIso8601String(),
          if (updated.inventoryStartMethod != null)
            'inventory_start_method': updated.inventoryStartMethod,
        }, onConflict: 'business_id,user_id');
      }
    }

    return updated;
  }

  Future<void> reset() async {
    _progress = const OnboardingProgress();
    _saveToDiskCache(_progress);
  }
}
