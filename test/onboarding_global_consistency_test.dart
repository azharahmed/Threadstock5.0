import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadstock/features/auth/presentation/pages/login_page.dart';
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
  });

  group('THREADSTOCK Onboarding Global Layout & Consistency Tests', () {
    testWidgets('1. Progress bar, business name, and step consistency on Step 0 (Welcome)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeOnboardingRepository(const OnboardingProgress(
        businessName: 'Vogue Atelier',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 0,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Progress bar visible
      expect(find.text('17% completed'), findsOneWidget);
      expect(find.text('1 of 6 completed'), findsOneWidget);

      // Business name badge in top header
      expect(find.byKey(const ValueKey('onboarding_workspace_badge')), findsOneWidget);
      expect(find.text('Setting up: Vogue Atelier'), findsOneWidget);

      // 6-step model in bottom stepper
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Location'), findsOneWidget);
      expect(find.text('Commerce'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Team'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Progress bar, business name, and step consistency on Step 1 (Business)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeOnboardingRepository(const OnboardingProgress(
        businessName: 'Luxe Couture',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 1,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step tag & title
      expect(find.text('STEP 2 OF 6 — BUSINESS'), findsOneWidget);
      expect(find.text('Tell us about your business'), findsOneWidget);

      // Progress bar on Step 1
      expect(find.text('17% completed'), findsOneWidget);
      expect(find.text('1 of 6 completed'), findsOneWidget);

      // Business badge
      expect(find.text('Setting up: Luxe Couture'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Progress bar, business name, and step consistency on Step 2 (Location)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Business completed -> 33%, 4 remaining
      final repo = _FakeOnboardingRepository(const OnboardingProgress(
        businessId: 'biz-123',
        businessName: 'Luxe Couture',
        isBusinessCompleted: true,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 2,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step tag & location title
      expect(find.text('STEP 3 OF 6 — LOCATION'), findsOneWidget);

      // Progress bar on Step 2
      expect(find.text('33% completed'), findsOneWidget);
      expect(find.text('2 of 6 completed'), findsOneWidget);

      // Business badge
      expect(find.text('Setting up: Luxe Couture'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('4. Progress bar, business name, and step consistency on Step 3 (Commerce)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Location completed -> 50%, 3 remaining
      final repo = _FakeOnboardingRepository(const OnboardingProgress(
        businessId: 'biz-123',
        businessName: 'Luxe Couture',
        isBusinessCompleted: true,
        isLocationCompleted: true,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 3,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step tag & commerce title
      expect(find.text('STEP 4 OF 6 — COMMERCE'), findsOneWidget);
      expect(find.text('Configure how you sell'), findsOneWidget);

      // Progress bar on Step 3
      expect(find.text('50% completed'), findsOneWidget);
      expect(find.text('3 of 6 completed'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Progress bar, business name, and step consistency on Step 4 (Inventory)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Commerce completed -> 67%, 2 remaining
      final repo = _FakeOnboardingRepository(const OnboardingProgress(
        businessId: 'biz-123',
        businessName: 'Luxe Couture',
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: true,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 4,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step tag & inventory title
      expect(find.text('STEP 5 OF 6 — INVENTORY'), findsOneWidget);
      expect(find.text('How would you like to start?'), findsOneWidget);

      // Progress bar on Step 4
      expect(find.text('67% completed'), findsOneWidget);
      expect(find.text('4 of 6 completed'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('6. Progress bar, business name, and step consistency on Step 5 (Team)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Inventory completed -> 83%, 1 remaining
      final repo = _FakeOnboardingRepository(const OnboardingProgress(
        businessId: 'biz-123',
        businessName: 'Luxe Couture',
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: true,
        isInventoryCompleted: true,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 5,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step tag & team title
      expect(find.text('STEP 6 OF 6 — TEAM'), findsOneWidget);
      expect(find.text('Invite your team'), findsOneWidget);

      // Progress bar on Step 5
      expect(find.text('83% completed'), findsOneWidget);
      expect(find.text('5 of 6 completed'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('7. Progress bar on Step 6 (Workspace Ready)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeOnboardingRepository(const OnboardingProgress(
        businessId: 'biz-123',
        businessName: 'Luxe Couture',
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: true,
        isInventoryCompleted: true,
        isTeamCompleted: true,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 6,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your workspace is ready'), findsOneWidget);
      expect(find.text('100% completed'), findsOneWidget);
      expect(find.text('6 of 6 completed'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('8. Progress bar and step label on Login Page',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STEP 1 OF 6 — LOGIN'), findsOneWidget);
      expect(find.text('0% completed'), findsOneWidget);
      expect(find.text('6 of 6 steps left'), findsOneWidget);
      expect(find.text('Workspace: New Business Setup'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('9. Graceful fallback for business name when unconfigured',
        (WidgetTester tester) async {
      final repo = _FakeOnboardingRepository(const OnboardingProgress());

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 1,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Setting up: Your Workspace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10. Responsive layout: narrow mobile (380x800) renders cleanly with no overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(380, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final repo = _FakeOnboardingRepository(const OnboardingProgress(
        businessName: 'Silk & Thread',
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 1,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STEP 2 OF 6 — BUSINESS'), findsOneWidget);
      expect(find.text('Setting up: Silk & Thread'), findsOneWidget);
      expect(find.text('17% completed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
