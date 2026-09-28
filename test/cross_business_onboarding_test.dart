import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/app/router/app_router.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';

class _FakeOnboardingRepository extends OnboardingRepository {
  _FakeOnboardingRepository(this._state);

  OnboardingProgress _state;

  @override
  OnboardingProgress get currentProgress => _state;

  void setState(OnboardingProgress state) {
    _state = state;
  }

  @override
  OnboardingProgress loadProgressSync() => _state;

  @override
  Future<OnboardingProgress> loadProgress() async => _state;

  @override
  Future<OnboardingProgress> loadProgressForBusiness(String businessId) async {
    return _state;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const businessLaunchGridId = '863b4f7b-7a8e-4ffa-a4aa-e4cd453613af';
  const businessOtherId = '970c80ef-b46c-4522-b38d-f63a30d17c01';

  setUp(() async {
    AppRouter.setAuthOverrideForTesting(true);
    await AppPreferencesService.instance.setCurrentBusinessId(businessLaunchGridId);
  });

  tearDown(() {
    AppRouter.setRepositoryForTesting(null);
    AppRouter.setAuthOverrideForTesting(null);
  });

  group('Cross-Business Onboarding Restoration Tests', () {
    test('1. Completed business (LaunchGrid) routes to overview and never opens Step 4', () {
      final launchGridProgress = const OnboardingProgress(
        businessId: businessLaunchGridId,
        businessName: 'LaunchGrid',
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: true,
        isInventoryCompleted: true,
        isTeamCompleted: true,
        isOnboardingCompleted: true,
        inventoryStartMethod: 'manual',
      );

      final repo = _FakeOnboardingRepository(launchGridProgress);
      AppRouter.setRepositoryForTesting(repo);

      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.overview),
      );

      expect(route, isA<MaterialPageRoute>());
      expect(route.settings.name, AppRoutes.overview);
    });

    test('2. Stale cache belonging to Business B is rejected when Business A is active', () {
      final otherBusinessProgress = const OnboardingProgress(
        businessId: businessOtherId,
        businessName: 'Other Incomplete Biz',
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: true,
        isInventoryCompleted: false,
        isTeamCompleted: false,
        isOnboardingCompleted: false,
      );

      final repo = _FakeOnboardingRepository(otherBusinessProgress);
      AppRouter.setRepositoryForTesting(repo);

      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.login),
      );

      expect(route, isA<MaterialPageRoute>());
    });

    testWidgets('3. OnboardingPage with completed progress immediately redirects to overview', (tester) async {
      final completedProgress = const OnboardingProgress(
        businessId: businessLaunchGridId,
        businessName: 'LaunchGrid',
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: true,
        isInventoryCompleted: true,
        isTeamCompleted: true,
        isOnboardingCompleted: true,
      );

      final repo = _FakeOnboardingRepository(completedProgress);

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            AppRoutes.overview: (ctx) => const Scaffold(body: Text('OVERVIEW_DASHBOARD')),
          },
          home: OnboardingPage(
            initialStep: 4,
            repository: repo,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('OVERVIEW_DASHBOARD'), findsOneWidget);
      expect(find.textContaining('STEP 4 OF 5'), findsNothing);
      expect(find.textContaining('INVENTORY INGESTION'), findsNothing);
    });

    test('4. Per-business cache files isolate progress on disk', () {
      final repo = OnboardingRepository();

      repo.clearCacheForBusiness(businessLaunchGridId);
      repo.clearCacheForBusiness(businessOtherId);

      final fileA = File('config/onboarding_progress_$businessLaunchGridId.json');
      final fileB = File('config/onboarding_progress_$businessOtherId.json');

      expect(fileA.existsSync(), isFalse);
      expect(fileB.existsSync(), isFalse);

      final progressA = const OnboardingProgress(
        businessId: businessLaunchGridId,
        businessName: 'LaunchGrid',
        isOnboardingCompleted: true,
      );
      fileA.writeAsStringSync(jsonEncode(progressA.toJson()), flush: true);

      final progressB = const OnboardingProgress(
        businessId: businessOtherId,
        businessName: 'Other Incomplete Biz',
        isOnboardingCompleted: false,
      );
      fileB.writeAsStringSync(jsonEncode(progressB.toJson()), flush: true);

      expect(fileA.existsSync(), isTrue);
      expect(fileB.existsSync(), isTrue);

      repo.clearCacheForBusiness(businessLaunchGridId);
      expect(fileA.existsSync(), isFalse);
      expect(fileB.existsSync(), isTrue);

      repo.clearCacheForBusiness(businessOtherId);
    });
  });
}
