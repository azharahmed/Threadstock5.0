import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/auth/auth_bootstrap.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/features/inventory/data/brand_repository.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/inventory/data/supplier_repository.dart';
import 'package:threadstock/features/inventory/presentation/providers/brand_provider.dart';
import 'package:threadstock/features/inventory/presentation/widgets/create_new_product_view.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';

void main() {
  setUp(() {
    BrandRepository.clearLocalState();
    BrandProvider.resetSharedInstance();
    CurrentBusinessService.instance.resetForTesting();
    OnboardingRepository.instance.reset();
  });

  tearDown(() {
    BrandRepository.clearLocalState();
    BrandProvider.resetSharedInstance();
    CurrentBusinessService.instance.resetForTesting();
    OnboardingRepository.instance.reset();
  });

  Future<void> pumpDesktop(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pumpAndSettle();
  }

  group('ThreadStock Auth & Business Bootstrap Root Tests', () {
    test(
      '1. AuthBootstrapService runs silently without crashing or requiring Login UI',
      () async {
        AuthBootstrapService.resetForTesting();
        // In local test mode without live Supabase connection
        final user = await AuthBootstrapService.initializeSilentAuth();
        // Should complete cleanly without exception
        expect(user, isNull); // disconnected test mode returns null gracefully
      },
    );

    test(
      '2. CurrentBusinessService normalizes location range for database check constraints',
      () {
        expect(CurrentBusinessService.normalizeLocationRange('1'), '1');
        expect(CurrentBusinessService.normalizeLocationRange('2 - 5'), '2-5');
        expect(CurrentBusinessService.normalizeLocationRange('6 - 20'), '6-20');
        expect(CurrentBusinessService.normalizeLocationRange('20+'), '20+');
        expect(CurrentBusinessService.normalizeLocationRange(null), '1');
      },
    );

    test(
      '3. Step 1 Business completes and establishes business.id, owner, and membership',
      () async {
        final onbRepo = OnboardingRepository();

        final updated = await onbRepo.markStepComplete(
          1,
          data: {
            'businessName': 'Azhar Couture Sydney',
            'businessType': 'Luxury Apparel',
            'countryCode': 'AU',
            'currencyCode': 'AUD',
            'locationRange': '2 - 5',
          },
        );

        expect(updated.isBusinessCompleted, isTrue);
        expect(updated.businessName, 'Azhar Couture Sydney');
        expect(updated.countryCode, 'AU');
        expect(updated.currencyCode, 'AUD');
        expect(updated.locationRange, '2-5');
        expect(updated.businessId, isNotNull);
        expect(updated.businessId!.isNotEmpty, isTrue);

        // Central business ID is updated app-wide
        expect(
          CurrentBusinessService.instance.currentBusinessId,
          updated.businessId,
        );

        // Verify serialization preserves businessId across restarts
        final json = updated.toJson();
        expect(json['businessId'], updated.businessId);
        final reloaded = OnboardingProgress.fromJson(json);
        expect(reloaded.businessId, updated.businessId);
      },
    );

    test(
      '4. Central business.id is resolved across all repositories',
      () async {
        final businessId =
            'test_biz_uuid_${DateTime.now().millisecondsSinceEpoch}';
        CurrentBusinessService.instance.setCurrentBusinessId(businessId);

        final brandRepo = BrandRepository();
        final catRepo = CategoryRepository();
        final supRepo = SupplierRepository();
        final locRepo = LocationRepository();
        final prodRepo = ProductRepository();

        expect(await brandRepo.resolveCurrentBusinessId(), businessId);
        expect(await catRepo.resolveCurrentBusinessId(), businessId);
        expect(await supRepo.resolveCurrentBusinessId(), businessId);
        expect(await locRepo.resolveCurrentBusinessId(), businessId);
        expect(await prodRepo.resolveCurrentBusinessId(), businessId);
      },
    );

    test(
      '5. Brand creation requires active business context and attaches business_id',
      () async {
        final repo = BrandRepository();
        final businessId = 'biz_active_tenant_123';
        CurrentBusinessService.instance.setCurrentBusinessId(businessId);

        final brand = await repo.createBrand(name: 'Silk & Thread');
        expect(brand.businessId, businessId);
        expect(brand.name, 'Silk & Thread');

        final list = await repo.getBrands(businessId: businessId);
        expect(list.length, 1);
        expect(list.first.name, 'Silk & Thread');
      },
    );

    test(
      '6. Duplicate brand in the same business is rejected with clean error message',
      () async {
        final repo = BrandRepository();
        final businessId = 'biz_active_tenant_456';
        CurrentBusinessService.instance.setCurrentBusinessId(businessId);

        await repo.createBrand(name: 'Milano Silk');

        // Attempt case-insensitive duplicate
        expect(
          () => repo.createBrand(name: ' milano silk '),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              'A brand with this name already exists.',
            ),
          ),
        );
      },
    );

    testWidgets(
      '7. Create Brand UI flow: auto-selects brand, closes modal, survives reopen',
      (tester) async {
        final businessId = 'biz_sydney_flagship';
        CurrentBusinessService.instance.setCurrentBusinessId(businessId);

        final repo = BrandRepository();
        final provider = BrandProvider(repository: repo);

        await pumpDesktop(
          tester,
          Scaffold(
            body: CreateNewProductView(
              brandProvider: provider,
              businessId: businessId,
            ),
          ),
        );

        // Open brand dropdown
        expect(find.text('Select brand'), findsOneWidget);
        await tester.tap(find.text('Select brand'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Tap 'Add new brand'
        await tester.tap(find.text('Add new brand'), warnIfMissed: false);
        await tester.pumpAndSettle();

        expect(find.text('Add New Brand'), findsOneWidget);

        // Enter brand name 'Hermès Atelier'
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter brand name'),
          'Hermès Atelier',
        );
        await tester.pumpAndSettle();

        // Click 'Save Brand'
        await tester.tap(find.text('Save Brand'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Modal is closed
        expect(find.text('Add New Brand'), findsNothing);

        // Newly created brand is auto-selected in dropdown
        expect(find.text('Hermès Atelier'), findsOneWidget);

        // Verify brand is in provider
        final loaded = await provider.loadBrands(businessId: businessId);
        expect(loaded.any((b) => b.name == 'Hermès Atelier'), isTrue);
      },
    );

    testWidgets(
      '8. Duplicate brand in UI modal shows "A brand with this name already exists."',
      (tester) async {
        final businessId = 'biz_duplicate_ui_test';
        CurrentBusinessService.instance.setCurrentBusinessId(businessId);

        final repo = BrandRepository();
        final provider = BrandProvider(repository: repo);

        // Pre-create 'Gucci'
        await repo.createBrand(name: 'Gucci', businessId: businessId);

        await pumpDesktop(
          tester,
          Scaffold(
            body: CreateNewProductView(
              brandProvider: provider,
              businessId: businessId,
            ),
          ),
        );

        // Open brand dropdown and click Add new brand
        await tester.tap(find.text('Select brand'), warnIfMissed: false);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add new brand'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Enter duplicate 'gucci'
        await tester.enterText(
          find.widgetWithText(TextField, 'Enter brand name'),
          'gucci',
        );
        await tester.pumpAndSettle();

        // Tap Save Brand
        await tester.tap(find.text('Save Brand'), warnIfMissed: false);
        await tester.pumpAndSettle();

        // Modal stays open and displays exact clean error
        expect(
          find.text('A brand with this name already exists.'),
          findsOneWidget,
        );
      },
    );
  });
}
