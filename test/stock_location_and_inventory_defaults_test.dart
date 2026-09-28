import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/data/brand_repository.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/inventory/data/supplier_repository.dart';
import 'package:threadstock/features/inventory/presentation/providers/brand_provider.dart';
import 'package:threadstock/features/inventory/presentation/widgets/create_new_product_view.dart';

void main() {
  setUp(() {
    LocationRepository.clearLocalState();
    ProductRepository.clearLocalState();
    BrandRepository.clearLocalState();
    CategoryRepository.clearLocalState();
    SupplierRepository.clearLocalState();
  });

  tearDown(() {
    LocationRepository.clearLocalState();
    ProductRepository.clearLocalState();
    BrandRepository.clearLocalState();
    CategoryRepository.clearLocalState();
    SupplierRepository.clearLocalState();
  });

  Future<void> pumpView(
    WidgetTester tester, {
    LocationRepository? locationRepo,
    ProductRepository? productRepo,
    BrandProvider? brandProvider,
    CategoryRepository? categoryRepo,
    SupplierRepository? supplierRepo,
    String? businessId,
  }) async {
    tester.view.physicalSize = const Size(1920, 3500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreateNewProductView(
            locationRepository: locationRepo,
            productRepository: productRepo,
            brandProvider: brandProvider,
            categoryRepository: categoryRepo,
            supplierRepository: supplierRepo,
            businessId: businessId ?? 'test_biz_1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    '0 real locations displays "No locations available" and "+ Add location"',
    (tester) async {
      final locationRepo = LocationRepository();
      await pumpView(tester, locationRepo: locationRepo);

      // Toggle Track Stock Levels switch to ON
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify hardcoded Milan Hub is NOT present
      expect(find.text('Main Distribution Center (Milan Hub)'), findsNothing);
      expect(find.text('Central Flagship Storefront'), findsNothing);
      expect(find.text('Northern Logistics Hub'), findsNothing);

      // Verify 0 locations behavior
      expect(find.text('No locations available'), findsWidgets);
      expect(find.text('+ Add location'), findsWidgets);
    },
  );

  testWidgets('1 real active location is auto-selected', (tester) async {
    final locationRepo = LocationRepository();
    final created = await locationRepo.createLocation(
      name: 'Main Brooklyn Warehouse',
      businessId: 'test_biz_1',
    );

    await pumpView(tester, locationRepo: locationRepo);

    // Toggle Track Stock Levels switch to ON
    await tester.tap(find.byType(Switch), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Exactly 1 real location should be auto-selected
    expect(find.text(created.name), findsOneWidget);
    expect(find.text('No locations available'), findsNothing);
    expect(find.text('Select stock location'), findsNothing);
  });

  testWidgets(
    '2+ real active locations show "Select stock location" placeholder and does not auto-select',
    (tester) async {
      final locationRepo = LocationRepository();
      await locationRepo.createLocation(
        name: 'Alpha Warehouse',
        businessId: 'test_biz_1',
      );
      await locationRepo.createLocation(
        name: 'Beta Fulfillment Center',
        businessId: 'test_biz_1',
      );

      await pumpView(tester, locationRepo: locationRepo);

      // Toggle Track Stock Levels switch to ON
      await tester.tap(find.byType(Switch), warnIfMissed: false);
      await tester.pumpAndSettle();

      // 2+ locations should display placeholder "Select stock location"
      expect(find.text('Select stock location'), findsOneWidget);
      expect(
        find.text('Alpha Warehouse'),
        findsNothing,
      ); // Not chosen yet in dropdown display
      expect(find.text('Beta Fulfillment Center'), findsNothing);

      // Open dropdown to choose one
      await tester.tap(find.text('Select stock location'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Alpha Warehouse'), findsOneWidget);
      expect(find.text('Beta Fulfillment Center'), findsOneWidget);

      // Select Alpha Warehouse
      await tester.tap(find.text('Alpha Warehouse').last, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Alpha Warehouse'), findsOneWidget);
    },
  );

  testWidgets('Can add a new location inline and it gets auto-selected', (
    tester,
  ) async {
    final locationRepo = LocationRepository();
    await pumpView(tester, locationRepo: locationRepo);

    // Toggle Track Stock Levels switch to ON
    await tester.tap(find.byType(Switch), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('No locations available'), findsWidgets);

    // Click "+ Add location"
    await tester.tap(find.text('+ Add location').first, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Modal appears
    expect(find.text('Add Stock Location'), findsOneWidget);

    // Enter name
    await tester.enterText(
      find
          .descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          )
          .first,
      'Downtown Hub',
    );
    await tester.pumpAndSettle();

    // Click Add Location
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Add Location'),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    // Dialog closed and Downtown Hub is selected
    expect(find.text('Add Stock Location'), findsNothing);
    expect(find.text('Downtown Hub'), findsOneWidget);
  });

  testWidgets(
    'Opening Stock and Low-Stock Threshold defaults are null/empty, not persisted as fake values',
    (tester) async {
      final locationRepo = LocationRepository();
      final loc = await locationRepo.createLocation(
        name: 'Single Depot',
        businessId: 'test_biz_1',
      );

      final brandRepo = BrandRepository();
      final brand = await brandRepo.createBrand(
        name: 'Test Brand',
        businessId: 'test_biz_1',
      );
      final brandProvider = BrandProvider(repository: brandRepo);
      await brandProvider.loadBrands(businessId: 'test_biz_1');

      final categoryRepo = CategoryRepository();
      final category = await categoryRepo.createCategory(
        name: 'Apparel',
        businessId: 'test_biz_1',
      );

      final supplierRepo = SupplierRepository();
      final supplier = await supplierRepo.createSupplier(
        name: 'Global Mill',
        businessId: 'test_biz_1',
      );

      final productRepo = ProductRepository();

      await pumpView(
        tester,
        locationRepo: locationRepo,
        productRepo: productRepo,
        brandProvider: brandProvider,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
        businessId: 'test_biz_1',
      );

      // Toggle Track Stock Levels switch to ON
      await tester.tap(find.byType(Switch), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Single location is auto-selected
      expect(find.text(loc.name), findsOneWidget);

      // Verify hints exist visually
      expect(find.text('0'), findsOneWidget); // Hint for opening stock
      expect(
        find.text('e.g. 5'),
        findsOneWidget,
      ); // Hint for low stock threshold

      // Fill required product fields
      final nameField = find.widgetWithText(TextField, 'Enter product title');
      await tester.enterText(nameField, 'Minimalist Jacket');

      final costField = find
          .byWidgetPredicate(
            (w) => w is TextField && w.decoration?.prefixText == '₹ ',
          )
          .first;
      await tester.enterText(costField, '40');

      final retailField = find
          .byWidgetPredicate(
            (w) => w is TextField && w.decoration?.prefixText == '₹ ',
          )
          .last;
      await tester.enterText(retailField, '100');

      // Select Brand
      await tester.tap(find.text('Select brand'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(brand.name).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Select Category
      await tester.tap(find.text('Select category'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(category.name).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Select Supplier
      await tester.tap(find.text('Select supplier'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(supplier.name).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Select Tax Category
      await tester.tap(find.text('Select tax category'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Apparel Standard (12% GST)').last,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Auto-generate SKU
      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Auto-generate'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Leave Opening Stock and Low-Stock Threshold empty!
      // Publish product
      final publishButton = find.widgetWithText(
        ElevatedButton,
        'Publish Product',
      );
      await tester.tap(publishButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify product published successfully
      expect(find.text('Product published'), findsOneWidget);

      // Verify in product repository:
      // Low-stock threshold is null (not 5)
      // No opening stock was silently created (0 units, no fake movements)
      final allProducts = ProductRepository.localFallbackProducts;
      expect(allProducts.isNotEmpty, isTrue);
      final published = allProducts.values.first;
      expect(published.lowStockThreshold, isNull);
      expect(
        ProductRepository.localFallbackInventory,
        isEmpty,
      ); // No fake zero movement created!
    },
  );

  testWidgets(
    'Entering opening stock publishes with real stock referencing location_id',
    (tester) async {
      final locationRepo = LocationRepository();
      final loc = await locationRepo.createLocation(
        name: 'Main Hub',
        businessId: 'test_biz_1',
      );

      final brandRepo = BrandRepository();
      final brand = await brandRepo.createBrand(
        name: 'Test Brand',
        businessId: 'test_biz_1',
      );
      final brandProvider = BrandProvider(repository: brandRepo);
      await brandProvider.loadBrands(businessId: 'test_biz_1');

      final categoryRepo = CategoryRepository();
      final category = await categoryRepo.createCategory(
        name: 'Apparel',
        businessId: 'test_biz_1',
      );

      final supplierRepo = SupplierRepository();
      final supplier = await supplierRepo.createSupplier(
        name: 'Global Mill',
        businessId: 'test_biz_1',
      );

      final productRepo = ProductRepository();

      await pumpView(
        tester,
        locationRepo: locationRepo,
        productRepo: productRepo,
        brandProvider: brandProvider,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
        businessId: 'test_biz_1',
      );

      // Toggle Track Stock Levels switch to ON
      await tester.tap(find.byType(Switch), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Fill required product fields
      final nameField = find.widgetWithText(TextField, 'Enter product title');
      await tester.enterText(nameField, 'Cashmere Sweater');

      final costField = find
          .byWidgetPredicate(
            (w) => w is TextField && w.decoration?.prefixText == '₹ ',
          )
          .first;
      await tester.enterText(costField, '50');

      final retailField = find
          .byWidgetPredicate(
            (w) => w is TextField && w.decoration?.prefixText == '₹ ',
          )
          .last;
      await tester.enterText(retailField, '150');

      // Select Brand, Category, Supplier, Tax
      await tester.tap(find.text('Select brand'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(brand.name).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select category'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(category.name).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select supplier'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(supplier.name).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select tax category'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Apparel Standard (12% GST)').last,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Auto-generate'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // Enter explicit opening stock and reorder point
      final openingStockField = find.widgetWithText(TextField, '0');
      await tester.enterText(openingStockField, '25');

      final reorderField = find.widgetWithText(TextField, 'e.g. 5');
      await tester.enterText(reorderField, '7');
      await tester.pumpAndSettle();

      // Publish product
      final publishButton = find.widgetWithText(
        ElevatedButton,
        'Publish Product',
      );
      await tester.tap(publishButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Product published'), findsOneWidget);

      final published = ProductRepository.localFallbackProducts.values.first;
      expect(published.lowStockThreshold, equals(7));
      // Check fallback inventory entry with locationId
      expect(
        ProductRepository.localFallbackInventory['${published.id}_${loc.id}'],
        equals(25),
      );
    },
  );

  testWidgets(
    'When stock tracking is ON and 0 locations exist, publishing warns user to select location',
    (tester) async {
      final locationRepo = LocationRepository();
      final brandRepo = BrandRepository();
      final brand = await brandRepo.createBrand(
        name: 'Test Brand',
        businessId: 'test_biz_1',
      );
      final brandProvider = BrandProvider(repository: brandRepo);
      await brandProvider.loadBrands(businessId: 'test_biz_1');

      final categoryRepo = CategoryRepository();
      final category = await categoryRepo.createCategory(
        name: 'Apparel',
        businessId: 'test_biz_1',
      );

      final supplierRepo = SupplierRepository();
      final supplier = await supplierRepo.createSupplier(
        name: 'Global Mill',
        businessId: 'test_biz_1',
      );

      final productRepo = ProductRepository();

      await pumpView(
        tester,
        locationRepo: locationRepo,
        productRepo: productRepo,
        brandProvider: brandProvider,
        categoryRepo: categoryRepo,
        supplierRepo: supplierRepo,
        businessId: 'test_biz_1',
      );

      // Toggle Track Stock Levels switch to ON
      await tester.tap(find.byType(Switch), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Fill required product fields
      final nameField = find.widgetWithText(TextField, 'Enter product title');
      await tester.enterText(nameField, 'Silk Scarf');

      final costField = find
          .byWidgetPredicate(
            (w) => w is TextField && w.decoration?.prefixText == '₹ ',
          )
          .first;
      await tester.enterText(costField, '20');

      final retailField = find
          .byWidgetPredicate(
            (w) => w is TextField && w.decoration?.prefixText == '₹ ',
          )
          .last;
      await tester.enterText(retailField, '60');

      await tester.tap(find.text('Select brand'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(brand.name).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select category'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(category.name).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select supplier'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text(supplier.name).last, warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select tax category'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.text('Apparel Standard (12% GST)').last,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Auto-generate'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // No location selected because 0 locations exist
      final publishButton = find.widgetWithText(
        ElevatedButton,
        'Publish Product',
      );
      await tester.tap(publishButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Select a stock location.'), findsOneWidget);
    },
  );
}
