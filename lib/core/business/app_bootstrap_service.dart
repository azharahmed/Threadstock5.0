import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/router/app_router.dart';
import '../auth/auth_service.dart';
import '../auth/authorization_service.dart';
import '../../features/onboarding/data/onboarding_repository.dart';
import '../../features/onboarding/domain/onboarding_completion_evaluator.dart';
import 'current_business_service.dart';

class BootstrapResult {
  final String initialRoute;
  final String? businessId;
  final bool isOnboardingCompleted;
  final int resumeStep;

  const BootstrapResult({
    required this.initialRoute,
    this.businessId,
    required this.isOnboardingCompleted,
    required this.resumeStep,
  });

  bool get isOnboardingComplete => isOnboardingCompleted;

  @override
  String toString() =>
      'BootstrapResult(initialRoute: $initialRoute, businessId: $businessId, isOnboardingCompleted: $isOnboardingCompleted, resumeStep: $resumeStep)';
}

class AppBootstrapService {
  AppBootstrapService._();

  static bool _isBootstrapping = false;
  static bool _isBootstrapped = false;
  static BootstrapResult? _lastResult;

  static bool get isBootstrapped => _isBootstrapped;
  static bool get isBootstrapping => _isBootstrapping;
  static BootstrapResult? get lastResult => _lastResult;

  /// Clears bootstrap session state on sign-out.
  static void clearSession() {
    _isBootstrapped = false;
    _isBootstrapping = false;
    _lastResult = null;
  }

  @visibleForTesting
  static void resetForTesting() => clearSession();

  @visibleForTesting
  static void setLastResultForTesting(BootstrapResult? result) {
    _lastResult = result;
    if (result != null) {
      _isBootstrapped = true;
    }
  }

  @visibleForTesting
  static void setIsBootstrappingForTesting(bool val) {
    _isBootstrapping = val;
  }

  static String routeForStep(int step) {
    switch (step) {
      case 0:
        return AppRoutes.onboardingWelcome;
      case 1:
      case 2:
        return AppRoutes.onboardingBusiness;
      case 3:
        return AppRoutes.onboardingLocation;
      case 4:
        return AppRoutes.onboardingCommerce;
      case 5:
        return AppRoutes.onboardingInventory;
      case 6:
        return AppRoutes.onboardingTeam;
      case 7:
      default:
        return AppRoutes.overview;
    }
  }

  /// Runs the full server-authoritative startup sequence:
  /// 1. Restore auth session
  ///    - If no valid session -> returns AppRoutes.login.
  /// 2. If authenticated, query businesses/memberships for user using precedence:
  ///    - explicit persisted last_business_id (revalidated against Supabase)
  ///    - active memberships
  ///    - owned completed business (prefer LaunchGrid / populated businesses)
  ///    - incomplete owned onboarding business
  /// 3. If no business found -> AppRoutes.onboardingBusiness
  /// 4. If business found: query onboarding status
  ///    - If complete -> AppRoutes.overview
  ///    - If incomplete -> route to first incomplete onboarding step
  ///
  /// CRITICAL: NEVER automatically creates an anonymous session or a business.
  static Future<BootstrapResult> bootstrap({SupabaseClient? client}) async {
    _isBootstrapping = true;

    final sb = client ??
        (() {
          try {
            return Supabase.instance.client;
          } catch (_) {
            return null;
          }
        })();

    if (sb != null) {
      await AuthService.instance.initialize(overrideClient: sb);
    }

    final user = AuthService.instance.currentUser;
    if (user == null) {
      debugPrint(
        '[AppBootstrapService] No active authenticated session. Routing to Login.',
      );
      final result = const BootstrapResult(
        initialRoute: AppRoutes.login,
        businessId: null,
        isOnboardingCompleted: false,
        resumeStep: 0,
      );
      _lastResult = result;
      _isBootstrapping = false;
      _isBootstrapped = true;
      return result;
    }

    debugPrint('[AppBootstrapService] Authenticated user active: ${user.id}');

    // 2. Query businesses & determine current business using server-authoritative precedence
    final businessService = CurrentBusinessService.instance;
    final resolvedBizId = await businessService.resolveCurrentBusinessId(
      forceRefresh: true,
    );

    if (resolvedBizId == null) {
      debugPrint(
        '[AppBootstrapService] No accessible businesses found. Routing to onboarding.',
      );
      final result = const BootstrapResult(
        initialRoute: AppRoutes.onboarding,
        businessId: null,
        isOnboardingCompleted: false,
        resumeStep: 1,
      );
      _lastResult = result;
      _isBootstrapping = false;
      _isBootstrapped = true;
      return result;
    }

    debugPrint(
      '[AppBootstrapService] Resolved active business: $resolvedBizId',
    );

    // Refresh application authorization context
    await AuthorizationService.instance.refreshAuthorization(
      businessId: resolvedBizId,
      overrideClient: sb,
    );

    // 3. Authoritative onboarding status evaluation
    final onboardingRepo = OnboardingRepository.instance;
    final progress = await onboardingRepo.loadProgressForBusiness(
      resolvedBizId,
    );
    final evaluation = await OnboardingCompletionEvaluator(client: sb)
        .evaluateOnboardingState(resolvedBizId);

    // 4. Route appropriately based on authoritative evaluation
    final bool isCompleted = evaluation.canEnterDashboard;
    final String targetRoute;
    final int effectiveStep;

    if (isCompleted) {
      targetRoute = AppRoutes.overview;
      effectiveStep = 6;
      debugPrint(
        '[AppBootstrapService] Business $resolvedBizId onboarding is COMPLETE -> Overview.',
      );
    } else {
      effectiveStep = evaluation.firstIncompleteStep;
      targetRoute = routeForStep(effectiveStep);
      debugPrint(
        '[AppBootstrapService] Business $resolvedBizId onboarding IN-PROGRESS -> Step $effectiveStep ($targetRoute).',
      );
    }

    final result = BootstrapResult(
      initialRoute: targetRoute,
      businessId: resolvedBizId,
      isOnboardingCompleted: isCompleted,
      resumeStep: effectiveStep,
    );

    _lastResult = result;
    _isBootstrapping = false;
    _isBootstrapped = true;

    // Requirement 6: Log diagnostic startup info
    final currentBizName = businessService.currentBusiness?.legalName ??
        progress.businessName ??
        'Unknown';
    debugPrint(
      '[Bootstrap Diagnostics]\n'
      'authUser: ${user.id}\n'
      'currentBusiness:\n$resolvedBizId\n\n'
      'businessName:\n$currentBizName\n\n'
      'onboarding:\n${isCompleted ? "complete" : "in_progress"}\n\n'
      'currentStep:\n$effectiveStep\n\n'
      'route:\n$targetRoute',
    );

    return result;
  }
}
