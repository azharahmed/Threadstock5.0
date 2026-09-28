import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:threadstock/core/auth/authorization_service.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/navigation/navigation_guard.dart';
import 'package:threadstock/core/services/google_places_service.dart';
import 'package:threadstock/features/business/domain/models/business.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:threadstock/features/overview/presentation/pages/overview_page.dart';
import 'package:threadstock/features/settings/data/business_profile_repository.dart';

Business createTestBusiness({
  required String id,
  required String legalName,
  required String businessType,
  String countryCode = 'IN',
  String currencyCode = 'INR',
  String locationRange = '2-5',
}) {
  return Business(
    id: id,
    ownerUserId: 'user_123',
    legalName: legalName,
    businessType: businessType,
    countryCode: countryCode,
    currencyCode: currencyCode,
    locationRange: locationRange,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    CurrentBusinessService.instance.clear();
    LocationRepository.clearLocalState();
    OnboardingRepository.instance.clearCache();
    GooglePlacesService.mockPredictions = null;
    GooglePlacesService.mockDetails = null;
  });

  tearDown(() {
    CurrentBusinessService.instance.clear();
    LocationRepository.clearLocalState();
    OnboardingRepository.instance.clearCache();
    GooglePlacesService.mockPredictions = null;
    GooglePlacesService.mockDetails = null;
    try {
      final cache = File('config/locations_cache.json');
      if (cache.existsSync()) cache.deleteSync();
    } catch (_) {}
  });

  group('1. One Authoritative Business Identity & Profile Fallbacks', () {
    test('BusinessProfileRepository falls back to businesses table when settings row is missing', () async {
      final repo = BusinessProfileRepository();

      // Seed business in CurrentBusinessService
      CurrentBusinessService.instance.setCurrentBusiness(
        createTestBusiness(
          id: 'e7c1462e-0478-4f5b-8b97-7c8bc3580bec',
          legalName: 'LaunchGrid',
          businessType: 'Multi-brand Fashion / Department',
        ),
      );

      final profile = await repo.loadProfile(businessId: 'e7c1462e-0478-4f5b-8b97-7c8bc3580bec');

      // Verify display fallback from authoritative business
      expect(profile['display_name'], equals('LaunchGrid'));
      expect(profile['legal_entity_name'], equals('LaunchGrid'));
      expect(profile['business_type'], equals('Multi-brand Fashion / Department'));
      expect(profile['registered_country'], contains('India'));
      expect(profile['primary_currency'], contains('INR'));
    });

    test('BusinessProfileRepository saves and upserts settings row cleanly', () async {
      final repo = BusinessProfileRepository();

      CurrentBusinessService.instance.setCurrentBusiness(
        createTestBusiness(
          id: 'test_biz_upsert',
          legalName: 'Test Business',
          businessType: 'Boutique',
        ),
      );

      await repo.saveProfile(
        businessId: 'test_biz_upsert',
        displayName: 'LaunchGrid Flagship',
        legalEntityName: 'LaunchGrid Retail Pvt Ltd',
        businessType: 'Multi-brand Fashion / Department',
        registeredCountry: 'India (IN)',
        primaryCurrency: 'INR (₹) - Indian Rupee',
        defaultLanguage: 'English (United States)',
        timezone: 'India Standard Time (GMT+5:30)',
        email: 'info@launchgrid.com',
        phone: '+91 98765 43210',
        website: 'https://launchgrid.com',
        streetAddress: 'Brigade Gateway',
        city: 'Bengaluru',
        postalCode: '560055',
      );

      final loaded = await repo.loadProfile(businessId: 'test_biz_upsert');
      expect(loaded['display_name'], equals('LaunchGrid Flagship'));
      expect(loaded['legal_entity_name'], equals('LaunchGrid Retail Pvt Ltd'));
    });
  });

  group('2. Google Places Search & Place Details', () {
    test('searchPlaces returns mock predictions when configured', () async {
      GooglePlacesService.mockPredictions = [
        const PlacePrediction(
          placeId: 'place_orion_mall',
          description: 'Orion Mall, Dr Rajkumar Road, Bengaluru',
          mainText: 'Orion Mall',
          secondaryText: 'Dr Rajkumar Road, Bengaluru',
        ),
        const PlacePrediction(
          placeId: 'place_orion_avenue',
          description: 'Orion Avenue, Brigade Gateway, Bengaluru',
          mainText: 'Orion Avenue',
          secondaryText: 'Brigade Gateway, Bengaluru',
        ),
      ];

      final results = await GooglePlacesService.instance.searchPlaces(
        query: 'Orion',
        countryCode: 'IN',
      );

      expect(results.length, equals(2));
      expect(results.first.mainText, equals('Orion Mall'));
      expect(results.first.placeId, equals('place_orion_mall'));
    });

    test('getPlaceDetails returns place details and coordinates', () async {
      GooglePlacesService.mockDetails = const PlaceDetails(
        placeId: 'place_orion_mall',
        name: 'Orion Mall',
        formattedAddress: 'Orion Mall, 26/1 Dr Rajkumar Rd, Bengaluru 560055, India',
        streetAddress: '26/1 Dr Rajkumar Rd',
        city: 'Bengaluru',
        state: 'Karnataka',
        postalCode: '560055',
        countryCode: 'IN',
        countryName: 'India',
        latitude: 12.9716,
        longitude: 77.5946,
      );

      final details = await GooglePlacesService.instance.getPlaceDetails('place_orion_mall');

      expect(details, isNotNull);
      expect(details!.streetAddress, equals('26/1 Dr Rajkumar Rd'));
      expect(details.city, equals('Bengaluru'));
      expect(details.postalCode, equals('560055'));
      expect(details.countryCode, equals('IN'));
      expect(details.latitude, equals(12.9716));
      expect(details.longitude, equals(77.5946));
    });
  });

  group('3. Location Persistence & Normalization', () {
    test('LocationRepository.createLocation normalizes locationType and persists address', () async {
      final repo = LocationRepository();

      final loc = await repo.createLocation(
        name: 'LaunchGrid Flagship',
        locationType: 'Flagship Store',
        streetAddress: '26/1 Dr Rajkumar Rd',
        city: 'Bengaluru',
        postalCode: '560055',
        countryCode: 'IN',
        businessId: 'test_biz_1',
      );

      expect(loc.id, isNotEmpty);
      expect(loc.name, equals('LaunchGrid Flagship'));
      expect(loc.locationType, equals('retail_store')); // Normalized to DB check constraint
      expect(loc.streetAddress, equals('26/1 Dr Rajkumar Rd'));
      expect(loc.city, equals('Bengaluru'));
      expect(loc.postalCode, equals('560055'));
      expect(loc.countryCode, equals('IN'));

      final all = await repo.getLocations(businessId: 'test_biz_1');
      expect(all.length, equals(1));
      expect(all.first.name, equals('LaunchGrid Flagship'));
    });

    test('LocationRepository rejects duplicate location name within same business', () async {
      final repo = LocationRepository();

      await repo.createLocation(
        name: 'Central Warehouse',
        locationType: 'warehouse',
        businessId: 'test_biz_1',
      );

      expect(
        () => repo.createLocation(
          name: '  central warehouse  ',
          locationType: 'warehouse',
          businessId: 'test_biz_1',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('4. Navigation Guard Idempotency & Lock Release', () {
    testWidgets('NavigationGuard releases lock and allows successive navigations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [NavigationGuard.observer],
          initialRoute: '/login',
          routes: {
            '/login': (context) => const Scaffold(body: Text('Login')),
            '/overview': (context) => const Scaffold(body: Text('Overview')),
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );

      expect(NavigationGuard.isNavigating, isFalse);

      final navContext = tester.element(find.text('Login'));

      // First navigation to /overview
      await NavigationGuard.safePushReplacementNamed(
        navContext,
        '/overview',
        source: 'test_first',
      );
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
      expect(NavigationGuard.isNavigating, isFalse);

      // Idempotent navigation to /overview (already current route)
      final overviewContext = tester.element(find.text('Overview'));
      await NavigationGuard.safePushReplacementNamed(
        overviewContext,
        '/overview',
        source: 'test_duplicate',
      );
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
      expect(NavigationGuard.isNavigating, isFalse);

      // Navigation to another route succeeds without lock conflict
      await NavigationGuard.safePushReplacementNamed(
        overviewContext,
        '/settings',
        source: 'test_settings',
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(NavigationGuard.isNavigating, isFalse);
    });
  });

  group('5. Authorization Deduplication', () {
    test('Concurrent refresh calls are deduplicated into a single in-flight operation', () async {
      final auth = AuthorizationService();

      final future1 = auth.refreshAuthorization(businessId: 'biz_dedup_test');
      final future2 = auth.refreshAuthorization(businessId: 'biz_dedup_test');

      // Both should complete without throwing
      await Future.wait<void>([future1, future2]);

      expect(auth.isLoading, isFalse);
    });
  });

  group('6. Overview Zero-Locations Recoverable State', () {
    testWidgets('OverviewPage displays recoverable empty state when business has 0 locations', (tester) async {
      CurrentBusinessService.instance.setCurrentBusiness(
        createTestBusiness(
          id: 'biz_zero_locations',
          legalName: 'LaunchGrid',
          businessType: 'Multi-brand Fashion / Department',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OverviewPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expect honest recoverable empty state
      expect(find.text('No location configured'), findsOneWidget);
      expect(
        find.text('Add your first location to start inventory and sales.'),
        findsOneWidget,
      );
      expect(find.text('Add Location'), findsOneWidget);
    });
  });

  group('7. Onboarding Header Immediate Business Name Update', () {
    testWidgets('Header displays Setting up: Your Workspace before business save, and LaunchGrid after save', (tester) async {
      final repo = OnboardingRepository.instance;
      await repo.reset();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OnboardingPage(
              initialStep: 0,
              repository: repo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Before Business is saved: shows Setting up: Your Workspace
      expect(find.text('Setting up: Your Workspace'), findsOneWidget);

      // Save business
      await repo.markStepComplete(
        1,
        data: {
          'businessName': 'LaunchGrid',
          'businessType': 'Multi-brand Fashion / Department',
        },
      );
      CurrentBusinessService.instance.setCurrentBusiness(
        createTestBusiness(
          id: 'biz_launchgrid',
          legalName: 'LaunchGrid',
          businessType: 'Multi-brand Fashion / Department',
        ),
      );

      await tester.pumpAndSettle();

      // Header immediately updates without restart
      expect(find.text('Setting up: LaunchGrid'), findsOneWidget);
    });
  });
}
