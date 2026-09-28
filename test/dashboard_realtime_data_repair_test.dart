import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/features/business/domain/models/business.dart';
import 'package:threadstock/features/inventory/data/product_repository.dart';
import 'package:threadstock/features/inventory/domain/inventory_change_notifier.dart';
import 'package:threadstock/features/inventory/domain/models/product.dart';
import 'package:threadstock/features/overview/data/dashboard_repository.dart';
import 'package:threadstock/features/overview/presentation/pages/overview_page.dart';
import 'package:threadstock/features/sales/data/sales_repository.dart';
import 'package:threadstock/features/sales/domain/models/sale.dart';
import 'package:threadstock/features/sales/domain/models/sale_item.dart';

void main() {
  const businessId = '863b4f7b-7a8e-4ffa-a4aa-e4cd453613af';
  const otherBusinessId = '970c80ef-b46c-4522-b38d-f63a30d17c01';
  const locationId = 'loc_stock_001';

  setUp(() {
    AppPreferencesService.resetForTesting();
    SalesRepository.clearLocalSalesForTesting();
    ProductRepository.clearLocalState();
    CurrentBusinessService.instance.clear();
    CurrentBusinessService.instance.setCurrentBusiness(
      Business(
        id: businessId,
        ownerUserId: 'user_azhar_001',
        legalName: 'LaunchGrid',
        businessType: 'Retail',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
    );
    CurrentBusinessService.instance.setCurrentLocationId(null);
  });

  tearDown(() async {
    AppPreferencesService.resetForTesting();
    await AppPreferencesService.instance.setCurrentBusinessId(null);
    SalesRepository.clearLocalSalesForTesting();
    ProductRepository.clearLocalState();
    CurrentBusinessService.instance.clear();
  });

  group('THREADSTOCK DASHBOARD DATA REPAIR TESTS', () {
    test('1. Today\'s Sales calculated using business timezone and excludes non-completed sales', () async {
      final repo = DashboardRepository();

      // India is GMT+5:30
      final nowUtc = DateTime.now().toUtc();
      final nowIST = nowUtc.add(const Duration(hours: 5, minutes: 30));

      // Sale 1: Completed today in business local time (e.g. ₹4,455 = 445500 paise)
      SalesRepository.addLocalSaleForTesting(
        Sale(
          id: 'sale_1',
          businessId: businessId,
          locationId: locationId,
          saleNumber: 'TS-2026-000001',
          status: 'completed',
          subtotalMinor: 445500,
          totalMinor: 445500,
          currencyCode: 'INR',
          completedAt: nowUtc,
          createdAt: nowUtc,
          items: const [
            SaleItem(
              id: 'item_1',
              saleId: 'sale_1',
              productId: 'prod_2',
              skuSnapshot: 'TS-PROD-2',
              productNameSnapshot: 'Product 2',
              quantity: 3,
              unitPriceMinor: 148500,
              taxableAmountMinor: 445500,
              lineTotalMinor: 445500,
            ),
          ],
        ),
      );

      // Sale 2: Held sale today (must NOT be counted in Today's Sales)
      SalesRepository.addLocalSaleForTesting(
        Sale(
          id: 'sale_held',
          businessId: businessId,
          locationId: locationId,
          saleNumber: 'TS-2026-000002',
          status: 'held',
          subtotalMinor: 200000,
          totalMinor: 200000,
          currencyCode: 'INR',
          createdAt: nowUtc,
        ),
      );

      // Sale 3: Completed yesterday in business local time (must NOT be counted in Today's Sales)
      final yesterdayIST = nowIST.subtract(const Duration(days: 1));
      final yesterdayUtc = yesterdayIST.subtract(const Duration(hours: 5, minutes: 30));
      SalesRepository.addLocalSaleForTesting(
        Sale(
          id: 'sale_yesterday',
          businessId: businessId,
          locationId: locationId,
          saleNumber: 'TS-2026-000000',
          status: 'completed',
          subtotalMinor: 100000,
          totalMinor: 100000,
          currencyCode: 'INR',
          completedAt: yesterdayUtc,
          createdAt: yesterdayUtc,
        ),
      );

      // Sale 4: Other business's completed sale today (cross-business isolation)
      SalesRepository.addLocalSaleForTesting(
        Sale(
          id: 'sale_other_biz',
          businessId: otherBusinessId,
          locationId: locationId,
          saleNumber: 'TS-OTHER-0001',
          status: 'completed',
          subtotalMinor: 999900,
          totalMinor: 999900,
          currencyCode: 'INR',
          completedAt: nowUtc,
          createdAt: nowUtc,
        ),
      );

      final data = await repo.fetchDashboardData(businessId: businessId);

      // Only TS-2026-000001 (₹4,455) should be in today's sales
      expect(data.todaySalesCents, 445500);
      expect(data.currencySymbol, '₹');
    });

    test('2. Sales Graph includes real continuous daily buckets including zero-value days', () async {
      final repo = DashboardRepository();
      final nowUtc = DateTime.now().toUtc();

      // Today's sale
      SalesRepository.addLocalSaleForTesting(
        Sale(
          id: 'sale_today',
          businessId: businessId,
          locationId: locationId,
          saleNumber: 'TS-2026-000001',
          status: 'completed',
          subtotalMinor: 445500,
          totalMinor: 445500,
          currencyCode: 'INR',
          completedAt: nowUtc,
          createdAt: nowUtc,
        ),
      );

      repo.chartRange = '7D';
      final data = await repo.fetchDashboardData(businessId: businessId);

      expect(data.salesTrend.length, 7);
      // Last point is today, must have amount 4455.0
      expect(data.salesTrend.last['amount'], 4455.0);
      expect(data.salesTrend.last['amountCents'], 445500);

      // Previous days must be 0.0 to keep the series continuous
      for (int i = 0; i < 6; i++) {
        expect(data.salesTrend[i]['amount'], 0.0);
      }
      expect(data.hasSalesData, isTrue);
    });

    test('3. Recent Activity displays completed sale TS-2026-000001 with details', () async {
      final repo = DashboardRepository();
      final nowUtc = DateTime.now().toUtc();

      SalesRepository.addLocalSaleForTesting(
        Sale(
          id: 'sale_1',
          businessId: businessId,
          locationId: locationId,
          saleNumber: 'TS-2026-000001',
          status: 'completed',
          subtotalMinor: 445500,
          totalMinor: 445500,
          currencyCode: 'INR',
          completedAt: nowUtc,
          createdAt: nowUtc,
        ),
      );

      final data = await repo.fetchDashboardData(businessId: businessId);

      expect(data.hasActivity, isTrue);
      expect(data.recentActivities.isNotEmpty, isTrue);

      final act = data.recentActivities.first;
      expect(act['title'], 'Sale completed');
      expect(act['subtitle'], contains('TS-2026-000001'));
      expect(act['subtitle'], contains('₹4455'));
    });

    test('4. Pending Transfers displays "—" for honest unavailable state when backend is not implemented', () async {
      final repo = DashboardRepository();
      final data = await repo.fetchDashboardData(businessId: businessId);

      expect(data.pendingTransfersCount, isNull);
      expect(data.resolvedPendingTransfers, '—');
    });

    test('5. Low-Stock calculation requires track_stock_levels=true, threshold!=null, and 0 < qty <= threshold', () async {
      // Product A: Tracked, threshold = 10, available = 5 -> LOW STOCK
      // Product B: Tracked, threshold = NULL, available = 2 -> NOT LOW STOCK (no threshold)
      // Product C: Untracked (track=false), threshold = 10, available = 3 -> NOT LOW STOCK (untracked)
      // Product D: Tracked, threshold = 10, available = 97 -> IN STOCK (not low stock)
      // Product E: Other business product (tracked, threshold = 10, available = 2) -> NOT COUNTED (tenant isolation)

      ProductRepository.addFallbackProduct(const Product(
        id: 'prod_a',
        businessId: businessId,
        name: 'Product A',
        status: 'active',
        trackStockLevels: true,
        lowStockThreshold: 10,
      ));
      ProductRepository.setFallbackInventory('prod_a', 5);

      ProductRepository.addFallbackProduct(const Product(
        id: 'prod_b',
        businessId: businessId,
        name: 'Product B',
        status: 'active',
        trackStockLevels: true,
        lowStockThreshold: null, // threshold is NULL
      ));
      ProductRepository.setFallbackInventory('prod_b', 2);

      ProductRepository.addFallbackProduct(const Product(
        id: 'prod_c',
        businessId: businessId,
        name: 'Product C',
        status: 'active',
        trackStockLevels: false, // tracking disabled
        lowStockThreshold: 10,
      ));
      ProductRepository.setFallbackInventory('prod_c', 3);

      ProductRepository.addFallbackProduct(const Product(
        id: 'prod_d',
        businessId: businessId,
        name: 'Product 2',
        status: 'active',
        trackStockLevels: true,
        lowStockThreshold: 10,
      ));
      ProductRepository.setFallbackInventory('prod_d', 97);

      ProductRepository.addFallbackProduct(const Product(
        id: 'prod_other',
        businessId: otherBusinessId,
        name: 'Competitor Product',
        status: 'active',
        trackStockLevels: true,
        lowStockThreshold: 10,
      ));
      ProductRepository.setFallbackInventory('prod_other', 2);

      final repo = DashboardRepository();
      final data = await repo.fetchDashboardData(businessId: businessId);

      // Only prod_a (qty 5 <= 10) meets all 3 criteria: tracked, threshold!=null, and 0 < qty <= threshold
      expect(data.lowStockCount, 1);
    });

    testWidgets('6. UI Widget Test: KPI cards show exact values, SKUs label, tooltips, and real graph', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const testData = DashboardData(
        userName: 'Azhar',
        locationName: 'Stock location',
        currencySymbol: '₹',
        todaySalesCents: 445500, // ₹4,455
        totalStockCount: 97, // 97 available
        lowStockCount: 0,
        pendingTransfersCount: null, // '—'
        pendingTransfersDisplay: '—',
        recentActivities: [
          {
            'id': 'sale_1',
            'type': 'sale',
            'title': 'Sale completed',
            'subtitle': 'TS-2026-000001 • ₹4,455',
            'detail': 'Azhar • Stock location',
            'time': 'Just now',
            'icon': Icons.verified_outlined,
            'iconColor': Color(0xFF059669),
            'iconBg': Color(0xFFD1FAE5),
          }
        ],
        salesTrend: [
          {'date': 'Sep 20', 'amount': 0.0, 'amountCents': 0},
          {'date': 'Sep 21', 'amount': 0.0, 'amountCents': 0},
          {'date': 'Sep 22', 'amount': 0.0, 'amountCents': 0},
          {'date': 'Sep 23', 'amount': 0.0, 'amountCents': 0},
          {'date': 'Sep 24', 'amount': 0.0, 'amountCents': 0},
          {'date': 'Sep 25', 'amount': 0.0, 'amountCents': 0},
          {'date': 'Sep 26', 'amount': 4455.0, 'amountCents': 445500},
        ],
        stockHealth: {'inStock': 97, 'lowStock': 0, 'outOfStock': 0},
        stockHealthRatios: {'inStock': 1.0, 'lowStock': 0.0, 'outOfStock': 0.0},
        stockHealthPercentages: {'inStock': '100%', 'lowStock': '0%', 'outOfStock': '0%'},
      );

      final mockRepo = _RepairTestMockRepo(testData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewPage(dashboardRepository: mockRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Today's Sales = ₹4455 (NOT ₹0!)
      expect(find.text('₹4455'), findsOneWidget);

      // 2. Total Stock = 97
      expect(find.text('97'), findsWidgets);

      // 3. Low-Stock SKUs = 0 SKUs (NOT '0 styles'!)
      expect(find.text('0 SKUs'), findsOneWidget);
      expect(find.textContaining('styles'), findsNothing);

      // 4. Pending Transfers = '—' (honest unavailable state)
      expect(find.text('—'), findsOneWidget);

      // 5. Tooltips on all 4 KPI cards
      expect(
        find.byWidgetPredicate((w) =>
            w is Tooltip &&
            w.message == 'Sum of completed sales for today at the selected business/location.'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) =>
            w is Tooltip &&
            w.message == 'Sellable units currently available across tracked inventory.'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) =>
            w is Tooltip &&
            w.message == 'Tracked SKUs at or below their configured low-stock threshold.'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) =>
            w is Tooltip &&
            w.message == 'Transfers awaiting completion.'),
        findsOneWidget,
      );

      // 6. Recent Activity includes TS-2026-000001
      expect(find.text('Sale completed'), findsOneWidget);
      expect(find.text('TS-2026-000001 • ₹4,455'), findsOneWidget);
      expect(find.text('Azhar • Stock location'), findsOneWidget);

      // 7. Sales graph includes continuous date labels
      expect(find.text('Sep 20'), findsOneWidget);
      expect(find.text('Sep 26'), findsOneWidget);
    });

    testWidgets('7. Mutation & Location Refresh: Dashboard reloads on inventory mutation without restart', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var fetchCount = 0;
      final reactiveRepo = _CountingMockRepo(() {
        fetchCount++;
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewPage(dashboardRepository: reactiveRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fetchCount, 1);

      // Trigger mutation via InventoryChangeNotifier (as happens on complete_sale, adjust_stock, etc.)
      InventoryChangeNotifier.instance.notifyInventoryChanged();
      await tester.pumpAndSettle();

      expect(fetchCount, 2);

      // Trigger location switch via CurrentBusinessService
      CurrentBusinessService.instance.setCurrentLocationId('loc_new_999');
      await tester.pumpAndSettle();

      expect(fetchCount, 3);
    });
  });
}

class _RepairTestMockRepo extends DashboardRepository {
  final DashboardData data;
  _RepairTestMockRepo(this.data);

  @override
  Future<DashboardData> fetchDashboardData({String? businessId}) async => data;
}

class _CountingMockRepo extends DashboardRepository {
  final VoidCallback onFetch;
  _CountingMockRepo(this.onFetch);

  @override
  Future<DashboardData> fetchDashboardData({String? businessId}) async {
    onFetch();
    return const DashboardData(
      userName: 'Azhar',
      locationName: 'Stock location',
      currencySymbol: '₹',
      todaySalesCents: 445500,
      totalStockCount: 97,
      lowStockCount: 0,
      pendingTransfersDisplay: '—',
      salesTrend: [
        {'date': 'Sep 26', 'amount': 4455.0, 'amountCents': 445500},
      ],
    );
  }
}
