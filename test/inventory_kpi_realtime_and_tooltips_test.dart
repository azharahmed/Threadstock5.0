import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/data/inventory_repository.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/inventory/data/supplier_repository.dart';
import 'package:threadstock/features/inventory/domain/inventory_change_notifier.dart';
import 'package:threadstock/features/inventory/presentation/widgets/inventory_products_view.dart';

void main() {
  setUp(() {
    ProductRepository.clearLocalState();
    CategoryRepository.clearLocalState();
    SupplierRepository.clearLocalState();
    LocationRepository.clearLocalState();
  });

  Future<void> pumpInventoryView(
    WidgetTester tester, {
    required ProductRepository productRepo,
    required InventoryRepository inventoryRepo,
    required LocationRepository locationRepo,
    required CategoryRepository categoryRepo,
    required SupplierRepository supplierRepo,
  }) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InventoryProductsView(
            businessId: 'test_biz',
            productRepository: productRepo,
            inventoryRepository: inventoryRepo,
            locationRepository: locationRepo,
            categoryRepository: categoryRepo,
            supplierRepository: supplierRepo,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('THREADSTOCK INVENTORY REAL-TIME KPI & TOOLTIP TESTS', () {
    testWidgets(
      '10. Production scenario: Product 2 (tracked 100, threshold null) & New Product 1 (untracked) -> In Stock 100%',
      (tester) async {
        final productRepo = ProductRepository();
        final inventoryRepo = InventoryRepository();
        final locationRepo = LocationRepository();
        final categoryRepo = CategoryRepository();
        final supplierRepo = SupplierRepository();

        // Product 2: track_stock_levels = true, available_qty = 100, low_stock_threshold = null
        await productRepo.publishProduct(
          productId: 'prod_2',
          businessId: 'test_biz',
          name: 'Product 2',
          brandId: 'brand_1',
          categoryId: 'cat_1',
          supplierId: 'sup_1',
          taxCategory: 'Standard',
          costPriceCents: 1000,
          retailPriceCents: 2000,
          sku: 'SKU-PROD-2',
          trackStockLevels: true,
          locationId: 'loc_1',
          openingStock: 100,
          lowStockThreshold: null,
        );

        // New product 1: track_stock_levels = false, available_qty = 0
        await productRepo.publishProduct(
          productId: 'prod_new_1',
          businessId: 'test_biz',
          name: 'New product 1',
          brandId: 'brand_1',
          categoryId: 'cat_1',
          supplierId: 'sup_1',
          taxCategory: 'Standard',
          costPriceCents: 1000,
          retailPriceCents: 2000,
          sku: 'SKU-NEW-1',
          trackStockLevels: false,
          locationId: 'loc_1',
          openingStock: 0,
          lowStockThreshold: null,
        );

        await pumpInventoryView(
          tester,
          productRepo: productRepo,
          inventoryRepo: inventoryRepo,
          locationRepo: locationRepo,
          categoryRepo: categoryRepo,
          supplierRepo: supplierRepo,
        );

        // 1. KPI Card Metrics:
        // Total Styles: 2
        expect(find.text('Total Styles'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        // In Stock: 1, In Stock %: 100% (NOT 50%)
        expect(find.text('In Stock'), findsWidgets);
        expect(find.text('100%'), findsWidgets);
        expect(find.text('100 units available'), findsOneWidget);

        // Low Stock: 0, Low Stock %: 0%
        expect(find.text('Low Stock'), findsOneWidget);
        expect(find.text('0%'), findsWidgets);

        // Out of Stock: 0, Out of Stock %: 0%
        expect(find.text('Out of Stock'), findsWidgets);

        // Row Statuses:
        // Product 2 status: In Stock
        expect(find.text('In Stock'), findsWidgets);

        // New product 1 status: Tracking Disabled (NOT Out of Stock)
        expect(find.text('Tracking Disabled'), findsOneWidget);

        // Select Product 2 and verify Low Stock Threshold displays "Not configured"
        await tester.tap(find.text('Product 2').first);
        await tester.pumpAndSettle();
        expect(find.text('Not configured'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Table Header Tooltips render correctly with required copy',
      (tester) async {
        final productRepo = ProductRepository();
        final inventoryRepo = InventoryRepository();
        final locationRepo = LocationRepository();
        final categoryRepo = CategoryRepository();
        final supplierRepo = SupplierRepository();

        await pumpInventoryView(
          tester,
          productRepo: productRepo,
          inventoryRepo: inventoryRepo,
          locationRepo: locationRepo,
          categoryRepo: categoryRepo,
          supplierRepo: supplierRepo,
        );

        // Verify tooltips for all 7 required table headers:
        final variantsTooltip = tester.widget<Tooltip>(
          find.ancestor(
            of: find.text('Variants'),
            matching: find.byType(Tooltip),
          ).first,
        );
        expect(
          variantsTooltip.message,
          equals('Number of product variants such as size, color, or material.'),
        );

        final availableTooltip = tester.widget<Tooltip>(
          find.ancestor(
            of: find.text('Available'),
            matching: find.byType(Tooltip),
          ).first,
        );
        expect(
          availableTooltip.message,
          equals('Sellable units currently available at the selected location(s).'),
        );

        final committedTooltip = tester.widget<Tooltip>(
          find.ancestor(
            of: find.text('Committed'),
            matching: find.byType(Tooltip),
          ).first,
        );
        expect(
          committedTooltip.message,
          equals('Units reserved or allocated and not currently available for sale.'),
        );

        final incomingTooltip = tester.widget<Tooltip>(
          find.ancestor(
            of: find.text('Incoming'),
            matching: find.byType(Tooltip),
          ).first,
        );
        expect(
          incomingTooltip.message,
          equals('Units expected from open purchase orders or inbound transfers.'),
        );

        final sales30dTooltip = tester.widget<Tooltip>(
          find.ancestor(
            of: find.text('Sales 30D'),
            matching: find.byType(Tooltip),
          ).first,
        );
        expect(
          sales30dTooltip.message,
          equals('Units sold during the last 30 days.'),
        );

        final sellThroughTooltip = tester.widget<Tooltip>(
          find.ancestor(
            of: find.text('Sell-through %'),
            matching: find.byType(Tooltip),
          ).first,
        );
        expect(
          sellThroughTooltip.message,
          equals('Percentage of available inventory sold during the measured period.'),
        );

        final statusTooltip = tester.widget<Tooltip>(
          find.ancestor(
            of: find.text('Status'),
            matching: find.byType(Tooltip),
          ).first,
        );
        expect(
          statusTooltip.message,
          equals('Inventory status based on stock tracking, available quantity, and low-stock threshold.'),
        );
      },
    );

    testWidgets(
      '8. KPI Card Tooltips explain style counts',
      (tester) async {
        final productRepo = ProductRepository();
        final inventoryRepo = InventoryRepository();
        final locationRepo = LocationRepository();
        final categoryRepo = CategoryRepository();
        final supplierRepo = SupplierRepository();

        await pumpInventoryView(
          tester,
          productRepo: productRepo,
          inventoryRepo: inventoryRepo,
          locationRepo: locationRepo,
          categoryRepo: categoryRepo,
          supplierRepo: supplierRepo,
        );

        final inStockTooltip = tester.widget<Tooltip>(
          find.ancestor(
            of: find.text('In Stock'),
            matching: find.byType(Tooltip),
          ).first,
        );
        expect(
          inStockTooltip.message,
          contains('Number of stock-tracked styles with one or more sellable units.'),
        );

        final totalTooltip = tester.widget<Tooltip>(
          find.ancestor(
            of: find.text('Total Styles'),
            matching: find.byType(Tooltip),
          ).first,
        );
        expect(
          totalTooltip.message,
          contains('Total Styles'),
        );
      },
    );

    testWidgets(
      '4. Real-time refresh via InventoryChangeNotifier updates view without delay',
      (tester) async {
        final productRepo = ProductRepository();
        final inventoryRepo = InventoryRepository();
        final locationRepo = LocationRepository();
        final categoryRepo = CategoryRepository();
        final supplierRepo = SupplierRepository();

        await pumpInventoryView(
          tester,
          productRepo: productRepo,
          inventoryRepo: inventoryRepo,
          locationRepo: locationRepo,
          categoryRepo: categoryRepo,
          supplierRepo: supplierRepo,
        );

        expect(find.text('No products found'), findsOneWidget);

        // Add a product in the background
        await productRepo.publishProduct(
          productId: 'prod_dynamic',
          businessId: 'test_biz',
          name: 'Dynamic Added Product',
          brandId: 'brand_1',
          categoryId: 'cat_1',
          supplierId: 'sup_1',
          taxCategory: 'Standard',
          costPriceCents: 1000,
          retailPriceCents: 2000,
          sku: 'SKU-DYN',
          trackStockLevels: true,
          locationId: 'loc_1',
          openingStock: 50,
          lowStockThreshold: 10,
        );

        // Notify inventory change
        InventoryChangeNotifier.instance.notifyInventoryChanged();
        await tester.pumpAndSettle();

        // Verify UI immediately updated with new product and In Stock status
        expect(find.text('Dynamic Added Product'), findsOneWidget);
        expect(find.text('50 units available'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Location dropdown recalculates stock per location and All Locations aggregates',
      (tester) async {
        final productRepo = ProductRepository();
        final inventoryRepo = InventoryRepository();
        final locationRepo = LocationRepository();
        final categoryRepo = CategoryRepository();
        final supplierRepo = SupplierRepository();

        // Seed 2 locations
        final loc1 = await locationRepo.createLocation(
          name: 'Warehouse A',
          businessId: 'test_biz',
        );
        final loc2 = await locationRepo.createLocation(
          name: 'Store Front',
          businessId: 'test_biz',
        );

        await productRepo.publishProduct(
          productId: 'prod_loc_test',
          businessId: 'test_biz',
          name: 'Location Test Product',
          brandId: 'brand_1',
          categoryId: 'cat_1',
          supplierId: 'sup_1',
          taxCategory: 'Standard',
          costPriceCents: 1000,
          retailPriceCents: 2000,
          sku: 'SKU-LOC-1',
          trackStockLevels: true,
          locationId: loc1.id,
          openingStock: 60,
          lowStockThreshold: 10,
        );

        // Add 40 stock at loc_2
        ProductRepository.setFallbackInventory('prod_loc_test_${loc2.id}', 40);

        await pumpInventoryView(
          tester,
          productRepo: productRepo,
          inventoryRepo: inventoryRepo,
          locationRepo: locationRepo,
          categoryRepo: categoryRepo,
          supplierRepo: supplierRepo,
        );

        // All Locations: 60 + 40 = 100 units
        expect(find.text('100 units available'), findsOneWidget);

        // Switch to Warehouse A
        await tester.tap(find.text('All Locations'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Warehouse A').last);
        await tester.pumpAndSettle();

        // Warehouse A should show 60 units
        expect(find.text('60 units available'), findsOneWidget);

        // Switch to Store Front
        await tester.tap(find.text('Warehouse A'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Store Front').last);
        await tester.pumpAndSettle();

        // Store Front should show 40 units
        expect(find.text('40 units available'), findsOneWidget);
      },
    );
  });
}
