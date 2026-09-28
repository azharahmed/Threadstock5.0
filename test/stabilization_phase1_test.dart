import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/auth/authorization_service.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/core/widgets/safe_image.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/data/inventory_repository.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/inventory/data/supplier_repository.dart';
import 'package:threadstock/features/inventory/domain/models/product.dart';
import 'package:threadstock/features/inventory/domain/models/product_category.dart';
import 'package:threadstock/features/inventory/domain/models/product_inventory_summary.dart';
import 'package:threadstock/features/inventory/domain/models/product_variant.dart';
import 'package:threadstock/features/inventory/domain/models/stock_location.dart';
import 'package:threadstock/features/inventory/domain/models/supplier.dart';
import 'package:threadstock/features/inventory/presentation/widgets/inventory_products_view.dart';
import 'package:threadstock/features/settings/data/business_profile_repository.dart';

class StubProductRepository extends ProductRepository {
  List<Product> products = [];
  @override
  Future<List<Product>> getProducts({String? businessId}) async => products;
}

class StubInventoryRepository extends InventoryRepository {
  Map<String, ProductInventorySummary> summaries = {};
  @override
  Future<Map<String, ProductInventorySummary>> getProductInventorySummaries({
    String? businessId,
    String? locationId,
    List<Product>? preloadedProducts,
  }) async =>
      summaries;
}

class StubSupplierRepository extends SupplierRepository {
  List<Supplier> suppliers = [];
  @override
  Future<List<Supplier>> getSuppliers({String? businessId}) async => suppliers;
}

class StubLocationRepository extends LocationRepository {
  List<StockLocation> locations = [];
  @override
  Future<List<StockLocation>> getLocations({
    String? businessId,
    bool onlyActive = false,
  }) async =>
      locations;
}

class StubCategoryRepository extends CategoryRepository {
  @override
  Future<List<ProductCategory>> getCategories({String? businessId}) async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AuthorizationService.instance.clear();
  });

  group('Stabilization Phase 1 — SafeImage Component', () {
    testWidgets('Renders network image without throwing error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeImage(
              source: 'https://example.com/images/logo.png',
              width: 100,
              height: 100,
            ),
          ),
        ),
      );
      expect(find.byType(SafeImage), findsOneWidget);
    });

    testWidgets('Renders asset image without throwing error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeImage(
              source: 'Assets/logo_mark.png',
              width: 40,
              height: 40,
            ),
          ),
        ),
      );
      expect(find.byType(SafeImage), findsOneWidget);
    });

    testWidgets('Renders fallback widget when source is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeImage(
              source: '',
              fallback: Text('Custom Fallback'),
            ),
          ),
        ),
      );
      expect(find.text('Custom Fallback'), findsOneWidget);
    });
  });

  group('Stabilization Phase 1 — Authorization Context & Legacy Aliases', () {
    test('Owner receives full access across catalog permissions', () {
      final authz = AuthorizationService();
      authz.setPermissionsForTesting(isOwner: true, roleName: 'Owner');

      expect(authz.isOwner, isTrue);
      expect(authz.can('inventory.manage'), isTrue);
      expect(authz.can('inventory.adjust'), isTrue);
      expect(authz.can('sales.create'), isTrue);
      expect(authz.can('settings.manage'), isTrue);
    });

    test('Legacy permission aliases resolve correctly to database codes', () {
      final authz = AuthorizationService();
      authz.setPermissionsForTesting(
        isOwner: false,
        roleName: 'Purchaser',
        permissions: {'purchasing.manage', 'transfers.manage'},
      );

      // Legacy checks must map to canonical permission
      expect(authz.can('purchasing.create'), isTrue);
      expect(authz.can('transfers.create'), isTrue);
      expect(authz.can('transfers.receive'), isTrue);
      expect(authz.can('sales.create'), isFalse);
    });
  });

  group('Stabilization Phase 1 — Business Profile Preferences & Persistence', () {
    test('AppPreferencesService stores and retrieves company logo URL per business', () {
      final prefs = AppPreferencesService.instance;
      const bizId = 'biz_test_stabilization_001';
      const logoUrl = 'https://supabase.co/storage/v1/object/public/product-media/biz/logo.png';

      prefs.setCompanyLogoUrl(bizId, logoUrl);
      expect(prefs.getCompanyLogoUrl(bizId), equals(logoUrl));
      expect(prefs.getCompanyLogoUrl('non_existent_biz'), isNull);
    });

    test('BusinessProfileRepository saveProfile and loadProfile offline/test behavior', () async {
      final repo = BusinessProfileRepository();
      const bizId = 'biz_test_stabilization_001';

      await repo.saveProfile(
        businessId: bizId,
        displayName: 'ThreadStock Silk',
        legalEntityName: 'ThreadStock Silk Co.',
        businessType: 'Boutique',
        registeredCountry: 'IN',
        primaryCurrency: 'INR',
        defaultLanguage: 'en',
        timezone: 'Asia/Kolkata',
        email: 'info@threadstock.silk',
        phone: '+91 9876543210',
        website: 'https://threadstock.silk',
        streetAddress: '12 Weaver Street',
        city: 'Varanasi',
        postalCode: '221001',
      );

      final profile = await repo.loadProfile(businessId: bizId);
      expect(profile['legal_entity_name'], equals('ThreadStock Silk Co.'));
      expect(profile['display_name'], equals('ThreadStock Silk'));
      expect(profile['city'], equals('Varanasi'));
      expect(profile['postal_code'], equals('221001'));
    });
  });

  group('Stabilization Phase 1 — Inventory Products View Supplier & Image Mapping', () {
    testWidgets('Populates supplier name and renders products correctly', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prodRepo = StubProductRepository();
      prodRepo.products = [
        const Product(
          id: 'prod-001',
          businessId: 'test-biz',
          name: 'Mulberry Silk Shirt',
          supplierId: 'sup-001',
          status: 'active',
        ),
        const Product(
          id: 'prod-002',
          businessId: 'test-biz',
          name: 'Cotton Oxford Shirt',
          supplierId: 'sup-002',
          status: 'active',
        ),
      ];

      final suppRepo = StubSupplierRepository();
      suppRepo.suppliers = [
        const Supplier(
          id: 'sup-001',
          businessId: 'test-biz',
          name: 'Royal Silk Mills',
        ),
        const Supplier(
          id: 'sup-002',
          businessId: 'test-biz',
          name: 'Global Cotton Co.',
        ),
      ];

      final invRepo = StubInventoryRepository();
      invRepo.summaries = {
        'prod-001': ProductInventorySummary(
          productId: 'prod-001',
          variantCount: 1,
          availableQty: 50,
          committedQty: 0,
          lowStockThreshold: 10,
          stockStatus: StockStatus.inStock,
          variants: [
            const ProductVariant(
              id: 'var-001',
              productId: 'prod-001',
              sku: 'MSS-001-M',
              costPriceCents: 50000,
              retailPriceCents: 120000,
            ),
          ],
        ),
        'prod-002': ProductInventorySummary(
          productId: 'prod-002',
          variantCount: 1,
          availableQty: 30,
          committedQty: 0,
          lowStockThreshold: 10,
          stockStatus: StockStatus.inStock,
          variants: [
            const ProductVariant(
              id: 'var-002',
              productId: 'prod-002',
              sku: 'COS-002-L',
              costPriceCents: 30000,
              retailPriceCents: 75000,
            ),
          ],
        ),
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InventoryProductsView(
              businessId: 'test-biz',
              productRepository: prodRepo,
              supplierRepository: suppRepo,
              inventoryRepository: invRepo,
              locationRepository: StubLocationRepository(),
              categoryRepository: StubCategoryRepository(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both products initially visible in table and selected product in detail drawer
      expect(find.text('Mulberry Silk Shirt'), findsWidgets);
      expect(find.text('Cotton Oxford Shirt'), findsWidgets);

      // Verify supplier name is displayed
      expect(find.textContaining('Royal Silk Mills'), findsWidgets);

      // Verify supplier dropdown widget exists
      expect(find.text('All Suppliers'), findsWidgets);
    });
  });
}
