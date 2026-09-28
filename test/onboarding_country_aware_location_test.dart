import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/reference/country_currency_reference.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';

class _MockOnboardingRepository extends OnboardingRepository {
  OnboardingProgress _state;

  _MockOnboardingRepository(this._state);

  @override
  OnboardingProgress get currentProgress => _state;

  @override
  Future<void> saveProgress(OnboardingProgress progress) async {
    _state = progress;
  }

  @override
  Future<OnboardingProgress> markStepComplete(
    int step, {
    Map<String, dynamic>? data,
  }) async {
    OnboardingProgress updated = _state;
    if (step == 1) {
      updated = updated.copyWith(
        isBusinessCompleted: true,
        businessName: data?['businessName'] as String?,
        businessType: data?['businessType'] as String?,
        countryCode: data?['countryCode'] as String?,
        currencyCode: data?['currencyCode'] as String?,
        locationRange: data?['locationRange'] as String?,
      );
    } else if (step == 2) {
      final locs = data?['configuredLocations'] as List?;
      updated = updated.copyWith(
        isLocationCompleted: true,
        configuredLocations: locs
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
    }
    _state = updated;
    return _state;
  }

  @override
  Future<OnboardingProgress> invalidateFrom(int step) async {
    if (step <= 2) {
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
    }
    return _state;
  }
}

void main() {
  void setDesktopSize(
    WidgetTester tester, {
    Size size = const Size(1920, 1200),
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('CountryCurrencyReference Country-Aware Validation', () {
    test('Postal code validation enforces country-specific formats', () {
      // Australia: 4 digits
      expect(CountryCurrencyReference.isValidPostalCode('AU', '2000'), isTrue);
      expect(CountryCurrencyReference.isValidPostalCode('AU', '3000'), isTrue);
      expect(
        CountryCurrencyReference.isValidPostalCode('AU', '110016'),
        isFalse,
      );
      expect(
        CountryCurrencyReference.validatePostalCode('AU', '110016'),
        contains('4-digit Australian postcode'),
      );

      // India: 6 digits
      expect(
        CountryCurrencyReference.isValidPostalCode('IN', '110016'),
        isTrue,
      );
      expect(CountryCurrencyReference.isValidPostalCode('IN', '2000'), isFalse);
      expect(
        CountryCurrencyReference.validatePostalCode('IN', '2000'),
        contains('6-digit Indian PIN code'),
      );

      // United States: 5 digits
      expect(CountryCurrencyReference.isValidPostalCode('US', '90210'), isTrue);
      expect(
        CountryCurrencyReference.isValidPostalCode('US', '110016'),
        isFalse,
      );

      // United Kingdom: alphanumeric
      expect(
        CountryCurrencyReference.isValidPostalCode('GB', 'SW1A 1AA'),
        isTrue,
      );
      expect(
        CountryCurrencyReference.isValidPostalCode('GB', '110016'),
        isFalse,
      );
    });

    test('Tax system labels match country jurisdiction', () {
      expect(
        CountryCurrencyReference.taxSystemLabelForCountry('AU'),
        'Australia — GST (10%)',
      );
      expect(
        CountryCurrencyReference.taxSystemLabelForCountry('IN'),
        'India — GST',
      );
      expect(
        CountryCurrencyReference.taxSystemLabelForCountry('US'),
        'United States — Sales Tax',
      );
      expect(
        CountryCurrencyReference.taxSystemLabelForCountry('GB'),
        'United Kingdom — VAT',
      );
    });
  });

  group('Step 2 Country-Aware Location Setup Widget Tests', () {
    testWidgets(
      '1. Australia selection in Step 1 propagates to Step 2 with neutral placeholders and zero India demo values',
      (tester) async {
        setDesktopSize(tester);
        final repo = _MockOnboardingRepository(
          const OnboardingProgress(
            isBusinessCompleted: true,
            countryCode: 'AU',
            currencyCode: 'AUD',
            businessName: 'Sydney Atelier',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(home: OnboardingPage(initialStep: 2, repository: repo)),
        );
        await tester.pumpAndSettle();

        // Step 2 should be rendered
        expect(find.byKey(const ValueKey('step_2_location')), findsOneWidget);

        // Step 2 displays country context badge: Australia (AU)
        expect(find.text('Australia (AU)'), findsOneWidget);

        // Neutral placeholders must be present
        expect(find.text('Enter location name'), findsOneWidget);
        expect(find.text('Enter street address'), findsOneWidget);
        expect(find.text('Enter city'), findsOneWidget);
        expect(find.text('Enter postal code'), findsOneWidget);
        expect(find.text('Select location type'), findsOneWidget);

        // Verify NO India-specific demo data is present
        expect(find.text('Flagship Delhi'), findsNothing);
        expect(find.text('12, Hauz Khas Village'), findsNothing);
        expect(find.text('New Delhi'), findsNothing);
        expect(find.text('110016'), findsNothing);

        // Corporate rules checkbox refers to Australia and AUD, not INR/India
        expect(find.textContaining('AUD'), findsWidgets);
        expect(find.textContaining('Australia — GST (10%)'), findsOneWidget);
        expect(find.textContaining('India — GST'), findsNothing);
        expect(find.textContaining('INR'), findsNothing);
      },
    );

    testWidgets(
      '2. Postal code validation in Step 2 rejects invalid Australian postcode and accepts 4-digit code',
      (tester) async {
        setDesktopSize(tester);
        final repo = _MockOnboardingRepository(
          const OnboardingProgress(
            isBusinessCompleted: true,
            countryCode: 'AU',
            currencyCode: 'AUD',
            businessName: 'Melbourne Thread',
          ),
        );

        await tester.pumpWidget(
          MaterialApp(home: OnboardingPage(initialStep: 2, repository: repo)),
        );
        await tester.pumpAndSettle();

        // Enter location name
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter location name'),
          'Melbourne Flagship',
        );
        // Select location type
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Retail Store').last);
        await tester.pumpAndSettle();

        // Enter street address & city
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter street address'),
          '250 Collins St',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter city'),
          'Melbourne',
        );

        // Enter Indian 6-digit PIN code while country is Australia
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter postal code'),
          '110016',
        );
        await tester.pumpAndSettle();

        // Click Save & Continue
        await tester.tap(find.text('Save & Continue'));
        await tester.pumpAndSettle();

        // Error must trigger specifically for Australian postcode
        expect(
          find.text('Enter a valid 4-digit Australian postcode (e.g. 2000).'),
          findsOneWidget,
        );
        expect(repo.currentProgress.isLocationCompleted, isFalse);

        // Now enter valid 4-digit Australian postcode (3000)
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter postal code'),
          '3000',
        );
        await tester.pumpAndSettle();

        // Click Save & Continue
        await tester.tap(find.text('Save & Continue'));
        await tester.pumpAndSettle();

        // Should succeed and mark location completed
        expect(repo.currentProgress.isLocationCompleted, isTrue);
        expect(
          repo.currentProgress.configuredLocations.first['countryCode'],
          'AU',
        );
        expect(
          repo.currentProgress.configuredLocations.first['postal'],
          '3000',
        );
      },
    );

    testWidgets(
      '3. Changing country from India to Australia in Step 1 invalidates Location step and marks it for review',
      (tester) async {
        setDesktopSize(tester);
        // Start with India completed with Indian location
        final repo = _MockOnboardingRepository(
          const OnboardingProgress(
            isBusinessCompleted: true,
            isLocationCompleted: true,
            businessName: 'Delhi Silks',
            businessType: 'Luxury Ready-to-Wear',
            countryCode: 'IN',
            currencyCode: 'INR',
            locationRange: '1',
            configuredLocations: [
              {
                'name': 'Delhi Store',
                'type': 'Retail Store',
                'street': 'Connaught Place',
                'city': 'New Delhi',
                'postal': '110001',
                'countryCode': 'IN',
              },
            ],
          ),
        );

        // Open at Step 1
        await tester.pumpWidget(
          MaterialApp(home: OnboardingPage(initialStep: 1, repository: repo)),
        );
        await tester.pumpAndSettle();

        // Change Country in Step 1 to Australia (AU)
        await tester.tap(find.text('India (IN)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Australia (AU)').last);
        await tester.pumpAndSettle();

        // Click Continue to Locations
        await tester.tap(find.text('Continue to Locations'));
        await tester.pumpAndSettle();

        // Now on Step 2
        expect(find.byKey(const ValueKey('step_2_location')), findsOneWidget);

        // Location step must be invalidated in repository
        expect(repo.currentProgress.isLocationCompleted, isFalse);

        // Alert banner must appear notifying the user that country changed and location details must be reviewed
        expect(
          find.text('Country changed. Please review your location details.'),
          findsOneWidget,
        );

        // The configured Indian location card must display 'Needs review' tag
        expect(find.text('Needs review'), findsOneWidget);

        // Attempting to Save & Continue with the stale Indian postcode (110001) must be blocked
        await tester.tap(find.text('Save & Continue'));
        await tester.pumpAndSettle();

        // Still on Step 2 because location postal is invalid for Australia
        expect(find.byKey(const ValueKey('step_2_location')), findsOneWidget);
        expect(repo.currentProgress.isLocationCompleted, isFalse);
      },
    );
  });
}
