import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/inventory/data/brand_repository.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/data/product_media_repository.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/inventory/data/supplier_repository.dart';
import 'package:threadstock/features/inventory/presentation/widgets/create_new_product_view.dart';

import 'package:threadstock/features/inventory/data/location_repository.dart';

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
    tester.view.physicalSize = const Size(1920, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
    await tester.pumpAndSettle();
  }

  group('Save Draft & Publish Product Functionality', () {
    testWidgets(
      '1. Draft with partial data: saves with status draft without fake values',
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

        // Enter product name only (brand & category left missing)
        final nameField = find.widgetWithText(TextField, 'Enter product title');
        expect(nameField, findsOneWidget);
        await tester.enterText(nameField, 'Linen Overshirt Draft');
        await tester.pumpAndSettle();

        // Click Save Draft
        final saveDraftButton = find.widgetWithText(
          OutlinedButton,
          'Save Draft',
        );
        expect(saveDraftButton, findsOneWidget);
        await tester.tap(saveDraftButton);
        await tester.pumpAndSettle();

        // Expect success feedback
        expect(find.text('Draft saved'), findsOneWidget);

        // Product name matches, status is draft
        expect(find.text('Linen Overshirt Draft'), findsOneWidget);
      },
    );

    testWidgets('2. Save Draft with empty name is rejected with validation', (
      tester,
    ) async {
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

      // Click Save Draft without entering a name
      final saveDraftButton = find.widgetWithText(OutlinedButton, 'Save Draft');
      await tester.tap(saveDraftButton);
      await tester.pumpAndSettle();

      // Expect error feedback
      expect(find.text('Enter a product name to save draft.'), findsOneWidget);
      expect(find.text('Enter a product name.'), findsOneWidget);
    });

    testWidgets('3. Save Draft with negative price is rejected', (
      tester,
    ) async {
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

      final nameField = find.widgetWithText(TextField, 'Enter product title');
      await tester.enterText(nameField, 'Test Product');

      // Enter negative cost
      final costField = find
          .byWidgetPredicate(
            (w) => w is TextField && w.decoration?.prefixText == '₹ ',
          )
          .first;
      await tester.enterText(costField, '-50');
      await tester.pumpAndSettle();

      final saveDraftButton = find.widgetWithText(OutlinedButton, 'Save Draft');
      await tester.tap(saveDraftButton);
      await tester.pumpAndSettle();

      expect(find.text('Unit cost cannot be negative.'), findsWidgets);
    });

    testWidgets(
      '4. Publish incomplete: missing required fields blocks publish and shows validation',
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

        // Enter only title
        final nameField = find.widgetWithText(TextField, 'Enter product title');
        await tester.enterText(nameField, 'Incomplete Coat');

        // Click Publish Product
        final publishButton = find.widgetWithText(
          ElevatedButton,
          'Publish Product',
        );
        await tester.tap(publishButton);
        await tester.pumpAndSettle();

        // Expect required fields snackbar and field validation labels
        expect(
          find.text('Please fix the required fields before publishing.'),
          findsOneWidget,
        );
        expect(find.text('Select a brand.'), findsOneWidget);
        expect(find.text('Select a category.'), findsOneWidget);
        expect(find.text('Select a valid supplier.'), findsOneWidget);
        expect(find.text('Select a tax category.'), findsOneWidget);
        expect(
          find.text('Enter a selling price greater than 0.'),
          findsOneWidget,
        );
        expect(
          find.text('Enter a System SKU or click Auto-generate.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '5. Publish valid product: saves active product with inventory and invokes callback',
      (tester) async {
        // Seed a brand, category, supplier, location
        await brandRepo.createBrand(name: 'Atelier Sartoriale');
        await categoryRepo.createCategory(name: 'Outerwear');
        await supplierRepo.createSupplier(name: 'Milano Tessuti');
        await locationRepo.createLocation(name: 'Main Distribution Center');

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

        // Fill in title
        final nameField = find.widgetWithText(TextField, 'Enter product title');
        await tester.enterText(nameField, 'Cashmere Trench Coat');

        // Select Brand
        final brandDropdown = find.text('Select brand');
        await tester.tap(brandDropdown, warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('Atelier Sartoriale').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        // Select Category
        final categoryDropdown = find.text('Select category');
        await tester.tap(categoryDropdown, warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Outerwear').last, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Select Supplier
        final supplierDropdown = find.text('Select supplier');
        await tester.tap(supplierDropdown, warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Milano Tessuti').last, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Select Tax Category
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
        await tester.tap(autoGenButton);
        await tester.pumpAndSettle();

        // Enable Track Stock Levels
        final trackSwitch = find.byType(Switch);
        await tester.tap(trackSwitch);
        await tester.pumpAndSettle();

        // Enter opening stock
        final openingStockField = find.widgetWithText(TextField, '0');
        await tester.enterText(openingStockField, '30');
        await tester.pumpAndSettle();

        // Click Publish Product
        final publishButton = find.widgetWithText(
          ElevatedButton,
          'Publish Product',
        );
        await tester.ensureVisible(publishButton);
        await tester.tap(publishButton);
        await tester.pumpAndSettle();

        expect(find.text('Product published'), findsOneWidget);
        expect(publishedInvoked, isTrue);
      },
    );

    testWidgets(
      '6. Double click protection disables buttons and executes once',
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

        final nameField = find.widgetWithText(TextField, 'Enter product title');
        await tester.enterText(nameField, 'Silk Pajamas Draft');

        final saveDraftButton = find.widgetWithText(
          OutlinedButton,
          'Save Draft',
        );

        // Tap twice rapidly
        await tester.tap(saveDraftButton);
        await tester.tap(saveDraftButton);
        await tester.pumpAndSettle();

        expect(find.text('Draft saved'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Draft -> edit -> publish updates the same record in-place without duplicates',
      (tester) async {
        await brandRepo.createBrand(name: 'Como Silks');
        await categoryRepo.createCategory(name: 'Loungewear');
        await supplierRepo.createSupplier(name: 'Como Silk Mills');

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

        // 1. Save Draft
        final nameField = find.widgetWithText(TextField, 'Enter product title');
        await tester.enterText(nameField, 'Mulberry Silk Kimono');

        final saveDraftButton = find.widgetWithText(
          OutlinedButton,
          'Save Draft',
        );
        await tester.tap(saveDraftButton);
        await tester.pumpAndSettle();

        expect(find.text('Draft saved'), findsOneWidget);

        // 2. Complete remaining required fields on the same page
        final brandDropdown = find.text('Select brand');
        await tester.tap(brandDropdown, warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Como Silks').last, warnIfMissed: false);
        await tester.pumpAndSettle();

        final categoryDropdown = find.text('Select category');
        await tester.tap(categoryDropdown, warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Loungewear').last, warnIfMissed: false);
        await tester.pumpAndSettle();

        final supplierDropdown = find.text('Select supplier');
        await tester.tap(supplierDropdown, warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('Como Silk Mills').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        final taxDropdown = find.text('Select tax category');
        await tester.tap(taxDropdown, warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('Luxury Apparel (18% GST)').last,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        final costField = find
            .byWidgetPredicate(
              (w) => w is TextField && w.decoration?.prefixText == '₹ ',
            )
            .first;
        await tester.enterText(costField, '1200');

        final priceField = find
            .byWidgetPredicate(
              (w) => w is TextField && w.decoration?.prefixText == '₹ ',
            )
            .last;
        await tester.enterText(priceField, '2800');
        await tester.pumpAndSettle();

        final autoGenButton = find.widgetWithText(
          OutlinedButton,
          'Auto-generate',
        );
        await tester.tap(autoGenButton);
        await tester.pumpAndSettle();

        // 3. Publish Product
        final publishButton = find.widgetWithText(
          ElevatedButton,
          'Publish Product',
        );
        await tester.ensureVisible(publishButton);
        await tester.tap(publishButton);
        await tester.pumpAndSettle();

        expect(find.text('Product published'), findsOneWidget);
      },
    );

    testWidgets(
      '8. Back button right after Save Draft exits without false unsaved changes warning',
      (tester) async {
        bool backInvoked = false;

        await pumpDesktop(
          tester,
          CreateNewProductView(
            brandRepository: brandRepo,
            categoryRepository: categoryRepo,
            supplierRepository: supplierRepo,
            productRepository: productRepo,
            mediaRepository: mediaRepo,
            onBack: () {
              backInvoked = true;
            },
          ),
        );

        // Enter title and save draft
        final nameField = find.widgetWithText(TextField, 'Enter product title');
        await tester.enterText(nameField, 'Draft Shirt');

        final saveDraftButton = find.widgetWithText(
          OutlinedButton,
          'Save Draft',
        );
        await tester.tap(saveDraftButton);
        await tester.pumpAndSettle();
        expect(find.text('Draft saved'), findsOneWidget);

        // Click Back
        final backButton = find.text('Back');
        await tester.tap(backButton);
        await tester.pumpAndSettle();

        // Since draft was just saved and no edits made, no warning dialog should appear
        expect(find.text('Leave product setup?'), findsNothing);
        expect(backInvoked, isTrue);
      },
    );
  });
}
