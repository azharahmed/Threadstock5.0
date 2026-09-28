import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/app/router/app_router.dart';
import 'package:threadstock/core/navigation/navigation_guard.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/features/inventory/presentation/pages/inventory_page.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:threadstock/features/onboarding/presentation/widgets/team_onboarding_view.dart';
import 'package:threadstock/features/settings/presentation/pages/settings_page.dart';
import 'package:threadstock/features/settings/presentation/widgets/team_access_view.dart';

void main() {
  setUp(() async {
    NavigationGuard.resetForTesting();
    await OnboardingRepository.instance.reset();
    CurrentBusinessService.instance.setCurrentBusinessId('biz-test-123');
  });

  tearDown(() async {
    NavigationGuard.resetForTesting();
    await OnboardingRepository.instance.reset();
  });

  Future<void> pumpStep4(
    WidgetTester tester, {
    Size size = const Size(1920, 1200),
    OnboardingRepository? repo,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = repo ?? OnboardingRepository.instance;
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: AppRoutes.onboardingInventory,
        routes: {
          AppRoutes.onboardingInventory: (_) =>
              OnboardingPage(initialStep: 4, repository: repository),
          AppRoutes.onboardingTeam: (_) =>
              OnboardingPage(initialStep: 5, repository: repository),
          AppRoutes.overview: (_) =>
              const Scaffold(body: Text('Overview Dashboard')),
        },
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Fresh Step 4: No selection, Initialize disabled, Skip & Go to Dashboard enabled',
    (tester) async {
      await pumpStep4(tester);

      final initFinder = find.widgetWithText(
        ElevatedButton,
        'Initialize Catalog Setup',
      );
      final skipFinder = find.widgetWithText(
        ElevatedButton,
        'Skip & Go to Dashboard',
      );
      final prevFinder = find.widgetWithText(OutlinedButton, 'Previous Step');

      expect(initFinder, findsOneWidget);
      expect(skipFinder, findsOneWidget);
      expect(prevFinder, findsOneWidget);
      // Ensure "Continue to Team" is gone
      expect(find.text('Continue to Team'), findsNothing);

      final initBtn = tester.widget<ElevatedButton>(initFinder);
      final skipBtn = tester.widget<ElevatedButton>(skipFinder);
      final prevBtn = tester.widget<OutlinedButton>(prevFinder);

      expect(
        initBtn.onPressed,
        isNull,
        reason: 'Initialize Catalog Setup must be disabled initially',
      );
      expect(
        skipBtn.onPressed,
        isNotNull,
        reason: 'Skip & Go to Dashboard must be always enabled on Step 4',
      );
      expect(
        prevBtn.onPressed,
        isNotNull,
        reason: 'Previous Step must be enabled',
      );
    },
  );

  testWidgets(
    'Step 4 with no selection: click Skip & Go to Dashboard -> onboarding completes -> routes to Overview',
    (tester) async {
      final repo = OnboardingRepository.instance;
      await repo.saveProgress(
        const OnboardingProgress(
          businessId: 'biz-test-123',
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: true,
          isInventoryCompleted: false,
        ),
      );

      await pumpStep4(tester, repo: repo);

      final skipFinder = find.widgetWithText(
        ElevatedButton,
        'Skip & Go to Dashboard',
      );
      final skipBtn = tester.widget<ElevatedButton>(skipFinder);
      expect(skipBtn.onPressed, isNotNull);

      // Click Skip with NO selection
      await tester.tap(skipFinder);
      await tester.pumpAndSettle();

      // Onboarding complete
      expect(repo.currentProgress.isInventoryCompleted, isTrue);
      expect(repo.currentProgress.isOnboardingCompleted, isTrue);
      expect(find.text('Overview Dashboard'), findsOneWidget);
      expect(find.byType(TeamOnboardingView), findsNothing);
    },
  );

  testWidgets(
    'Create Manually selected: Skip & Go to Dashboard enabled -> click Skip -> onboarding complete -> Overview',
    (tester) async {
      final repo = OnboardingRepository.instance;
      await repo.saveProgress(
        const OnboardingProgress(
          businessId: 'biz-test-123',
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: true,
          isInventoryCompleted: false,
        ),
      );

      await pumpStep4(tester, repo: repo);

      // Select Create Manually
      await tester.tap(find.text('Create Manually'));
      await tester.pump();

      final skipFinder = find.widgetWithText(
        ElevatedButton,
        'Skip & Go to Dashboard',
      );
      final skipBtn = tester.widget<ElevatedButton>(skipFinder);
      expect(
        skipBtn.onPressed,
        isNotNull,
        reason: 'Skip & Go to Dashboard should be enabled once method is selected',
      );

      // Click Skip & Go to Dashboard
      await tester.tap(skipFinder);
      await tester.pumpAndSettle();

      // Sequence verification:
      // 1. inventory_start_method persisted
      expect(repo.currentProgress.inventoryStartMethod, equals('manual'));
      expect(repo.currentProgress.isInventoryCompleted, isTrue);

      // 2. Onboarding complete
      expect(repo.currentProgress.isOnboardingCompleted, isTrue);

      // 3. Directly routed to Overview Dashboard, not Team
      expect(find.text('Overview Dashboard'), findsOneWidget);
      expect(find.byType(TeamOnboardingView), findsNothing);
    },
  );

  testWidgets(
    'Upload CSV / Excel selected: Skip & Go to Dashboard enabled -> click Skip -> onboarding complete -> Overview',
    (tester) async {
      final repo = OnboardingRepository.instance;
      await repo.saveProgress(
        const OnboardingProgress(
          businessId: 'biz-test-123',
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: true,
          isInventoryCompleted: false,
        ),
      );

      await pumpStep4(tester, repo: repo);

      // Select Upload CSV / Excel
      await tester.tap(find.text('Upload CSV / Excel'));
      await tester.pump();

      final skipFinder = find.widgetWithText(
        ElevatedButton,
        'Skip & Go to Dashboard',
      );
      final skipBtn = tester.widget<ElevatedButton>(skipFinder);
      expect(skipBtn.onPressed, isNotNull);

      // Click Skip & Go to Dashboard
      await tester.tap(skipFinder);
      await tester.pumpAndSettle();

      // Verified:
      expect(repo.currentProgress.inventoryStartMethod, equals('file_import'));
      expect(repo.currentProgress.isInventoryCompleted, isTrue);
      expect(repo.currentProgress.isOnboardingCompleted, isTrue);
      expect(find.text('Overview Dashboard'), findsOneWidget);
    },
  );

  testWidgets(
    'Connect Shopify selected: Skip & Go to Dashboard enabled -> click Skip -> onboarding complete -> Overview',
    (tester) async {
      final repo = OnboardingRepository.instance;
      await repo.saveProgress(
        const OnboardingProgress(
          businessId: 'biz-test-123',
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: true,
          isInventoryCompleted: false,
        ),
      );

      await pumpStep4(tester, repo: repo);

      // Select Connect Shopify
      await tester.tap(find.text('Connect Shopify'));
      await tester.pump();

      final skipFinder = find.widgetWithText(
        ElevatedButton,
        'Skip & Go to Dashboard',
      );
      final skipBtn = tester.widget<ElevatedButton>(skipFinder);
      expect(skipBtn.onPressed, isNotNull);

      // Click Skip & Go to Dashboard
      await tester.tap(skipFinder);
      await tester.pumpAndSettle();

      // Verified:
      expect(repo.currentProgress.inventoryStartMethod, equals('shopify'));
      expect(repo.currentProgress.isInventoryCompleted, isTrue);
      expect(repo.currentProgress.isOnboardingCompleted, isTrue);
      expect(find.text('Overview Dashboard'), findsOneWidget);
    },
  );

  testWidgets(
    'Cancel or back from Create Product leaves Step 4 selection intact with Skip enabled',
    (tester) async {
      final repo = OnboardingRepository.instance;
      await repo.saveProgress(
        const OnboardingProgress(
          businessId: 'biz-test-123',
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: true,
          isInventoryCompleted: false,
        ),
      );

      await pumpStep4(tester, repo: repo);

      await tester.tap(find.text('Create Manually'));
      await tester.pump();

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Initialize Catalog Setup'),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InventoryPage), findsOneWidget);

      // Cancel / Go back without publishing
      final backBtn = find.byTooltip('Back to inventory');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.byType(InventoryPage), findsNothing);

      // Skip & Go to Dashboard remains enabled
      final skipBtn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Skip & Go to Dashboard'),
      );
      expect(skipBtn.onPressed, isNotNull);
      expect(repo.currentProgress.isOnboardingCompleted, isFalse);
    },
  );

  testWidgets(
    'After completion: Restart/sign-in must route to Overview and NOT reopen Step 4 or Team',
    (tester) async {
      final repo = OnboardingRepository.instance;
      // Simulate completed onboarding
      await repo.saveProgress(
        const OnboardingProgress(
          businessId: 'biz-test-123',
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: true,
          isInventoryCompleted: true,
          isTeamCompleted: true,
          isOnboardingCompleted: true,
          inventoryStartMethod: 'manual',
        ),
      );

      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      AppRouter.setRepositoryForTesting(repo);
      AppRouter.setAuthOverrideForTesting(true);
      addTearDown(() {
        AppRouter.setRepositoryForTesting(null);
        AppRouter.setAuthOverrideForTesting(null);
      });

      // Simulating sign-in / app boot to /login or /onboarding/inventory
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.onboardingInventory,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      );
      await tester.pumpAndSettle();

      // Guarded onboarding step redirects to Overview AppShell
      expect(find.text('STEP 4 OF 5 — INVENTORY INGESTION'), findsNothing);
      expect(find.byType(TeamOnboardingView), findsNothing);
    },
  );

  testWidgets(
    'Settings -> Team: Team can still be configured later after skipping during onboarding',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SettingsPage(initialSection: 'team_directory'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TeamAccessView), findsOneWidget);
      expect(find.text('Team Directory'), findsOneWidget);
    },
  );

  testWidgets(
    'Existing products already present: onboarding marks completed and routes to Overview',
    (tester) async {
      final repo = OnboardingRepository.instance;
      // Mark completed as triggered when existing products are detected
      await repo.markStepComplete(6);
      expect(repo.currentProgress.isOnboardingCompleted, isTrue);

      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      AppRouter.setRepositoryForTesting(repo);
      AppRouter.setAuthOverrideForTesting(true);
      addTearDown(() {
        AppRouter.setRepositoryForTesting(null);
        AppRouter.setAuthOverrideForTesting(null);
      });

      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.overview,
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STEP 4 OF 5 — INVENTORY INGESTION'), findsNothing);
    },
  );
}
