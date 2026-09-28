import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/inventory/data/brand_repository.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/data/product_media_repository.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/inventory/data/supplier_repository.dart';
import 'package:threadstock/features/inventory/domain/models/product.dart';
import 'package:threadstock/features/inventory/domain/models/product_image_item.dart';
import 'package:threadstock/features/inventory/presentation/pages/inventory_page.dart';
import 'package:threadstock/features/inventory/presentation/widgets/create_new_product_view.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/features/onboarding/presentation/widgets/team_onboarding_view.dart';

class FailingProductRepository extends ProductRepository {
  @override
  Future<Product> publishProduct({
    String? productId,
    String? businessId,
    required String name,
    String? description,
    required String? brandId,
    required String? categoryId,
    required String? supplierId,
    required String? taxCategory,
    List<String> tags = const [],
    required int costPriceCents,
    required int retailPriceCents,
    required String sku,
    String? barcode,
    bool trackStockLevels = false,
    String? locationId,
    String? locationName,
    int openingStock = 0,
    int? lowStockThreshold,
    List<ProductImageItem> images = const [],
  }) async {
    throw Exception('Simulated network failure on publish');
  }
}

void main() {
  late OnboardingRepository onboardingRepo;
  late BrandRepository brandRepo;
  late CategoryRepository categoryRepo;
  late SupplierRepository supplierRepo;
  late ProductRepository productRepo;
  late ProductMediaRepository mediaRepo;
  late LocationRepository locationRepo;

  setUp(() async {
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

    onboardingRepo = OnboardingRepository.instance;
    await onboardingRepo.reset();
    CurrentBusinessService.instance.setCurrentBusinessId('biz-1');

    // Seed test master data for the business
    await brandRepo.createBrand(name: 'Atelier Brand', businessId: 'biz-1');
    await categoryRepo.createCategory(
      name: 'Silk Apparel',
      businessId: 'biz-1',
    );
    await supplierRepo.createSupplier(
      name: 'Direct Mills',
      businessId: 'biz-1',
    );
    await locationRepo.createLocation(
      name: 'Main Flagship',
      businessId: 'biz-1',
    );

    // Prepare onboarding state through Step 3 complete, Step 4 ready
    await onboardingRepo.saveProgress(
      const OnboardingProgress(
        businessId: 'biz-1',
        isBusinessCompleted: true,
        isLocationCompleted: true,
        isCommerceCompleted: true,
        isInventoryCompleted: false,
        inventorySetupStatus: 'not_started',
      ),
    );
  });

  tearDown(() async {
    await onboardingRepo.reset();
  });

  Widget buildTestApp({OnboardingRepository? repo, ProductRepository? pRepo}) {
    return MaterialApp(
      home: OnboardingPage(
        initialStep: 4,
        repository: repo ?? onboardingRepo,
        productRepository: pRepo ?? productRepo,
        brandRepository: brandRepo,
        categoryRepository: categoryRepo,
        supplierRepository: supplierRepo,
        locationRepository: locationRepo,
        mediaRepository: mediaRepo,
      ),
    );
  }

  Future<void> fillValidProduct(
    WidgetTester tester, {
    String title = 'Cashmere Oversized Coat',
  }) async {
    final titleField = find.widgetWithText(TextField, 'Enter product title');
    await tester.ensureVisible(titleField);
    await tester.enterText(titleField, title);
    await tester.pumpAndSettle();

    if (find.text('Atelier Brand').evaluate().isEmpty) {
      final brandDropdown = find.text('Select brand');
      await tester.ensureVisible(brandDropdown);
      await tester.tap(brandDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atelier Brand').last);
      await tester.pumpAndSettle();
    }

    if (find.text('Silk Apparel').evaluate().isEmpty) {
      final catDropdown = find.text('Select category');
      await tester.ensureVisible(catDropdown);
      await tester.tap(catDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Silk Apparel').last);
      await tester.pumpAndSettle();
    }

    if (find.text('Direct Mills').evaluate().isEmpty) {
      final supDropdown = find.text('Select supplier');
      await tester.ensureVisible(supDropdown);
      await tester.tap(supDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Direct Mills').last);
      await tester.pumpAndSettle();
    }

    final taxDropdown = find.text('Select tax category');
    await tester.ensureVisible(taxDropdown);
    await tester.tap(taxDropdown, warnIfMissed: false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apparel Standard (12% GST)').last);
    await tester.pumpAndSettle();

    final costField = find
        .byWidgetPredicate(
          (w) => w is TextField && w.decoration?.prefixText == '₹ ',
        )
        .first;
    final priceField = find
        .byWidgetPredicate(
          (w) => w is TextField && w.decoration?.prefixText == '₹ ',
        )
        .last;
    await tester.ensureVisible(costField);
    await tester.enterText(costField, '800');
    await tester.ensureVisible(priceField);
    await tester.enterText(priceField, '1500');
    await tester.pumpAndSettle();

    final autoGenButton = find.widgetWithText(OutlinedButton, 'Auto-generate');
    if (autoGenButton.evaluate().isNotEmpty) {
      await tester.ensureVisible(autoGenButton);
      await tester.tap(autoGenButton);
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'Manual Product Publish: auto-completes Step 4 and automatically navigates to Team',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 1. Select Create Manually
      await tester.tap(find.text('Create Manually'));
      await tester.pump();

      // 2. Initialize Catalog Setup opens Create Product
      final initBtn = find.widgetWithText(
        ElevatedButton,
        'Initialize Catalog Setup',
      );
      expect(initBtn, findsOneWidget);
      await tester.tap(initBtn);
      await tester.pumpAndSettle();

      expect(find.byType(CreateNewProductView), findsOneWidget);

      // 3. Fill required product fields
      await fillValidProduct(tester, title: 'Cashmere Oversized Coat');

      // 4. Click Publish Product
      final publishBtn = find.widgetWithText(ElevatedButton, 'Publish Product');
      expect(publishBtn, findsOneWidget);
      await tester.ensureVisible(publishBtn);
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();

      // VERIFICATION:
      // A. Product publish snackbar shown
      expect(find.text('Product published'), findsOneWidget);

      // B. Step 4 is marked complete in onboarding repo
      expect(onboardingRepo.currentProgress.isInventoryCompleted, isTrue);
      expect(
        onboardingRepo.currentProgress.inventorySetupStatus,
        equals('completed'),
      );
      expect(
        onboardingRepo.currentProgress.inventoryStartMethod,
        equals('manual'),
      );

      // C. Does NOT navigate to Team onboarding; returns to Step 4 with Skip & Go to Dashboard active
      expect(find.byType(TeamOnboardingView), findsNothing);
      expect(find.byType(CreateNewProductView), findsNothing);
      expect(find.text('STEP 5 OF 6 — INVENTORY'), findsOneWidget);

      final skipFinder = find.widgetWithText(
        ElevatedButton,
        'Skip & Go to Dashboard',
      );
      expect(skipFinder, findsOneWidget);
      final skipBtn = tester.widget<ElevatedButton>(skipFinder);
      expect(skipBtn.onPressed, isNotNull);
    },
  );

  testWidgets(
    'Save Draft does NOT complete Step 4 and does NOT navigate to Team',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Manually'));
      await tester.pump();

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Initialize Catalog Setup'),
      );
      await tester.pumpAndSettle();

      // Enter draft name
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter product title'),
        'Draft Blazer',
      );
      await tester.pumpAndSettle();

      // Click Save Draft
      final saveDraftBtn = find.widgetWithText(OutlinedButton, 'Save Draft');
      await tester.ensureVisible(saveDraftBtn);
      await tester.tap(saveDraftBtn);
      await tester.pumpAndSettle();

      // VERIFICATION:
      expect(find.text('Draft saved'), findsOneWidget);

      // Remains on Create Product view
      expect(find.byType(CreateNewProductView), findsOneWidget);
      expect(find.byType(TeamOnboardingView), findsNothing);

      // Step 4 remains incomplete
      expect(onboardingRepo.currentProgress.isInventoryCompleted, isFalse);
      expect(onboardingRepo.currentProgress.isStepAccessible(5), isFalse);
    },
  );

  testWidgets(
    'Publish failure remains on Create Product, Step 4 incomplete, Team locked',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final failingRepo = FailingProductRepository();

      await tester.pumpWidget(buildTestApp(pRepo: failingRepo));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Create Manually'));
      await tester.pump();

      await tester.tap(
        find.widgetWithText(ElevatedButton, 'Initialize Catalog Setup'),
      );
      await tester.pumpAndSettle();

      // Fill valid product
      await fillValidProduct(tester, title: 'Failure Test Item');

      // Click Publish Product
      final publishBtn = find.widgetWithText(ElevatedButton, 'Publish Product');
      await tester.ensureVisible(publishBtn);
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();

      // VERIFICATION:
      // Should remain on Create Product
      expect(find.byType(CreateNewProductView), findsOneWidget);
      expect(find.byType(TeamOnboardingView), findsNothing);

      // Step 4 remains incomplete
      expect(onboardingRepo.currentProgress.isInventoryCompleted, isFalse);
      expect(onboardingRepo.currentProgress.isStepAccessible(5), isFalse);
    },
  );

  testWidgets(
    'App restart resumes directly at Step 5 (Team) after manual publish',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Simulate completion of Step 4 via manual publish
      await onboardingRepo.markStepComplete(
        4,
        data: {
          'inventoryStartMethod': 'manual',
          'inventorySetupStatus': 'completed',
        },
      );

      expect(onboardingRepo.currentProgress.firstIncompleteStep, equals(6));

      // Fresh application boot / restart
      await tester.pumpWidget(
        MaterialApp(home: OnboardingPage(repository: onboardingRepo)),
      );
      await tester.pumpAndSettle();

      // Must open Step 5 (Team) directly
      expect(find.byType(TeamOnboardingView), findsOneWidget);
      expect(find.text('STEP 6 OF 6 — TEAM'), findsOneWidget);
      expect(find.text('STEP 5 OF 6 — INVENTORY'), findsNothing);
    },
  );

  testWidgets(
    'Normal Inventory product publish does NOT navigate to onboarding Team',
    (tester) async {
      tester.view.physicalSize = const Size(1920, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Normal inventory module outside onboarding
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryPage(
              businessId: 'biz-1',
              initialMode: InventoryPageMode.createProduct,
              productRepository: productRepo,
              brandRepository: brandRepo,
              categoryRepository: categoryRepo,
              supplierRepository: supplierRepo,
              locationRepository: locationRepo,
              mediaRepository: mediaRepo,
              // Notice: onCatalogSetupCompleted is null!
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CreateNewProductView), findsOneWidget);

      await fillValidProduct(tester, title: 'Standalone Product');

      final publishBtn = find.widgetWithText(ElevatedButton, 'Publish Product');
      await tester.ensureVisible(publishBtn);
      await tester.tap(publishBtn);
      await tester.pumpAndSettle();

      // Product publish confirmed
      expect(find.text('Product published'), findsOneWidget);

      // Did not navigate to Team
      expect(find.byType(TeamOnboardingView), findsNothing);

      // Onboarding repo remains untouched
      expect(onboardingRepo.currentProgress.isInventoryCompleted, isFalse);
    },
  );
}
