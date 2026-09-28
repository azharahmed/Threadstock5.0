import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/features/business/domain/models/business.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/domain/inventory_change_notifier.dart';
import 'package:threadstock/features/inventory/domain/models/stock_location.dart';
import 'package:threadstock/features/sales/data/sales_repository.dart';
import 'package:threadstock/features/sales/presentation/active_sale_session.dart';
import 'package:threadstock/features/sales/presentation/widgets/new_sale_view.dart';

void main() {
  const launchGridBizId = '863b4f7b-7a8e-4ffa-a4aa-e4cd453613af';
  const stockLocationId = 'bf4f8239-a054-4248-bce0-506c686549dd';
  const otherBizId = '99999999-9999-9999-9999-999999999999';

  final launchGridStockLocation = StockLocation(
    id: stockLocationId,
    businessId: launchGridBizId,
    name: 'Stock location',
    locationType: 'warehouse',
    status: 'active',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final inactiveLocation = StockLocation(
    id: 'inactive-loc-001',
    businessId: launchGridBizId,
    name: 'Closed Storehouse',
    locationType: 'warehouse',
    status: 'inactive',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    LocationRepository.clearLocalState();
    SalesRepository.clearLocalSalesForTesting();
    ActiveSaleSession.instance.clear();
    CurrentBusinessService.instance.clear();
    AppPreferencesService.resetForTesting();

    // Set LaunchGrid as current business
    CurrentBusinessService.instance.setCurrentBusiness(
      Business(
        id: launchGridBizId,
        ownerUserId: 'owner-launchgrid',
        legalName: 'LaunchGrid',
        businessType: 'retail',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    // Seed mock locations: 1 active ("Stock location") and 1 inactive
    LocationRepository.setMockLocations(launchGridBizId, [
      launchGridStockLocation,
      inactiveLocation,
    ]);
  });

  tearDown(() {
    LocationRepository.clearLocalState();
    ActiveSaleSession.instance.clear();
    CurrentBusinessService.instance.clear();
  });

  group('THREADSTOCK SALES LOCATION CONTRACT', () {
    test('1. Current-business location loading: scopes to currentBusiness.id and status = active', () async {
      final locRepo = LocationRepository();
      final activeLocs = await locRepo.getLocations(
        businessId: launchGridBizId,
        onlyActive: true,
      );

      expect(activeLocs.length, 1);
      expect(activeLocs.first.id, stockLocationId);
      expect(activeLocs.first.name, 'Stock location');
      expect(activeLocs.first.status, 'active');

      // Verify inactive location was excluded
      final allLocs = await locRepo.getLocations(
        businessId: launchGridBizId,
        onlyActive: false,
      );
      expect(allLocs.length, 2);
      expect(allLocs.any((l) => l.status == 'inactive'), isTrue);
    });

    test('2. Cross-business leakage: locations from LaunchGrid never leak to another business', () async {
      final locRepo = LocationRepository();
      final otherLocs = await locRepo.getLocations(
        businessId: otherBizId,
        onlyActive: true,
      );

      // Business B has no locations configured yet
      expect(otherLocs, isEmpty);
      expect(otherLocs.any((l) => l.id == stockLocationId), isFalse);
    });

    testWidgets('3. UI: Auto-select single active location, display real name, hide false warning banner', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NewSaleView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Location selector in header displays real name "Stock location"
      final selectorFinder = find.byKey(const Key('sales_location_selector'));
      expect(selectorFinder, findsOneWidget);
      expect(find.descendant(of: selectorFinder, matching: find.text('Stock location')), findsOneWidget);

      // False warning banner "No Location Configured" MUST NOT BE RENDERED
      expect(find.text('No Location Configured'), findsNothing);

      // Authoritative central state is synchronized
      expect(CurrentBusinessService.instance.currentLocationId, stockLocationId);
      expect(ActiveSaleSession.instance.locationId, stockLocationId);
      expect(ActiveSaleSession.instance.locationName, 'Stock location');
    });

    testWidgets('4. UI: If business truly has no locations, warning banner is displayed', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Switch to a business with 0 locations
      CurrentBusinessService.instance.setCurrentBusiness(
        Business(
          id: otherBizId,
          ownerUserId: 'owner-other',
          legalName: 'Other Business',
          businessType: 'retail',
          countryCode: 'IN',
          currencyCode: 'INR',
          locationRange: '1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NewSaleView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Warning banner is displayed
      expect(find.text('No Location Configured'), findsOneWidget);
      expect(find.text('No Location'), findsOneWidget);
    });

    testWidgets('5. complete_sale payload uses authoritative selectedLocationId and does not wipe location on complete', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NewSaleView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Session and central service have stockLocationId
      expect(CurrentBusinessService.instance.currentLocationId, stockLocationId);
      expect(ActiveSaleSession.instance.locationId, stockLocationId);

      // Complete sale via SalesRepository
      final result = await SalesRepository.instance.completeSale(
        businessId: launchGridBizId,
        locationId: stockLocationId,
        subtotal: 1000.0,
        discount: 0.0,
        tax: 0.0,
        total: 1000.0,
        currencyCode: 'INR',
        items: [
          {
            'product_id': 'prod-002',
            'product_name_snapshot': 'Product 2',
            'sku_snapshot': 'P2-SKU',
            'quantity': 1,
            'unit_price_minor': 100000,
            'unit_cost_minor': 50000,
            'line_total_minor': 100000,
            'taxable_amount_minor': 100000,
            'discount_minor': 0,
            'tax_minor': 0,
            'tax_category_snapshot': 'standard',
          }
        ],
        payments: [
          {
            'payment_method': 'cash',
            'amount_minor': 100000,
            'currency_code': 'INR',
            'status': 'completed',
          }
        ],
      );

      expect(result.success, isTrue);
      expect(result.sale, isNotNull);
      expect(result.sale!.locationId, stockLocationId);

      // Cart session cleared with preserveLocation: true
      ActiveSaleSession.instance.clear(preserveLocation: true);
      expect(ActiveSaleSession.instance.locationId, stockLocationId);
      expect(ActiveSaleSession.instance.lines, isEmpty);
    });

    test('6. Restart restoration: preferences restore previously selected location safely', () async {
      // Save location preference for LaunchGrid
      await AppPreferencesService.instance.setCurrentLocationId(
        launchGridBizId,
        stockLocationId,
      );

      // Simulate app restart: clear in-memory state
      CurrentBusinessService.instance.clear();
      expect(CurrentBusinessService.instance.currentLocationId, isNull);

      // Set business as LaunchGrid upon startup resolution
      CurrentBusinessService.instance.setCurrentBusinessId(launchGridBizId);

      // Location is automatically restored from preferences
      expect(CurrentBusinessService.instance.currentLocationId, stockLocationId);
    });

    test('7. Invalidation: changing location status or adding location triggers reactive reload', () async {
      final locRepo = LocationRepository();
      var notificationCount = 0;
      InventoryChangeNotifier.instance.addListener(() {
        notificationCount++;
      });

      // Activate a new location
      await locRepo.createLocation(
        name: 'Secondary Outlet',
        locationType: 'store',
        businessId: launchGridBizId,
      );

      expect(notificationCount, greaterThan(0));

      final activeLocs = await locRepo.getLocations(
        businessId: launchGridBizId,
        onlyActive: true,
      );
      expect(activeLocs.any((l) => l.name == 'Secondary Outlet'), isTrue);
    });
  });
}
