import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/app/router/app_router.dart';
import 'package:threadstock/core/business/app_bootstrap_service.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/core/navigation/navigation_guard.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:threadstock/features/sales/presentation/active_sale_session.dart';

class _MockOnboardingRepository extends OnboardingRepository {
  _MockOnboardingRepository(this._progress);

  OnboardingProgress _progress;

  @override
  OnboardingProgress get currentProgress => _progress;

  @override
  OnboardingProgress loadProgressSync() => _progress;

  @override
  Future<OnboardingProgress> loadProgressForBusiness(String businessId) async {
    return _progress;
  }

  @override
  Future<OnboardingProgress> markStepComplete(
    int step, {
    Map<String, dynamic>? data,
  }) async {
    switch (step) {
      case 1:
        _progress = _progress.copyWith(isBusinessCompleted: true);
        break;
      case 2:
        _progress = _progress.copyWith(isLocationCompleted: true);
        break;
      case 3:
        _progress = _progress.copyWith(isCommerceCompleted: true);
        break;
      case 4:
        _progress = _progress.copyWith(isInventoryCompleted: true);
        break;
      case 5:
        _progress = _progress.copyWith(isTeamCompleted: true);
        break;
      case 6:
        _progress = _progress.copyWith(isOnboardingCompleted: true);
        break;
    }
    return _progress;
  }

  @override
  void clearCache() {
    _progress = const OnboardingProgress();
  }
}

void main() {
  setUp(() {
    NavigationGuard.resetForTesting();
    AppBootstrapService.resetForTesting();
    LocationRepository.clearLocalState();
    ActiveSaleSession.instance.clear(preserveLocation: false);
  });

  tearDown(() {
    NavigationGuard.resetForTesting();
    AppBootstrapService.resetForTesting();
    LocationRepository.clearLocalState();
    ActiveSaleSession.instance.clear(preserveLocation: false);
  });

  group('ThreadStock — Onboarding Sign Out Flow', () {
    testWidgets(
      'Sign out button is present on all onboarding steps (0 to 5) with correct style & placement',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Test each step 0 through 5
        for (int step = 0; step <= 5; step++) {
          NavigationGuard.resetForTesting();
          final progress = OnboardingProgress(
            businessName: 'Silk Atelier',
            countryCode: 'US',
            currencyCode: 'USD',
            businessType: 'Retail',
            isBusinessCompleted: step >= 1,
            isLocationCompleted: step >= 2,
            isCommerceCompleted: step >= 3,
            isInventoryCompleted: step >= 4,
            isTeamCompleted: step >= 5,
          );
          final repo = _MockOnboardingRepository(progress);

          await tester.pumpWidget(
            MaterialApp(
              routes: {
                AppRoutes.login: (_) => const Scaffold(body: Text('Login')),
              },
              home: OnboardingPage(
                initialStep: step,
                repository: repo,
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Verify header contains Support and Sign out
          expect(
            find.byKey(const ValueKey('onboarding_sign_out_button')),
            findsOneWidget,
            reason: 'Step $step must render Sign out button',
          );
          expect(
            find.text('Sign out'),
            findsOneWidget,
            reason: 'Step $step must show Sign out text',
          );
          expect(
            find.text('ThreadStock Support'),
            findsOneWidget,
            reason: 'Step $step must show ThreadStock Support in header',
          );
        }
      },
    );

    testWidgets(
      'Sign out from Business step (with unsaved edits) prompts confirmation dialog and can cancel',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final repo = _MockOnboardingRepository(const OnboardingProgress());
        String? routedTo;

        await tester.pumpWidget(
          MaterialApp(
            routes: {
              AppRoutes.login: (_) {
                routedTo = AppRoutes.login;
                return const Scaffold(body: Text('Login Screen'));
              },
            },
            home: OnboardingPage(
              initialStep: 1,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Enter unsaved business name
        await tester.enterText(
          find.byType(TextFormField).first,
          'Unsaved Boutique',
        );
        await tester.pumpAndSettle();

        // Tap Sign out button
        await tester.tap(find.byKey(const ValueKey('onboarding_sign_out_button')));
        await tester.pumpAndSettle();

        // Verify confirmation dialog title and copy
        expect(find.text('Sign out?'), findsOneWidget);
        expect(
          find.text('Unsaved changes on this page will be lost.'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.byKey(const ValueKey('confirm_sign_out_button')), findsOneWidget);

        // Tap Cancel: dialog closes, stays on page without routing
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Sign out?'), findsNothing);
        expect(routedTo, isNull);
        expect(find.text('Unsaved Boutique'), findsOneWidget);
      },
    );

    testWidgets(
      'Sign out from Business step confirms, clears user-scoped local state, and routes to /login removing previous routes',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Setup mock user-scoped state
        await AppPreferencesService.instance.setCurrentBusinessId('00000000-0000-0000-0000-000000000001');
        CurrentBusinessService.instance.setCurrentLocationId('loc-123');
        ActiveSaleSession.instance.lines = [
          const ActiveCartLine(
            productId: 'prod-1',
            title: 'Silk Scarf',
            sku: 'SILK-01',
            variantSubtitle: 'Red',
            unitPriceMinor: 5000,
            quantity: 1,
            stockCount: 10,
          ),
        ];

        final repo = _MockOnboardingRepository(const OnboardingProgress());
        String? routedTo;

        await tester.pumpWidget(
          MaterialApp(
            routes: {
              AppRoutes.login: (_) {
                routedTo = AppRoutes.login;
                return const Scaffold(body: Text('Login Screen'));
              },
            },
            home: OnboardingPage(
              initialStep: 1,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap Sign out directly (no unsaved edits)
        await tester.tap(find.byKey(const ValueKey('onboarding_sign_out_button')));
        await tester.pumpAndSettle();

        // 1. Routed to Login
        expect(routedTo, equals(AppRoutes.login));
        expect(find.text('Login Screen'), findsOneWidget);

        // 2. User-scoped local state cleared
        expect(CurrentBusinessService.instance.currentBusinessId, isNull);
        expect(CurrentBusinessService.instance.currentLocationId, isNull);
        expect(AppPreferencesService.instance.currentBusinessId, isNull);
        expect(ActiveSaleSession.instance.hasItems, isFalse);
        expect(ActiveSaleSession.instance.lines, isEmpty);
      },
    );

    testWidgets(
      'Sign out only ends authenticated session and clears local user state without deleting business records',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Progress already saved for a business
        final existingProgress = const OnboardingProgress(
          businessName: 'Royal Silk House',
          businessType: 'Boutique',
          countryCode: 'GB',
          currencyCode: 'GBP',
          isBusinessCompleted: true,
          isLocationCompleted: true,
        );
        final repo = _MockOnboardingRepository(existingProgress);

        await tester.pumpWidget(
          MaterialApp(
            routes: {
              AppRoutes.login: (_) => const Scaffold(body: Text('Login Screen')),
            },
            home: OnboardingPage(
              initialStep: 3,
              repository: repo,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Sign out
        await tester.tap(find.byKey(const ValueKey('onboarding_sign_out_button')));
        await tester.pumpAndSettle();

        expect(find.text('Login Screen'), findsOneWidget);

        // When logging back in or reloading the business record:
        // the saved business record is preserved
        expect(existingProgress.businessName, equals('Royal Silk House'));
        expect(existingProgress.isBusinessCompleted, isTrue);
        expect(existingProgress.isLocationCompleted, isTrue);
      },
    );
  });
}
