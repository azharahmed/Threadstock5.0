import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/onboarding_progress.dart';
import '../../../core/business/current_business_service.dart';
import '../../business/domain/models/business.dart';

class OnboardingRepository {
  final SupabaseClient? client;

  OnboardingRepository({this.client}) {
    _progress = loadProgressSync();
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

  static File? _resolveCacheFile() {
    try {
      final configDir = Directory('config');
      if (!configDir.existsSync()) {
        configDir.createSync(recursive: true);
      }
      return File('config/onboarding_progress.json');
    } catch (_) {
      return null;
    }
  }

  OnboardingProgress loadProgressSync() {
    try {
      final file = _resolveCacheFile();
      if (file == null || !file.existsSync()) {
        _progress = const OnboardingProgress();
        return _progress;
      }

      final content = file.readAsStringSync();
      if (content.isEmpty) {
        _progress = const OnboardingProgress();
        return _progress;
      }

      final json = jsonDecode(content) as Map<String, dynamic>;
      _progress = OnboardingProgress.fromJson(json);
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
    } catch (e) {
      debugPrint('[OnboardingRepository] Error clearing onboarding cache: $e');
    }
  }

  /// Loads onboarding progress for an explicitly resolved business.
  Future<OnboardingProgress> loadProgressForBusiness(String businessId) async {
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

      // 2. Fetch onboarding session for this business
      final sessionRow = await supabase
          .from('onboarding_sessions')
          .select()
          .eq('business_id', businessId)
          .maybeSingle();

      if (sessionRow != null) {
        final currentStep = (sessionRow['current_step'] as num?)?.toInt() ?? 1;
        final status = sessionRow['status'] as String? ?? 'in_progress';
        final isComplete = status == 'complete' || currentStep >= 6;
        final inventoryMethod = sessionRow['inventory_start_method'] as String?;

        final bizComplete = isComplete || currentStep >= 2;
        final locComplete = isComplete || (bizComplete && currentStep >= 3);
        final comComplete = isComplete || (locComplete && currentStep >= 4);
        final invComplete = isComplete || (comComplete && currentStep >= 5);
        final teamComplete = isComplete || (invComplete && currentStep >= 6);

        _progress = _progress.copyWith(
          businessId: businessId,
          businessName: business?.legalName ?? _progress.businessName,
          businessType: business?.businessType ?? _progress.businessType,
          countryCode: business?.countryCode ?? _progress.countryCode,
          currencyCode: business?.currencyCode ?? _progress.currencyCode,
          locationRange: business?.locationRange ?? _progress.locationRange,
          isBusinessCompleted: bizComplete,
          isLocationCompleted: locComplete,
          isCommerceCompleted: comComplete,
          isInventoryCompleted: invComplete,
          isTeamCompleted: teamComplete,
          isOnboardingCompleted: isComplete,
          inventoryStartMethod:
              inventoryMethod ?? _progress.inventoryStartMethod,
        );
        _saveToDiskCache(_progress);
      } else {
        // Business exists but no onboarding session recorded yet
        _progress = _progress.copyWith(
          businessId: businessId,
          businessName: business?.legalName ?? _progress.businessName,
          businessType: business?.businessType ?? _progress.businessType,
          countryCode: business?.countryCode ?? _progress.countryCode,
          currencyCode: business?.currencyCode ?? _progress.currencyCode,
          locationRange: business?.locationRange ?? _progress.locationRange,
          isBusinessCompleted: false,
          isLocationCompleted: false,
          isCommerceCompleted: false,
          isInventoryCompleted: false,
          isTeamCompleted: false,
          isOnboardingCompleted: false,
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
    loadProgressSync();

    final supabase = _resolvedClient;
    if (supabase == null) return _progress;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return _progress;

      final resolvedBizId = await CurrentBusinessService.instance
          .resolveCurrentBusinessId();
      if (resolvedBizId != null && resolvedBizId.isNotEmpty) {
        return await loadProgressForBusiness(resolvedBizId);
      } else {
        // True new user with 0 businesses
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
      final file = _resolveCacheFile();
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

      int currentStep = 1;
      if (progress.isOnboardingCompleted) {
        currentStep = 6;
      } else if (progress.isTeamCompleted && progress.isInventoryCompleted) {
        currentStep = 6;
      } else if (progress.isInventoryCompleted) {
        currentStep = 5;
      } else if (progress.isCommerceCompleted) {
        currentStep = 4;
      } else if (progress.isLocationCompleted) {
        currentStep = 3;
      } else if (progress.isBusinessCompleted) {
        currentStep = 2;
      } else {
        currentStep = 1;
      }

      final status = progress.isOnboardingCompleted
          ? 'complete'
          : 'in_progress';
      final bizId =
          progress.businessId ??
          CurrentBusinessService.instance.currentBusinessId;

      if (bizId != null && bizId.isNotEmpty) {
        await supabase.from('onboarding_sessions').upsert({
          'business_id': bizId,
          'user_id': user.id,
          'current_step': currentStep,
          'status': status,
          if (progress.isOnboardingCompleted)
            'completed_at': DateTime.now().toIso8601String(),
          if (progress.inventoryStartMethod != null)
            'inventory_start_method': progress.inventoryStartMethod,
        }, onConflict: 'business_id,user_id');
      }
    } catch (e) {
      debugPrint('Error syncing onboarding session to Supabase: $e');
    }
  }

  Future<OnboardingProgress> markStepComplete(
    int step, {
    Map<String, dynamic>? data,
  }) async {
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

        String? createdBizId = updated.businessId;
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
                  existingBusinessId: updated.businessId,
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
        final channels = data?['selectedSalesChannels'] as Iterable<int>?;
        updated = updated.copyWith(
          isCommerceCompleted: true,
          selectedSalesChannels:
              channels?.toSet() ?? updated.selectedSalesChannels,
          paymentTerms:
              data?['paymentTerms'] as String? ?? updated.paymentTerms,
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
        final isCompleted = status == 'completed';
        updated = updated.copyWith(
          isInventoryCompleted: isCompleted,
          inventoryStartMethod:
              data?['inventoryStartMethod'] as String? ??
              updated.inventoryStartMethod,
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
        if (!updated.isTeamCompleted) {
          debugPrint(
            '[OnboardingRepository] Cannot mark Step 6 complete: Step 5 is incomplete.',
          );
          return _progress;
        }
        updated = updated.copyWith(isOnboardingCompleted: true);
        break;
    }

    await saveProgress(updated);
    return updated;
  }

  Future<OnboardingProgress> invalidateFrom(int step) async {
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

  Future<void> reset() async {
    _progress = const OnboardingProgress();
    _saveToDiskCache(_progress);
  }
}
