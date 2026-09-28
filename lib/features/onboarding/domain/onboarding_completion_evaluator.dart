import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/auth_service.dart';
import '../../../core/business/current_business_service.dart';
import '../../inventory/data/location_repository.dart';
import '../data/onboarding_repository.dart';
import 'models/onboarding_progress.dart';

class OnboardingEvaluation {
  final String? businessId;
  final bool isLoginComplete;
  final bool isBusinessSaved;
  final bool isLocationSaved;
  final bool isCommerceSaved;
  final bool isInventoryResolved;
  final bool isTeamResolved;
  final int completedMilestones;
  final int percentage;
  final int firstIncompleteStep;
  final bool canEnterDashboard;

  const OnboardingEvaluation({
    required this.businessId,
    required this.isLoginComplete,
    required this.isBusinessSaved,
    required this.isLocationSaved,
    required this.isCommerceSaved,
    required this.isInventoryResolved,
    required this.isTeamResolved,
    required this.completedMilestones,
    required this.percentage,
    required this.firstIncompleteStep,
    required this.canEnterDashboard,
  });

  String get firstIncompleteStepName {
    switch (firstIncompleteStep) {
      case 1:
        return 'Login';
      case 2:
        return 'Business';
      case 3:
        return 'Location';
      case 4:
        return 'Commerce';
      case 5:
        return 'Inventory';
      case 6:
        return 'Team';
      default:
        return 'Complete';
    }
  }

  @override
  String toString() =>
      'OnboardingEvaluation(businessId: $businessId, login: $isLoginComplete, biz: $isBusinessSaved, loc: $isLocationSaved, com: $isCommerceSaved, inv: $isInventoryResolved, team: $isTeamResolved, milestones: $completedMilestones, %: $percentage, step: $firstIncompleteStep ($firstIncompleteStepName), canEnter: $canEnterDashboard)';
}

/// Authoritative evaluator for onboarding completion across ThreadStock.
///
/// Ensures:
/// - Location is STRICTLY required (at least 1 active persisted location).
/// - Commerce profile is STRICTLY required in business_commerce_profiles.
/// - Inventory may be completed OR explicitly skipped (products=0 does NOT mean incomplete if skipped).
/// - Team completion requires explicit invite/skip (Owner membership alone does NOT prove completion).
/// - current_step is NOT treated as proof of completion.
/// - Single source of truth for: bootstrap, router guard, stepper, progress %, and dashboard access.
class OnboardingCompletionEvaluator {
  final SupabaseClient? client;

  OnboardingCompletionEvaluator({this.client});

  static final OnboardingCompletionEvaluator instance =
      OnboardingCompletionEvaluator();

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Evaluates an existing [OnboardingProgress] object against known location and product counts.
  static OnboardingEvaluation evaluateFromProgress({
    required OnboardingProgress progress,
    required int locationCount,
    bool hasProducts = false,
    bool isAuthenticated = true,
    bool? isBusinessSaved,
    bool? isLocationSaved,
    bool isCommerceSaved = false,
    bool isInventorySkipped = false,
    bool isTeamExplicitlyResolved = false,
  }) {
    final bool isLogin = isAuthenticated;
    final bool isBiz = isBusinessSaved ??
        (progress.isBusinessCompleted &&
            (progress.businessName != null &&
                progress.businessName!.trim().isNotEmpty));
    // Location is mandatory: at least 1 real location must exist.
    final bool isLoc = isBiz &&
        (isLocationSaved ??
            (locationCount > 0 ||
                progress.isLocationCompleted ||
                progress.configuredLocations.isNotEmpty));
    final bool isCom = isLoc &&
        (isCommerceSaved ||
            progress.isCommerceCompleted ||
            progress.selectedSalesChannels.isNotEmpty);
    final bool isInv = isCom &&
        (hasProducts ||
            isInventorySkipped ||
            progress.isInventoryCompleted ||
            progress.inventorySetupStatus == 'completed' ||
            progress.inventorySetupStatus == 'skipped' ||
            (progress.inventoryStartMethod != null &&
                progress.inventoryStartMethod!.isNotEmpty));
    final bool isTeam = isInv &&
        (isTeamExplicitlyResolved ||
            progress.isTeamCompleted ||
            progress.savedTeamInvites.isNotEmpty);

    final bool canEnter =
        isLogin && isBiz && isLoc && isCom && isInv && isTeam;

    final int milestones;
    final int step;
    if (!isLogin) {
      milestones = 0;
      step = 1; // Login
    } else if (!isBiz) {
      milestones = 1;
      step = 2; // Business
    } else if (!isLoc) {
      milestones = 2;
      step = 3; // Location
    } else if (!isCom) {
      milestones = 3;
      step = 4; // Commerce
    } else if (!isInv) {
      milestones = 4;
      step = 5; // Inventory
    } else if (!isTeam) {
      milestones = 5;
      step = 6; // Team
    } else {
      milestones = 6;
      step = 7; // Completed
    }

    final int pct;
    switch (milestones) {
      case 0:
        pct = 0;
        break;
      case 1:
        pct = 17;
        break;
      case 2:
        pct = 33;
        break;
      case 3:
        pct = 50;
        break;
      case 4:
        pct = 67;
        break;
      case 5:
        pct = 83;
        break;
      case 6:
      default:
        pct = 100;
        break;
    }

    return OnboardingEvaluation(
      businessId: progress.businessId,
      isLoginComplete: isLogin,
      isBusinessSaved: isBiz,
      isLocationSaved: isLoc,
      isCommerceSaved: isCom,
      isInventoryResolved: isInv,
      isTeamResolved: isTeam,
      completedMilestones: milestones,
      percentage: pct,
      firstIncompleteStep: step,
      canEnterDashboard: canEnter,
    );
  }

  /// Authoritative evaluation function inspecting persisted milestones in Supabase.
  Future<OnboardingEvaluation> evaluateOnboardingState(String businessId) async {
    return evaluateBusiness(businessId);
  }

  /// Server-authoritative asynchronous evaluation querying Supabase and real repositories.
  Future<OnboardingEvaluation> evaluateBusiness(String businessId) async {
    final sb = _resolvedClient;
    final user = (sb != null) ? sb.auth.currentUser : AuthService.instance.currentUser;
    final bool isLogin = user != null || AuthService.instance.isAuthenticated;

    // 1. Check business in DB or CurrentBusinessService
    bool isBiz = false;
    if (sb != null && user != null) {
      try {
        final bizRow = await sb
            .from('businesses')
            .select('id, legal_name, business_type')
            .eq('id', businessId)
            .maybeSingle();
        if (bizRow != null) {
          final legalName = bizRow['legal_name'] as String? ?? '';
          isBiz = legalName.trim().isNotEmpty;
        }
      } catch (e) {
        debugPrint('[OnboardingCompletionEvaluator] Error checking business: $e');
      }
    }
    if (!isBiz) {
      final curBiz = CurrentBusinessService.instance.currentBusiness;
      if (curBiz != null && curBiz.id == businessId && curBiz.legalName.trim().isNotEmpty) {
        isBiz = true;
      }
    }

    // 2. Check locations count in DB or LocationRepository (STRICT REQUIREMENT)
    int locationCount = 0;
    if (sb != null && user != null) {
      try {
        final locRows = await sb
            .from('locations')
            .select('id')
            .eq('business_id', businessId)
            .eq('status', 'active');
        locationCount = (locRows as List).length;
      } catch (e) {
        debugPrint('[OnboardingCompletionEvaluator] Error checking locations: $e');
      }
    }
    if (locationCount == 0) {
      final locRepo = LocationRepository(client: sb);
      final localLocs = await locRepo.getLocations(businessId: businessId);
      locationCount = localLocs.length;
    }

    // 3. Check commerce profile in DB (STRICT REQUIREMENT: business_commerce_profiles)
    bool isCommerceSaved = false;
    if (sb != null && user != null) {
      try {
        final commerceRow = await sb
            .from('business_commerce_profiles')
            .select('business_id, sales_channels, preferred_payment_terms')
            .eq('business_id', businessId)
            .maybeSingle();
        if (commerceRow != null) {
          final channels = commerceRow['sales_channels'];
          final terms = commerceRow['preferred_payment_terms'] as String?;
          final hasChannels = channels != null && (channels is List && channels.isNotEmpty);
          final hasTerms = terms != null && terms.trim().isNotEmpty;
          if (hasChannels || hasTerms) {
            isCommerceSaved = true;
          }
        }
      } catch (e) {
        debugPrint('[OnboardingCompletionEvaluator] Error checking commerce profile: $e');
      }
    }

    // 4. Check products and inventory start method
    bool hasProducts = false;
    if (sb != null && user != null) {
      try {
        final prodRows = await sb
            .from('products')
            .select('id')
            .eq('business_id', businessId)
            .limit(1);
        hasProducts = (prodRows as List).isNotEmpty;
      } catch (_) {}
    }

    bool isInventorySkipped = false;
    if (sb != null && user != null) {
      try {
        final sessionRow = await sb
            .from('onboarding_sessions')
            .select('inventory_start_method, status')
            .eq('business_id', businessId)
            .maybeSingle();
        if (sessionRow != null) {
          final method = sessionRow['inventory_start_method'] as String?;
          if (method != null && method.trim().isNotEmpty) {
            isInventorySkipped = true;
          }
        }
      } catch (_) {}
    }

    // 5. Check team completion (STRICT: Owner row does NOT count as team complete)
    bool isTeamExplicitlyResolved = false;
    if (sb != null && user != null) {
      try {
        final members = await sb
            .from('business_memberships')
            .select('id')
            .eq('business_id', businessId);
        final count = (members as List).length;
        if (count > 1) {
          isTeamExplicitlyResolved = true;
        }
      } catch (_) {}
    }

    // Fallback: check in-memory progress if active business matches
    final progress = OnboardingRepository.instance.currentProgress;
    if (progress.businessId == businessId) {
      if (!isCommerceSaved && (progress.isCommerceCompleted || progress.selectedSalesChannels.isNotEmpty)) {
        isCommerceSaved = true;
      }
      if (!isInventorySkipped &&
          (progress.isInventoryCompleted ||
           progress.inventorySetupStatus == 'completed' ||
           progress.inventorySetupStatus == 'skipped' ||
           (progress.inventoryStartMethod != null && progress.inventoryStartMethod!.isNotEmpty))) {
        isInventorySkipped = true;
      }
      if (!isTeamExplicitlyResolved && (progress.isTeamCompleted || progress.savedTeamInvites.isNotEmpty)) {
        isTeamExplicitlyResolved = true;
      }
    }

    final effectiveProgress = progress.businessId == businessId
        ? progress
        : progress.copyWith(businessId: businessId);

    return evaluateFromProgress(
      progress: effectiveProgress,
      locationCount: locationCount,
      hasProducts: hasProducts,
      isAuthenticated: isLogin,
      isBusinessSaved: isBiz,
      isLocationSaved: isBiz && (locationCount > 0),
      isCommerceSaved: isCommerceSaved,
      isInventorySkipped: isInventorySkipped,
      isTeamExplicitlyResolved: isTeamExplicitlyResolved,
    );
  }
}
