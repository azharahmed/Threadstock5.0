import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/ai_studio/data/demand_forecast_repository.dart';
import 'package:threadstock/features/ai_studio/presentation/widgets/demand_forecast_view.dart';

void main() {
  group('DemandForecastRepository Readiness Logic', () {
    test(
      'Correctly identifies insufficient data with 1 product and 1 transaction',
      () {
        final summary = DemandForecastSummary(
          state: ForecastUiState.insufficientData,
          businessId: 'test-biz-id',
          locationId: 'test-loc-id',
          readinessConditions: const [
            ForecastReadinessCondition(
              title: 'Product catalog created',
              isMet: false,
              details:
                  '1 product registered (minimum 3 required for trend tracking)',
            ),
            ForecastReadinessCondition(
              title: 'Inventory tracking started',
              isMet: true,
              details: '1 stock balance tracked across 1 location',
            ),
            ForecastReadinessCondition(
              title: 'More sales history needed',
              isMet: false,
              details: '1 demand activity recorded (minimum 14 required)',
            ),
            ForecastReadinessCondition(
              title: 'More demand observations needed',
              isMet: false,
              details:
                  '1 day of historical data (minimum 7 distinct days required)',
            ),
          ],
          productsCount: 1,
          locationsCount: 1,
          demandObservationsCount: 1,
          distinctDaysCount: 1,
        );

        expect(summary.isReady, isFalse);
        expect(summary.forecastedSales, isNull);
        expect(summary.recommendedOrders, isNull);
        expect(summary.highRiskSkus, isNull);
        expect(summary.productsRequiringAttention, isEmpty);
      },
    );
  });

  group('DemandForecastView Rendering & Dummy Data Absence', () {
    testWidgets('Renders empty/readiness state without demo data', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DemandForecastView())),
      );

      await tester.pumpAndSettle();

      // Verify Readiness Banner and Explanations
      expect(find.text('Not enough data yet'), findsOneWidget);
      expect(
        find.text(
          'ThreadStock AI will build demand forecasts once there is enough sales and inventory history to identify reliable trends.',
        ),
        findsOneWidget,
      );

      // Verify Conditions Checklist
      expect(find.text('Product catalog created'), findsOneWidget);
      expect(find.text('Inventory tracking started'), findsOneWidget);
      expect(find.text('More sales history needed'), findsOneWidget);
      expect(find.text('More demand observations needed'), findsOneWidget);

      // Verify Clean KPIs
      expect(find.text('FORECASTED SALES'), findsOneWidget);
      expect(find.text('RECOMMENDED ORDERS'), findsOneWidget);
      expect(find.text('HIGH RISK SKUS'), findsOneWidget);
      expect(find.text('Awaiting sufficient history'), findsWidgets);

      // Verify Clean Chart Container
      expect(find.text('No forecast available yet'), findsOneWidget);

      // Verify Clean Attention Table Container
      expect(find.text('No AI recommendations yet'), findsOneWidget);

      // Verify Clean Forecast Inspector
      expect(find.text('Select a forecast to inspect'), findsOneWidget);
      expect(find.text('No AI insight available yet.'), findsOneWidget);

      // Absolute Verification: Demo data must NOT be present
      expect(find.text('Oxford Linen Shirt'), findsNothing);
      expect(find.text('Silk Evening Dress'), findsNothing);
      expect(find.text('Raw Denim Jeans'), findsNothing);
      expect(find.text('₹6,84,000'), findsNothing);
      expect(find.text('1,420 units'), findsNothing);
      expect(find.text('₹1,82,000'), findsNothing);
      expect(find.text('Prepare PO (80 units)'), findsNothing);
      expect(find.text('TS-10432-W'), findsNothing);
      expect(find.text('SED-16166'), findsNothing);
      expect(find.text('RDJ-22011-L'), findsNothing);
    });
  });
}
