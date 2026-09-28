import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadstock/app/router/app_router.dart';
import 'package:threadstock/core/business/app_bootstrap_service.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/navigation/navigation_guard.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';
import 'package:threadstock/features/onboarding/domain/onboarding_completion_evaluator.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    NavigationGuard.resetForTesting();
  });

  tearDown(() {
    NavigationGuard.resetForTesting();
  });

  group('LaunchGrid Onboarding Reconciliation & Stepper Tests', () {
    const launchGridBizId = 'e7c1462e-0478-4f5b-8b97-7c8bc3580bec';

    test('1. Authoritative evaluation of LaunchGrid state (Commerce missing)', () {
      final eval = OnboardingCompletionEvaluator.evaluateFromProgress(
        progress: const OnboardingProgress(
          businessId: launchGridBizId,
          businessName: 'LaunchGrid',
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: false,
          isInventoryCompleted: false,
          isTeamCompleted: false,
        ),
        locationCount: 1,
        isCommerceSaved: false,
        hasProducts: false,
        isInventorySkipped: false,
        isTeamExplicitlyResolved: false,
      );

      expect(eval.isLoginComplete, isTrue);
      expect(eval.isBusinessSaved, isTrue);
      expect(eval.isLocationSaved, isTrue);
      expect(eval.isCommerceSaved, isFalse);
      expect(eval.isInventoryResolved, isFalse);
      expect(eval.isTeamResolved, isFalse);

      expect(eval.completedMilestones, equals(3));
      expect(eval.percentage, equals(50));
      expect(eval.firstIncompleteStep, equals(4));
      expect(eval.firstIncompleteStepName, equals('Commerce'));
      expect(eval.canEnterDashboard, isFalse);
    });

    test('2. Reconcile invalid complete state when prerequisites are incomplete', () {
      final invalidProgress = const OnboardingProgress(
        businessId: launchGridBizId,
        businessName: 'LaunchGrid',
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: false,
        isOnboardingCompleted: true,
      );

      final eval = OnboardingCompletionEvaluator.evaluateFromProgress(
        progress: invalidProgress,
        locationCount: 1,
        isCommerceSaved: false,
        hasProducts: false,
        isInventorySkipped: false,
        isTeamExplicitlyResolved: false,
      );

      // Safeguard check: cannot enter dashboard
      expect(eval.canEnterDashboard, isFalse);
      expect(eval.firstIncompleteStep, equals(4));

      // Reconciled progress
      final reconciled = invalidProgress.copyWith(
        isOnboardingCompleted: false,
        isCommerceCompleted: false,
        isInventoryCompleted: false,
        isTeamCompleted: false,
      );

      expect(reconciled.progressPercentage, equals(50));
      expect(reconciled.firstIncompleteStep, equals(4));
      expect(reconciled.remainingStepsCount, equals(3));
    });

    test('3. Truly completed business preserves complete status', () {
      final validProgress = const OnboardingProgress(
        businessId: launchGridBizId,
        businessName: 'LaunchGrid',
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: true,
        isInventoryCompleted: true,
        isTeamCompleted: true,
        isOnboardingCompleted: true,
      );

      final eval = OnboardingCompletionEvaluator.evaluateFromProgress(
        progress: validProgress,
        locationCount: 1,
        isCommerceSaved: true,
        hasProducts: true,
        isInventorySkipped: false,
        isTeamExplicitlyResolved: true,
      );

      expect(eval.canEnterDashboard, isTrue);
      expect(eval.percentage, equals(100));
      expect(eval.completedMilestones, equals(6));
      expect(eval.firstIncompleteStep, equals(7));
    });

    test('4. Router and Bootstrap Service route LaunchGrid to Commerce, not Overview', () {
      final targetRoute = AppBootstrapService.routeForStep(4);
      expect(targetRoute, equals(AppRoutes.onboardingCommerce));
      expect(targetRoute, isNot(equals(AppRoutes.overview)));
    });

    testWidgets('5. Horizontal Stepper renders correct connector colors for LaunchGrid (50%)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      CurrentBusinessService.instance.setCurrentBusinessId(launchGridBizId);

      // LaunchGrid state: Login(1), Business(2), Location(3) complete; Commerce(4) active
      final repo = OnboardingRepository.instance;
      await repo.saveProgress(
        const OnboardingProgress(
          businessId: launchGridBizId,
          businessName: 'LaunchGrid',
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: false,
          isInventoryCompleted: false,
          isTeamCompleted: false,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 3, // Step 3 view is Commerce (STEP 4 OF 6 — COMMERCE)
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify active step header
      expect(find.text('STEP 4 OF 6 — COMMERCE'), findsOneWidget);

      // Verify progress summary
      expect(find.text('50% completed'), findsOneWidget);
      expect(find.text('3 of 6 completed'), findsOneWidget);

      // Verify connector lines:
      // Login -> Business (1 -> 2) = gold
      final conn12 = tester.widget<Container>(
        find.byKey(const ValueKey('stepper_connector_1_2')),
      );
      final dec12 = conn12.decoration as BoxDecoration;
      expect(dec12.color, equals(const Color(0xFFBA8A55))); // Gold

      // Business -> Location (2 -> 3) = gold
      final conn23 = tester.widget<Container>(
        find.byKey(const ValueKey('stepper_connector_2_3')),
      );
      final dec23 = conn23.decoration as BoxDecoration;
      expect(dec23.color, equals(const Color(0xFFBA8A55))); // Gold

      // Location -> Commerce (3 -> 4) = gold (Location completed, Commerce active)
      final conn34 = tester.widget<Container>(
        find.byKey(const ValueKey('stepper_connector_3_4')),
      );
      final dec34 = conn34.decoration as BoxDecoration;
      expect(dec34.color, equals(const Color(0xFFBA8A55))); // Gold

      // Commerce -> Inventory (4 -> 5) = muted (#D6CABD)
      final conn45 = tester.widget<Container>(
        find.byKey(const ValueKey('stepper_connector_4_5')),
      );
      final dec45 = conn45.decoration as BoxDecoration;
      expect(dec45.color, equals(const Color(0xFFD6CABD))); // Muted

      // Inventory -> Team (5 -> 6) = muted (#D6CABD)
      final conn56 = tester.widget<Container>(
        find.byKey(const ValueKey('stepper_connector_5_6')),
      );
      final dec56 = conn56.decoration as BoxDecoration;
      expect(dec56.color, equals(const Color(0xFFD6CABD))); // Muted
    });

    test('6. Full progression sequence: Commerce (67%) -> Inventory (83%) -> Team (100%)', () {
      // Step A: LaunchGrid initial state
      var progress = const OnboardingProgress(
        businessId: launchGridBizId,
        isBusinessCompleted: true,
        isLocationCompleted: true,
      );
      expect(progress.progressPercentage, equals(50));
      expect(progress.firstIncompleteStep, equals(4));

      // Step B: Complete Commerce
      progress = progress.copyWith(isCommerceCompleted: true);
      expect(progress.progressPercentage, equals(67));
      expect(progress.firstIncompleteStep, equals(5));
      expect(AppBootstrapService.routeForStep(progress.firstIncompleteStep),
          equals(AppRoutes.onboardingInventory));

      // Step C: Finish or skip Inventory
      progress = progress.copyWith(
        isInventoryCompleted: true,
        inventorySetupStatus: 'skipped',
      );
      expect(progress.progressPercentage, equals(83));
      expect(progress.firstIncompleteStep, equals(6));
      expect(AppBootstrapService.routeForStep(progress.firstIncompleteStep),
          equals(AppRoutes.onboardingTeam));

      // Step D: Complete or skip Team
      progress = progress.copyWith(
        isTeamCompleted: true,
        isOnboardingCompleted: true,
      );
      expect(progress.progressPercentage, equals(100));
      expect(progress.firstIncompleteStep, equals(7));
      expect(AppBootstrapService.routeForStep(progress.firstIncompleteStep),
          equals(AppRoutes.overview));
    });

    test('7. Authoritative evaluation preserves persisted state even if in-memory progress is blank', () {
      // Simulates the exact bug condition: in-memory progress was reset/blank,
      // but DB has business saved and location saved.
      final eval = OnboardingCompletionEvaluator.evaluateFromProgress(
        progress: const OnboardingProgress(
          businessId: launchGridBizId,
          isBusinessCompleted: false, // in-memory was blank/false
          isLocationCompleted: false,
        ),
        locationCount: 2,
        isBusinessSaved: true, // DB has legal_name
        isLocationSaved: true, // DB has 2 active locations
        isCommerceSaved: false, // DB has no commerce profile
      );

      expect(eval.isLoginComplete, isTrue);
      expect(eval.isBusinessSaved, isTrue);
      expect(eval.isLocationSaved, isTrue);
      expect(eval.isCommerceSaved, isFalse);
      expect(eval.completedMilestones, equals(3));
      expect(eval.percentage, equals(50));
      expect(eval.firstIncompleteStep, equals(4));
      expect(eval.firstIncompleteStepName, equals('Commerce'));
    });

    testWidgets('8. Back-navigation to Business preserves 50% completed and 3 of 6 completed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      CurrentBusinessService.instance.setCurrentBusinessId(launchGridBizId);

      // LaunchGrid persisted state
      final repo = OnboardingRepository.instance;
      await repo.saveProgress(
        const OnboardingProgress(
          businessId: launchGridBizId,
          businessName: 'LaunchGrid',
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: false,
        ),
      );

      // User navigates back to Business view (view index 1)
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 1, // Step 2 (Business)
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Business view is shown for editing
      expect(find.text('STEP 2 OF 6 — BUSINESS'), findsOneWidget);
      expect(find.byKey(const ValueKey('step_1_business')), findsOneWidget);

      // Verify progress remains 50% / 3 of 6 completed (NOT 17% / 1 of 6!)
      expect(find.text('50% completed'), findsOneWidget);
      expect(find.text('3 of 6 completed'), findsOneWidget);
      expect(find.text('17% completed'), findsNothing);
      expect(find.text('1 of 6 completed'), findsNothing);
    });

    testWidgets('9. Stepper renders checkmarks for Login, Business, Location and 4 for Commerce',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      CurrentBusinessService.instance.setCurrentBusinessId(launchGridBizId);

      final repo = OnboardingRepository.instance;
      await repo.saveProgress(
        const OnboardingProgress(
          businessId: launchGridBizId,
          businessName: 'LaunchGrid',
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: false,
        ),
      );

      // Render Commerce view (Step 4 of 6)
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 3, // Commerce
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Checkmarks for 3 completed steps (Login, Business, Location)
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(3));

      // Active Commerce step circle displays "4"
      expect(find.text('4'), findsOneWidget);

      // Upcoming steps display "5" and "6"
      expect(find.text('5'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);

      // Connectors 1_2, 2_3, 3_4 are gold
      final conn12 = tester.widget<Container>(find.byKey(const ValueKey('stepper_connector_1_2')));
      final conn23 = tester.widget<Container>(find.byKey(const ValueKey('stepper_connector_2_3')));
      final conn34 = tester.widget<Container>(find.byKey(const ValueKey('stepper_connector_3_4')));
      expect((conn12.decoration as BoxDecoration).color, equals(const Color(0xFFBA8A55)));
      expect((conn23.decoration as BoxDecoration).color, equals(const Color(0xFFBA8A55)));
      expect((conn34.decoration as BoxDecoration).color, equals(const Color(0xFFBA8A55)));
    });

    testWidgets('10. After successful Commerce save, refreshes state, advances to Inventory with 67% and 4 of 6 completed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      CurrentBusinessService.instance.setCurrentBusinessId(launchGridBizId);

      final repo = OnboardingRepository.instance;
      await repo.saveProgress(
        const OnboardingProgress(
          businessId: launchGridBizId,
          businessName: 'LaunchGrid',
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: false,
        ),
      );

      // Render Commerce view (Step 4 of 6)
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 3, // Commerce
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial Commerce view state
      expect(find.text('STEP 4 OF 6 — COMMERCE'), findsOneWidget);
      expect(find.text('50% completed'), findsOneWidget);
      expect(find.text('3 of 6 completed'), findsOneWidget);

      // Select Sales Channel: In-Store Retail & Showrooms
      await tester.tap(find.text('In-Store Retail & Showrooms'));
      await tester.pumpAndSettle();

      // Select Payment Terms from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Immediate / Paid (Standard Retail)').last);
      await tester.pumpAndSettle();

      // Tap Continue to Inventory
      await tester.tap(find.byKey(const ValueKey('commerce_continue_button')));
      await tester.pumpAndSettle();

      // Expected immediately after Commerce save:
      // STEP 5 OF 6 — INVENTORY
      expect(find.text('STEP 5 OF 6 — INVENTORY'), findsOneWidget);

      // 67% completed | 4 of 6 completed
      expect(find.text('67% completed'), findsOneWidget);
      expect(find.text('4 of 6 completed'), findsOneWidget);

      // 4 completed step checkmarks: Login, Business, Location, Commerce
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(4));

      // 5 Inventory active
      expect(find.text('5'), findsOneWidget);

      // 6 Team upcoming
      expect(find.text('6'), findsOneWidget);

      // Connectors up to Inventory (1-2, 2-3, 3-4, 4-5) should be gold
      final conn12 = tester.widget<Container>(find.byKey(const ValueKey('stepper_connector_1_2')));
      final conn23 = tester.widget<Container>(find.byKey(const ValueKey('stepper_connector_2_3')));
      final conn34 = tester.widget<Container>(find.byKey(const ValueKey('stepper_connector_3_4')));
      final conn45 = tester.widget<Container>(find.byKey(const ValueKey('stepper_connector_4_5')));
      final conn56 = tester.widget<Container>(find.byKey(const ValueKey('stepper_connector_5_6')));

      expect((conn12.decoration as BoxDecoration).color, equals(const Color(0xFFBA8A55)));
      expect((conn23.decoration as BoxDecoration).color, equals(const Color(0xFFBA8A55)));
      expect((conn34.decoration as BoxDecoration).color, equals(const Color(0xFFBA8A55)));
      expect((conn45.decoration as BoxDecoration).color, equals(const Color(0xFFBA8A55)));
      expect((conn56.decoration as BoxDecoration).color, equals(const Color(0xFFD6CABD)));
    });
  });
}
