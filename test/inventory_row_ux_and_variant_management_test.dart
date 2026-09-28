import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/auth/authorization_service.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/data/inventory_repository.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/inventory/data/supplier_repository.dart';
import 'package:threadstock/features/inventory/presentation/widgets/inventory_products_view.dart';
import 'package:threadstock/features/inventory/presentation/widgets/product_details_view.dart';

void main() {
  setUp(() {
    ProductRepository.clearLocalState();
    CategoryRepository.clearLocalState();
    SupplierRepository.clearLocalState();
    LocationRepository.clearLocalState();
    AuthorizationService.instance.clear();
    AuthorizationService.instance.setPermissionsForTesting(isOwner: true);
  });

  Future<void> pumpInventoryView(
    WidgetTester tester, {
    required ProductRepository productRepo,
    required InventoryRepository inventoryRepo,
    required LocationRepository locationRepo,
    required CategoryRepository categoryRepo,
    required SupplierRepository supplierRepo,
    String businessId = 'test_biz',
  }) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InventoryProductsView(
            businessId: businessId,
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

  group('THREADSTOCK PRODUCT LIST & VARIANT UX TESTS', () {
    testWidgets('1. Inventory initial load → no product selected', (tester) async {
      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final locationRepo = LocationRepository();
      final categoryRepo = CategoryRepository();
      final supplierRepo = SupplierRepository();

      await productRepo.publishProduct(
        productId: 'prod_1',
        businessId: 'test_biz',
        name: 'Oxford Cotton Shirt',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1200,
        retailPriceCents: 2500,
        sku: 'TS-OCS-00001',
        trackStockLevels: true,
        locationId: 'loc_1',
        openingStock: 50,
      );

      await productRepo.publishProduct(
        productId: 'prod_2',
        businessId: 'test_biz',
        name: 'Linen Casual Trouser',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1800,
        retailPriceCents: 3500,
        sku: 'TS-LCT-00002',
        trackStockLevels: true,
        locationId: 'loc_1',
        openingStock: 25,
      );

      await pumpInventoryView(
        tester,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        locationRepo: locationRepo,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
      );

      // Verify that no product is auto-selected and the elegant empty preview is shown
      expect(find.text('Select a product'), findsOneWidget);
      expect(
        find.text('Choose a product to view inventory, variants and activity.'),
        findsOneWidget,
      );
      // Product 2 should NOT be auto-selected
      expect(find.text('Selected Product'), findsNothing);
    });

    testWidgets('2. mouse enter/leave product row → subtle warm ivory tint, no movement, stable table', (tester) async {
      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final locationRepo = LocationRepository();
      final categoryRepo = CategoryRepository();
      final supplierRepo = SupplierRepository();

      await productRepo.publishProduct(
        productId: 'prod_1',
        businessId: 'test_biz',
        name: 'Oxford Cotton Shirt',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1200,
        retailPriceCents: 2500,
        sku: 'TS-OCS-00001',
        trackStockLevels: true,
      );

      await pumpInventoryView(
        tester,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        locationRepo: locationRepo,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
      );

      final rowFinder = find.text('Oxford Cotton Shirt');
      expect(rowFinder, findsOneWidget);
      final initialRect = tester.getRect(rowFinder);

      // Verify AnimatedContainer is used with short ~140ms duration for color/border only
      final animatedContainerFinder = find.ancestor(
        of: rowFinder,
        matching: find.byType(AnimatedContainer),
      );
      expect(animatedContainerFinder, findsWidgets);
      final animatedContainer = tester.widget<AnimatedContainer>(animatedContainerFinder.first);
      expect(animatedContainer.duration, const Duration(milliseconds: 140));

      // Verify no transform, scale, or translation on the row container
      expect(animatedContainer.transform, isNull);
      expect(find.byType(AnimatedScale), findsNothing);

      // Find the row's MouseRegion and verify cursor is pointer (SystemMouseCursors.click)
      final mouseRegionFinder = find.ancestor(
        of: rowFinder,
        matching: find.byType(MouseRegion),
      );
      expect(mouseRegionFinder, findsWidgets);
      final rowMouseRegion = tester.widget<MouseRegion>(mouseRegionFinder.first);
      expect(rowMouseRegion.cursor, SystemMouseCursors.click);

      // Initial state: row background is transparent (no hover, not selected)
      final initialDecoration = animatedContainer.decoration as BoxDecoration?;
      expect(initialDecoration?.color, Colors.transparent);
      expect(initialDecoration?.boxShadow, isNull);

      // 1. Mouse enter / hover over the product row using a pointer gesture
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      await gesture.moveTo(tester.getCenter(rowFinder));
      await tester.pumpAndSettle();

      // Verify row position remains perfectly unchanged on hover (no translateY/translateX/scale)
      final hoveredRect = tester.getRect(rowFinder);
      expect(hoveredRect, initialRect, reason: 'Row position must remain unchanged on mouse enter');

      final hoveredRowContainer = tester.widget<AnimatedContainer>(animatedContainerFinder.first);
      final hoveredDecoration = hoveredRowContainer.decoration as BoxDecoration?;
      expect(
        hoveredDecoration?.color,
        const Color(0xFFFAF7F2),
        reason: 'Hover color must be subtle warm ivory / champagne tint',
      );
      expect(hoveredDecoration?.boxShadow, isNull, reason: 'Row shadow must not appear on mouse enter');

      // 2. Mouse leave / roll-out
      await gesture.moveTo(Offset.zero);
      await tester.pumpAndSettle();

      final leaveRect = tester.getRect(rowFinder);
      expect(leaveRect, initialRect, reason: 'Row position must remain unchanged on mouse leave');

      final leaveRowContainer = tester.widget<AnimatedContainer>(animatedContainerFinder.first);
      final leaveDecoration = leaveRowContainer.decoration as BoxDecoration?;
      expect(leaveDecoration?.color, Colors.transparent, reason: 'Row color must return to transparent on mouse leave');
      expect(leaveDecoration?.boxShadow, isNull, reason: 'Row shadow must remain null on mouse leave');

      // 3. Selected styling applies ONLY after user actually clicks the row
      await tester.tap(rowFinder);
      await tester.pumpAndSettle();

      final selectedRowContainer = tester.widget<AnimatedContainer>(animatedContainerFinder.first);
      final selectedDecoration = selectedRowContainer.decoration as BoxDecoration?;
      expect(
        selectedDecoration?.color,
        const Color(0xFFF5EFE5),
        reason: 'Selected color must be slightly stronger warm ivory tint',
      );
    });

    testWidgets('3. click row → Selected Product panel loads', (tester) async {
      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final locationRepo = LocationRepository();
      final categoryRepo = CategoryRepository();
      final supplierRepo = SupplierRepository();

      await productRepo.publishProduct(
        productId: 'prod_1',
        businessId: 'test_biz',
        name: 'Oxford Cotton Shirt',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1200,
        retailPriceCents: 2500,
        sku: 'TS-OCS-00001',
        trackStockLevels: true,
        locationId: 'loc_1',
        openingStock: 42,
      );

      await pumpInventoryView(
        tester,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        locationRepo: locationRepo,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
      );

      // Empty preview initially
      expect(find.text('Select a product'), findsOneWidget);

      // Click the product row
      await tester.tap(find.text('Oxford Cotton Shirt'));
      await tester.pumpAndSettle();

      // Preview panel is now loaded for Oxford Cotton Shirt
      expect(find.text('Selected Product'), findsOneWidget);
      expect(find.text('42 units'), findsOneWidget);
      expect(find.text('Select a product'), findsNothing);
    });

    testWidgets('4. checkbox only → does not unexpectedly open preview', (tester) async {
      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final locationRepo = LocationRepository();
      final categoryRepo = CategoryRepository();
      final supplierRepo = SupplierRepository();

      await productRepo.publishProduct(
        productId: 'prod_1',
        businessId: 'test_biz',
        name: 'Oxford Cotton Shirt',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1200,
        retailPriceCents: 2500,
        sku: 'TS-OCS-00001',
        trackStockLevels: true,
      );

      await pumpInventoryView(
        tester,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        locationRepo: locationRepo,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
      );

      // Preview is initially empty
      expect(find.text('Select a product'), findsOneWidget);

      // Click the checkbox icon
      final checkboxFinder = find.byIcon(Icons.check_box_outline_blank).at(1);
      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Checkbox is now checked
      expect(find.byIcon(Icons.check_box_rounded), findsOneWidget);

      // PREVIEW MUST STILL BE EMPTY: Checkbox does not drive the preview!
      expect(find.text('Select a product'), findsOneWidget);
      expect(find.text('Selected Product'), findsNothing);
    });

    testWidgets('5. ⋮ → menu opens with contextual actions', (tester) async {
      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final locationRepo = LocationRepository();
      final categoryRepo = CategoryRepository();
      final supplierRepo = SupplierRepository();

      await productRepo.publishProduct(
        productId: 'prod_1',
        businessId: 'test_biz',
        name: 'Oxford Cotton Shirt',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1200,
        retailPriceCents: 2500,
        sku: 'TS-OCS-00001',
        trackStockLevels: true,
      );

      await pumpInventoryView(
        tester,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        locationRepo: locationRepo,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
      );

      // Tap ⋮ button
      final moreButton = find.byType(PopupMenuButton<String>);
      expect(moreButton, findsOneWidget);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Verify all contextual product actions are displayed
      expect(find.text('View Details'), findsOneWidget);
      expect(find.text('Edit Product'), findsOneWidget);
      expect(find.text('Add Variant'), findsOneWidget);
      expect(find.text('Adjust Stock'), findsWidgets);
      expect(find.text('Disable Tracking'), findsOneWidget);
      expect(find.text('Stock History'), findsOneWidget);
      expect(find.text('Archive Product'), findsOneWidget);
    });

    testWidgets('6. Add Variant → form opens', (tester) async {
      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final locationRepo = LocationRepository();
      final categoryRepo = CategoryRepository();
      final supplierRepo = SupplierRepository();

      await productRepo.publishProduct(
        productId: 'prod_1',
        businessId: 'test_biz',
        name: 'Oxford Cotton Shirt',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1200,
        retailPriceCents: 2500,
        sku: 'TS-OCS-00001',
        trackStockLevels: true,
      );

      await pumpInventoryView(
        tester,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        locationRepo: locationRepo,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
      );

      // Open ⋮ menu and select Add Variant
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Variant'));
      await tester.pumpAndSettle();

      // Verify Add Product Variant dialog is open with fields
      expect(find.text('Add Product Variant'), findsOneWidget);
      expect(find.text('System SKU *'), findsOneWidget);
      expect(find.text('Color'), findsOneWidget);
      expect(find.text('Size'), findsOneWidget);
      expect(find.text('Material'), findsOneWidget);
      expect(find.text('Unit Cost (₹)'), findsOneWidget);
      expect(find.text('Selling Price (₹) *'), findsOneWidget);
      expect(find.text('Opening Stock'), findsOneWidget);
    });

    testWidgets('7 & 8. create second variant → persists & Product Details → Variants (2)', (tester) async {
      final productRepo = ProductRepository();
      final locationRepo = LocationRepository();

      final p = await productRepo.publishProduct(
        productId: 'prod_var_test',
        businessId: 'test_biz',
        name: 'Silk Blend Kurta',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 2000,
        retailPriceCents: 4500,
        sku: 'TS-SBK-00001',
        trackStockLevels: true,
        locationId: 'loc_main',
        openingStock: 10,
      );

      // Initial details check: 1 variant
      final initialDetails = await productRepo.getProductDetails(p.id);
      final initialVariants = initialDetails!['variants'] as List;
      expect(initialVariants.length, equals(1));

      // Create a second variant using repository
      final v2 = await productRepo.createVariant(
        productId: p.id,
        businessId: 'test_biz',
        sku: 'TS-SBK-00002',
        barcode: '8901234567890',
        color: 'Emerald Green',
        size: 'XL',
        material: 'Raw Silk',
        costPriceCents: 2200,
        retailPriceCents: 4800,
        status: 'active',
        initialStock: 15,
        locationId: 'loc_main',
      );

      expect(v2.sku, equals('TS-SBK-00002'));

      // Check details after adding variant: Variants (2) and stock sum = 10 + 15 = 25
      final updatedDetails = await productRepo.getProductDetails(p.id);
      final updatedVariants = updatedDetails!['variants'] as List;
      final totalStock = updatedDetails['totalStock'] as int;

      expect(updatedVariants.length, equals(2));
      expect(totalStock, equals(25));

      // Verify UI rendering in ProductDetailsView
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProductDetailsView(
              productId: p.id,
              businessId: 'test_biz',
              productRepository: productRepo,
              locationRepository: locationRepo,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Product Details has dynamic tab "Variants (2)"
      expect(find.text('Variants (2)'), findsOneWidget);

      // Tap Variants (2) tab
      await tester.tap(find.text('Variants (2)'));
      await tester.pumpAndSettle();

      // Table displays both variants with SKU and attributes
      expect(find.text('TS-SBK-00001'), findsOneWidget);
      expect(find.text('TS-SBK-00002'), findsOneWidget);
      expect(find.text('Emerald Green'), findsOneWidget);
      expect(find.text('XL'), findsOneWidget);
      expect(find.text('Raw Silk'), findsOneWidget);
      expect(find.text('+ Add Variant'), findsOneWidget);
    });

    test('9. app restart → still 2 variants', () async {
      final productRepo = ProductRepository();

      final p = await productRepo.publishProduct(
        productId: 'prod_restart_test',
        businessId: 'test_biz',
        name: 'Denim Jacket',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 3000,
        retailPriceCents: 6000,
        sku: 'TS-DJ-00001',
        trackStockLevels: true,
      );

      await productRepo.createVariant(
        productId: p.id,
        businessId: 'test_biz',
        sku: 'TS-DJ-00002',
        color: 'Washed Black',
        size: 'L',
        costPriceCents: 3200,
        retailPriceCents: 6500,
      );

      // Simulate app restart by querying fresh repository instance
      final freshRepo = ProductRepository();
      final details = await freshRepo.getProductDetails(p.id);
      final variants = details!['variants'] as List;

      expect(variants.length, equals(2));
      expect(variants[0].sku, equals('TS-DJ-00001'));
      expect(variants[1].sku, equals('TS-DJ-00002'));
    });

    test('10. cross-business product → cannot receive variant', () async {
      final productRepo = ProductRepository();

      final prodBusinessA = await productRepo.publishProduct(
        productId: 'prod_biz_a',
        businessId: 'business_aaa',
        name: 'Business A Product',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1000,
        retailPriceCents: 2000,
        sku: 'TS-BA-00001',
        trackStockLevels: true,
      );

      // Attempt to attach a variant to Business A's product using Business B's context
      expect(
        () async => await productRepo.createVariant(
          productId: prodBusinessA.id,
          businessId: 'business_bbb',
          sku: 'TS-BA-00002',
          costPriceCents: 1000,
          retailPriceCents: 2000,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Cross-business violation'),
        )),
      );
    });

    test('11. Owner → can add/edit variants', () async {
      final productRepo = ProductRepository();
      AuthorizationService.instance.setPermissionsForTesting(isOwner: true);

      final p = await productRepo.publishProduct(
        productId: 'prod_owner_test',
        businessId: 'test_biz',
        name: 'Owner Managed Product',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1000,
        retailPriceCents: 2000,
        sku: 'TS-OMP-00001',
      );

      final v = await productRepo.createVariant(
        productId: p.id,
        businessId: 'test_biz',
        sku: 'TS-OMP-00002',
        costPriceCents: 1100,
        retailPriceCents: 2200,
      );

      expect(v.sku, equals('TS-OMP-00002'));
    });

    test('12. user without inventory.manage → cannot mutate variants', () async {
      final productRepo = ProductRepository();

      final p = await productRepo.publishProduct(
        productId: 'prod_rbac_test',
        businessId: 'test_biz',
        name: 'RBAC Protected Product',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1000,
        retailPriceCents: 2000,
        sku: 'TS-RPP-00001',
      );

      // Set user to read-only inventory permission (no inventory.manage)
      AuthorizationService.instance.setPermissionsForTesting(
        isOwner: false,
        permissions: {'inventory.view'},
      );

      expect(
        () async => await productRepo.createVariant(
          productId: p.id,
          businessId: 'test_biz',
          sku: 'TS-RPP-00002',
          costPriceCents: 1100,
          retailPriceCents: 2200,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('inventory.manage required'),
        )),
      );
    });
  });
}
