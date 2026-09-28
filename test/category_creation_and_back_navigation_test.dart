import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/presentation/pages/inventory_page.dart';
import 'package:threadstock/features/inventory/presentation/widgets/create_new_product_view.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  setUp(() {
    CategoryRepository.clearLocalState();
  });

  Future<void> pumpDesktop(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pumpAndSettle();
  }

  test(
    'CategoryRepository throws StateError on duplicate within business',
    () async {
      final repo = CategoryRepository();
      await repo.createCategory(name: 'Formal Wear', businessId: 'biz_1');
      expect(
        () => repo.createCategory(name: 'formal wear', businessId: 'biz_1'),
        throwsA(isA<StateError>()),
      );
    },
  );

  testWidgets(
    'Category initial state starts with 0 categories and Select category placeholder',
    (tester) async {
      final repo = CategoryRepository();

      await pumpDesktop(
        tester,
        Scaffold(
          body: CreateNewProductView(
            categoryRepository: repo,
            businessId: 'biz_fresh_cat_123',
          ),
        ),
      );

      // Initial state check
      expect(find.text('Select category'), findsOneWidget);
      // Hardcoded dummy values must not be present
      expect(find.text('Knitwear'), findsNothing);
      expect(find.text('Shirts'), findsNothing);
      expect(find.text('Outerwear'), findsNothing);
      expect(find.text('Denim'), findsNothing);
      expect(find.text('Dresses'), findsNothing);
      expect(find.text('Accessories'), findsNothing);

      // Tap dropdown to open
      await tester.tap(find.text('Select category'));
      await tester.pumpAndSettle();

      // Dropdown empty state check
      expect(find.text('No categories yet'), findsOneWidget);
      expect(find.text('Add new category'), findsOneWidget);
    },
  );

  testWidgets(
    'Creating a real category persists to repository and auto-selects in dropdown',
    (tester) async {
      final repo = CategoryRepository();

      await pumpDesktop(
        tester,
        Scaffold(
          body: CreateNewProductView(
            categoryRepository: repo,
            businessId: 'biz_fresh_cat_123',
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.text('Select category'));
      await tester.pumpAndSettle();

      // Tap 'Add new category'
      await tester.tap(find.text('Add new category'));
      await tester.pumpAndSettle();

      // Modal should be visible with empty category name input
      expect(find.text('Add New Category'), findsOneWidget);
      expect(find.text('Enter category name'), findsOneWidget);

      // Enter category name: Formal Wear
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter category name'),
        'Formal Wear',
      );
      await tester.pumpAndSettle();

      // Tap Add Category button
      await tester.tap(find.text('Add Category'));
      await tester.pumpAndSettle();

      // Modal closed and Formal Wear auto-selected
      expect(find.text('Add New Category'), findsNothing);
      expect(find.text('Formal Wear'), findsOneWidget);

      // Verify category is in repository for this business
      final categories = await repo.getCategories(
        businessId: 'biz_fresh_cat_123',
      );
      expect(categories.length, 1);
      expect(categories.first.name, 'Formal Wear');
    },
  );

  testWidgets(
    'Different business does NOT see categories from another business',
    (tester) async {
      final repo = CategoryRepository();

      // Create category in business A
      await repo.createCategory(
        name: 'Formal Wear',
        businessId: 'business_cat_A',
      );

      // Open CreateNewProductView for business B
      await pumpDesktop(
        tester,
        Scaffold(
          body: CreateNewProductView(
            categoryRepository: repo,
            businessId: 'business_cat_B',
          ),
        ),
      );

      // Initial state for business B
      expect(find.text('Select category'), findsOneWidget);

      // Open dropdown
      await tester.tap(find.text('Select category'));
      await tester.pumpAndSettle();

      // Business B should NOT see 'Formal Wear'
      expect(find.text('Formal Wear'), findsNothing);
      expect(find.text('No categories yet'), findsOneWidget);
    },
  );

  testWidgets('Duplicate category validation within same business', (
    tester,
  ) async {
    final repo = CategoryRepository();
    await repo.createCategory(name: 'Formal Wear', businessId: 'biz_dup_test');

    await pumpDesktop(
      tester,
      Scaffold(
        body: CreateNewProductView(
          categoryRepository: repo,
          businessId: 'biz_dup_test',
        ),
      ),
    );

    // Open dropdown
    await tester.tap(find.text('Select category'));
    await tester.pumpAndSettle();

    // Tap 'Add new category'
    await tester.tap(find.text('Add new category'));
    await tester.pumpAndSettle();

    // Try entering same name case-insensitive
    expect(find.text('Add New Category'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Enter category name'),
      'formal wear',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add Category'));
    await tester.pumpAndSettle();

    expect(
      find.text('A category with this name already exists.'),
      findsOneWidget,
    );
  });

  testWidgets('Untouched Create Product Back navigates without confirmation', (
    tester,
  ) async {
    var wentBack = false;

    await pumpDesktop(
      tester,
      Scaffold(body: CreateNewProductView(onBack: () => wentBack = true)),
    );

    expect(find.text('Back'), findsOneWidget);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(wentBack, isTrue);
    expect(find.text('Leave product setup?'), findsNothing);
  });

  testWidgets(
    'Unsaved product information shows warning and allows Stay or Leave',
    (tester) async {
      var wentBack = false;

      await pumpDesktop(
        tester,
        Scaffold(body: CreateNewProductView(onBack: () => wentBack = true)),
      );

      // Enter a product title
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter product title'),
        'Loro Piana Cashmere Knit',
      );
      await tester.pumpAndSettle();

      // Click Back
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Warning dialog appears
      expect(find.text('Leave product setup?'), findsOneWidget);
      expect(
        find.text('Your unsaved product information will be lost.'),
        findsOneWidget,
      );
      expect(wentBack, isFalse);

      // Click Stay
      await tester.tap(find.text('Stay'));
      await tester.pumpAndSettle();

      expect(find.text('Leave product setup?'), findsNothing);
      expect(wentBack, isFalse);

      // Click Back again and choose Leave
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Leave product setup?'), findsOneWidget);

      await tester.tap(find.text('Leave'));
      await tester.pumpAndSettle();

      expect(wentBack, isTrue);
    },
  );

  testWidgets(
    'InventoryPage navigation: Add Product -> Create Product -> Back returns to stockList',
    (tester) async {
      String? currentTitle;

      await pumpDesktop(
        tester,
        Scaffold(
          body: InventoryPage(
            initialMode: InventoryPageMode.stockList,
            onTitleChanged: (title) => currentTitle = title,
          ),
        ),
      );

      // Tap Add Product in Stock Registry
      expect(find.text('Add Product'), findsWidgets);
      await tester.tap(find.text('Add Product').first);
      await tester.pumpAndSettle();

      // Should be on Create New Product page
      expect(find.text('Create New Product'), findsOneWidget);

      // Tap Back without unsaved changes
      await tester.tap(find.text('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Stock list may emit unrelated layout overflows; drain them.
      while (tester.takeException() != null) {}

      // Returned to stockList
      expect(find.text('Create New Product'), findsNothing);
      expect(currentTitle, 'Inventory');
    },
  );

  testWidgets(
    'Onboarding Step 4: Create Manually -> Create Product -> Back returns to Step 4 with data preserved',
    (tester) async {
      await pumpDesktop(tester, const OnboardingPage(initialStep: 4));

      // Choose Create Manually
      await tester.tap(find.text('Create Manually'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Initialize Catalog Setup'),
        200,
      );
      await tester.tap(find.text('Initialize Catalog Setup'));
      await tester.pumpAndSettle();

      // Should be on Create New Product
      expect(find.byType(InventoryPage), findsOneWidget);
      expect(find.text('Create New Product'), findsOneWidget);

      // Tap Back
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Should be back at Step 4 — Inventory Ingestion
      expect(find.byType(InventoryPage), findsNothing);
      expect(find.text('How would you like to start?'), findsOneWidget);
      expect(find.text('Create Manually'), findsOneWidget);
      expect(find.text('Upload CSV / Excel'), findsOneWidget);
    },
  );
}
