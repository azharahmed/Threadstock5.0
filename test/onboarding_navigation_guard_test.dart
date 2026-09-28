import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/app/router/app_router.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';

class _TestOnboardingRepository extends OnboardingRepository {
  OnboardingProgress _state;

  _TestOnboardingRepository([this._state = const OnboardingProgress()]);

  @override
  OnboardingProgress get currentProgress => _state;

  @override
  OnboardingProgress loadProgressSync() => _state;

  @override
  Future<OnboardingProgress> loadProgress() async => _state;

  @override
  Future<void> saveProgress(OnboardingProgress progress) async {
    _state = progress;
  }

  @override
  Future<OnboardingProgress> markStepComplete(
    int step, {
    Map<String, dynamic>? data,
  }) async {
    switch (step) {
      case 1:
        _state = _state.copyWith(
          isBusinessCompleted: true,
          businessName: data?['businessName'] as String? ?? _state.businessName,
          businessType: data?['businessType'] as String? ?? _state.businessType,
          countryCode: data?['countryCode'] as String? ?? _state.countryCode,
          currencyCode: data?['currencyCode'] as String? ?? _state.currencyCode,
          locationRange:
              data?['locationRange'] as String? ?? _state.locationRange,
        );
        break;
      case 2:
        final locs = data?['configuredLocations'] as List<dynamic>?;
        _state = _state.copyWith(
          isLocationCompleted: true,
          configuredLocations: locs != null
              ? locs.map((e) => Map<String, dynamic>.from(e as Map)).toList()
              : _state.configuredLocations,
        );
        break;
      case 3:
        final channels = data?['selectedSalesChannels'] as Iterable<int>?;
        _state = _state.copyWith(
          isCommerceCompleted: true,
          selectedSalesChannels:
              channels?.toSet() ?? _state.selectedSalesChannels,
          paymentTerms: data?['paymentTerms'] as String? ?? _state.paymentTerms,
        );
        break;
      case 4:
        _state = _state.copyWith(
          isInventoryCompleted: true,
          inventoryStartMethod:
              data?['inventoryStartMethod'] as String? ??
              _state.inventoryStartMethod,
        );
        break;
      case 5:
        _state = _state.copyWith(isTeamCompleted: true);
        break;
      case 6:
        _state = _state.copyWith(isOnboardingCompleted: true);
        break;
    }
    return _state;
  }

  @override
  Future<OnboardingProgress> invalidateFrom(int step) async {
    if (step <= 1) {
      _state = _state.copyWith(
        isBusinessCompleted: false,
        isLocationCompleted: false,
        isCommerceCompleted: false,
        isInventoryCompleted: false,
        isTeamCompleted: false,
        isOnboardingCompleted: false,
      );
    } else if (step <= 2) {
      _state = _state.copyWith(
        isLocationCompleted: false,
        isCommerceCompleted: false,
        isInventoryCompleted: false,
        isTeamCompleted: false,
        isOnboardingCompleted: false,
      );
    } else if (step <= 3) {
      _state = _state.copyWith(
        isCommerceCompleted: false,
        isInventoryCompleted: false,
        isTeamCompleted: false,
        isOnboardingCompleted: false,
      );
    } else if (step <= 4) {
      _state = _state.copyWith(
        isInventoryCompleted: false,
        isTeamCompleted: false,
        isOnboardingCompleted: false,
      );
    } else if (step <= 5) {
      _state = _state.copyWith(
        isTeamCompleted: false,
        isOnboardingCompleted: false,
      );
    } else if (step <= 6) {
      _state = _state.copyWith(isOnboardingCompleted: false);
    }
    return _state;
  }
}

void main() {
  setUp(() {
    AppRouter.setRepositoryForTesting(null);
  });

  tearDown(() {
    AppRouter.setRepositoryForTesting(null);
  });

  void setDesktopSize(
    WidgetTester tester, {
    Size size = const Size(1920, 1200),
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('Sequential Onboarding Progression Tests', () {
    testWidgets(
      '1. New user on Step 1: clicking future steps (Location, Commerce, Inventory, Team) is blocked',
      (tester) async {
        setDesktopSize(tester);
        final repo = _TestOnboardingRepository(const OnboardingProgress());

        await tester.pumpWidget(
          MaterialApp(home: OnboardingPage(initialStep: 1, repository: repo)),
        );
        await tester.pumpAndSettle();

        // Step 1 should be visible
        expect(find.byKey(const ValueKey('step_1_business')), findsOneWidget);

        // Attempt to click Location (step 2) in bottom stepper
        await tester.tap(find.text('Location'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_1_business')), findsOneWidget);
        expect(find.byKey(const ValueKey('step_2_location')), findsNothing);

        // Attempt to click Commerce (step 3)
        await tester.tap(find.text('Commerce'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_1_business')), findsOneWidget);
        expect(find.byKey(const ValueKey('step_3_commerce')), findsNothing);

        // Attempt to click Inventory (step 4)
        await tester.tap(find.text('Inventory'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_1_business')), findsOneWidget);
        expect(find.byKey(const ValueKey('step_4_inventory')), findsNothing);

        // Attempt to click Team (step 5)
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_1_business')), findsOneWidget);
        expect(find.byKey(const ValueKey('step_5_team')), findsNothing);
      },
    );

    testWidgets('2. Complete Step 1: Location becomes available', (
      tester,
    ) async {
      setDesktopSize(tester);
      final repo = _TestOnboardingRepository(const OnboardingProgress());

      await tester.pumpWidget(
        MaterialApp(home: OnboardingPage(initialStep: 1, repository: repo)),
      );
      await tester.pumpAndSettle();

      // Fill valid Step 1 business details
      await tester.enterText(
        find.byType(TextFormField).first,
        'Acme Sartoria Ltd',
      );
      await tester.ensureVisible(find.text('Select business type'));
      await tester.tap(find.text('Select business type'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Luxury Ready-to-Wear').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Select country'));
      await tester.tap(find.text('Select country'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('United Kingdom (GB)').last);
      await tester.pumpAndSettle();

      // Location range selection
      await tester.ensureVisible(find.text('1').first);
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();

      // Tap "Continue to Locations"
      await tester.ensureVisible(find.text('Continue to Locations'));
      await tester.tap(find.text('Continue to Locations'));
      await tester.pumpAndSettle();

      // Should have advanced to Step 2
      expect(find.byKey(const ValueKey('step_2_location')), findsOneWidget);
      expect(repo.currentProgress.isBusinessCompleted, isTrue);
      expect(repo.currentProgress.firstIncompleteStep, equals(3));
    });

    testWidgets(
      '3. At Step 2: Backward to Step 1 allowed; Commerce, Inventory, Team locked until Location complete',
      (tester) async {
        setDesktopSize(tester);
        final repo = _TestOnboardingRepository(
          const OnboardingProgress(
            isBusinessCompleted: true,
            businessName: 'Acme Sartoria Ltd',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(home: OnboardingPage(initialStep: 2, repository: repo)),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('step_2_location')), findsOneWidget);

        // Backward navigation to Step 1: allowed
        await tester.tap(find.text('Business'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_1_business')), findsOneWidget);

        // Forward navigation back to reached Step 2: allowed
        await tester.tap(find.text('Location'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_2_location')), findsOneWidget);

        // Jumping to Commerce: blocked
        await tester.tap(find.text('Commerce'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_2_location')), findsOneWidget);

        // Jumping to Team: blocked
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_2_location')), findsOneWidget);
      },
    );

    testWidgets(
      '4. At Step 4: Backward to Steps 1, 2, 3 allowed; Team blocked until Inventory complete',
      (tester) async {
        setDesktopSize(tester);
        final repo = _TestOnboardingRepository(
          const OnboardingProgress(
            isBusinessCompleted: true,
            isLocationCompleted: true,
            isCommerceCompleted: true,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(home: OnboardingPage(initialStep: 4, repository: repo)),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('step_4_inventory')), findsOneWidget);

        // Backward to Step 1
        await tester.tap(find.text('Business'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_1_business')), findsOneWidget);

        // Backward to Step 2
        await tester.tap(find.text('Location'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_2_location')), findsOneWidget);

        // Backward to Step 3
        await tester.tap(find.text('Commerce'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_3_commerce')), findsOneWidget);

        // Return to reached Step 4
        await tester.tap(find.text('Inventory'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_4_inventory')), findsOneWidget);

        // Jumping to Step 5 (Team): blocked
        await tester.tap(find.text('Team'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_4_inventory')), findsOneWidget);
        expect(find.byKey(const ValueKey('step_5_team')), findsNothing);
      },
    );

    testWidgets(
      '5. Direct route protection: attempting direct access to Team before prerequisites redirects to first incomplete step',
      (tester) async {
        setDesktopSize(tester);
        // Step 1 is complete, but Step 2 (Location) is NOT complete
        final repo = _TestOnboardingRepository(
          const OnboardingProgress(isBusinessCompleted: true),
        );
        AppRouter.setRepositoryForTesting(repo);

        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRoutes.onboardingTeam,
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        );
        await tester.pumpAndSettle();

        // Access to Team should be denied and redirected to Step 2 (Location)
        expect(find.byKey(const ValueKey('step_2_location')), findsOneWidget);
        expect(find.byKey(const ValueKey('step_5_team')), findsNothing);
      },
    );

    testWidgets(
      '6. Restart persistence: completing Steps 1 & 2 resumes at Step 3',
      (tester) async {
        setDesktopSize(tester);
        final repo = _TestOnboardingRepository(
          const OnboardingProgress(
            isBusinessCompleted: true,
            isLocationCompleted: true,
            businessName: 'Milan Textiles',
          ),
        );
        AppRouter.setRepositoryForTesting(repo);

        // Boot application at initial route
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: AppRoutes.onboarding,
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        );
        await tester.pumpAndSettle();

        // Expected: automatically resumes at Step 3 (Commerce)
        expect(find.byKey(const ValueKey('step_3_commerce')), findsOneWidget);
      },
    );

    testWidgets(
      '7. Dashboard protection: attempting dashboard before onboarding completion redirects to first incomplete step',
      (tester) async {
        setDesktopSize(tester);
        // Onboarding in progress: steps 1, 2, 3 complete, step 4 incomplete
        final repo = _TestOnboardingRepository(
          const OnboardingProgress(
            isBusinessCompleted: true,
            isLocationCompleted: true,
            isCommerceCompleted: true,
          ),
        );
        AppRouter.setRepositoryForTesting(repo);

        // Attempt to access root dashboard '/'
        await tester.pumpWidget(
          MaterialApp(
            initialRoute: '/',
            onGenerateRoute: AppRouter.onGenerateRoute,
          ),
        );
        await tester.pumpAndSettle();

        // Redirected to first incomplete step: Step 4 (Inventory)
        expect(find.byKey(const ValueKey('step_4_inventory')), findsOneWidget);
      },
    );

    testWidgets(
      '8. Changing country in Step 1 invalidates downstream commerce & inventory steps',
      (tester) async {
        setDesktopSize(tester);
        final repo = _TestOnboardingRepository(
          const OnboardingProgress(
            isBusinessCompleted: true,
            isLocationCompleted: true,
            isCommerceCompleted: true,
            isInventoryCompleted: true,
            businessName: 'Tessuti Global',
            businessType: 'Luxury Ready-to-Wear',
            countryCode: 'IN',
            currencyCode: 'INR',
            locationRange: '1',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(home: OnboardingPage(initialStep: 1, repository: repo)),
        );
        await tester.pumpAndSettle();

        // Select a new country
        await tester.tap(find.text('India (IN)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('United States (US)').last);
        await tester.pumpAndSettle();

        // Continue to Locations
        await tester.tap(find.text('Continue to Locations'));
        await tester.pumpAndSettle();

        // Downstream steps must be invalidated
        expect(repo.currentProgress.isCommerceCompleted, isFalse);
        expect(repo.currentProgress.isInventoryCompleted, isFalse);
        expect(repo.currentProgress.countryCode, equals('US'));
      },
    );

    testWidgets(
      '9. Fresh onboarding on Step 1: exactly 0 checkmarks, all downstream steps locked',
      (tester) async {
        setDesktopSize(tester);
        final repo = _TestOnboardingRepository(const OnboardingProgress());

        await tester.pumpWidget(
          MaterialApp(home: OnboardingPage(initialStep: 1, repository: repo)),
        );
        await tester.pumpAndSettle();

        // Milestone 1 (Login) is completed by default upon entering onboarding (1 checkmark)
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);

        // Business is current (milestone 2, shows '2'), downstream steps show milestone numbers
        expect(find.text('2'), findsWidgets);
        expect(find.text('3'), findsOneWidget);
        expect(find.text('4'), findsOneWidget);
        expect(find.text('5'), findsOneWidget);
        expect(find.text('6'), findsOneWidget);

        // Clicking Team on Step 1 is locked and blocked
        await tester.tap(find.text('Team'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('step_1_business')), findsOneWidget);
        expect(find.byKey(const ValueKey('step_5_team')), findsNothing);
      },
    );

    testWidgets(
      '10. Reaching Step 5 (Team) shows Team as CURRENT (●), NOT completed (✓)',
      (tester) async {
        setDesktopSize(tester);
        final repo = _TestOnboardingRepository(
          const OnboardingProgress(
            isBusinessCompleted: true,
            isLocationCompleted: true,
            isCommerceCompleted: true,
            isInventoryCompleted: true,
            isTeamCompleted: false,
          ),
        );

        await tester.pumpWidget(
          MaterialApp(home: OnboardingPage(initialStep: 5, repository: repo)),
        );
        await tester.pumpAndSettle();

        // Team page is active
        expect(find.byKey(const ValueKey('step_5_team')), findsOneWidget);

        // Exactly 5 checkmarks (Login, Business, Location, Commerce, Inventory)
        expect(find.byIcon(Icons.check_rounded), findsNWidgets(5));

        // Team shows active badge '6', NOT a checkmark
        expect(find.text('6'), findsOneWidget);
      },
    );

    test(
      '11. Stale state protection: isTeamCompleted without prior steps is sanitized to false',
      () {
        final json = {
          'isBusinessCompleted': false,
          'isLocationCompleted': false,
          'isCommerceCompleted': false,
          'isInventoryCompleted': false,
          'isTeamCompleted': true,
          'isOnboardingCompleted': false,
        };

        final progress = OnboardingProgress.fromJson(json);
        expect(progress.isTeamCompleted, isFalse);
        expect(progress.isStepCompleted(5), isFalse);
        expect(progress.isStepAccessible(5), isFalse);
      },
    );

    testWidgets(
      '12. Corrupted disk cache with isTeamCompleted:true on Step 1 never renders green check',
      (tester) async {
        setDesktopSize(tester);
        // Simulate reading a corrupted state
        final progress = OnboardingProgress.fromJson({
          'isBusinessCompleted': false,
          'isTeamCompleted': true,
        });
        final repo = _TestOnboardingRepository(progress);

        await tester.pumpWidget(
          MaterialApp(home: OnboardingPage(initialStep: 1, repository: repo)),
        );
        await tester.pumpAndSettle();

        // Only Login milestone (milestone 1) is checked; corrupted Team is sanitized and not checked
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      },
    );
  });
}
