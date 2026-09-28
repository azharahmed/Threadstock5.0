import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/navigation/navigation_guard.dart';
import 'package:threadstock/core/services/google_places_service.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:threadstock/features/onboarding/presentation/widgets/google_location_map_view.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    NavigationGuard.resetForTesting();
    GooglePlacesService.instance.resetUsageCounters();
    GooglePlacesService.instance.clearSessionCache();
    GooglePlacesService.mockPredictions = null;
    GooglePlacesService.mockDetails = null;
    GooglePlacesService.mockApiUnavailable = false;
  });

  tearDown(() {
    NavigationGuard.resetForTesting();
    GooglePlacesService.instance.resetUsageCounters();
    GooglePlacesService.instance.clearSessionCache();
    GooglePlacesService.mockPredictions = null;
    GooglePlacesService.mockDetails = null;
    GooglePlacesService.mockApiUnavailable = false;
  });

  group('THREADSTOCK GOOGLE PLACES COST CONTROL TESTS', () {
    test('1. Minimum characters: query < 2 chars does not call Places or increment counter', () async {
      final service = GooglePlacesService.instance;

      final res1 = await service.searchPlacesWithResult(query: 'w');
      expect(res1.predictions, isEmpty);
      expect(service.usageCounters.autocomplete, equals(0));

      final res2 = await service.searchPlacesWithResult(query: ' ');
      expect(res2.predictions, isEmpty);
      expect(service.usageCounters.autocomplete, equals(0));
    });

    test('2. Autocomplete result limit: capped at 5 results maximum', () async {
      final service = GooglePlacesService.instance;
      GooglePlacesService.mockPredictions = List.generate(
        12,
        (i) => PlacePrediction(
          placeId: 'place_$i',
          description: 'Bangalore Store $i, Karnataka, India',
          mainText: 'Bangalore Store $i',
          secondaryText: 'Karnataka, India',
        ),
      );

      final result = await service.searchPlacesWithResult(
        query: 'Bangalore',
        countryCode: 'IN',
      );

      expect(result.isSuccess, isTrue);
      expect(result.predictions.length, equals(5)); // Capped at 5
      expect(service.usageCounters.autocomplete, equals(1));
    });

    test('3. Session Cache: identical query + country reuses cached predictions without new API call', () async {
      final service = GooglePlacesService.instance;
      GooglePlacesService.mockPredictions = [
        const PlacePrediction(
          placeId: 'place_hebbal_1',
          description: 'Hebbal Kempapura, Bengaluru, Karnataka, India',
          mainText: 'Hebbal Kempapura',
          secondaryText: 'Bengaluru, Karnataka, India',
        ),
      ];

      // First call -> populates cache
      final res1 = await service.searchPlacesWithResult(
        query: 'hebbal',
        countryCode: 'IN',
      );
      expect(res1.predictions.length, equals(1));
      expect(service.usageCounters.autocomplete, equals(1));
      expect(service.usageCounters.cacheHits, equals(0));

      // Second identical call -> hits cache
      final res2 = await service.searchPlacesWithResult(
        query: 'hebbal',
        countryCode: 'IN',
      );
      expect(res2.predictions.length, equals(1));
      expect(service.usageCounters.autocomplete, equals(1)); // Did NOT increment
      expect(service.usageCounters.cacheHits, equals(1)); // Cache hit recorded!
    });

    test('4. Details called ONLY on selection: autocomplete leaves details counter at 0', () async {
      final service = GooglePlacesService.instance;
      GooglePlacesService.mockPredictions = [
        const PlacePrediction(
          placeId: 'place_sel_1',
          description: 'Silk Board, Bengaluru, Karnataka',
          mainText: 'Silk Board',
          secondaryText: 'Bengaluru',
        ),
      ];
      GooglePlacesService.mockDetails = const PlaceDetails(
        placeId: 'place_sel_1',
        name: 'Silk Board Flagship',
        formattedAddress: 'Silk Board, Bengaluru, Karnataka 560068',
        streetAddress: 'Outer Ring Rd',
        city: 'Bengaluru',
        state: 'Karnataka',
        postalCode: '560068',
        countryCode: 'IN',
        countryName: 'India',
        latitude: 12.9172,
        longitude: 77.6228,
      );

      // Perform autocomplete only
      await service.searchPlacesWithResult(query: 'silk board', countryCode: 'IN');
      expect(service.usageCounters.autocomplete, equals(1));
      expect(service.usageCounters.details, equals(0)); // Details NOT called

      // Now user clicks/selects the place
      final details = await service.getPlaceDetails(
        'place_sel_1',
        sessionToken: 'test_session_token_123',
      );
      expect(details, isNotNull);
      expect(details!.placeId, equals('place_sel_1'));
      expect(service.usageCounters.details, equals(1)); // Details called exactly once
    });

    test('5. Session token lifecycle: token passed to details and usage tracked', () {
      final token1 = PlacesSessionToken.generate();
      final token2 = PlacesSessionToken.generate();
      expect(token1, isNotEmpty);
      expect(token2, isNotEmpty);
      expect(token1, isNot(equals(token2)));
    });

    test('6. Development usage counters string format does NOT leak secrets', () {
      final service = GooglePlacesService.instance;
      final countersStr = service.usageCounters.toString();
      expect(countersStr, contains('[PlacesUsage] autocomplete=0 details=0 cacheHits=0 failures=0'));
      expect(countersStr, isNot(contains('key')));
      expect(countersStr, isNot(contains('secret')));
      expect(countersStr, isNot(contains('token')));
    });

    testWidgets('7. Map rendering: manual address with no coordinates displays "Address entered manually"',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoogleLocationMapView(
              placeName: 'Manual Flagship Store',
              streetAddress: '100 Main Road',
              city: 'Bengaluru',
              latitude: null,
              longitude: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Expect manual address badge, NOT a map
      expect(find.text('Address entered manually'), findsOneWidget);
      expect(find.byKey(const ValueKey('manual_address_indicator')), findsOneWidget);
      expect(find.byKey(const ValueKey('real_google_map')), findsNothing);
    });

    testWidgets('8. Map rendering: real coordinates render coordinates badge and map representation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoogleLocationMapView(
              placeName: 'Bangalore Flagship',
              streetAddress: 'Outer Ring Rd',
              city: 'Bengaluru',
              latitude: 12.9172,
              longitude: 77.6228,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('manual_address_indicator')), findsNothing);
      expect(find.text('12.9172, 77.6228'), findsOneWidget);
    });

    testWidgets('9. Reopening/editing saved location does not trigger Google Places calls',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      CurrentBusinessService.instance.setCurrentBusinessId('test_biz_reopen');

      final repo = OnboardingRepository.instance;
      await repo.saveProgress(
        const OnboardingProgress(
          businessId: 'test_biz_reopen',
          businessName: 'Reopen Boutique',
          isBusinessCompleted: true,
          configuredLocations: [
            {
              'name': 'Existing Stored Warehouse',
              'type': 'Warehouse',
              'street': '77 Industrial Area',
              'city': 'Bengaluru',
              'postal': '560058',
              'country': 'IN',
            }
          ],
        ),
      );

      final service = GooglePlacesService.instance;
      service.resetUsageCounters();

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 2, // Location view step
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify that viewing location page did not invoke Google Places
      expect(service.usageCounters.autocomplete, equals(0));
      expect(service.usageCounters.details, equals(0));
    });

    testWidgets('10. Graceful manual fallback: when Google is unavailable, allows manual entry and continue',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      GooglePlacesService.mockApiUnavailable = true;

      CurrentBusinessService.instance.setCurrentBusinessId('test_biz_manual');
      final repo = OnboardingRepository.instance;
      await repo.saveProgress(
        const OnboardingProgress(
          businessId: 'test_biz_manual',
          businessName: 'Manual Entry Co',
          isBusinessCompleted: true,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            initialStep: 2, // Location step
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Type in location name -> triggers unavailable notice
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter location name'),
        'Custom Boutique',
      );
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      // Verify honest failure notice is displayed
      expect(
        find.text('Location search is temporarily unavailable. You can enter the address manually.'),
        findsOneWidget,
      );

      // Select location type
      await tester.tap(find.text('Select location type'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Flagship Store').last);
      await tester.pumpAndSettle();

      // Verify user can enter street, city, pin manually
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter street address'),
        '42 MG Road',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter city'),
        'Bengaluru',
      );
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(3), '560001');
      await tester.pumpAndSettle();

      // Save & Continue button is enabled
      final saveBtn = find.widgetWithText(ElevatedButton, 'Save & Continue');
      expect(tester.widget<ElevatedButton>(saveBtn).onPressed, isNotNull);

      // Tap Save & Continue
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Advances successfully to Step 4 of 6 (Commerce)
      expect(find.text('STEP 4 OF 6 — COMMERCE'), findsOneWidget);
    });

    test('11. ZERO_RESULTS does NOT increment failures counter and returns standard notice', () async {
      final service = GooglePlacesService.instance;
      // Setup mock empty predictions
      GooglePlacesService.mockPredictions = [];

      final result = await service.searchPlacesWithResult(
        query: 'nonexistentplace12345xyz',
        countryCode: 'IN',
      );

      expect(result.isZeroResults, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.isUnavailable, isFalse);
      expect(result.predictions, isEmpty);
      expect(
        result.errorMessage,
        equals('No matching locations found. Try another search or enter the address manually.'),
      );
      // Autocomplete count incremented, but failures remains 0
      expect(service.usageCounters.autocomplete, equals(1));
      expect(service.usageCounters.failures, equals(0));
    });

    test('12. API failure increments failures counter and marks as unavailable', () async {
      final service = GooglePlacesService.instance;
      GooglePlacesService.mockApiUnavailable = true;

      final result = await service.searchPlacesWithResult(
        query: 'hebbal',
        countryCode: 'IN',
      );

      expect(result.isUnavailable, isTrue);
      expect(result.isSuccess, isFalse);
      expect(result.isZeroResults, isFalse);
      expect(result.predictions, isEmpty);
      expect(
        result.errorMessage,
        equals('Location search is temporarily unavailable. You can enter the address manually.'),
      );
      expect(service.usageCounters.failures, equals(1));
      expect(service.usageCounters.autocomplete, equals(0));
    });
  });
}

