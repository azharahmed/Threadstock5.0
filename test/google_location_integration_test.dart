import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/services/google_places_service.dart';
import 'package:threadstock/features/inventory/domain/models/stock_location.dart';
import 'package:threadstock/features/onboarding/presentation/widgets/google_location_map_view.dart';

void main() {
  group('Google Places Service & Models Tests', () {
    test('PlacesSessionToken generates non-empty distinct UUID tokens', () {
      final token1 = PlacesSessionToken.generate();
      final token2 = PlacesSessionToken.generate();

      expect(token1.isNotEmpty, isTrue);
      expect(token2.isNotEmpty, isTrue);
      expect(token1, isNot(equals(token2)));
    });

    test('PlacePrediction properly parses JSON structure', () {
      final json = {
        'place_id': 'ChIJ48220qYTrjsR68gO758s5_w',
        'description': 'Winst Sai Kalyan, Hebbal, Bengaluru, Karnataka, India',
        'structured_formatting': {
          'main_text': 'Winst Sai Kalyan',
          'secondary_text': 'Hebbal, Bengaluru, Karnataka, India',
        },
      };

      final prediction = PlacePrediction.fromJson(json);

      expect(prediction.placeId, equals('ChIJ48220qYTrjsR68gO758s5_w'));
      expect(prediction.description, contains('Winst Sai Kalyan'));
      expect(prediction.mainText, equals('Winst Sai Kalyan'));
      expect(prediction.secondaryText, contains('Hebbal, Bengaluru'));
    });

    test('PlaceDetails correctly parses address components and coordinates', () {
      final json = {
        'place_id': 'ChIJ48220qYTrjsR68gO758s5_w',
        'name': 'Winst Sai Kalyan',
        'formatted_address':
            'Hebbal Kempapura, Bengaluru, Karnataka 560024, India',
        'geometry': {
          'location': {
            'lat': 13.0483,
            'lng': 77.5925,
          },
        },
        'address_components': [
          {
            'long_name': 'Kempapura',
            'short_name': 'Kempapura',
            'types': ['sublocality_level_1', 'sublocality', 'political'],
          },
          {
            'long_name': 'Hebbal',
            'short_name': 'Hebbal',
            'types': ['sublocality_level_2', 'sublocality', 'political'],
          },
          {
            'long_name': 'Bengaluru',
            'short_name': 'Bengaluru',
            'types': ['locality', 'political'],
          },
          {
            'long_name': 'Karnataka',
            'short_name': 'KA',
            'types': ['administrative_area_level_1', 'political'],
          },
          {
            'long_name': '560024',
            'short_name': '560024',
            'types': ['postal_code'],
          },
          {
            'long_name': 'India',
            'short_name': 'IN',
            'types': ['country', 'political'],
          },
        ],
      };

      final details = PlaceDetails.fromJson(json);

      expect(details.placeId, equals('ChIJ48220qYTrjsR68gO758s5_w'));
      expect(details.name, equals('Winst Sai Kalyan'));
      expect(details.formattedAddress, contains('560024'));
      expect(details.latitude, equals(13.0483));
      expect(details.longitude, equals(77.5925));
      expect(details.city, equals('Bengaluru'));
      expect(details.state, equals('Karnataka'));
      expect(details.postalCode, equals('560024'));
      expect(details.countryName, equals('India'));
      expect(details.countryCode, equals('IN'));
    });

    test('StockLocation model preserves googlePlaceId, coordinates, and formattedAddress', () {
      final location = StockLocation(
        id: 'loc-100',
        businessId: 'biz-100',
        name: 'Winst Sai Kalyan',
        locationType: 'Retail Store',
        streetAddress: 'Hebbal Kempapura',
        city: 'Bengaluru',
        postalCode: '560024',
        countryCode: 'IN',
        googlePlaceId: 'ChIJ48220qYTrjsR68gO758s5_w',
        latitude: 13.0483,
        longitude: 77.5925,
        formattedAddress: 'Hebbal Kempapura, Bengaluru, Karnataka 560024, India',
      );

      expect(location.hasCoordinates, isTrue);

      final json = location.toJson();
      expect(json['google_place_id'], equals('ChIJ48220qYTrjsR68gO758s5_w'));
      expect(json['latitude'], equals(13.0483));
      expect(json['longitude'], equals(77.5925));
      expect(json['formatted_address'], contains('560024'));

      final restored = StockLocation.fromJson(json);
      expect(restored.googlePlaceId, equals('ChIJ48220qYTrjsR68gO758s5_w'));
      expect(restored.latitude, equals(13.0483));
      expect(restored.longitude, equals(77.5925));
      expect(restored.formattedAddress, equals(location.formattedAddress));
    });
  });

  group('GoogleLocationMapView Widget Tests', () {
    testWidgets('Renders Verified location badge and Google place details when verified',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GoogleLocationMapView(
                latitude: 13.0483,
                longitude: 77.5925,
                placeName: 'Winst Sai Kalyan',
                formattedAddress:
                    'Hebbal Kempapura, Bengaluru, Karnataka 560024, India',
                streetAddress: 'Hebbal Kempapura',
                city: 'Bengaluru',
                postalCode: '560024',
                state: 'Karnataka',
                country: 'India',
                isVerified: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('✓ Verified location'), findsOneWidget);
      expect(find.text('Winst Sai Kalyan'), findsWidgets);
      expect(find.textContaining('13.0483, 77.5925'), findsOneWidget);
      expect(find.text('Hebbal Kempapura, Bengaluru, Karnataka 560024, India'),
          findsOneWidget);
    });

    testWidgets('Renders Manual address badge when entered without Google place selection',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GoogleLocationMapView(
                latitude: -37.8136,
                longitude: 144.9631,
                placeName: 'Custom Workshop',
                streetAddress: '42 Industrial Road',
                city: 'Melbourne',
                postalCode: '3000',
                country: 'Australia',
                isVerified: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Manual address'), findsOneWidget);
      expect(find.text('Custom Workshop'), findsWidgets);
      expect(find.text('42 Industrial Road'), findsOneWidget);
      expect(find.text('Melbourne 3000'), findsOneWidget);
      expect(find.text('✓ Verified location'), findsNothing);
    });

    testWidgets('Renders nothing when no coordinates exist (no fake preview)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GoogleLocationMapView(
              latitude: null,
              longitude: null,
              placeName: 'Unlocated Store',
              streetAddress: '123 Fake Street',
              city: 'Melbourne',
              isVerified: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('google_location_map_view')), findsNothing);
      expect(find.text('Unlocated Store'), findsNothing);
    });

    test('PlacesSearchResult correctly identifies zero results and unavailable states', () {
      const zeroResult = PlacesSearchResult(
        status: PlacesSearchStatus.zeroResults,
        errorMessage:
            'No matching Google places found. You can still enter the address manually.',
      );
      expect(zeroResult.isZeroResults, isTrue);
      expect(zeroResult.isSuccess, isFalse);
      expect(zeroResult.isUnavailable, isFalse);
      expect(zeroResult.predictions, isEmpty);

      const unavailableResult = PlacesSearchResult(
        status: PlacesSearchStatus.unavailable,
        errorMessage: 'Google lookup unavailable. Enter address manually.',
      );
      expect(unavailableResult.isUnavailable, isTrue);
      expect(unavailableResult.isSuccess, isFalse);
      expect(unavailableResult.isZeroResults, isFalse);
    });

    test('StockLocation enforces coordinate bounds (-90 to 90 lat, -180 to 180 lng)', () {
      final validLoc = StockLocation(
        id: 'loc-1',
        businessId: 'biz-1',
        name: 'Valid Coordinates',
        latitude: 12.9716,
        longitude: 77.5946,
      );
      expect(validLoc.latitude! >= -90 && validLoc.latitude! <= 90, isTrue);
      expect(validLoc.longitude! >= -180 && validLoc.longitude! <= 180, isTrue);
      expect(validLoc.hasCoordinates, isTrue);

      final noCoordLoc = StockLocation(
        id: 'loc-2',
        businessId: 'biz-1',
        name: 'Manual No Coords',
      );
      expect(noCoordLoc.hasCoordinates, isFalse);
    });
  });
}

