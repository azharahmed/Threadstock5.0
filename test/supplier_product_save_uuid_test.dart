import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/inventory/data/brand_repository.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/data/product_media_repository.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/inventory/data/supplier_repository.dart';
import 'package:threadstock/features/inventory/presentation/widgets/create_new_product_view.dart';

void main() {
  final uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

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
    tester.view.physicalSize = const Size(1920, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
    await tester.pumpAndSettle();
  }

  group('SupplierRepository & UUID verification', () {
    test(
      'Fresh supplier state: 0 suppliers returned, no hardcoded demo entries',
      () async {
        final suppliers = await supplierRepo.getSuppliers(
          businessId: 'test_biz',
        );
        expect(suppliers, isEmpty);
        expect(
          suppliers.any((s) => s.name.contains('Milano Tessuti')),
          isFalse,
        );
        expect(
          suppliers.any((s) => s.name.contains('Como Silk Mills')),
          isFalse,
        );
        expect(
          suppliers.any((s) => s.name.contains('Veneto Leathers')),
          isFalse,
        );
      },
    );

    test(
      'createSupplier produces genuine RFC 4122 v4 UUID (never "sup_...")',
      () async {
        final supplier = await supplierRepo.createSupplier(
          name: 'Biella Wool Guild',
          businessId: 'test_biz',
          contactEmail: 'contact@biella.it',
        );

        expect(supplier.name, equals('Biella Wool Guild'));
        expect(supplier.id.startsWith('sup_'), isFalse);
        expect(
          uuidRegex.hasMatch(supplier.id),
          isTrue,
          reason: 'Supplier ID must be a valid UUID',
        );

        final list = await supplierRepo.getSuppliers(businessId: 'test_biz');
        expect(list.length, equals(1));
        expect(list.first.id, equals(supplier.id));
      },
    );
  });

  group('CreateNewProductView Supplier & Publishing UX', () {
    testWidgets(
      '1. Fresh state: shows Select supplier, No suppliers yet, and Add new supplier',
      (tester) async {
        await pumpDesktop(
          tester,
          CreateNewProductView(
            brandRepository: brandRepo,
            categoryRepository: categoryRepo,
            supplierRepository: supplierRepo,
            productRepository: productRepo,
            mediaRepository: mediaRepo,
          ),
        );

        // Verify dropdown hint
        expect(find.text('Select supplier'), findsOneWidget);

        // Verify fake compliance banner is completely absent
        expect(find.text('Supplier Compliance Verified'), findsNothing);
        expect(
          find.text('Milano Tessuti is GST registered and active.'),
          findsNothing,
        );
        expect(find.text('Milano Tessuti'), findsNothing);

        // Tap the dropdown to open menu items
        await tester.tap(find.text('Select supplier'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Check items
        expect(find.text('No suppliers yet'), findsOneWidget);
        expect(find.text('+ Add new supplier'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Add new supplier modal creates supplier with UUID and auto-selects it',
      (tester) async {
        await pumpDesktop(
          tester,
          CreateNewProductView(
            brandRepository: brandRepo,
            categoryRepository: categoryRepo,
            supplierRepository: supplierRepo,
            productRepository: productRepo,
            mediaRepository: mediaRepo,
          ),
        );

        // Open dropdown
        await tester.tap(find.text('Select supplier'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Tap + Add new supplier
        await tester.tap(
          find.text('+ Add new supplier').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Modal is open
        expect(find.text('Add New Supplier'), findsOneWidget);
        expect(find.text('Enter supplier name'), findsOneWidget);

        // Enter name
        final nameField = find.widgetWithText(TextField, 'Enter supplier name');
        await tester.enterText(nameField, 'Firenze Weavers');
        await tester.pumpAndSettle();

        // Tap Add Supplier button
        final addSupplierBtn = find.widgetWithText(
          ElevatedButton,
          'Add Supplier',
        );
        await tester.tap(addSupplierBtn);
        await tester.pumpAndSettle();

        // Modal closed and supplier is selected
        expect(find.text('Add New Supplier'), findsNothing);
        expect(find.text('Firenze Weavers'), findsOneWidget);

        // Verify saved in repository with genuine UUID
        final suppliers = await supplierRepo.getSuppliers();
        expect(suppliers.length, equals(1));
        expect(suppliers.first.name, equals('Firenze Weavers'));
        expect(uuidRegex.hasMatch(suppliers.first.id), isTrue);
      },
    );

    testWidgets(
      '3. Publish without supplier blocks with "Select a valid supplier."',
      (tester) async {
        await brandRepo.createBrand(name: 'Heritage');
        await categoryRepo.createCategory(name: 'Knitwear');

        await pumpDesktop(
          tester,
          CreateNewProductView(
            brandRepository: brandRepo,
            categoryRepository: categoryRepo,
            supplierRepository: supplierRepo,
            productRepository: productRepo,
            mediaRepository: mediaRepo,
          ),
        );

        // Fill required fields EXCEPT supplier
        final nameField = find.widgetWithText(TextField, 'Enter product title');
        await tester.enterText(nameField, 'Cashmere Scarf');

        // Select brand
        await tester.tap(find.text('Select brand'), warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Heritage').last, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Select category
        await tester.tap(find.text('Select category'), warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Knitwear').last, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Select tax category
        final taxDropdown = find.text('Select tax category');
        await tester.tap(taxDropdown, warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('Apparel Standard (12% GST)').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Pricing
        final priceField = find
            .byWidgetPredicate(
              (w) => w is TextField && w.decoration?.prefixText == '₹ ',
            )
            .last;
        await tester.enterText(priceField, '1200');

        // Auto-generate SKU
        final autoGenButton = find.widgetWithText(
          OutlinedButton,
          'Auto-generate',
        );
        await tester.tap(autoGenButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Supplier is NOT selected
        // Click Publish
        final publishBtn = find.widgetWithText(
          ElevatedButton,
          'Publish Product',
        );
        await tester.ensureVisible(publishBtn);
        await tester.tap(publishBtn, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Validation message shown
        expect(find.text('Select a valid supplier.'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Publish with newly added supplier saves with genuine UUID',
      (tester) async {
        await brandRepo.createBrand(name: 'Artisan Brand');
        await categoryRepo.createCategory(name: 'Apparel');

        bool publishedInvoked = false;

        await pumpDesktop(
          tester,
          CreateNewProductView(
            brandRepository: brandRepo,
            categoryRepository: categoryRepo,
            supplierRepository: supplierRepo,
            productRepository: productRepo,
            mediaRepository: mediaRepo,
            locationRepository: locationRepo,
            onPublishProduct: () {
              publishedInvoked = true;
            },
          ),
        );

        // Title
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter product title'),
          'Merino Wool Cardigan',
        );

        // Brand
        await tester.tap(find.text('Select brand'), warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Artisan Brand').last, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Category
        await tester.tap(find.text('Select category'), warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Apparel').last, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Add supplier
        await tester.tap(find.text('Select supplier'), warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('+ Add new supplier').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter supplier name'),
          'Como Fine Wool Mills',
        );
        await tester.tap(find.widgetWithText(ElevatedButton, 'Add Supplier'));
        await tester.pumpAndSettle();

        expect(find.text('Como Fine Wool Mills'), findsOneWidget);

        // Select tax category
        final taxDropdown = find.text('Select tax category');
        await tester.tap(taxDropdown, warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('Apparel Standard (12% GST)').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Pricing
        final costField = find
            .byWidgetPredicate(
              (w) => w is TextField && w.decoration?.prefixText == '₹ ',
            )
            .first;
        await tester.enterText(costField, '800');

        final priceField = find
            .byWidgetPredicate(
              (w) => w is TextField && w.decoration?.prefixText == '₹ ',
            )
            .last;
        await tester.enterText(priceField, '1500');
        await tester.pumpAndSettle();

        // Auto-generate SKU
        final autoGenButton = find.widgetWithText(
          OutlinedButton,
          'Auto-generate',
        );
        await tester.tap(autoGenButton, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Publish Product
        final publishBtn = find.widgetWithText(
          ElevatedButton,
          'Publish Product',
        );
        await tester.ensureVisible(publishBtn);
        await tester.tap(publishBtn, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Success
        expect(publishedInvoked, isTrue);
        expect(find.text('Product published'), findsOneWidget);

        final products = ProductRepository.localFallbackProducts.values
            .toList();
        expect(products.isNotEmpty, isTrue);
        final published = products.first;
        expect(published.name, equals('Merino Wool Cardigan'));
        expect(published.supplierId, isNotNull);
        expect(published.supplierId!.startsWith('sup_'), isFalse);
        expect(
          uuidRegex.hasMatch(published.supplierId!),
          isTrue,
          reason: 'published.supplierId must be a genuine UUID',
        );
      },
    );
  });
}
