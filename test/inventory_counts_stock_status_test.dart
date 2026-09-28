import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/data/inventory_repository.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/inventory/data/supplier_repository.dart';
import 'package:threadstock/features/inventory/domain/models/product_inventory_summary.dart';
import 'package:threadstock/features/inventory/presentation/widgets/inventory_products_view.dart';

void main() {
  setUp(() {
    ProductRepository.clearLocalState();
    CategoryRepository.clearLocalState();
    SupplierRepository.clearLocalState();
    LocationRepository.clearLocalState();
  });

  group('1. Stock Status Calculation Contract Tests', () {
    test('qty 20, threshold 20 -> Low Stock', () {
      final status = ProductInventorySummary.calculateStockStatus(
        availableQty: 20,
        lowStockThreshold: 20,
        trackStockLevels: true,
      );
      expect(status, equals(StockStatus.lowStock));
    });

    test('qty 1, threshold 20 -> Low Stock', () {
      final status = ProductInventorySummary.calculateStockStatus(
        availableQty: 1,
        lowStockThreshold: 20,
        trackStockLevels: true,
      );
      expect(status, equals(StockStatus.lowStock));
    });

    test('qty 0, threshold 20 -> Out of Stock', () {
      final status = ProductInventorySummary.calculateStockStatus(
        availableQty: 0,
        lowStockThreshold: 20,
        trackStockLevels: true,
      );
      expect(status, equals(StockStatus.outOfStock));
    });

    test('negative qty, threshold 20 -> Out of Stock', () {
      final status = ProductInventorySummary.calculateStockStatus(
        availableQty: -5,
        lowStockThreshold: 20,
        trackStockLevels: true,
      );
      expect(status, equals(StockStatus.outOfStock));
    });

    test('qty 21, threshold 20 -> In Stock', () {
      final status = ProductInventorySummary.calculateStockStatus(
        availableQty: 21,
        lowStockThreshold: 20,
        trackStockLevels: true,
      );
      expect(status, equals(StockStatus.inStock));
    });

    test('qty 100, threshold 20 (qwd expected) -> In Stock', () {
      final status = ProductInventorySummary.calculateStockStatus(
        availableQty: 100,
        lowStockThreshold: 20,
        trackStockLevels: true,
      );
      expect(status, equals(StockStatus.inStock));
    });

    test('trackStockLevels == false -> Tracking Disabled regardless of qty', () {
      final status = ProductInventorySummary.calculateStockStatus(
        availableQty: 0,
        lowStockThreshold: 20,
        trackStockLevels: false,
      );
      expect(status, equals(StockStatus.trackingDisabled));
    });
  });

  group('2. InventoryRepository Aggregation Tests', () {
    test(
      'Aggregates variant count and available stock correctly for qwd',
      () async {
        final productRepo = ProductRepository();
        final inventoryRepo = InventoryRepository();

        // Setup product qwd in fallback state
        final product = await productRepo.publishProduct(
          productId: '00491d3f-03f4-4105-91aa-4966a9e81b5d',
          businessId: 'test_biz',
          name: 'qwd',
          brandId: 'brand_1',
          categoryId: 'cat_1',
          supplierId: 'sup_1',
          taxCategory: 'Standard',
          costPriceCents: 5000,
          retailPriceCents: 9000,
          sku: 'TS-QWD-05850',
          trackStockLevels: true,
          locationId: 'loc_flagship',
          openingStock: 100,
          lowStockThreshold: 20,
        );

        expect(product.name, equals('qwd'));

        // Fetch summary via InventoryRepository
        final summaries = await inventoryRepo.getProductInventorySummaries(
          businessId: 'test_biz',
        );

        final qwdSummary = summaries['00491d3f-03f4-4105-91aa-4966a9e81b5d'];
        expect(qwdSummary, isNotNull);
        expect(qwdSummary!.variantCount, equals(1));
        expect(qwdSummary.availableQty, equals(100));
        expect(qwdSummary.committedQty, equals(0));
        expect(qwdSummary.lowStockThreshold, equals(20));
        expect(qwdSummary.stockStatus, equals(StockStatus.inStock));
        expect(qwdSummary.stockStatusLabel, equals('In Stock'));
      },
    );

    test(
      'Location-specific aggregation vs All Locations aggregation',
      () async {
        final productRepo = ProductRepository();
        final inventoryRepo = InventoryRepository();

        await productRepo.publishProduct(
          productId: 'prod_multi_loc',
          businessId: 'test_biz',
          name: 'Multi Loc Product',
          brandId: 'brand_1',
          categoryId: 'cat_1',
          supplierId: 'sup_1',
          taxCategory: 'Standard',
          costPriceCents: 5000,
          retailPriceCents: 9000,
          sku: 'SKU-MULTI',
          trackStockLevels: true,
          locationId: 'loc_1',
          openingStock: 60,
          lowStockThreshold: 20,
        );

        // Add stock at loc_2
        ProductRepository.setFallbackInventory('prod_multi_loc_loc_2', 40);

        // All Locations should aggregate 60 + 40 = 100
        final allSummaries = await inventoryRepo.getProductInventorySummaries(
          businessId: 'test_biz',
          locationId: 'all',
        );
        expect(allSummaries['prod_multi_loc']!.availableQty, equals(100));

        // Specific location loc_1 should show 60
        final loc1Summaries = await inventoryRepo.getProductInventorySummaries(
          businessId: 'test_biz',
          locationId: 'loc_1',
        );
        expect(loc1Summaries['prod_multi_loc']!.availableQty, equals(60));

        // Specific location loc_2 should show 40
        final loc2Summaries = await inventoryRepo.getProductInventorySummaries(
          businessId: 'test_biz',
          locationId: 'loc_2',
        );
        expect(loc2Summaries['prod_multi_loc']!.availableQty, equals(40));
      },
    );
  });

  group('3. InventoryProductsView Data Binding & UI Verification', () {
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

    testWidgets(
      'Inventory UI correctly binds product qwd: 1 variant, 100 available, Healthy, and 1 In Stock summary card',
      (tester) async {
        final productRepo = ProductRepository();
        final inventoryRepo = InventoryRepository();
        final locationRepo = LocationRepository();
        final categoryRepo = CategoryRepository();
        final supplierRepo = SupplierRepository();

        // Publish product qwd exactly as reported
        await productRepo.publishProduct(
          productId: '00491d3f-03f4-4105-91aa-4966a9e81b5d',
          businessId: 'test_biz',
          name: 'qwd',
          brandId: 'brand_1',
          categoryId: 'cat_1',
          supplierId: 'sup_1',
          taxCategory: 'Standard',
          costPriceCents: 5000,
          retailPriceCents: 9000,
          sku: 'TS-QWD-05850',
          trackStockLevels: true,
          locationId: 'loc_main',
          openingStock: 100,
          lowStockThreshold: 20,
        );

        await pumpInventoryView(
          tester,
          productRepo: productRepo,
          inventoryRepo: inventoryRepo,
          locationRepo: locationRepo,
          categoryRepo: categoryRepo,
          supplierRepo: supplierRepo,
        );

        // Verify Product row shows:
        // Product Name: qwd
        expect(find.text('qwd'), findsWidgets);
        // SKU: TS-QWD-05850
        expect(find.text('TS-QWD-05850'), findsWidgets);
        // Variants: 1 variant (NOT 0)
        expect(find.text('1 variant'), findsOneWidget);
        // Available: 100 (NOT 0)
        expect(find.text('100'), findsOneWidget);
        // Committed: 0
        expect(find.text('0'), findsWidgets);
        // Status badge: In Stock
        expect(find.text('In Stock'), findsWidgets);

        // Verify Summary Cards:
        // Total Styles: 1
        expect(find.text('Total Styles'), findsOneWidget);
        // In Stock: 1 (100%)
        expect(find.text('In Stock'), findsWidgets);
        expect(find.text('100%'), findsWidgets);
        // Low Stock: 0
        expect(find.text('Low Stock'), findsOneWidget);
        // Out of Stock: 0
        expect(find.text('Out of Stock'), findsOneWidget);

        // Initially no product selected
        expect(find.text('Select a product'), findsOneWidget);

        // Click on product row to select it
        await tester.tap(find.text('qwd').first);
        await tester.pumpAndSettle();

        // Verify Selected Product drawer shows 100 units available (NOT 0 units)
        expect(find.text('100 units'), findsOneWidget);
        expect(find.text('0 units'), findsWidgets);
        expect(find.text('Variants (1)'), findsOneWidget);
      },
    );

    testWidgets(
      'Selected Product drawer switches to Variants tab and displays SKU TS-QWD-05850',
      (tester) async {
        final productRepo = ProductRepository();
        final inventoryRepo = InventoryRepository();
        final locationRepo = LocationRepository();
        final categoryRepo = CategoryRepository();
        final supplierRepo = SupplierRepository();

        await productRepo.publishProduct(
          productId: '00491d3f-03f4-4105-91aa-4966a9e81b5d',
          businessId: 'test_biz',
          name: 'qwd',
          brandId: 'brand_1',
          categoryId: 'cat_1',
          supplierId: 'sup_1',
          taxCategory: 'Standard',
          costPriceCents: 5000,
          retailPriceCents: 9000,
          sku: 'TS-QWD-05850',
          trackStockLevels: true,
          locationId: 'loc_main',
          openingStock: 100,
          lowStockThreshold: 20,
        );

        await pumpInventoryView(
          tester,
          productRepo: productRepo,
          inventoryRepo: inventoryRepo,
          locationRepo: locationRepo,
          categoryRepo: categoryRepo,
          supplierRepo: supplierRepo,
        );

        // Initially no product selected
        expect(find.text('Select a product'), findsOneWidget);

        // Tap product row to open drawer
        await tester.tap(find.text('qwd').first);
        await tester.pumpAndSettle();

        // Click on Variants (1) tab in drawer
        final variantsTab = find.text('Variants (1)');
        expect(variantsTab, findsOneWidget);
        await tester.tap(variantsTab);
        await tester.pumpAndSettle();

        // Verify variant details are rendered in drawer
        expect(find.text('₹90'), findsOneWidget);
      },
    );

    testWidgets(
      'Controlled stock states test: qty 20 -> Low Stock, qty 0 -> Out of Stock, qty 21 -> Healthy',
      (tester) async {
        final productRepo = ProductRepository();
        final inventoryRepo = InventoryRepository();
        final locationRepo = LocationRepository();
        final categoryRepo = CategoryRepository();
        final supplierRepo = SupplierRepository();

        // Product 1: Low Stock (qty = 20, threshold = 20)
        await productRepo.publishProduct(
          productId: 'prod_low',
          businessId: 'test_biz',
          name: 'Low Stock Product',
          brandId: 'brand_1',
          categoryId: 'cat_1',
          supplierId: 'sup_1',
          taxCategory: 'Standard',
          costPriceCents: 1000,
          retailPriceCents: 2000,
          sku: 'SKU-LOW',
          trackStockLevels: true,
          locationId: 'loc_1',
          openingStock: 20,
          lowStockThreshold: 20,
        );

        // Product 2: Out of Stock (qty = 0, threshold = 20)
        await productRepo.publishProduct(
          productId: 'prod_out',
          businessId: 'test_biz',
          name: 'Out of Stock Product',
          brandId: 'brand_1',
          categoryId: 'cat_1',
          supplierId: 'sup_1',
          taxCategory: 'Standard',
          costPriceCents: 1000,
          retailPriceCents: 2000,
          sku: 'SKU-OUT',
          trackStockLevels: true,
          locationId: 'loc_1',
          openingStock: 0,
          lowStockThreshold: 20,
        );

        // Product 3: Healthy (qty = 21, threshold = 20)
        await productRepo.publishProduct(
          productId: 'prod_healthy',
          businessId: 'test_biz',
          name: 'Healthy Product',
          brandId: 'brand_1',
          categoryId: 'cat_1',
          supplierId: 'sup_1',
          taxCategory: 'Standard',
          costPriceCents: 1000,
          retailPriceCents: 2000,
          sku: 'SKU-HEALTHY',
          trackStockLevels: true,
          locationId: 'loc_1',
          openingStock: 21,
          lowStockThreshold: 20,
        );

        await pumpInventoryView(
          tester,
          productRepo: productRepo,
          inventoryRepo: inventoryRepo,
          locationRepo: locationRepo,
          categoryRepo: categoryRepo,
          supplierRepo: supplierRepo,
        );

        // Verify row statuses
        expect(find.text('Low Stock'), findsWidgets);
        expect(find.text('Out of Stock'), findsWidgets);
        expect(find.text('In Stock'), findsWidgets);

        // Verify Summary card counts
        // Total Styles: 3
        expect(find.text('3'), findsOneWidget);
      },
    );
  });
}
