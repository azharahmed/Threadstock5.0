import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/inventory/data/brand_repository.dart';
import 'package:threadstock/features/inventory/domain/models/brand.dart';
import 'package:threadstock/features/inventory/presentation/providers/brand_provider.dart';
import 'package:threadstock/features/inventory/presentation/widgets/create_new_product_view.dart';

void main() {
  setUp(() {
    BrandRepository.clearLocalState();
    BrandProvider.resetSharedInstance();
  });

  tearDown(() {
    BrandRepository.clearLocalState();
    BrandProvider.resetSharedInstance();
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
    'Scenario 1: Create Brand "WD" -> Save Brand -> Modal closes and WD auto-selected',
    (tester) async {
      final repo = BrandRepository();
      final provider = BrandProvider(repository: repo);

      await pumpDesktop(
        tester,
        Scaffold(
          body: CreateNewProductView(
            brandProvider: provider,
            businessId: 'business_milan_01',
          ),
        ),
      );

      // Initial check: Select brand placeholder
      expect(find.text('Select brand'), findsOneWidget);

      // Open dropdown
      await tester.tap(find.text('Select brand'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Click 'Add new brand'
      await tester.tap(find.text('Add new brand'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.text('Add New Brand'), findsOneWidget);
      expect(find.text('Enter brand name'), findsOneWidget);

      // Enter 'WD'
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter brand name'),
        'WD',
      );
      await tester.pumpAndSettle();

      // Tap 'Save Brand'
      await tester.tap(find.text('Save Brand'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Modal closes
      expect(find.text('Add New Brand'), findsNothing);

      // WD is immediately auto-selected in the Brand field
      expect(find.text('WD'), findsOneWidget);

      // Verify in provider and repository
      final brands = await provider.loadBrands(businessId: 'business_milan_01');
      expect(brands.length, 1);
      expect(brands.first.name, 'WD');
    },
  );

  testWidgets(
    'Scenario 2: Navigate away and reopen Create Product -> WD appears in dropdown',
    (tester) async {
      final repo = BrandRepository();
      final provider = BrandProvider(repository: repo);

      // Pre-create WD for business_milan_01
      await provider.createBrand(name: 'WD', businessId: 'business_milan_01');

      // Mount CreateNewProductView as if reopening
      await pumpDesktop(
        tester,
        Scaffold(
          body: CreateNewProductView(
            brandProvider: provider,
            businessId: 'business_milan_01',
          ),
        ),
      );

      // Dropdown initially shows Select brand
      expect(find.text('Select brand'), findsOneWidget);

      // Open dropdown
      await tester.tap(find.text('Select brand'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // WD is listed in the items
      expect(find.text('WD'), findsOneWidget);
      expect(find.text('No brands yet'), findsNothing);
    },
  );

  testWidgets(
    'Scenario 3: Restart application -> WD still appears from persistent storage',
    (tester) async {
      // Session 1: Create brand WD
      {
        final repoSession1 = BrandRepository();
        final providerSession1 = BrandProvider(repository: repoSession1);
        await providerSession1.createBrand(
          name: 'WD',
          businessId: 'business_milan_01',
        );
      }

      // Session 2: Simulated app restart with completely fresh repository and provider instances
      {
        final repoSession2 = BrandRepository();
        final providerSession2 = BrandProvider(repository: repoSession2);

        await pumpDesktop(
          tester,
          Scaffold(
            body: CreateNewProductView(
              brandProvider: providerSession2,
              businessId: 'business_milan_01',
            ),
          ),
        );

        // Open dropdown
        await tester.tap(find.text('Select brand'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // WD is loaded from persistent storage and appears in the dropdown
        expect(find.text('WD'), findsOneWidget);
      }
    },
  );

  testWidgets('Scenario 4: Different business (Business B) must NOT see WD', (
    tester,
  ) async {
    final repo = BrandRepository();
    final provider = BrandProvider(repository: repo);

    // Create WD in Business A
    await provider.createBrand(name: 'WD', businessId: 'business_A');

    // Open Create Product for Business B
    await pumpDesktop(
      tester,
      Scaffold(
        body: CreateNewProductView(
          brandProvider: provider,
          businessId: 'business_B',
        ),
      ),
    );

    // Open dropdown in Business B
    await tester.tap(find.text('Select brand'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Business B must NOT see WD
    expect(find.text('WD'), findsNothing);
    expect(find.text('No brands yet'), findsOneWidget);
  });

  testWidgets(
    'Scenario 5: Duplicate brand protection rejects duplicate (case-insensitive & trimmed)',
    (tester) async {
      final repo = BrandRepository();
      final provider = BrandProvider(repository: repo);

      // Existing: WD
      await provider.createBrand(name: 'WD', businessId: 'business_milan_01');

      await pumpDesktop(
        tester,
        Scaffold(
          body: CreateNewProductView(
            brandProvider: provider,
            businessId: 'business_milan_01',
          ),
        ),
      );

      // Open dropdown & Add new brand
      await tester.tap(find.text('Select brand'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add new brand'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Enter duplicate with different casing & spacing: '  wd  '
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter brand name'),
        '  wd  ',
      );
      await tester.pumpAndSettle();

      // Tap Save Brand
      await tester.tap(find.text('Save Brand'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Modal stays open and displays concise duplicate error
      expect(find.text('Add New Brand'), findsOneWidget);
      expect(
        find.text('A brand with this name already exists.'),
        findsOneWidget,
      );

      // Brand name input is preserved
      expect(find.widgetWithText(TextField, '  wd  '), findsOneWidget);
    },
  );

  testWidgets(
    'Scenario 6: Empty brand name displays concise error without closing modal',
    (tester) async {
      final repo = BrandRepository();
      final provider = BrandProvider(repository: repo);

      await pumpDesktop(
        tester,
        Scaffold(
          body: CreateNewProductView(
            brandProvider: provider,
            businessId: 'business_milan_01',
          ),
        ),
      );

      await tester.tap(find.text('Select brand'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add new brand'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Leave empty and tap Save Brand
      await tester.tap(find.text('Save Brand'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Modal stays open with error
      expect(find.text('Add New Brand'), findsOneWidget);
      expect(find.text('Enter a brand name.'), findsOneWidget);
    },
  );

  testWidgets(
    'Scenario 7: Failure state keeps modal open, preserves typed name, shows concise error',
    (tester) async {
      final throwingRepo = _ThrowingBrandRepository();
      final provider = BrandProvider(repository: throwingRepo);

      await pumpDesktop(
        tester,
        Scaffold(
          body: CreateNewProductView(
            brandProvider: provider,
            businessId: 'business_milan_01',
          ),
        ),
      );

      await tester.tap(find.text('Select brand'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add new brand'), warnIfMissed: false);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Enter brand name'),
        'FailingBrand',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Brand'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Modal stays open
      expect(find.text('Add New Brand'), findsOneWidget);
      // Concise error shown
      expect(
        find.text("We couldn't save this brand. Please try again."),
        findsOneWidget,
      );
      // Typed text preserved
      expect(find.widgetWithText(TextField, 'FailingBrand'), findsOneWidget);
      // No fake local brand in provider
      expect(provider.brands, isEmpty);
    },
  );
}

class _ThrowingBrandRepository extends BrandRepository {
  @override
  Future<Brand> createBrand({required String name, String? businessId}) async {
    throw Exception('Simulated network/database failure');
  }
}
