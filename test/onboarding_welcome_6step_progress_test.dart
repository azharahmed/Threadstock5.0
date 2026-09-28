// Onboarding Welcome + 6-Step Progress Tests
//
// Test States per Spec:
// A. registered/login complete only -> 17%, 5 of 6 steps remaining, Login checked, Business next
// B. Business completed -> 33%, 4 remaining
// C. Location completed -> 50%, 3 remaining
// D. Commerce completed -> 67%, 2 remaining
// E. Inventory completed -> 83%, 1 remaining
// F. Team completed/skipped -> 100%, onboarding complete -> Overview
// G. Existing incomplete business -> Continue Setup -> resume correct step
// H. Completed business -> welcome screen never appears

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadstock/app/router/app_router.dart';
import 'package:threadstock/core/navigation/navigation_guard.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';

class _FakeOnboardingRepository extends OnboardingRepository {
  OnboardingProgress _fakeProgress;

  _FakeOnboardingRepository(this._fakeProgress);

  @override
  OnboardingProgress get currentProgress => _fakeProgress;

  @override
  OnboardingProgress loadProgressSync() => _fakeProgress;

  @override
  Future<OnboardingProgress> loadProgressForBusiness(String businessId) async {
    return _fakeProgress;
  }

  void setProgress(OnboardingProgress progress) {
    _fakeProgress = progress;
  }
}

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    NavigationGuard.resetForTesting();
  });

  tearDown(() {
    NavigationGuard.resetForTesting();
    try {
      final configDir = Directory('config');
      if (configDir.existsSync()) {
        final files = configDir.listSync();
        for (final file in files) {
          if (file.path.contains('test_biz') ||
              file.path.contains('onboarding_progress_test')) {
            try {
              file.deleteSync();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}
  });

  group('1. OnboardingProgress Domain Model — 6 Milestones Calculation', () {
    test('Case A: registered/login complete only -> 17%, 5 remaining', () {
      const progress = OnboardingProgress();
      expect(progress.completedMilestoneCount, 1);
      expect(progress.progressPercentage, 17);
      expect(progress.remainingStepsCount, 5);
      expect(progress.isMilestoneCompleted(1), isTrue); // Login
      expect(progress.isMilestoneCompleted(2), isFalse); // Business
    });

    test('Case B: Business completed -> 33%, 4 remaining', () {
      const progress = OnboardingProgress(isBusinessCompleted: true);
      expect(progress.completedMilestoneCount, 2);
      expect(progress.progressPercentage, 33);
      expect(progress.remainingStepsCount, 4);
      expect(progress.isMilestoneCompleted(1), isTrue);
      expect(progress.isMilestoneCompleted(2), isTrue);
      expect(progress.isMilestoneCompleted(3), isFalse);
    });

    test('Case C: Location completed -> 50%, 3 remaining', () {
      const progress = OnboardingProgress(
        isBusinessCompleted: true,
        isLocationCompleted: true,
      );
      expect(progress.completedMilestoneCount, 3);
      expect(progress.progressPercentage, 50);
      expect(progress.remainingStepsCount, 3);
      expect(progress.isMilestoneCompleted(3), isTrue);
      expect(progress.isMilestoneCompleted(4), isFalse);
    });

    test('Case D: Commerce completed -> 67%, 2 remaining', () {
      const progress = OnboardingProgress(
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: true,
      );
      expect(progress.completedMilestoneCount, 4);
      expect(progress.progressPercentage, 67);
      expect(progress.remainingStepsCount, 2);
      expect(progress.isMilestoneCompleted(4), isTrue);
      expect(progress.isMilestoneCompleted(5), isFalse);
    });

    test('Case E: Inventory completed -> 83%, 1 remaining', () {
      const progress = OnboardingProgress(
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: true,
        isInventoryCompleted: true,
      );
      expect(progress.completedMilestoneCount, 5);
      expect(progress.progressPercentage, 83);
      expect(progress.remainingStepsCount, 1);
      expect(progress.isMilestoneCompleted(5), isTrue);
      expect(progress.isMilestoneCompleted(6), isFalse);
    });

    test('Case F: Team completed -> 100%, 0 remaining', () {
      const progress = OnboardingProgress(
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: true,
        isInventoryCompleted: true,
        isTeamCompleted: true,
      );
      expect(progress.completedMilestoneCount, 6);
      expect(progress.progressPercentage, 100);
      expect(progress.remainingStepsCount, 0);
      expect(progress.isMilestoneCompleted(6), isTrue);
    });

    test('Case F: isOnboardingCompleted -> 100%, 0 remaining', () {
      const progress = OnboardingProgress(isOnboardingCompleted: true);
      expect(progress.completedMilestoneCount, 6);
      expect(progress.progressPercentage, 100);
      expect(progress.remainingStepsCount, 0);
      for (int i = 1; i <= 6; i++) {
        expect(progress.isMilestoneCompleted(i), isTrue);
      }
    });
  });

  group('2. Welcome Screen & 6-Step Stepper UI Rendering', () {
    testWidgets(
        'Case A: Brand new user renders 17%, 5 of 6 steps remaining, Login checked, and Set Up My Business button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeOnboardingRepository(const OnboardingProgress());

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 0,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Heading and approved description
      expect(find.text('THREADSTOCK OS V2.0'), findsOneWidget);
      expect(find.text('Welcome to ThreadStock'), findsOneWidget);
      expect(find.text('AI Inventory & Commerce OS for Fashion'), findsOneWidget);
      expect(
        find.textContaining('You’re in! Let’s set up your workspace.'),
        findsOneWidget,
      );

      // Compact progress indicator
      expect(find.text('17% completed'), findsOneWidget);
      expect(find.text('1 of 6 completed'), findsOneWidget);

      // Only "Set Up My Business" button is shown, NOT "Continue Setup"
      expect(find.byKey(const ValueKey('btn_setup_business')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_continue_setup')), findsNothing);

      // 6-step stepper labels
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Commerce'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Team'), findsOneWidget);

      // Login has white checkmark icon
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Business is NOT active on Welcome screen; it shows '2'
      expect(find.text('Setting up: Your Workspace'), findsOneWidget);

      // On Welcome screen: Login completed, Business upcoming -> Login->Business connector is muted (0xFFD6CABD)
      final welcomeConnector = tester.widget<Container>(
        find.byKey(const ValueKey('stepper_connector_1_2')),
      );
      final firstConnectorDecor = welcomeConnector.decoration as BoxDecoration;
      expect(firstConnectorDecor.color, equals(const Color(0xFFD6CABD)));

      // Tapping Set Up My Business transitions to Business step (1)
      await tester.tap(find.byKey(const ValueKey('btn_setup_business')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('step_1_business')), findsOneWidget);
      // On Business step: progress remains 17% until saved, and Business is active
      expect(find.text('17% completed'), findsOneWidget);

      // On Business step: Login completed, Business active -> Login->Business connector is champagne gold (0xFFBA8A55)
      final businessConnector = tester.widget<Container>(
        find.byKey(const ValueKey('stepper_connector_1_2')),
      );
      final activeFirstConnectorDecor = businessConnector.decoration as BoxDecoration;
      expect(activeFirstConnectorDecor.color, equals(const Color(0xFFBA8A55)));
    });

    testWidgets(
        'Case G: Incomplete business shows Continue Setup button and resumes next incomplete step',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Business completed, Location incomplete -> 33%, 4 remaining
      final repo = _FakeOnboardingRepository(
        const OnboardingProgress(
          businessId: 'test_biz_123',
          businessName: 'Atelier Mode',
          isBusinessCompleted: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 0,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Progress line
      expect(find.text('33% completed'), findsOneWidget);
      expect(find.text('2 of 6 completed'), findsOneWidget);

      // Shows Continue Setup, NOT Set Up My Business
      expect(find.byKey(const ValueKey('btn_continue_setup')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_setup_business')), findsNothing);

      // Both Login and Business have checkmarks
      expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));

      // Tapping Continue Setup navigates straight to Location (step 2)
      await tester.tap(find.byKey(const ValueKey('btn_continue_setup')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('step_2_location')), findsOneWidget);
    });

    testWidgets(
        'Case H: Completed business immediately routes to /overview and never shows welcome screen',
        (WidgetTester tester) async {
      final repo = _FakeOnboardingRepository(
        const OnboardingProgress(
          businessId: 'test_biz_done',
          isOnboardingCompleted: true,
        ),
      );

      String? pushedRoute;

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.overview: (_) {
              pushedRoute = AppRoutes.overview;
              return const Scaffold(body: Text('Overview Page'));
            },
          },
          home: OnboardingPage(
            initialStep: 0,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Welcome screen is not shown
      expect(find.text('Welcome to ThreadStock'), findsNothing);
      expect(pushedRoute, AppRoutes.overview);
      expect(find.text('Overview Page'), findsOneWidget);
    });

    testWidgets('Responsive check: narrow mobile width (380x800) renders cleanly with no overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(380, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeOnboardingRepository(const OnboardingProgress());

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 0,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to ThreadStock'), findsOneWidget);
      expect(find.text('17% completed'), findsOneWidget);
      expect(find.text('1 of 6 completed'), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_setup_business')), findsOneWidget);

      // Verify no RenderFlex overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sign out button is visible on onboarding and routes to login',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeOnboardingRepository(const OnboardingProgress());
      String? routedTo;

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.login: (_) {
              routedTo = AppRoutes.login;
              return const Scaffold(body: Text('Login Page'));
            },
          },
          home: OnboardingPage(
            initialStep: 0,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Sign out action button is rendered
      expect(find.byKey(const ValueKey('onboarding_sign_out_button')), findsOneWidget);
      expect(find.text('Sign out'), findsOneWidget);

      // Tapping Sign out without edits immediately routes to login
      await tester.tap(find.byKey(const ValueKey('onboarding_sign_out_button')));
      await tester.pumpAndSettle();

      expect(routedTo, equals(AppRoutes.login));
      expect(find.text('Login Page'), findsOneWidget);
    });

    testWidgets('Sign out with unsaved edits displays confirmation dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeOnboardingRepository(const OnboardingProgress());
      String? routedTo;

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.login: (_) {
              routedTo = AppRoutes.login;
              return const Scaffold(body: Text('Login Page'));
            },
          },
          home: OnboardingPage(
            initialStep: 1,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter an unsaved business name
      await tester.enterText(find.byType(TextFormField).first, 'Unsaved Couture Ltd');
      await tester.pumpAndSettle();

      // Tap Sign out
      await tester.tap(find.byKey(const ValueKey('onboarding_sign_out_button')));
      await tester.pumpAndSettle();

      // Confirmation dialog should be presented
      expect(find.text('Sign out?'), findsOneWidget);
      expect(find.text('Unsaved changes on this page will be lost.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byKey(const ValueKey('confirm_sign_out_button')), findsOneWidget);

      // Tap Cancel -> stays on page
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsNothing);
      expect(routedTo, isNull);

      // Tap Sign out again, then confirm -> routes to login
      await tester.tap(find.byKey(const ValueKey('onboarding_sign_out_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm_sign_out_button')));
      await tester.pumpAndSettle();

      expect(routedTo, equals(AppRoutes.login));
    });
  });
}
