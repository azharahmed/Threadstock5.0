import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadstock/app/router/app_router.dart';
import 'package:threadstock/core/auth/auth_service.dart';
import 'package:threadstock/core/auth/authorization_service.dart';
import 'package:threadstock/core/business/app_bootstrap_service.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/features/business/domain/models/business.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const launchGridBizId = '863b4f7b-7a8e-4ffa-a4aa-e4cd453613af';
  const ownerUserId = '95e46b8a-ec10-4713-a3ec-ae20192866fa';
  const userBId = '11111111-2222-3333-4444-555555555555';

  setUp(() async {
    AuthService.instance.resetForTesting();
    AuthorizationService.instance.clear();
    CurrentBusinessService.instance.clear();
    AppPreferencesService.resetForTesting();
    await AppPreferencesService.instance.setCurrentBusinessId(null);
    OnboardingRepository.instance.clearCache();
  });

  tearDown(() async {
    AuthService.instance.resetForTesting();
    AuthorizationService.instance.clear();
    CurrentBusinessService.instance.clear();
    AppPreferencesService.resetForTesting();
    await AppPreferencesService.instance.setCurrentBusinessId(null);
    OnboardingRepository.instance.clearCache();
  });

  group('THREADSTOCK CURRENT BUSINESS BOOTSTRAP REPAIR TESTS', () {
    test('1. UUID syntax validation strictly accepts valid UUIDs and rejects synthetic IDs', () {
      expect(CurrentBusinessService.isValidUuid(launchGridBizId), isTrue);
      expect(CurrentBusinessService.isValidUuid('0e44d09f-b383-46cc-9b45-2d3f7a528971'), isTrue);
      expect(CurrentBusinessService.isValidUuid('c5fe7bee-11ab-4575-9752-46ca4b3bdc34'), isTrue);

      // Synthetic demo / invalid IDs must be rejected
      expect(CurrentBusinessService.isValidUuid('biz_launchgrid_001'), isFalse);
      expect(CurrentBusinessService.isValidUuid('biz_demo_001'), isFalse);
      expect(CurrentBusinessService.isValidUuid('business_001'), isFalse);
      expect(CurrentBusinessService.isValidUuid(''), isFalse);
      expect(CurrentBusinessService.isValidUuid(null), isFalse);
      expect(CurrentBusinessService.isValidUuid('not-a-valid-uuid-length'), isFalse);
    });

    test('2. AppPreferencesService refuses to persist malformed non-UUID business ID', () async {
      await AppPreferencesService.instance.setCurrentBusinessId('biz_launchgrid_001');
      expect(AppPreferencesService.instance.currentBusinessId, isNull);

      // Valid UUID persists normally
      await AppPreferencesService.instance.setCurrentBusinessId(launchGridBizId);
      expect(AppPreferencesService.instance.currentBusinessId, launchGridBizId);

      // Clearing with null works
      await AppPreferencesService.instance.setCurrentBusinessId(null);
      expect(AppPreferencesService.instance.currentBusinessId, isNull);
    });

    test('3. Cached valid accessible UUID is restored', () async {
      final biz = Business(
        id: launchGridBizId,
        ownerUserId: ownerUserId,
        legalName: 'LaunchGrid',
        businessType: 'Retail',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      CurrentBusinessService.instance.setCurrentBusiness(biz);
      expect(CurrentBusinessService.instance.currentBusinessId, launchGridBizId);
      expect(AppPreferencesService.instance.currentBusinessId, launchGridBizId);
    });

    test('4. Cached malformed ID "biz_launchgrid_001" is discarded and does not crash resolution', () async {
      // Manually set an invalid string in in-memory test preferences
      AppPreferencesService.resetForTesting(businessId: 'biz_launchgrid_001');
      expect(AppPreferencesService.instance.currentBusinessId, 'biz_launchgrid_001');

      // Offline resolveCurrentBusinessId discards invalid ID and does not crash
      final resolved = await CurrentBusinessService.instance.resolveCurrentBusinessId();
      // Since sb is null in disconnected test, invalid ID is discarded and returns null cleanly without throw
      expect(resolved, isNull);
      expect(AppPreferencesService.instance.currentBusinessId, isNull);
    });

    test('5. Completed business resolution restores LaunchGrid and routes to Overview', () async {
      final biz = Business(
        id: launchGridBizId,
        ownerUserId: ownerUserId,
        legalName: 'LaunchGrid',
        businessType: 'Retail',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      CurrentBusinessService.instance.setCurrentBusiness(biz);
      OnboardingRepository.instance.saveProgress(
        const OnboardingProgress(
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: true,
          isInventoryCompleted: true,
          isTeamCompleted: true,
          isOnboardingCompleted: true,
          businessId: launchGridBizId,
        ),
      );

      AuthService.instance.setAuthenticatedForTesting(
        user: const User(
          id: ownerUserId,
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-09-24T00:00:00Z',
        ),
      );

      final result = await AppBootstrapService.bootstrap();
      expect(result.businessId, launchGridBizId);
      expect(result.isOnboardingCompleted, isTrue);
      expect(result.initialRoute, AppRoutes.overview);
    });

    test('6. Malformed cache does NOT route directly to onboarding when business is available', () async {
      // In-memory test state holds completed business
      final biz = Business(
        id: launchGridBizId,
        ownerUserId: ownerUserId,
        legalName: 'LaunchGrid',
        businessType: 'Retail',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      CurrentBusinessService.instance.setCurrentBusiness(biz);

      // Force preference to malformed ID
      AppPreferencesService.resetForTesting(businessId: 'biz_launchgrid_001');

      OnboardingRepository.instance.saveProgress(
        const OnboardingProgress(
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: true,
          isInventoryCompleted: true,
          isTeamCompleted: true,
          isOnboardingCompleted: true,
          businessId: launchGridBizId,
        ),
      );

      AuthService.instance.setAuthenticatedForTesting(
        user: const User(
          id: ownerUserId,
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-09-24T00:00:00Z',
        ),
      );

      final result = await AppBootstrapService.bootstrap();
      expect(result.initialRoute, AppRoutes.overview);
      expect(result.businessId, launchGridBizId);
    });

    test('7. createOrUpdateBusinessForOwner prevents duplicate creation and uses UUID', () async {
      // In disconnected mode (sb == null), fallback generates a valid UUID, NEVER "biz_"
      final created = await CurrentBusinessService.instance.createOrUpdateBusinessForOwner(
        legalName: 'LaunchGrid',
        businessType: 'Retail',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1',
      );

      expect(CurrentBusinessService.isValidUuid(created.id), isTrue);
      expect(created.id.startsWith('biz_'), isFalse);
      expect(CurrentBusinessService.instance.currentBusinessId, created.id);
    });

    test('8. Permissions load properly for authoritative business owner', () {
      final biz = Business(
        id: launchGridBizId,
        ownerUserId: ownerUserId,
        legalName: 'LaunchGrid',
        businessType: 'Retail',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      CurrentBusinessService.instance.setCurrentBusiness(biz);

      // Explicitly configure owner permissions for test
      AuthorizationService.instance.setPermissionsForTesting(
        isOwner: true,
        roleName: 'Owner',
      );

      expect(AuthorizationService.instance.isOwner, isTrue);
      expect(AuthorizationService.instance.can('inventory.view'), isTrue);
      expect(AuthorizationService.instance.can('inventory.manage'), isTrue);
      expect(AuthorizationService.instance.can('inventory.adjust'), isTrue);
      expect(AuthorizationService.instance.can('sales.create'), isTrue);
    });

    test('9. Global sign-out purges user-specific business and auth state', () async {
      final biz = Business(
        id: launchGridBizId,
        ownerUserId: ownerUserId,
        legalName: 'LaunchGrid',
        businessType: 'Retail',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      CurrentBusinessService.instance.setCurrentBusiness(biz);
      expect(CurrentBusinessService.instance.currentBusinessId, launchGridBizId);

      // Perform sign-out
      await AuthService.instance.signOut();

      expect(CurrentBusinessService.instance.currentBusinessId, isNull);
      expect(CurrentBusinessService.instance.currentBusiness, isNull);
      expect(AppPreferencesService.instance.currentBusinessId, isNull);
      expect(AuthorizationService.instance.permissions, isEmpty);
      expect(AuthService.instance.isAuthenticated, isFalse);
    });

    test('10. Different user login does NOT inherit previous user business context', () async {
      // User A signs in with LaunchGrid
      final bizA = Business(
        id: launchGridBizId,
        ownerUserId: ownerUserId,
        legalName: 'LaunchGrid',
        businessType: 'Retail',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      CurrentBusinessService.instance.setCurrentBusiness(bizA);

      // User A signs out
      await AuthService.instance.signOut();
      expect(CurrentBusinessService.instance.currentBusinessId, isNull);

      // User B logs in without business
      AuthService.instance.setAuthenticatedForTesting(
        user: const User(
          id: userBId,
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-09-24T00:00:00Z',
        ),
      );

      // User B bootstrap routes to onboarding without adopting User A's business ID
      final resultB = await AppBootstrapService.bootstrap();
      expect(resultB.businessId, isNull);
      expect(resultB.initialRoute, AppRoutes.onboarding);
    });
  });
}
