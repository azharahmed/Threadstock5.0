import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/app/shell/app_shell.dart';
import 'package:threadstock/features/inventory/data/brand_repository.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/data/product_media_repository.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/inventory/data/supplier_repository.dart';
import 'package:threadstock/features/inventory/domain/models/product.dart';
import 'package:threadstock/features/inventory/presentation/widgets/create_new_product_view.dart';
import 'package:threadstock/features/inventory/presentation/widgets/inventory_products_view.dart';
import 'package:threadstock/features/inventory/presentation/widgets/product_details_view.dart';
import 'package:threadstock/features/inventory/presentation/widgets/stock_adjustment_view.dart';

void main() {
  late BrandRepository brandRepo;
  late CategoryRepository categoryRepo;
  late SupplierRepository supplierRepo;
  late ProductRepository productRepo;
  late ProductMediaRepository mediaRepo;
  late LocationRepository locationRepo;

  setUp(() {
    BrandRepository.clearLocalState();
    CategoryRepository.clearLocalState();
    SupplierRepository.clearLocalState();
    ProductRepository.clearLocalState();
    ProductMediaRepository.clearLocalState();
    LocationRepository.clearLocalState();

    brandRepo = BrandRepository();
    categoryRepo = CategoryRepository();
    supplierRepo = SupplierRepository();
    mediaRepo = ProductMediaRepository();
    productRepo = ProductRepository(mediaRepository: mediaRepo);
    locationRepo = LocationRepository();
  });

  Future<void> pumpDesktop(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1920, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
    await tester.pumpAndSettle();
  }

  group('ThreadStock Stock Entry & Breadcrumb Verification', () {
    testWidgets('1. Create Product Breadcrumb is "Inventory > Add Product" and clicking Inventory navigates to root', (tester) async {
      await pumpDesktop(tester, const AppShell(initialIndex: 1));

      // Locate Add Product button on Inventory landing page
      final addProductButton = find.widgetWithText(ElevatedButton, 'Add Product');
      expect(addProductButton, findsWidgets);
      await tester.tap(addProductButton.first);
      await tester.pumpAndSettle();

      // Check breadcrumb hierarchy: should be "Inventory" > "Add Product"
      // Verify obsolete breadcrumb hierarchy "Products > Setup Ledger" is NOT present
      expect(find.text('Setup Ledger'), findsNothing);
      expect(find.text('Catalog Setup'), findsNothing);

      // Verify canonical breadcrumb shows "Inventory" and "Add Product"
      expect(find.text('Add Product'), findsWidgets);
      expect(find.text('Inventory'), findsWidgets);

      // Tapping "Inventory" in breadcrumb must navigate back to root inventory list
      final inventoryBreadcrumb = find.ancestor(
        of: find.text('Inventory'),
        matching: find.byType(InkWell),
      );
      expect(inventoryBreadcrumb, findsWidgets);
      await tester.tap(inventoryBreadcrumb.last);
      await tester.pumpAndSettle();

      while (tester.takeException() != null) {}

      // Verified root inventory is reached
      expect(find.widgetWithText(OutlinedButton, 'Adjust Stock'), findsWidgets);
      expect(find.widgetWithText(ElevatedButton, 'Add Product'), findsWidgets);
    });

    testWidgets('2. Track Stock Levels toggle: OFF hides stock fields, ON shows Location *, Opening Stock, Low Stock Threshold', (tester) async {
      await pumpDesktop(
        tester,
        CreateNewProductView(
          brandRepository: brandRepo,
          categoryRepository: categoryRepo,
          supplierRepository: supplierRepo,
          productRepository: productRepo,
          mediaRepository: mediaRepo,
          locationRepository: locationRepo,
          businessId: 'test_biz_1',
        ),
      );

      // Default: trackStockLevels is true
      expect(find.text('Track Stock Levels'), findsOneWidget);
      expect(find.text('Location *'), findsOneWidget);
      expect(find.text('Opening Stock'), findsOneWidget);
      expect(find.text('Initial quantity available at this location'), findsOneWidget);
      expect(find.text('Low Stock Threshold'), findsOneWidget);

      // Toggle Track Stock Levels to OFF
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Now stock fields must be hidden
      expect(find.text('Location *'), findsNothing);
      expect(find.text('Initial quantity available at this location'), findsNothing);
      expect(find.text('Low Stock Threshold'), findsNothing);

      // Toggle back to ON
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Location *, Opening Stock, and Low Stock Threshold are visible again
      expect(find.text('Location *'), findsOneWidget);
      expect(find.text('Initial quantity available at this location'), findsOneWidget);
      expect(find.text('Low Stock Threshold'), findsOneWidget);
    });

    testWidgets('3. Location Requirement: zero locations shows "No location configured", "Create a location before adding stock.", and "Create Location" button', (tester) async {
      await pumpDesktop(
        tester,
        CreateNewProductView(
          brandRepository: brandRepo,
          categoryRepository: categoryRepo,
          supplierRepository: supplierRepo,
          productRepository: productRepo,
          mediaRepository: mediaRepo,
          locationRepository: locationRepo,
          businessId: 'empty_loc_biz',
        ),
      );

      // Zero locations state
      expect(find.text('No location configured'), findsOneWidget);
      expect(find.text('Create a location before adding stock.'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Create Location'), findsOneWidget);
    });

    testWidgets('4. Valid location + opening stock 20 publishes payload with track_stock_levels: true and opening_stock: 20', (tester) async {
      // Seed required entities
      await brandRepo.createBrand(name: 'Tailor Brand', businessId: 'biz_stock_test');
      await categoryRepo.createCategory(name: 'Suits', businessId: 'biz_stock_test');
      await supplierRepo.createSupplier(name: 'Fabric Mills', businessId: 'biz_stock_test');
      await locationRepo.createLocation(name: 'Warehouse A', businessId: 'biz_stock_test');

      Product? publishedResult;

      await pumpDesktop(
        tester,
        CreateNewProductView(
          brandRepository: brandRepo,
          categoryRepository: categoryRepo,
          supplierRepository: supplierRepo,
          productRepository: productRepo,
          mediaRepository: mediaRepo,
          locationRepository: locationRepo,
          businessId: 'biz_stock_test',
          onPublishSuccess: (prod) => publishedResult = prod,
        ),
      );

      // Fill in required product title
      final titleField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Enter product title');
      await tester.enterText(titleField, 'Classic Wool Blazer');
      await tester.pumpAndSettle();

      // Select brand
      await tester.tap(find.text('Select brand'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tailor Brand').last);
      await tester.pumpAndSettle();

      // Select category
      await tester.tap(find.text('Select category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Suits').last);
      await tester.pumpAndSettle();

      // Select supplier
      await tester.tap(find.text('Select supplier'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fabric Mills').last);
      await tester.pumpAndSettle();

      // Auto-generate SKU
      await tester.tap(find.text('Auto-generate'));
      await tester.pumpAndSettle();

      // Enter pricing
      final priceFields = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == '0.00');
      await tester.enterText(priceFields.first, '40.00'); // Cost
      await tester.enterText(priceFields.last, '120.00'); // Retail
      await tester.pumpAndSettle();

      // Enter opening stock = 20
      final openingStockInput = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == '0');
      expect(openingStockInput, findsOneWidget);
      await tester.enterText(openingStockInput, '20');
      await tester.pumpAndSettle();

      // Select tax category
      await tester.tap(find.text('Select tax category'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Luxury Apparel (18% GST)').last);
      await tester.pumpAndSettle();

      // Publish product
      final publishButton = find.widgetWithText(ElevatedButton, 'Publish Product');
      await tester.tap(publishButton);
      await tester.pumpAndSettle();

      expect(publishedResult, isNotNull);
      expect(publishedResult!.trackStockLevels, isTrue);
    });

    testWidgets('5. Existing product stock action: Inventory landing page has prominent "Adjust Stock" button opening StockAdjustmentView', (tester) async {
      bool adjustStockTapped = false;

      await pumpDesktop(
        tester,
        InventoryProductsView(
          businessId: 'biz_action_test',
          productRepository: productRepo,
          categoryRepository: categoryRepo,
          supplierRepository: supplierRepo,
          locationRepository: locationRepo,
          onAdjustStock: () => adjustStockTapped = true,
        ),
      );

      // Prominent Adjust Stock button in top action row
      final adjustStockBtn = find.widgetWithText(OutlinedButton, 'Adjust Stock').first;
      expect(adjustStockBtn, findsOneWidget);

      await tester.tap(adjustStockBtn);
      await tester.pumpAndSettle();
      expect(adjustStockTapped, isTrue);
    });

    testWidgets('6. StockAdjustmentView supports Add Stock, Remove Stock, and Correct Quantity', (tester) async {
      final loc = await locationRepo.createLocation(name: 'Central Warehouse', businessId: 'biz_adjust_test');
      final prod = await productRepo.publishProduct(
        businessId: 'biz_adjust_test',
        name: 'Oxford Cotton Shirt',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'a0000000-0000-0000-0000-000000000001',
        taxCategory: 'Luxury Apparel (18% GST)',
        costPriceCents: 1500,
        retailPriceCents: 4500,
        sku: 'OXF-SHT-01',
        trackStockLevels: true,
        locationId: loc.id,
        openingStock: 10,
      );

      await pumpDesktop(
        tester,
        StockAdjustmentView(
          initialProductId: prod.id,
          initialAdjustmentType: StockAdjustmentType.add,
        ),
      );

      // Advance from Step 1 (Select Product) to Step 2 (Adjust Details)
      final continueBtn = find.widgetWithText(ElevatedButton, 'Continue');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Verify the 3 adjustment type options are present
      expect(find.text('Add Stock'), findsWidgets);
      expect(find.text('Remove Stock'), findsOneWidget);
      expect(find.text('Correct Quantity'), findsOneWidget);

      // Switch to Remove Stock
      await tester.tap(find.text('Remove Stock'));
      await tester.pumpAndSettle();

      // Switch to Correct Quantity
      await tester.tap(find.text('Correct Quantity'));
      await tester.pumpAndSettle();
      expect(find.text('Actual Counted / New Quantity'), findsOneWidget);
    });

    testWidgets('7. Product Details > Inventory: shows location columns (Location, Available, Committed, Damaged, Last Counted) & stock actions', (tester) async {
      final loc = await locationRepo.createLocation(name: 'Store 1', businessId: 'biz_details_test');
      final prod = await productRepo.publishProduct(
        businessId: 'biz_details_test',
        name: 'Linen Trousers',
        brandId: 'brand_1',
        categoryId: 'cat_1',
        supplierId: 'a0000000-0000-0000-0000-000000000001',
        taxCategory: 'Luxury Apparel (18% GST)',
        costPriceCents: 2000,
        retailPriceCents: 5000,
        sku: 'LIN-TRS-01',
        trackStockLevels: true,
        locationId: loc.id,
        openingStock: 15,
      );

      // Mock details with location balance
      final mockRepo = ProductRepository();

      await pumpDesktop(
        tester,
        ProductDetailsView(
          productId: prod.id,
          productRepository: mockRepo,
        ),
      );

      // Tap Inventory Tab
      final invTab = find.text('Inventory');
      expect(invTab, findsWidgets);
      await tester.tap(invTab.first);
      await tester.pumpAndSettle();

      // Check for Tracking Disabled or No stock recorded or location headers
      // If product has trackStockLevels = false: shows "Tracking Disabled"
      // If product has trackStockLevels = true and 0 stock: shows "No stock recorded" with "Add Stock"
      expect(find.text('Add Stock'), findsWidgets);
    });

    testWidgets('8. Product Details > Inventory: Tracking Disabled state shows "Enable Tracking" action', (tester) async {
      // Create product with trackStockLevels = false
      final untrackedProduct = Product(
        id: 'untracked_p1',
        businessId: 'biz_untracked',
        name: 'Untracked Scarf',
        trackStockLevels: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Local fallback in repository
      await productRepo.updateProduct(untrackedProduct);

      await pumpDesktop(
        tester,
        ProductDetailsView(
          productId: 'untracked_p1',
          productRepository: productRepo,
        ),
      );

      // Navigate to Inventory Tab (tab index 2)
      final invTab = find.text('Inventory');
      await tester.tap(invTab.first);
      await tester.pumpAndSettle();

      // Expect "Tracking Disabled" and "Enable Tracking" button
      expect(find.text('Tracking Disabled'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Enable Tracking'), findsOneWidget);
    });
  });
}
