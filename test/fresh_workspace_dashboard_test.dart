import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/features/business/domain/models/business.dart';
import 'package:threadstock/features/inventory/domain/inventory_change_notifier.dart';
import 'package:threadstock/features/overview/data/dashboard_repository.dart';
import 'package:threadstock/features/overview/presentation/pages/overview_page.dart';
import 'package:threadstock/features/overview/presentation/widgets/live_dashboard_header.dart';
import 'package:threadstock/features/overview/presentation/widgets/live_date_time_text.dart';

class _TestMockDashboardRepository extends DashboardRepository {
  DashboardData mockData;
  _TestMockDashboardRepository(this.mockData);

  @override
  Future<DashboardData> fetchDashboardData({String? businessId}) async {
    return mockData;
  }
}

void main() {
  setUp(() {
    CurrentBusinessService.instance.setCurrentBusiness(
      Business(
        id: 'biz_launchgrid',
        ownerUserId: 'user_123',
        legalName: 'LaunchGrid',
        businessType: 'Retail Fashion',
        countryCode: 'IND',
        currencyCode: 'INR',
        locationRange: 'single',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  group('THREADSTOCK FRESH WORKSPACE DASHBOARD TESTS', () {
    testWidgets('1. Fresh business: only useful setup UI, Add Product is prominent, empty analytics hidden', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const freshData = DashboardData(
        userName: 'Azhar',
        locationName: 'Main Store',
        currencySymbol: '₹',
        totalProductsCount: 0,
        totalStockCount: 0,
        todaySalesCents: 0,
        completedSalesCount: 0,
        supplierCount: 0,
      );

      final repo = _TestMockDashboardRepository(freshData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewPage(dashboardRepository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fresh Hero greeting & live date/time
      expect(find.textContaining('Azhar 👋'), findsOneWidget);
      expect(find.byType(LiveDashboardHeader), findsOneWidget);
      expect(find.byType(LiveDateTimeText), findsOneWidget);
      expect(find.textContaining('LaunchGrid is ready.'), findsOneWidget);
      expect(find.textContaining('Let’s get your store operational.'), findsOneWidget);

      // Getting Started Panel
      expect(find.text('GET STARTED'), findsOneWidget);
      expect(find.text('Get started with ThreadStock'), findsOneWidget);
      expect(find.text('Store setup  •  1 of 4 ready'), findsOneWidget);

      // Checklist steps
      expect(find.text('Business & location setup'), findsOneWidget);
      expect(find.text('Add your first product'), findsOneWidget);
      expect(find.byKey(const ValueKey('fresh_setup_add_product_button')), findsOneWidget);
      expect(find.text('Add stock'), findsOneWidget);
      expect(find.text('Add a supplier'), findsOneWidget);
      expect(find.text('Make your first sale'), findsOneWidget);

      // Add Product CTA is prominent; Add Stock CTA is not shown until product exists
      expect(find.byKey(const ValueKey('fresh_setup_add_stock_button')), findsNothing);

      // Empty analytics panels are completely hidden
      expect(find.text('Sales Trend'), findsNothing);
      expect(find.text('Top Categories'), findsNothing);
      expect(find.text('Stock Health'), findsNothing);
      expect(find.text('ThreadStock AI'), findsNothing);
      expect(find.text('No sales data yet'), findsNothing);
      expect(find.text('No category data yet'), findsNothing);
      expect(find.text('No inventory data yet'), findsNothing);
      expect(find.text('No activity yet'), findsNothing);

      // Development diagnostics removed
      expect(find.text('DEVELOPMENT DIAGNOSTICS'), findsNothing);
    });

    testWidgets('2. Product created: Product marked checked, Add Stock becomes primary CTA', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const productCreatedData = DashboardData(
        userName: 'Azhar',
        locationName: 'Main Store',
        currencySymbol: '₹',
        totalProductsCount: 1,
        firstProductId: 'prod_101',
        firstProductName: 'Silk Oxford Shirt',
        totalStockCount: 0,
        todaySalesCents: 0,
        completedSalesCount: 0,
        supplierCount: 0,
      );

      final repo = _TestMockDashboardRepository(productCreatedData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewPage(dashboardRepository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Progress advances to 2 of 4 ready
      expect(find.text('Store setup  •  2 of 4 ready'), findsOneWidget);

      // Product step completed subtitle
      expect(find.text('1 product created.'), findsOneWidget);
      expect(find.byKey(const ValueKey('fresh_setup_add_product_button')), findsNothing);

      // Add Stock is now primary CTA
      expect(find.byKey(const ValueKey('fresh_setup_add_stock_button')), findsOneWidget);
    });

    testWidgets('3. Stock added: Add Stock checked, Start a Sale becomes primary CTA', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const stockAddedData = DashboardData(
        userName: 'Azhar',
        locationName: 'Main Store',
        currencySymbol: '₹',
        totalProductsCount: 1,
        firstProductId: 'prod_101',
        firstProductName: 'Silk Oxford Shirt',
        totalStockCount: 25,
        todaySalesCents: 0,
        completedSalesCount: 0,
        supplierCount: 0,
      );

      final repo = _TestMockDashboardRepository(stockAddedData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewPage(dashboardRepository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Progress advances to 3 of 4 ready
      expect(find.text('Store setup  •  3 of 4 ready'), findsOneWidget);

      // Stock step marked complete with 25 units
      expect(find.text('25 units recorded in inventory.'), findsOneWidget);
      expect(find.byKey(const ValueKey('fresh_setup_add_stock_button')), findsNothing);

      // Start a Sale is now primary CTA
      expect(find.byKey(const ValueKey('fresh_setup_start_sale_button')), findsOneWidget);
    });

    testWidgets('4. Supplier step is optional and can be skipped without blocking sales or setup', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const freshData = DashboardData(
        userName: 'Azhar',
        locationName: 'Main Store',
        currencySymbol: '₹',
        totalProductsCount: 0,
        totalStockCount: 0,
        todaySalesCents: 0,
        completedSalesCount: 0,
        supplierCount: 0,
      );

      final repo = _TestMockDashboardRepository(freshData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewPage(dashboardRepository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Supplier step shows "Optional" badge and [Skip] button
      expect(find.text('Optional'), findsOneWidget);
      expect(find.byKey(const ValueKey('fresh_setup_skip_supplier_button')), findsOneWidget);
      expect(find.byKey(const ValueKey('fresh_setup_add_supplier_button')), findsOneWidget);

      // Click Skip
      await tester.tap(find.byKey(const ValueKey('fresh_setup_skip_supplier_button')));
      await tester.pumpAndSettle();

      // Marked as skipped, buttons removed
      expect(find.text('Optional step skipped.'), findsOneWidget);
      expect(find.byKey(const ValueKey('fresh_setup_skip_supplier_button')), findsNothing);
    });

    testWidgets('5. First Sale CTA when 0 stock: shows Add stock before starting a sale notice', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const noStockData = DashboardData(
        userName: 'Azhar',
        locationName: 'Main Store',
        currencySymbol: '₹',
        totalProductsCount: 1,
        totalStockCount: 0, // No stock!
        todaySalesCents: 0,
        completedSalesCount: 0,
      );

      final repo = _TestMockDashboardRepository(noStockData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewPage(dashboardRepository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Attempt to tap Start a Sale when stock is 0
      await tester.tap(find.byKey(const ValueKey('fresh_setup_start_sale_button')));
      await tester.pumpAndSettle();

      // Should display notice dialog preventing dead-end sales flow
      expect(find.text('Add stock before starting a sale.'), findsOneWidget);
      expect(find.byKey(const ValueKey('notice_add_stock_button')), findsOneWidget);
    });

    testWidgets('6. First completed sale: transitions into normal operational dashboard', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const matureData = DashboardData(
        userName: 'Azhar',
        locationName: 'Main Store',
        currencySymbol: '₹',
        totalProductsCount: 3,
        totalStockCount: 45,
        todaySalesCents: 249000,
        completedSalesCount: 1,
        salesTrend: [
          {'date': 'Sep 28', 'amount': 2490.0, 'amountCents': 249000},
        ],
        recentActivities: [
          {
            'id': 'sale_1',
            'type': 'sale',
            'title': 'Sale completed',
            'subtitle': 'TS-001 • ₹2,490',
            'detail': 'Azhar • Main Store',
            'time': 'Just now',
            'icon': Icons.verified_outlined,
            'iconColor': Color(0xFF059669),
            'iconBg': Color(0xFFD1FAE5),
          }
        ],
      );

      final repo = _TestMockDashboardRepository(matureData);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewPage(dashboardRepository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Getting started setup checklist is NO longer shown
      expect(find.text('Get started with ThreadStock'), findsNothing);

      // Normal operational dashboard is shown
      expect(find.text("Today's Sales"), findsOneWidget);
      expect(find.text('₹2490'), findsOneWidget);
      expect(find.text('Total Stock'), findsOneWidget);
      expect(find.text('45'), findsWidgets);
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Sale completed'), findsOneWidget);
    });

    testWidgets('7. Real-time refresh: Inventory mutation immediately reloads dashboard data without app restart', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var fetchCount = 0;
      final repo = _CountingRepo(() => fetchCount++);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewPage(dashboardRepository: repo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fetchCount, 1);

      // Simulate real product/inventory mutation
      InventoryChangeNotifier.instance.notifyInventoryChanged();
      await tester.pumpAndSettle();

      // Verified: immediate reactive refresh without restart
      expect(fetchCount, 2);
    });
  });
}

class _CountingRepo extends DashboardRepository {
  final VoidCallback onFetch;
  _CountingRepo(this.onFetch);

  @override
  Future<DashboardData> fetchDashboardData({String? businessId}) async {
    onFetch();
    return const DashboardData(
      userName: 'Azhar',
      currencySymbol: '₹',
      totalProductsCount: 0,
      totalStockCount: 0,
      todaySalesCents: 0,
    );
  }
}
