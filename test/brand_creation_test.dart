import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/inventory/data/brand_repository.dart';
import 'package:threadstock/features/inventory/presentation/widgets/create_new_product_view.dart';

void main() {
  setUp(() {
    BrandRepository.clearLocalState();
  });

  Future<void> pumpDesktop(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Brand initial state starts with 0 brands and Select brand placeholder',
    (tester) async {
      final repo = BrandRepository();

      await pumpDesktop(
        tester,
        Scaffold(
          body: CreateNewProductView(
            brandRepository: repo,
            businessId: 'biz_fresh_123',
          ),
        ),
      );

      // Initial state check
      expect(find.text('Select brand'), findsOneWidget);
      expect(find.text('ThreadStock'), findsNothing);
      expect(find.text('ThreadStock Essentials'), findsNothing);
      expect(find.text('Tessuti Sartoriale'), findsNothing);

      // Tap dropdown to open
      await tester.tap(find.text('Select brand'));
      await tester.pumpAndSettle();

      // Dropdown empty state check
      expect(find.text('No brands yet'), findsOneWidget);
      expect(find.text('Add new brand'), findsOneWidget);
    },
  );

  testWidgets(
    'Creating a real brand persists to repository and auto-selects in dropdown',
    (tester) async {
      final repo = BrandRepository();

      await pumpDesktop(
        tester,
        Scaffold(
          body: CreateNewProductView(
            brandRepository: repo,
            businessId: 'biz_fresh_123',
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.text('Select brand'));
      await tester.pumpAndSettle();

      // Tap 'Add new brand'
      await tester.tap(find.text('Add new brand'));
      await tester.pumpAndSettle();

      // Modal should be visible with empty brand name input
      expect(find.text('Add New Brand'), findsOneWidget);
      expect(find.text('Enter brand name'), findsOneWidget);

      // Enter brand name: Azhar Couture
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter brand name'),
        'Azhar Couture',
      );
      await tester.pumpAndSettle();

      // Tap Save Brand
      await tester.tap(find.text('Save Brand'));
      await tester.pumpAndSettle();

      // Modal closed and Azhar Couture auto-selected
      expect(find.text('Add New Brand'), findsNothing);
      expect(find.text('Azhar Couture'), findsOneWidget);

      // Verify brand is in repository for this business
      final brands = await repo.getBrands(businessId: 'biz_fresh_123');
      expect(brands.length, 1);
      expect(brands.first.name, 'Azhar Couture');
    },
  );

  testWidgets('Different business does NOT see brands from another business', (
    tester,
  ) async {
    final repo = BrandRepository();

    // Create brand in business A
    await repo.createBrand(name: 'Azhar Couture', businessId: 'business_A');

    // Open CreateNewProductView for business B
    await pumpDesktop(
      tester,
      Scaffold(
        body: CreateNewProductView(
          brandRepository: repo,
          businessId: 'business_B',
        ),
      ),
    );

    // Business B should see 'Select brand' and 0 brands
    expect(find.text('Select brand'), findsOneWidget);
    expect(find.text('Azhar Couture'), findsNothing);

    await tester.tap(find.text('Select brand'));
    await tester.pumpAndSettle();

    expect(find.text('No brands yet'), findsOneWidget);
    expect(find.text('Azhar Couture'), findsNothing);
  });

  testWidgets('Brand is required when publishing product without selection', (
    tester,
  ) async {
    final repo = BrandRepository();

    await pumpDesktop(
      tester,
      Scaffold(
        body: CreateNewProductView(
          brandRepository: repo,
          businessId: 'biz_fresh_123',
        ),
      ),
    );

    // Tap Publish Product without selecting brand
    await tester.tap(find.text('Publish Product'));
    await tester.pumpAndSettle();

    expect(find.text('Select a brand.'), findsOneWidget);
  });
}
