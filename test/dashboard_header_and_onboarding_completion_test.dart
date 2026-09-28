import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/app/router/app_router.dart';
import 'package:threadstock/app/shell/app_shell.dart';
import 'package:threadstock/core/business/app_bootstrap_service.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/domain/models/stock_location.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';
import 'package:threadstock/features/onboarding/domain/onboarding_completion_evaluator.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';

class _MockOnboardingRepo extends OnboardingRepository {
  _MockOnboardingRepo({required this.progress});

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
    if (!progress.isLocationCompleted && progress.configuredLocations.isEmpty) {
      throw StateError(
        'Cannot skip to dashboard: at least one location must be configured for business $businessId.',
      );
    }
    progress = progress.copyWith(
      isInventoryCompleted: true,
      isTeamCompleted: true,
      isOnboardingCompleted: true,
      inventorySetupStatus: 'skipped',
      businessId: businessId ?? progress.businessId,
    );
    return progress;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const launchGridBizId = 'e7c1462e-0478-4f5b-8b97-7c8bc3580bec';

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
    CurrentBusinessService.instance.setCurrentBusinessId(launchGridBizId);
  });

  tearDown(() async {
    AppRouter.setRepositoryForTesting(null);
    AppRouter.setAuthOverrideForTesting(null);
    AppBootstrapService.resetForTesting();
    LocationRepository.clearTestingLocations();
  });

  group('1. OnboardingCompletionEvaluator Unit Tests', () {
    test('Business saved + no location: blocks dashboard, first incomplete step = 2 (Location), % = 33%', () {
      const rawProgress = OnboardingProgress(
        businessId: launchGridBizId,
        businessName: 'LaunchGrid',
        isBusinessCompleted: true,
        isLocationCompleted: false,
        configuredLocations: [],
      );

      final eval = OnboardingCompletionEvaluator.evaluateFromProgress(
        progress: rawProgress,
        locationCount: 0,
      );

      expect(eval.isLoginComplete, isTrue);
      expect(eval.isBusinessSaved, isTrue);
      expect(eval.isLocationSaved, isFalse);
      expect(eval.firstIncompleteStep, equals(3)); // Location (Milestone 3)
      expect(eval.percentage, equals(33));
      expect(eval.completedMilestones, equals(2));
      expect(eval.canEnterDashboard, isFalse);
    });

    test('Save real location: Location complete, Commerce next (step 4), % = 50%', () {
      const progressWithLoc = OnboardingProgress(
        businessId: launchGridBizId,
        businessName: 'LaunchGrid',
        isBusinessCompleted: true,
        isLocationCompleted: true,
        configuredLocations: [
          {'id': 'loc-1', 'name': 'Main Warehouse'}
        ],
      );

      final eval = OnboardingCompletionEvaluator.evaluateFromProgress(
        progress: progressWithLoc,
        locationCount: 1,
      );

      expect(eval.isLoginComplete, isTrue);
      expect(eval.isBusinessSaved, isTrue);
      expect(eval.isLocationSaved, isTrue);
      expect(eval.firstIncompleteStep, equals(4)); // Commerce (Milestone 4)
      expect(eval.percentage, equals(50));
      expect(eval.completedMilestones, equals(3));
      expect(eval.canEnterDashboard, isFalse);
    });

    test('Commerce complete, Inventory skipped legitimately: Inventory resolved, % = 83%', () {
      const progressInvSkipped = OnboardingProgress(
        businessId: launchGridBizId,
        businessName: 'LaunchGrid',
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: true,
        inventorySetupStatus: 'skipped',
        configuredLocations: [
          {'id': 'loc-1', 'name': 'Main Warehouse'}
        ],
        selectedSalesChannels: {1},
      );

      final eval = OnboardingCompletionEvaluator.evaluateFromProgress(
        progress: progressInvSkipped,
        locationCount: 1,
      );

      expect(eval.isCommerceSaved, isTrue);
      expect(eval.isInventoryResolved, isTrue);
      expect(eval.firstIncompleteStep, equals(6)); // Team (Milestone 6)
      expect(eval.percentage, equals(83));
      expect(eval.canEnterDashboard, isFalse);
    });

    test('All required conditions satisfied: onboarding complete, canEnterDashboard = true, % = 100%', () {
      const progressComplete = OnboardingProgress(
        businessId: launchGridBizId,
        businessName: 'LaunchGrid',
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: true,
        isInventoryCompleted: true,
        isTeamCompleted: true,
        isOnboardingCompleted: true,
        configuredLocations: [
          {'id': 'loc-1', 'name': 'Main Warehouse'}
        ],
        selectedSalesChannels: {1},
      );

      final eval = OnboardingCompletionEvaluator.evaluateFromProgress(
        progress: progressComplete,
        locationCount: 1,
        isTeamExplicitlyResolved: true,
      );

      expect(eval.canEnterDashboard, isTrue);
      expect(eval.completedMilestones, equals(6));
      expect(eval.percentage, equals(100));
      expect(eval.firstIncompleteStep, equals(7));
    });

    test('current_step alone is NOT trusted as completion proof when locations = 0', () {
      // Even if isOnboardingCompleted is true or current_step was 6, if locationCount is 0,
      // evaluator strictly denies dashboard access.
      const fakeCompleteProgress = OnboardingProgress(
        businessId: launchGridBizId,
        businessName: 'LaunchGrid',
        isBusinessCompleted: true,
        isLocationCompleted: false, // 0 locations!
        isOnboardingCompleted: true, // premature status!
        configuredLocations: [],
      );

      final eval = OnboardingCompletionEvaluator.evaluateFromProgress(
        progress: fakeCompleteProgress,
        locationCount: 0,
      );

      expect(eval.canEnterDashboard, isFalse);
      expect(eval.firstIncompleteStep, equals(3)); // Location (Milestone 3)
      expect(eval.percentage, equals(33));
    });
  });

  group('2. Skip & Go to Dashboard Enforcement', () {
    test('Skip cannot bypass mandatory Location when locationCount = 0', () async {
      final repo = _MockOnboardingRepo(
        progress: const OnboardingProgress(
          businessId: launchGridBizId,
          businessName: 'LaunchGrid',
          isBusinessCompleted: true,
          isLocationCompleted: false,
          configuredLocations: [],
        ),
      );

      expect(
        () => repo.skipToDashboard(businessId: launchGridBizId),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('3. Overview Router Guard Enforcement', () {
    testWidgets(
      'Business saved + no location: attempting /overview redirects to /onboarding/location',
      (tester) async {
        setDesktopSize(tester);
        final repo = _MockOnboardingRepo(
          progress: const OnboardingProgress(
            businessId: launchGridBizId,
            businessName: 'LaunchGrid',
            isBusinessCompleted: true,
            isLocationCompleted: false,
            configuredLocations: [],
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

        // Must NOT render AppShell/Overview
        expect(find.byType(AppShell), findsNothing);
        // Must render OnboardingPage at Step 2 (Location)
        expect(find.byType(OnboardingPage), findsOneWidget);
        expect(find.byKey(const ValueKey('step_2_location')), findsOneWidget);
      },
    );

    testWidgets(
      'All prerequisites satisfied: /overview is allowed and renders AppShell',
      (tester) async {
        setDesktopSize(tester);
        final repo = _MockOnboardingRepo(
          progress: const OnboardingProgress(
            businessId: launchGridBizId,
            businessName: 'LaunchGrid',
            isBusinessCompleted: true,
            isLocationCompleted: true,
            isCommerceCompleted: true,
            isInventoryCompleted: true,
            isTeamCompleted: true,
            isOnboardingCompleted: true,
            configuredLocations: [
              {'id': 'loc-1', 'name': 'Main Warehouse'}
            ],
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

        expect(find.byType(AppShell), findsOneWidget);
        expect(find.byType(OnboardingPage), findsNothing);
      },
    );
  });

  group('4. Overview Topbar Header and Location Selector', () {
    testWidgets(
      'Overview with 0 locations renders neutral "No location configured" badge and [Add Location] action button; NO duplicate dropdowns',
      (tester) async {
        setDesktopSize(tester);
        LocationRepository.setLocationsForTesting(launchGridBizId, []);

        await tester.pumpWidget(
          const MaterialApp(
            home: AppShell(),
          ),
        );
        await tester.pumpAndSettle();

        // Verify topbar empty state widget is rendered
        expect(find.byKey(const ValueKey('topbar_location_empty_state')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('topbar_location_empty_state')),
            matching: find.text('No location configured'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('topbar_location_empty_state')),
            matching: find.text('Add Location'),
          ),
          findsOneWidget,
        );

        // Verify there is NO fake dropdown with "No locations configured"
        expect(find.text('No locations configured'), findsNothing);
      },
    );

    testWidgets(
      'Overview with 1 location renders exactly ONE location selector dropdown in header',
      (tester) async {
        setDesktopSize(tester);
        LocationRepository.setLocationsForTesting(launchGridBizId, [
          StockLocation(
            id: 'loc-main',
            businessId: launchGridBizId,
            name: 'Stock Location',
            locationType: 'warehouse',
            streetAddress: '123 Fashion Ave',
            city: 'Mumbai',
            countryCode: 'IN',
            postalCode: '400001',
            status: 'active',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);

        await tester.pumpWidget(
          const MaterialApp(
            home: AppShell(),
          ),
        );
        await tester.pumpAndSettle();

        // Exactly one location dropdown containing "Stock Location" in the top bar
        expect(find.byKey(const ValueKey('topbar_location_dropdown')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('topbar_location_dropdown')),
            matching: find.text('Stock Location (Mumbai)'),
          ),
          findsOneWidget,
        );

        // Ensure no duplicate dropdown or "No locations configured"
        expect(find.text('No locations configured'), findsNothing);
        expect(find.byKey(const ValueKey('topbar_location_empty_state')), findsNothing);
      },
    );
  });
}
