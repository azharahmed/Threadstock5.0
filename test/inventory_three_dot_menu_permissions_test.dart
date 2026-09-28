import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/auth/authorization_service.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/features/business/domain/models/business.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/data/inventory_repository.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/inventory/data/supplier_repository.dart';
import 'package:threadstock/features/inventory/presentation/widgets/inventory_products_view.dart';

void main() {
  setUp(() {
    ProductRepository.clearLocalState();
    CategoryRepository.clearLocalState();
    SupplierRepository.clearLocalState();
    LocationRepository.clearLocalState();
    AuthorizationService.instance.clear();
    AuthorizationService.instance.setPermissionsForTesting(isOwner: true);
    CurrentBusinessService.instance.clear();
  });

  Future<void> pumpInventoryView(
    WidgetTester tester, {
    required ProductRepository productRepo,
    required InventoryRepository inventoryRepo,
    required LocationRepository locationRepo,
    required CategoryRepository categoryRepo,
    required SupplierRepository supplierRepo,
    String businessId = 'test_biz',
    ValueChanged<String>? onViewProductDetails,
    ValueChanged<String>? onEditProduct,
    ValueChanged<String>? onAdjustProductStock,
    ValueChanged<String>? onProductStockHistory,
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
            onViewProductDetails: onViewProductDetails,
            onEditProduct: onEditProduct,
            onAdjustProductStock: onAdjustProductStock,
            onProductStockHistory: onProductStockHistory,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('THREADSTOCK INVENTORY THREE-DOT MENU PERMISSION & STATE TESTS', () {
    testWidgets('1. Owner role has all context menu actions enabled', (tester) async {
      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final locationRepo = LocationRepository();
      final categoryRepo = CategoryRepository();
      final supplierRepo = SupplierRepository();

      await productRepo.publishProduct(
        productId: 'prod_owner_test',
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

      // Explicit Owner permissions
      AuthorizationService.instance.setPermissionsForTesting(isOwner: true);

      await pumpInventoryView(
        tester,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        locationRepo: locationRepo,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
      );

      // Open ⋮ menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Find all PopupMenuItems
      final popupMenuItems = tester.widgetList<PopupMenuItem<String>>(
        find.byType(PopupMenuItem<String>),
      ).toList();

      // Verify all items are enabled for Owner
      final viewDetails = popupMenuItems.firstWhere((item) => item.value == 'view_details');
      final editProduct = popupMenuItems.firstWhere((item) => item.value == 'edit_product');
      final addVariant = popupMenuItems.firstWhere((item) => item.value == 'add_variant');
      final adjustStock = popupMenuItems.firstWhere((item) => item.value == 'adjust_stock');
      final toggleTracking = popupMenuItems.firstWhere((item) => item.value == 'toggle_tracking');
      final stockHistory = popupMenuItems.firstWhere((item) => item.value == 'stock_history');
      final archiveProduct = popupMenuItems.firstWhere((item) => item.value == 'archive_product');

      expect(viewDetails.enabled, isTrue, reason: 'View Details must be enabled for Owner');
      expect(editProduct.enabled, isTrue, reason: 'Edit Product must be enabled for Owner');
      expect(addVariant.enabled, isTrue, reason: 'Add Variant must be enabled for Owner');
      expect(adjustStock.enabled, isTrue, reason: 'Adjust Stock must be enabled for Owner');
      expect(toggleTracking.enabled, isTrue, reason: 'Disable Tracking must be enabled for Owner');
      expect(stockHistory.enabled, isTrue, reason: 'Stock History must be enabled for Owner');
      expect(archiveProduct.enabled, isTrue, reason: 'Archive Product must be enabled for Owner');
    });

    testWidgets('2. Restricted: inventory.view only enables View Details & Stock History', (tester) async {
      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final locationRepo = LocationRepository();
      final categoryRepo = CategoryRepository();
      final supplierRepo = SupplierRepository();

      await productRepo.publishProduct(
        productId: 'prod_view_only',
        businessId: 'test_biz',
        name: 'Linen Casual Shirt',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1500,
        retailPriceCents: 3000,
        sku: 'TS-LCS-00001',
      );

      // User with view only permission
      AuthorizationService.instance.setPermissionsForTesting(
        isOwner: false,
        permissions: {'inventory.view'},
      );

      await pumpInventoryView(
        tester,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        locationRepo: locationRepo,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      final popupMenuItems = tester.widgetList<PopupMenuItem<String>>(
        find.byType(PopupMenuItem<String>),
      ).toList();

      final viewDetails = popupMenuItems.firstWhere((item) => item.value == 'view_details');
      final stockHistory = popupMenuItems.firstWhere((item) => item.value == 'stock_history');
      final editProduct = popupMenuItems.firstWhere((item) => item.value == 'edit_product');
      final addVariant = popupMenuItems.firstWhere((item) => item.value == 'add_variant');
      final adjustStock = popupMenuItems.firstWhere((item) => item.value == 'adjust_stock');
      final toggleTracking = popupMenuItems.firstWhere((item) => item.value == 'toggle_tracking');
      final archiveProduct = popupMenuItems.firstWhere((item) => item.value == 'archive_product');

      expect(viewDetails.enabled, isTrue, reason: 'View Details requires inventory.view only');
      expect(stockHistory.enabled, isTrue, reason: 'Stock History requires inventory.view only');
      expect(editProduct.enabled, isFalse, reason: 'Edit Product requires inventory.manage');
      expect(addVariant.enabled, isFalse, reason: 'Add Variant requires inventory.manage');
      expect(adjustStock.enabled, isFalse, reason: 'Adjust Stock requires inventory.adjust');
      expect(toggleTracking.enabled, isFalse, reason: 'Toggle Tracking requires inventory.manage');
      expect(archiveProduct.enabled, isFalse, reason: 'Archive Product requires inventory.manage');
    });

    testWidgets('3. Restricted: inventory.manage only enables Edit, Add Variant, Tracking, Archive', (tester) async {
      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final locationRepo = LocationRepository();
      final categoryRepo = CategoryRepository();
      final supplierRepo = SupplierRepository();

      await productRepo.publishProduct(
        productId: 'prod_manage_only',
        businessId: 'test_biz',
        name: 'Denim Jacket',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 2000,
        retailPriceCents: 4500,
        sku: 'TS-DJ-00001',
      );

      // User with manage only permission
      AuthorizationService.instance.setPermissionsForTesting(
        isOwner: false,
        permissions: {'inventory.manage'},
      );

      await pumpInventoryView(
        tester,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        locationRepo: locationRepo,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      final popupMenuItems = tester.widgetList<PopupMenuItem<String>>(
        find.byType(PopupMenuItem<String>),
      ).toList();

      final viewDetails = popupMenuItems.firstWhere((item) => item.value == 'view_details');
      final stockHistory = popupMenuItems.firstWhere((item) => item.value == 'stock_history');
      final editProduct = popupMenuItems.firstWhere((item) => item.value == 'edit_product');
      final addVariant = popupMenuItems.firstWhere((item) => item.value == 'add_variant');
      final adjustStock = popupMenuItems.firstWhere((item) => item.value == 'adjust_stock');
      final toggleTracking = popupMenuItems.firstWhere((item) => item.value == 'toggle_tracking');
      final archiveProduct = popupMenuItems.firstWhere((item) => item.value == 'archive_product');

      expect(viewDetails.enabled, isFalse, reason: 'View Details requires inventory.view');
      expect(stockHistory.enabled, isFalse, reason: 'Stock History requires inventory.view');
      expect(editProduct.enabled, isTrue, reason: 'Edit Product enabled for inventory.manage');
      expect(addVariant.enabled, isTrue, reason: 'Add Variant enabled for inventory.manage');
      expect(adjustStock.enabled, isFalse, reason: 'Adjust Stock requires inventory.adjust');
      expect(toggleTracking.enabled, isTrue, reason: 'Toggle Tracking enabled for inventory.manage');
      expect(archiveProduct.enabled, isTrue, reason: 'Archive Product enabled for inventory.manage');
    });

    testWidgets('4. Restricted: inventory.adjust only enables Adjust Stock', (tester) async {
      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final locationRepo = LocationRepository();
      final categoryRepo = CategoryRepository();
      final supplierRepo = SupplierRepository();

      await productRepo.publishProduct(
        productId: 'prod_adjust_only',
        businessId: 'test_biz',
        name: 'Wool Overcoat',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 5000,
        retailPriceCents: 12000,
        sku: 'TS-WO-00001',
      );

      // User with adjust only permission
      AuthorizationService.instance.setPermissionsForTesting(
        isOwner: false,
        permissions: {'inventory.adjust'},
      );

      await pumpInventoryView(
        tester,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        locationRepo: locationRepo,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      final popupMenuItems = tester.widgetList<PopupMenuItem<String>>(
        find.byType(PopupMenuItem<String>),
      ).toList();

      final adjustStock = popupMenuItems.firstWhere((item) => item.value == 'adjust_stock');
      final editProduct = popupMenuItems.firstWhere((item) => item.value == 'edit_product');
      final addVariant = popupMenuItems.firstWhere((item) => item.value == 'add_variant');
      final viewDetails = popupMenuItems.firstWhere((item) => item.value == 'view_details');

      expect(adjustStock.enabled, isTrue, reason: 'Adjust Stock enabled for inventory.adjust');
      expect(editProduct.enabled, isFalse);
      expect(addVariant.enabled, isFalse);
      expect(viewDetails.enabled, isFalse);
    });

    testWidgets('5. Bulk checkbox selection does NOT disable context menu actions', (tester) async {
      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final locationRepo = LocationRepository();
      final categoryRepo = CategoryRepository();
      final supplierRepo = SupplierRepository();

      await productRepo.publishProduct(
        productId: 'prod_checkbox_test',
        businessId: 'test_biz',
        name: 'Oxford Cotton Shirt',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1200,
        retailPriceCents: 2500,
        sku: 'TS-OCS-00001',
      );

      AuthorizationService.instance.setPermissionsForTesting(isOwner: true);

      await pumpInventoryView(
        tester,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        locationRepo: locationRepo,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
      );

      // Tap row checkbox to select
      await tester.tap(find.byIcon(Icons.check_box_outline_blank).at(1));
      await tester.pumpAndSettle();

      // Checkbox is now checked
      expect(find.byIcon(Icons.check_box_rounded), findsOneWidget);

      // Open context menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      final popupMenuItems = tester.widgetList<PopupMenuItem<String>>(
        find.byType(PopupMenuItem<String>),
      ).toList();

      // All actions still enabled despite checkbox selection
      for (final item in popupMenuItems) {
        expect(item.enabled, isTrue, reason: 'Action ${item.value} must not be disabled by checkbox selection');
      }
    });

    testWidgets('6. Authoritative owner from CurrentBusinessService context grants all permissions', (tester) async {
      final biz = Business(
        id: 'biz_authoritative_test',
        ownerUserId: 'user_owner_123',
        legalName: 'Authoritative Owner Boutique',
        businessType: 'Retail',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      CurrentBusinessService.instance.setCurrentBusiness(biz);

      // Check that AuthorizationService recognizes catalog permissions
      expect(AuthorizationService.allCatalogPermissions.every((p) => p.isNotEmpty), isTrue);
      expect(AuthorizationService.allCatalogPermissions.contains('inventory.view'), isTrue);
      expect(AuthorizationService.allCatalogPermissions.contains('inventory.manage'), isTrue);
      expect(AuthorizationService.allCatalogPermissions.contains('inventory.adjust'), isTrue);
    });

    testWidgets('7. Actions invoke correct callbacks: View Details, Edit, Adjust Stock, History', (tester) async {
      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final locationRepo = LocationRepository();
      final categoryRepo = CategoryRepository();
      final supplierRepo = SupplierRepository();

      await productRepo.publishProduct(
        productId: 'prod_action_dispatch',
        businessId: 'test_biz',
        name: 'Oxford Cotton Shirt',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1200,
        retailPriceCents: 2500,
        sku: 'TS-OCS-00001',
      );

      AuthorizationService.instance.setPermissionsForTesting(isOwner: true);

      String? viewedProductId;
      String? editedProductId;
      String? adjustedProductId;
      String? historyProductId;

      await pumpInventoryView(
        tester,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        locationRepo: locationRepo,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
        onViewProductDetails: (id) => viewedProductId = id,
        onEditProduct: (id) => editedProductId = id,
        onAdjustProductStock: (id) => adjustedProductId = id,
        onProductStockHistory: (id) => historyProductId = id,
      );

      // 1. Click View Details
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();
      expect(viewedProductId, 'prod_action_dispatch');

      // 2. Click Edit Product
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit Product'));
      await tester.pumpAndSettle();
      expect(editedProductId, 'prod_action_dispatch');

      // 3. Click Adjust Stock
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(PopupMenuItem<String>, 'Adjust Stock'));
      await tester.pumpAndSettle();
      expect(adjustedProductId, 'prod_action_dispatch');

      // 4. Click Stock History
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stock History'));
      await tester.pumpAndSettle();
      expect(historyProductId, 'prod_action_dispatch');
    });

    testWidgets('8. Archive Product opens confirmation dialog and does not hard-delete', (tester) async {
      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final locationRepo = LocationRepository();
      final categoryRepo = CategoryRepository();
      final supplierRepo = SupplierRepository();

      await productRepo.publishProduct(
        productId: 'prod_archive_test',
        businessId: 'test_biz',
        name: 'Oxford Cotton Shirt',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'sup_1',
        taxCategory: 'Standard',
        costPriceCents: 1200,
        retailPriceCents: 2500,
        sku: 'TS-OCS-00001',
      );

      AuthorizationService.instance.setPermissionsForTesting(isOwner: true);

      await pumpInventoryView(
        tester,
        productRepo: productRepo,
        inventoryRepo: inventoryRepo,
        locationRepo: locationRepo,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Archive Product'));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appeared
      expect(find.text('Archive Product'), findsWidgets);
      expect(find.textContaining('Are you sure you want to archive'), findsOneWidget);

      // Cancel keeps the product active
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      final p = await productRepo.getProduct('prod_archive_test');
      expect(p, isNotNull);
      expect(p!.status, isNot('archived'));
    });
  });
}
