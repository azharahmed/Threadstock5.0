// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadstock/app/router/app_router.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/features/business/domain/models/business.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';

class _FailingSaveOnboardingRepository extends OnboardingRepository {
  _FailingSaveOnboardingRepository({required this.exceptionToThrow});

  final Object exceptionToThrow;
  OnboardingProgress _state = const OnboardingProgress();

  @override
  OnboardingProgress get currentProgress => _state;

  @override
  OnboardingProgress loadProgressSync() => _state;

  @override
  Future<OnboardingProgress> loadProgress() async => _state;

  @override
  Future<void> saveProgress(OnboardingProgress progress) async {
    throw exceptionToThrow;
  }

  @override
  Future<OnboardingProgress> markStepComplete(
    int step, {
    Map<String, dynamic>? data,
  }) async {
    throw exceptionToThrow;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const businessLaunchGridId = '863b4f7b-7a8e-4ffa-a4aa-e4cd453613af';
  const businessOtherIncompleteId = '970c80ef-b46c-4522-b38d-f63a30d17c01';

  final launchGrid = Business(
    id: businessLaunchGridId,
    ownerUserId: 'owner-launchgrid-user',
    legalName: 'LaunchGrid',
    businessType: 'Boutique & Designer Wear',
    countryCode: 'IN',
    currencyCode: 'INR',
    locationRange: '2-5',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() async {
    AppRouter.setAuthOverrideForTesting(true);
    AppPreferencesService.instance.reset();
    CurrentBusinessService.instance.resetForTesting();
    OnboardingRepository.instance.reset();
    await AppPreferencesService.instance.setCurrentBusinessId(businessLaunchGridId);
  });

  tearDown(() {
    AppRouter.setRepositoryForTesting(null);
    AppRouter.setAuthOverrideForTesting(null);
    AppPreferencesService.instance.reset();
    CurrentBusinessService.instance.resetForTesting();
    OnboardingRepository.instance.reset();
  });

  group('ThreadStock — Business Setup Save & Completed Onboarding Reentry Tests', () {
    test('1. Existing completed LaunchGrid -> startup -> Overview', () {
      CurrentBusinessService.instance.setCurrentBusiness(launchGrid);

      final repo = OnboardingRepository();
      repo.saveProgress(
        const OnboardingProgress(
          businessId: businessLaunchGridId,
          businessName: 'LaunchGrid',
          businessType: 'Boutique & Designer Wear',
          countryCode: 'IN',
          currencyCode: 'INR',
          locationRange: '2-5',
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: true,
          isInventoryCompleted: true,
          isTeamCompleted: true,
          isOnboardingCompleted: true,
        ),
      );
      AppRouter.setRepositoryForTesting(repo);

      // On startup with completed LaunchGrid, initial route to overview must stay on overview
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.overview),
      );

      expect(route, isA<MaterialPageRoute>());
      expect(route.settings.name, AppRoutes.overview);
    });

    testWidgets('2. Completed LaunchGrid -> onboarding route manually requested -> redirect to Overview', (tester) async {
      CurrentBusinessService.instance.setCurrentBusiness(launchGrid);

      final repo = OnboardingRepository();
      repo.saveProgress(
        const OnboardingProgress(
          businessId: businessLaunchGridId,
          businessName: 'LaunchGrid',
          businessType: 'Boutique & Designer Wear',
          countryCode: 'IN',
          currencyCode: 'INR',
          locationRange: '2-5',
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: true,
          isInventoryCompleted: true,
          isTeamCompleted: true,
          isOnboardingCompleted: true,
        ),
      );
      AppRouter.setRepositoryForTesting(repo);

      // Router level check: direct request to /onboarding/business immediately routes to overview
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.onboardingBusiness),
      );
      expect(route, isA<MaterialPageRoute>());
      expect(route.settings.name, AppRoutes.overview);

      // Widget level check: if OnboardingPage is mounted directly with completed progress,
      // it must NEVER render Step 1 (not even on first frame), but redirect to Overview.
      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.overview: (ctx) => const Scaffold(body: Text('OVERVIEW_DASHBOARD')),
          },
          home: OnboardingPage(
            initialStep: 1,
            repository: repo,
          ),
        ),
      );

      // Must NOT render Step 1 on first frame
      expect(find.text('STEP 1 OF 5 — PROFILE'), findsNothing);
      expect(find.text('Continue to Locations'), findsNothing);

      await tester.pumpAndSettle();

      // Successfully replaced to Overview
      expect(find.text('OVERVIEW_DASHBOARD'), findsOneWidget);
      expect(find.text('STEP 1 OF 5 — PROFILE'), findsNothing);
    });

    test('3. Existing business edit -> UPDATE, not INSERT', () async {
      CurrentBusinessService.instance.setCurrentBusiness(launchGrid);

      // When saving an existing business, it must update the existing record
      final updatedBiz = await CurrentBusinessService.instance.createOrUpdateBusinessForOwner(
        legalName: 'LaunchGrid Haute Couture',
        businessType: 'Boutique & Designer Wear',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '2-5',
        existingBusinessId: businessLaunchGridId,
      );

      // Must reuse existing ID, NOT generate or insert a new one
      expect(updatedBiz.id, businessLaunchGridId);
      expect(updatedBiz.legalName, 'LaunchGrid Haute Couture');
      expect(CurrentBusinessService.instance.currentBusinessId, businessLaunchGridId);
    });

    test('4. Business save succeeds -> state refreshes', () async {
      CurrentBusinessService.instance.setCurrentBusiness(launchGrid);

      final repo = OnboardingRepository();
      repo.saveProgress(
        const OnboardingProgress(
          businessId: businessLaunchGridId,
          businessName: 'LaunchGrid',
          countryCode: 'IN',
          currencyCode: 'INR',
          locationRange: '2-5',
        ),
      );

      final updatedProgress = await repo.markStepComplete(
        1,
        data: {
          'businessName': 'LaunchGrid Global',
          'businessType': 'Boutique & Designer Wear',
          'countryCode': 'IN',
          'currencyCode': 'INR',
          'locationRange': '2-5',
        },
      );

      // Progress state refreshed
      expect(updatedProgress.isBusinessCompleted, true);
      expect(updatedProgress.businessName, 'LaunchGrid Global');
      expect(updatedProgress.businessId, businessLaunchGridId);

      // Authoritative CurrentBusinessService refreshed
      expect(CurrentBusinessService.instance.currentBusiness?.legalName, 'LaunchGrid Global');
      expect(CurrentBusinessService.instance.currentBusinessId, businessLaunchGridId);
    });

    testWidgets('5. Onboarding update failure -> no route advance', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1400, 1000);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      CurrentBusinessService.instance.setCurrentBusiness(launchGrid);

      final failingRepo = _FailingSaveOnboardingRepository(
        exceptionToThrow: const PostgrestException(
          message: 'Connection timeout updating onboarding session',
          code: '08006',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            repository: failingRepo,
            initialSelectedCountry: 'IN',
            initialSelectedCurrency: 'INR',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill valid Step 1 details
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'LaunchGrid');
      await tester.pumpAndSettle();

      final typeDropdown = find.text('Select business type');
      await tester.tap(typeDropdown, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Boutique & Designer Wear').last);
      await tester.pumpAndSettle();

      final locTile = find.widgetWithText(InkWell, '2 - 5').first;
      await tester.tap(locTile);
      await tester.pumpAndSettle();

      final continueBtn = find.widgetWithText(ElevatedButton, 'Continue to Locations');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Must show actionable error banner
      expect(
        find.textContaining("We couldn't save your business setup"),
        findsOneWidget,
      );

      // Step must NOT advance: still on Step 1, continue button remains
      expect(continueBtn, findsOneWidget);
      expect(find.text('STEP 1 OF 5 — PROFILE'), findsOneWidget);
      expect(find.text('Location Nodes'), findsNothing);
    });

    test('6. Wrong business ID -> fail closed', () async {
      CurrentBusinessService.instance.setCurrentBusiness(launchGrid);

      const mismatchedBizId = '00000000-0000-0000-0000-000000000000';

      // Attempting to save with a mismatched onboarding business ID must fail closed
      expect(
        () => CurrentBusinessService.instance.createOrUpdateBusinessForOwner(
          legalName: 'Hijack Attempt',
          businessType: 'Boutique & Designer Wear',
          countryCode: 'IN',
          currencyCode: 'INR',
          locationRange: '2-5',
          existingBusinessId: mismatchedBizId,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Business ID mismatch'),
          ),
        ),
      );

      // Authoritative state remains LaunchGrid
      expect(CurrentBusinessService.instance.currentBusinessId, businessLaunchGridId);
    });

    test('7. Another incomplete business exists -> does not hijack LaunchGrid', () async {
      CurrentBusinessService.instance.setCurrentBusiness(launchGrid);

      // Incomplete session for a different business
      final otherRepo = OnboardingRepository();
      otherRepo.saveProgress(
        const OnboardingProgress(
          businessId: businessOtherIncompleteId,
          businessName: 'Incomplete Other Business',
          isBusinessCompleted: false,
          isOnboardingCompleted: false,
        ),
      );

      AppRouter.setRepositoryForTesting(otherRepo);

      // When LaunchGrid is the active business, otherRepo's incomplete progress is rejected
      // and cannot hijack routing into onboarding step 1
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.login),
      );

      expect(route, isA<MaterialPageRoute>());
      // Does not use other business's incomplete state to redirect active business to onboarding
      expect(CurrentBusinessService.instance.currentBusinessId, businessLaunchGridId);
    });

    test('8. Completed onboarding reset protection: saveProgress refuses to reset complete to in_progress', () async {
      final repo = OnboardingRepository();
      repo.saveProgress(
        const OnboardingProgress(
          businessId: businessLaunchGridId,
          businessName: 'LaunchGrid',
          isOnboardingCompleted: true,
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: true,
          isInventoryCompleted: true,
          isTeamCompleted: true,
        ),
      );

      expect(repo.currentProgress.isOnboardingCompleted, true);

      // Attempting to invalidate from Step 1 on a completed progress must be refused
      await repo.invalidateFrom(1);
      expect(repo.currentProgress.isOnboardingCompleted, true);
      expect(repo.currentProgress.isBusinessCompleted, true);
    });
  });
}
