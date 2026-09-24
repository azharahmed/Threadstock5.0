import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadstock/app/router/app_router.dart';
import 'package:threadstock/core/auth/auth_service.dart';
import 'package:threadstock/core/business/app_bootstrap_service.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/features/inventory/data/brand_repository.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/inventory/data/supplier_repository.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AuthService.instance.setUnauthenticatedForTesting();
    AppPreferencesService.instance.reset();
    CurrentBusinessService.instance.resetForTesting();
    OnboardingRepository.instance.reset();
    BrandRepository.clearLocalState();
    CategoryRepository.clearLocalState();
  });

  tearDown(() {
    AuthService.instance.setUnauthenticatedForTesting();
    AppPreferencesService.instance.reset();
    CurrentBusinessService.instance.resetForTesting();
    OnboardingRepository.instance.reset();
    BrandRepository.clearLocalState();
    CategoryRepository.clearLocalState();
  });

  group('Startup & Business Restoration Unit Tests', () {
    test(
      '1. AppPreferencesService persists and reloads currentBusinessId',
      () async {
        const testBizId = 'c5fe7bee-11ab-4575-9752-46ca4b3bdc34';
        await AppPreferencesService.instance.setCurrentBusinessId(testBizId);
        expect(AppPreferencesService.instance.currentBusinessId, testBizId);

        // Reset in-memory cache and verify reload from disk
        AppPreferencesService.reloadForTesting();
        expect(AppPreferencesService.instance.currentBusinessId, testBizId);
      },
    );

    test(
      '2. CurrentBusinessService never creates a business during resolveCurrentBusinessId',
      () async {
        // In disconnected mode or with no accessible businesses
        final resolved = await CurrentBusinessService.instance
            .resolveCurrentBusinessId();
        expect(resolved, isNull);
        expect(CurrentBusinessService.instance.currentBusiness, isNull);
        expect(CurrentBusinessService.instance.currentBusinessId, isNull);
      },
    );

    test(
      '3. AppBootstrapService routes to onboarding for truly new user without creating business',
      () async {
        AuthService.instance.setAuthenticatedForTesting(
          user: const User(
            id: 'test-user-uuid',
            appMetadata: {},
            userMetadata: {},
            aud: 'authenticated',
            createdAt: '2026-09-24T00:00:00Z',
          ),
        );
        final result = await AppBootstrapService.bootstrap();
        expect(result.initialRoute, AppRoutes.onboarding);
        expect(result.businessId, isNull);
        expect(result.isOnboardingCompleted, false);
        expect(result.resumeStep, 1);
        // Ensure no business was auto-created
        expect(CurrentBusinessService.instance.currentBusinessId, isNull);
        AuthService.instance.setUnauthenticatedForTesting();
      },
    );

    test(
      '4. AppRouter redirects /onboarding to /overview if onboarding is completed',
      () {
        final repo = OnboardingRepository();
        // Set completed progress
        repo.saveProgress(
          const OnboardingProgress(
            isBusinessCompleted: true,
            isLocationCompleted: true,
            isCommerceCompleted: true,
            isInventoryCompleted: true,
            isTeamCompleted: true,
            isOnboardingCompleted: true,
            businessId: 'c5fe7bee-11ab-4575-9752-46ca4b3bdc34',
          ),
        );
        AppRouter.setRepositoryForTesting(repo);

        final route = AppRouter.onGenerateRoute(
          const RouteSettings(name: AppRoutes.onboarding),
        );
        expect(route, isA<MaterialPageRoute<dynamic>>());
        final pageRoute = route as MaterialPageRoute<dynamic>;
        expect(pageRoute.settings.name, AppRoutes.overview);

        // Same for /onboarding/business
        final stepRoute = AppRouter.onGenerateRoute(
          const RouteSettings(name: AppRoutes.onboardingBusiness),
        );
        expect(stepRoute.settings.name, AppRoutes.overview);

        AppRouter.setRepositoryForTesting(null);
      },
    );

    test('5. AppRouter resumes at first incomplete step if in-progress', () {
      final repo = OnboardingRepository();
      // Step 1 & 2 complete, step 3 (commerce) incomplete
      repo.saveProgress(
        const OnboardingProgress(
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: false,
          isInventoryCompleted: false,
          isTeamCompleted: false,
          isOnboardingCompleted: false,
          businessId: 'c5fe7bee-11ab-4575-9752-46ca4b3bdc34',
        ),
      );
      AppRouter.setRepositoryForTesting(repo);

      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.onboarding),
      );
      expect(route, isA<MaterialPageRoute<dynamic>>());
      final pageRoute = route as MaterialPageRoute<dynamic>;
      expect(pageRoute.settings.name, AppRoutes.onboardingCommerce);

      AppRouter.setRepositoryForTesting(null);
    });

    test(
      '6. All repositories resolve currentBusinessId from CurrentBusinessService',
      () async {
        const restoredBizId = 'c5fe7bee-11ab-4575-9752-46ca4b3bdc34';
        CurrentBusinessService.instance.setCurrentBusinessId(restoredBizId);

        expect(
          await BrandRepository().resolveCurrentBusinessId(),
          restoredBizId,
        );
        expect(
          await CategoryRepository().resolveCurrentBusinessId(),
          restoredBizId,
        );
        expect(
          await SupplierRepository().resolveCurrentBusinessId(),
          restoredBizId,
        );
        expect(
          await ProductRepository().resolveCurrentBusinessId(),
          restoredBizId,
        );
        expect(
          await LocationRepository().resolveCurrentBusinessId(),
          restoredBizId,
        );
      },
    );

    test(
      '7. createOrUpdateBusinessForOwner idempotency: updates rather than inserting new records',
      () async {
        final biz1 = await CurrentBusinessService.instance
            .createOrUpdateBusinessForOwner(
              legalName: 'Test Label Studio',
              businessType: 'Bespoke Atelier',
              countryCode: 'US',
              currencyCode: 'USD',
              locationRange: '1',
            );
        expect(biz1.id, isNotEmpty);
        expect(CurrentBusinessService.instance.currentBusinessId, biz1.id);

        // Re-invoking with the same or updated details must reuse the same business id
        final biz2 = await CurrentBusinessService.instance
            .createOrUpdateBusinessForOwner(
              legalName: 'Test Label Studio Updated',
              businessType: 'Bespoke Atelier',
              countryCode: 'US',
              currencyCode: 'USD',
              locationRange: '1',
              existingBusinessId: biz1.id,
            );
        expect(biz2.id, biz1.id);
      },
    );
  });

  group('Live Supabase Session & Business Restoration Tests', () {
    test(
      '8. Live Supabase: authenticates existing session and restores completed business',
      () async {
        HttpOverrides.global = null;

        final configFile = File('config/supabase_config.json');
        if (!configFile.existsSync()) return;

        final config =
            jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
        final url = config['supabaseUrl'] as String;
        final anonKey = config['supabaseAnonKey'] as String;

        final sessionFile = File(
          'build/windows/x64/runner/Debug/shared_preferences.json',
        );
        String? refreshToken;

        if (sessionFile.existsSync()) {
          final prefs =
              jsonDecode(sessionFile.readAsStringSync())
                  as Map<String, dynamic>;
          for (final entry in prefs.entries) {
            if (entry.key.startsWith('flutter.supabase.auth.token')) {
              final sessionData =
                  jsonDecode(entry.value as String) as Map<String, dynamic>;
              refreshToken = sessionData['refresh_token'] as String?;
            }
          }
        }

        final client = SupabaseClient(url, anonKey);
        if (refreshToken != null) {
          await client.auth.setSession(refreshToken);
        }

        final user = client.auth.currentUser;
        expect(user, isNotNull);

        // Test CurrentBusinessService with real client
        final businessService = CurrentBusinessService(client: client);
        final resolvedBizId = await businessService.resolveCurrentBusinessId(
          forceRefresh: true,
        );
        expect(resolvedBizId, isNotNull);
        expect(businessService.currentBusiness, isNotNull);

        // Verify that completed business 'c5fe7bee-11ab-4575-9752-46ca4b3bdc34' was selected by precedence
        expect(resolvedBizId, 'c5fe7bee-11ab-4575-9752-46ca4b3bdc34');

        // Test OnboardingRepository with real client
        final onboardingRepo = OnboardingRepository(client: client);
        final progress = await onboardingRepo.loadProgressForBusiness(
          resolvedBizId!,
        );
        expect(progress.isOnboardingCompleted, true);
        expect(progress.isBusinessCompleted, true);
        expect(progress.isLocationCompleted, true);
        expect(progress.isCommerceCompleted, true);
        expect(progress.isInventoryCompleted, true);
        expect(progress.isTeamCompleted, true);

        // Verify all repositories resolve the completed business ID
        CurrentBusinessService.instance.setCurrentBusiness(
          businessService.currentBusiness!,
        );
        expect(
          await BrandRepository().resolveCurrentBusinessId(),
          resolvedBizId,
        );
        expect(
          await CategoryRepository().resolveCurrentBusinessId(),
          resolvedBizId,
        );
        expect(
          await SupplierRepository().resolveCurrentBusinessId(),
          resolvedBizId,
        );
        expect(
          await ProductRepository().resolveCurrentBusinessId(),
          resolvedBizId,
        );
        expect(
          await LocationRepository().resolveCurrentBusinessId(),
          resolvedBizId,
        );

        // Query products, brands, categories, suppliers, locations in Supabase using this businessId
        final products = await client
            .from('products')
            .select()
            .eq('business_id', resolvedBizId);
        expect((products as List).length, greaterThanOrEqualTo(1));

        final brands = await client
            .from('brands')
            .select()
            .eq('business_id', resolvedBizId);
        expect((brands as List).length, greaterThanOrEqualTo(1));

        final categories = await client
            .from('categories')
            .select()
            .eq('business_id', resolvedBizId);
        expect((categories as List).length, greaterThanOrEqualTo(1));

        final suppliers = await client
            .from('suppliers')
            .select()
            .eq('business_id', resolvedBizId);
        expect((suppliers as List).length, greaterThanOrEqualTo(1));

        final locations = await client
            .from('locations')
            .select()
            .eq('business_id', resolvedBizId);
        expect((locations as List).length, greaterThanOrEqualTo(1));
      },
    );
  });
}
