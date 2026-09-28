import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/app/shell/app_shell.dart';
import 'package:threadstock/app/widgets/command_palette_dialog.dart';
import 'package:threadstock/app/widgets/search_shortcut_coachmark.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/features/overview/data/dashboard_repository.dart';
import 'package:threadstock/features/overview/presentation/pages/overview_page.dart';

void main() {
  setUp(() {
    AppPreferencesService.resetForTesting();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('1. Search Shortcut Coachmark & Platform Awareness', () {
    testWidgets('Renders Windows shortcut (Ctrl + K) on Windows', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SearchShortcutCoachmark(
                onDismiss: () => dismissed = true,
                autoDismissDuration: const Duration(seconds: 4),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Quick Search'), findsOneWidget);
      expect(find.text('Ctrl'), findsOneWidget);
      expect(find.text('K'), findsOneWidget);
      expect(find.text('⌘'), findsNothing);
      expect(find.textContaining('to search'), findsOneWidget);
      expect(find.textContaining('ThreadStock or ask AI'), findsOneWidget);

      // Dismiss on tap
      await tester.tap(find.byType(SearchShortcutCoachmark));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Renders macOS shortcut (⌘ + K) on macOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SearchShortcutCoachmark(
                onDismiss: () => dismissed = true,
                autoDismissDuration: const Duration(seconds: 4),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Quick Search'), findsOneWidget);
      expect(find.text('⌘'), findsOneWidget);
      expect(find.text('K'), findsOneWidget);
      expect(find.text('Ctrl'), findsNothing);

      await tester.tap(find.byType(SearchShortcutCoachmark));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('Auto dismisses after 4-5 seconds', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;

      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SearchShortcutCoachmark(
                onDismiss: () => dismissed = true,
                autoDismissDuration: const Duration(seconds: 4),
              ),
            ),
          ),
        ),
      );

      expect(dismissed, isFalse);
      await tester.pump(const Duration(seconds: 3));
      expect(dismissed, isFalse);

      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);

      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('2. AppPreferencesService Persistence', () {
    test('Defaults to false and persists to true once seen', () async {
      expect(
        AppPreferencesService.instance.dashboardSearchShortcutHintSeen,
        isFalse,
      );
      await AppPreferencesService.instance.setDashboardSearchShortcutHintSeen(
        true,
      );
      expect(
        AppPreferencesService.instance.dashboardSearchShortcutHintSeen,
        isTrue,
      );
    });
  });

  group('3. Overview / Dashboard Dummy Data Removal & Real Empty States', () {
    testWidgets(
      'Shows fresh setup hero and getting started checklist for fresh account with empty analytics hidden',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        const freshData = DashboardData(
          userName: null,
          locationName: 'Primary Warehouse',
          currencySymbol: '₹',
          todaySalesCents: 0,
          totalStockCount: 0,
          lowStockCount: 0,
          pendingTransfersCount: 0,
          recentActivities: [],
          topCategories: [],
          stockHealth: {},
          salesTrend: [],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OverviewPage(
                dashboardRepository: _MockDashboardRepository(freshData),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Greeting: neutral greeting, NO "Alex"
        expect(find.textContaining('👋'), findsOneWidget);
        expect(find.textContaining('Alex'), findsNothing);

        // Fresh hero subtitle
        expect(
          find.textContaining('Let’s get your store operational.'),
          findsOneWidget,
        );

        // Getting started panel heading and progress
        expect(find.text('Get started with ThreadStock'), findsOneWidget);
        expect(find.text('Store setup  •  1 of 4 ready'), findsOneWidget);

        // Checklist steps
        expect(find.text('Business & location setup'), findsOneWidget);
        expect(find.text('Add your first product'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('fresh_setup_add_product_button')),
          findsOneWidget,
        );
        expect(find.text('Add stock'), findsOneWidget);
        expect(find.text('Add a supplier'), findsOneWidget);
        expect(find.text('Make your first sale'), findsOneWidget);

        // Compact status summary
        expect(find.textContaining('Products:'), findsOneWidget);
        expect(find.textContaining('Stock:'), findsOneWidget);
        expect(find.textContaining('Sales:'), findsOneWidget);

        // Empty analytics widgets must be HIDDEN in fresh mode (Requirement 6)
        expect(find.text('No activity yet'), findsNothing);
        expect(find.text('No sales data yet'), findsNothing);
        expect(find.text('No category data yet'), findsNothing);
        expect(find.text('No inventory data yet'), findsNothing);
        expect(find.text('DEVELOPMENT DIAGNOSTICS'), findsNothing);
      },
    );

    testWidgets('Shows user name in fresh greeting if available', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const namedData = DashboardData(
        userName: 'Aarav',
        locationName: 'Mumbai Studio',
        currencySymbol: '₹',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewPage(
              dashboardRepository: _MockDashboardRepository(namedData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Aarav 👋'), findsOneWidget);
      expect(
        find.textContaining('Let’s get your store operational.'),
        findsOneWidget,
      );
    });

    testWidgets('Preserves normal operational dashboard for mature business with sales', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const matureData = DashboardData(
        userName: 'Aarav',
        locationName: 'Mumbai Studio',
        currencySymbol: '₹',
        todaySalesCents: 150000,
        totalStockCount: 42,
        lowStockCount: 2,
        completedSalesCount: 5,
        salesTrend: [
          {'date': 'Sep 26', 'amount': 1500.0, 'amountCents': 150000},
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OverviewPage(
              dashboardRepository: _MockDashboardRepository(matureData),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Normal dashboard shows greeting with operational update
      expect(find.textContaining('Aarav 👋'), findsOneWidget);
      expect(find.textContaining('Mumbai Studio'), findsOneWidget);

      // Getting started checklist is NOT shown for mature business
      expect(find.text('Get started with ThreadStock'), findsNothing);

      // Normal KPI cards are shown
      expect(find.text("Today's Sales"), findsOneWidget);
      expect(find.text('Total Stock'), findsOneWidget);
    });
  });

  group('4. Command Palette Clean Suggestions & Platform Shortcut', () {
    testWidgets(
      'Contains only generic suggestions and no fake suppliers or products',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.windows;

        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: CommandPaletteDialog())),
        );
        await tester.pumpAndSettle();

        // Generic AI prompts
        expect(find.text('Ask about your inventory'), findsOneWidget);
        expect(find.text('Find a product'), findsOneWidget);
        expect(find.text('Search suppliers'), findsOneWidget);

        // NO fake queries or companies
        expect(find.textContaining('Biella Italian Mill'), findsNothing);
        expect(find.textContaining('Central Warehouse'), findsNothing);
        expect(find.textContaining('Oxford Linen Shirt'), findsNothing);

        // Key chips show Ctrl on Windows
        expect(find.textContaining('Ctrl'), findsWidgets);
        expect(find.textContaining('⌘'), findsNothing);

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('Command Palette shows ⌘ on macOS', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: CommandPaletteDialog())),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('⌘'), findsWidgets);
      expect(find.textContaining('Ctrl'), findsNothing);

      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('5. AppShell Auto-Open Removal & Coachmark Flow', () {
    testWidgets(
      'Does NOT auto-open CommandPaletteDialog when Dashboard loads',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        debugDefaultTargetPlatformOverride = TargetPlatform.windows;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);

        await tester.pumpWidget(
          const MaterialApp(
            home: AppShell(
              initialIndex: 0, // Overview / Dashboard
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // CommandPaletteDialog MUST NOT be open
        expect(find.byType(CommandPaletteDialog), findsNothing);

        // But SearchShortcutCoachmark MUST be visible!
        expect(find.byType(SearchShortcutCoachmark), findsOneWidget);
        expect(find.text('Quick Search'), findsOneWidget);
        expect(find.text('Ctrl'), findsOneWidget);

        // Top bar search field shows Windows shortcut badge
        expect(find.text('Ctrl K'), findsOneWidget);

        // After auto-dismiss duration, coachmark disappears
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        expect(find.byType(SearchShortcutCoachmark), findsNothing);

        // Preference has been marked as seen
        expect(
          AppPreferencesService.instance.dashboardSearchShortcutHintSeen,
          isTrue,
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('Does not show coachmark if already seen', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await AppPreferencesService.instance.setDashboardSearchShortcutHintSeen(
        true,
      );

      await tester.pumpWidget(
        const MaterialApp(home: AppShell(initialIndex: 0)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Neither dialog nor coachmark should be open
      expect(find.byType(CommandPaletteDialog), findsNothing);
      expect(find.byType(SearchShortcutCoachmark), findsNothing);
    });

    testWidgets('Explicitly clicking top search bar opens Command Palette', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await AppPreferencesService.instance.setDashboardSearchShortcutHintSeen(
        true,
      );

      await tester.pumpWidget(
        const MaterialApp(home: AppShell(initialIndex: 0)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CommandPaletteDialog), findsNothing);

      // Tap the top search field
      final searchField = find.byKey(const ValueKey('top_bar_search_action'));
      expect(searchField, findsOneWidget);
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      // Command Palette is now open!
      expect(find.byType(CommandPaletteDialog), findsOneWidget);
    });
  });
}

class _MockDashboardRepository extends DashboardRepository {
  final DashboardData _mockData;
  _MockDashboardRepository(this._mockData);

  @override
  Future<DashboardData> fetchDashboardData({String? businessId}) async =>
      _mockData;
}
