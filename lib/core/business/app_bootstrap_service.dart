import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/router/app_router.dart';
import '../auth/auth_service.dart';
import '../auth/authorization_service.dart';
import '../../features/onboarding/data/onboarding_repository.dart';
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

  @override
  String toString() =>
      'BootstrapResult(initialRoute: $initialRoute, businessId: $businessId, isOnboardingCompleted: $isOnboardingCompleted, resumeStep: $resumeStep)';
}

class AppBootstrapService {
  AppBootstrapService._();

  static String routeForStep(int step) {
    switch (step) {
      case 0:
        return AppRoutes.onboardingWelcome;
      case 1:
        return AppRoutes.onboardingBusiness;
      case 2:
        return AppRoutes.onboardingLocation;
      case 3:
        return AppRoutes.onboardingCommerce;
      case 4:
        return AppRoutes.onboardingInventory;
      case 5:
        return AppRoutes.onboardingTeam;
      case 6:
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
  ///    - owned completed business
  ///    - incomplete owned onboarding business
  /// 3. If no business found -> AppRoutes.onboardingBusiness
  /// 4. If business found: query onboarding status
  ///    - If complete -> AppRoutes.overview
  ///    - If incomplete -> route to first incomplete onboarding step
  ///
  /// CRITICAL: NEVER automatically creates an anonymous session or a business.
  static Future<BootstrapResult> bootstrap({SupabaseClient? client}) async {
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
      return const BootstrapResult(
        initialRoute: AppRoutes.login,
        businessId: null,
        isOnboardingCompleted: false,
        resumeStep: 0,
      );
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
      return const BootstrapResult(
        initialRoute: AppRoutes.onboarding,
        businessId: null,
        isOnboardingCompleted: false,
        resumeStep: 1,
      );
    }

    debugPrint(
      '[AppBootstrapService] Resolved active business: $resolvedBizId',
    );

    // Refresh application authorization context
    await AuthorizationService.instance.refreshAuthorization(
      businessId: resolvedBizId,
      overrideClient: sb,
    );

    // 3. Query onboarding status for that business
    final onboardingRepo = OnboardingRepository.instance;
    final progress = await onboardingRepo.loadProgressForBusiness(
      resolvedBizId,
    );

    // 4. Route appropriately
    if (progress.isOnboardingCompleted) {
      debugPrint(
        '[AppBootstrapService] Business $resolvedBizId onboarding is COMPLETE -> Overview.',
      );
      return BootstrapResult(
        initialRoute: AppRoutes.overview,
        businessId: resolvedBizId,
        isOnboardingCompleted: true,
        resumeStep: 6,
      );
    } else {
      final firstIncomplete = progress.firstIncompleteStep;
      final targetRoute = routeForStep(firstIncomplete);
      debugPrint(
        '[AppBootstrapService] Business $resolvedBizId onboarding IN-PROGRESS -> Step $firstIncomplete ($targetRoute).',
      );
      return BootstrapResult(
        initialRoute: targetRoute,
        businessId: resolvedBizId,
        isOnboardingCompleted: false,
        resumeStep: firstIncomplete,
      );
    }
  }
}
