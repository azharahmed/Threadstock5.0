import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/app/router/app_router.dart';
import 'package:threadstock/app/shell/app_loading_shell.dart';
import 'package:threadstock/app/shell/app_shell.dart';
import 'package:threadstock/core/auth/auth_service.dart';
import 'package:threadstock/core/business/app_bootstrap_service.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';

class _MockAuthoritativeOnboardingRepo extends OnboardingRepository {
  _MockAuthoritativeOnboardingRepo({
    required this.progress,
  });

  OnboardingProgress progress;

  @override
  OnboardingProgress get currentProgress => progress;

  @override
  OnboardingProgress loadProgressSync() => progress;

  @override
  Future<OnboardingProgress> loadProgress() async => progress;

  @override
  Future<OnboardingProgress> loadProgressForBusiness(String businessId) async =>
      progress;

  @override
  Future<void> saveProgress(OnboardingProgress updated) async {
    progress = updated;
  }

  @override
  Future<OnboardingProgress> skipToDashboard({
    String? businessId,
    String? inventoryStartMethod,
  }) async {
    progress = progress.copyWith(
      isBusinessCompleted: true,
      isLocationCompleted: true,
      isCommerceCompleted: true,
      isInventoryCompleted: true,
      isTeamCompleted: true,
      isOnboardingCompleted: true,
      inventorySetupStatus: 'skipped',
      inventoryStartMethod: inventoryStartMethod ?? progress.inventoryStartMethod,
      businessId: businessId ?? progress.businessId,
    );
    return progress;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const launchGridBizId = '863b4f7b-7a8e-4ffa-a4aa-e4cd453613af';

  void setDesktopSize(WidgetTester tester) {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  setUp(() async {
    AppRouter.setAuthOverrideForTesting(true);
    await AppPreferencesService.instance.setCurrentBusinessId(launchGridBizId);
  });

  tearDown(() async {
    AppRouter.setRepositoryForTesting(null);
    AppRouter.setAuthOverrideForTesting(null);
    AppBootstrapService.resetForTesting();
  });

  group('THREADSTOCK COMPLETED ONBOARDING BOOTSTRAP VERIFICATION TESTS', () {
    testWidgets(
      '1. LaunchGrid complete + step 6 -> app startup -> Overview',
      (tester) async {
        setDesktopSize(tester);
        final repo = _MockAuthoritativeOnboardingRepo(
          progress: const OnboardingProgress(
            businessId: launchGridBizId,
            businessName: 'LaunchGrid',
            isBusinessCompleted: true,
            isLocationCompleted: true,
            isCommerceCompleted: true,
            isInventoryCompleted: true,
            isTeamCompleted: true,
            isOnboardingCompleted: true,
          ),
        );
        AppRouter.setRepositoryForTesting(repo);

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRoutes.overview,
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        );
        await tester.pumpAndSettle();

        // Must render AppShell/Dashboard and never OnboardingPage
        expect(find.byType(AppShell), findsOneWidget);
        expect(find.byType(OnboardingPage), findsNothing);
      },
    );

    testWidgets(
      '2. App restart with completed status routes directly to Overview',
      (tester) async {
        setDesktopSize(tester);
        final repo = _MockAuthoritativeOnboardingRepo(
          progress: const OnboardingProgress(
            businessId: launchGridBizId,
            businessName: 'LaunchGrid',
            isBusinessCompleted: true,
            isLocationCompleted: true,
            isCommerceCompleted: true,
            isInventoryCompleted: true,
            isTeamCompleted: true,
            isOnboardingCompleted: true,
          ),
        );
        AppRouter.setRepositoryForTesting(repo);

        // Simulate app boot with '/' route
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: '/',
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppShell), findsOneWidget);
        expect(find.byType(OnboardingPage), findsNothing);
      },
    );

    testWidgets(
      '3. Sign-out clears local caches, and subsequent completed user sign-in routes to Overview',
      (tester) async {
        setDesktopSize(tester);

        // Configure current state
        await AppPreferencesService.instance.setCurrentBusinessId(launchGridBizId);
        CurrentBusinessService.instance.setCurrentBusinessId(launchGridBizId);

        // Perform sign out
        await AuthService.instance.signOut();

        expect(CurrentBusinessService.instance.currentBusinessId, isNull);
        expect(AppPreferencesService.instance.currentBusinessId, isNull);
        expect(AppBootstrapService.isBootstrapped, isFalse);

        // Simulate re-authenticated user with completed onboarding
        AppRouter.setAuthOverrideForTesting(true);
        await AppPreferencesService.instance.setCurrentBusinessId(launchGridBizId);
        final repo = _MockAuthoritativeOnboardingRepo(
          progress: const OnboardingProgress(
            businessId: launchGridBizId,
            businessName: 'LaunchGrid',
            isBusinessCompleted: true,
            isLocationCompleted: true,
            isCommerceCompleted: true,
            isInventoryCompleted: true,
            isTeamCompleted: true,
            isOnboardingCompleted: true,
          ),
        );
        AppRouter.setRepositoryForTesting(repo);

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRoutes.login,
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppShell), findsOneWidget);
        expect(find.byType(OnboardingPage), findsNothing);
      },
    );

    testWidgets(
      '4. Manually navigating to any onboarding route redirects to Overview when completed',
      (tester) async {
        setDesktopSize(tester);
        final repo = _MockAuthoritativeOnboardingRepo(
          progress: const OnboardingProgress(
            businessId: launchGridBizId,
            businessName: 'LaunchGrid',
            isBusinessCompleted: true,
            isLocationCompleted: true,
            isCommerceCompleted: true,
            isInventoryCompleted: true,
            isTeamCompleted: true,
            isOnboardingCompleted: true,
          ),
        );
        AppRouter.setRepositoryForTesting(repo);

        final onboardingRoutes = [
          AppRoutes.onboarding,
          AppRoutes.onboardingWelcome,
          AppRoutes.onboardingBusiness,
          AppRoutes.onboardingLocation,
          AppRoutes.onboardingCommerce,
          AppRoutes.onboardingInventory,
          AppRoutes.onboardingTeam,
          AppRoutes.onboardingComplete,
        ];

        for (final route in onboardingRoutes) {
          await tester.pumpWidget(
            MaterialApp(
              initialRoute: route,
              onGenerateRoute: AppRouter.onGenerateRoute,
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byType(AppShell),
            findsOneWidget,
            reason: 'Route $route must redirect to AppShell when complete',
          );
          expect(
            find.byType(OnboardingPage),
            findsNothing,
            reason: 'Route $route must not render OnboardingPage',
          );
        }
      },
    );

    testWidgets(
      '5. Stale local currentStep=4 + backend complete -> backend wins -> Overview',
      (tester) async {
        setDesktopSize(tester);

        // Stale local progress says steps 1-3 complete, step 4 incomplete
        final repo = _MockAuthoritativeOnboardingRepo(
          progress: const OnboardingProgress(
            businessId: launchGridBizId,
            businessName: 'LaunchGrid',
            isBusinessCompleted: true,
            isLocationCompleted: true,
            isCommerceCompleted: true,
            isInventoryCompleted: false, // stale local value
            isOnboardingCompleted: false, // stale local value
          ),
        );

        // Backend authoritative bootstrap result confirms completed
        AppBootstrapService.setLastResultForTesting(
          const BootstrapResult(
            initialRoute: AppRoutes.overview,
            businessId: launchGridBizId,
            isOnboardingCompleted: true, // Backend wins!
            resumeStep: 6,
          ),
        );
        AppRouter.setRepositoryForTesting(repo);

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRoutes.onboardingInventory,
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        );
        await tester.pumpAndSettle();

        // Must redirect to AppShell, NOT render Step 4
        expect(find.byType(AppShell), findsOneWidget);
        expect(find.byType(OnboardingPage), findsNothing);
      },
    );

    testWidgets(
      '6. Skip Step 4 -> completes backend -> immediately Overview',
      (tester) async {
        setDesktopSize(tester);

        final repo = _MockAuthoritativeOnboardingRepo(
          progress: const OnboardingProgress(
            businessId: launchGridBizId,
            businessName: 'LaunchGrid',
            isBusinessCompleted: true,
            isLocationCompleted: true,
            isCommerceCompleted: true,
            isInventoryCompleted: false,
            isOnboardingCompleted: false,
          ),
        );

        AppRouter.setRepositoryForTesting(repo);
        AppRouter.setAuthOverrideForTesting(true);

        await tester.pumpWidget(
          MaterialApp(
            home: OnboardingPage(
              initialStep: 4,
              repository: repo,
            ),
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        );
        await tester.pumpAndSettle();

        final skipFinder = find.widgetWithText(
          ElevatedButton,
          'Skip & Go to Dashboard',
        );
        expect(skipFinder, findsOneWidget);

        await tester.ensureVisible(skipFinder);
        await tester.tap(skipFinder);
        await tester.pumpAndSettle();

        expect(repo.currentProgress.isOnboardingCompleted, isTrue);
        expect(find.byType(AppShell), findsOneWidget);
        expect(find.byType(OnboardingPage), findsNothing);
      },
    );

    testWidgets(
      '7. No onboarding flash before bootstrap finishes (renders splash/loading shell)',
      (tester) async {
        setDesktopSize(tester);

        // Ensure bootstrap is marked NOT completed yet and currently bootstrapping
        AppBootstrapService.resetForTesting();
        AppBootstrapService.setIsBootstrappingForTesting(true);
        AppRouter.setAuthOverrideForTesting(true);
        AppRouter.setRepositoryForTesting(null); // Real environment simulation

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRoutes.overview,
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        );
        await tester.pump();

        // While bootstrapping, must render AppLoadingShell, NEVER OnboardingPage
        expect(find.byType(AppLoadingShell), findsOneWidget);
        expect(find.byType(OnboardingPage), findsNothing);
      },
    );
  });
}
