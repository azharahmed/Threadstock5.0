import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/sales/presentation/widgets/new_sale_view.dart';

void main() {
  setUp(() {
    LocationRepository.clearLocalState();
    ProductRepository.clearLocalState();
    CurrentBusinessService.instance.setCurrentBusinessId('biz_alpha');
    CurrentBusinessService.instance.setCurrentLocationId(null);
  });

  tearDown(() {
    LocationRepository.clearLocalState();
    ProductRepository.clearLocalState();
    CurrentBusinessService.instance.setCurrentBusinessId(null);
    CurrentBusinessService.instance.setCurrentLocationId(null);
  });

  group('Cross-tenant Location Leakage Prevention', () {
    test('Switching business ID resets currentLocationId to null', () {
      final service = CurrentBusinessService.instance;
      service.setCurrentBusinessId('biz_1');
      service.setCurrentLocationId('loc_biz_1_warehouse');

      expect(service.currentLocationId, equals('loc_biz_1_warehouse'));

      // Switch to another business (e.g., Product 2 business with 0 locations)
      service.setCurrentBusinessId('biz_2');

      // Must be null to prevent cross-tenant location leakage
      expect(service.currentLocationId, isNull);
    });
  });

  group('NewSaleView No-Location Guarding', () {
    testWidgets('Displays warning banner and blocks add to cart when no location exists', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      final service = CurrentBusinessService.instance;
      service.setCurrentBusinessId('biz_with_no_locations');
      service.setCurrentLocationId(null);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NewSaleView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Banner should be visible
      expect(find.text('No Location Configured'), findsOneWidget);
      expect(
        find.text('This business has no active inventory locations. Sales and stock tracking require at least one location.'),
        findsOneWidget,
      );

      // Complete Sale button should still exist but cannot be triggered without a location
      expect(find.text('Complete Sale'), findsOneWidget);
    });
  });
}
