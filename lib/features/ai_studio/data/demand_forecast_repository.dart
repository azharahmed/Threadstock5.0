import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/business/current_business_service.dart';
import '../presentation/widgets/demand_forecast_view.dart';

enum ForecastUiState {
  loading,
  insufficientData,
  ready,
  generating,
  loaded,
  error,
}

class ForecastReadinessCondition {
  final String title;
  final bool isMet;
  final String details;

  const ForecastReadinessCondition({
    required this.title,
    required this.isMet,
    required this.details,
  });
}

class DemandForecastSummary {
  final ForecastUiState state;
  final String? businessId;
  final String? locationId;
  final int productsCount;
  final int variantsCount;
  final int locationsCount;
  final int inventoryBalancesCount;
  final int ledgerRowsCount;
  final int demandObservationsCount;
  final int distinctDaysCount;
  final List<ForecastReadinessCondition> readinessConditions;
  final bool isReady;
  final String? forecastedSales;
  final String? recommendedOrders;
  final String? highRiskSkus;
  final List<DemandForecastProductRow> productsRequiringAttention;
  final DemandForecastProductRow? selectedProduct;
  final String? aiInsight;
  final String? errorMessage;

  const DemandForecastSummary({
    required this.state,
    this.businessId,
    this.locationId,
    this.productsCount = 0,
    this.variantsCount = 0,
    this.locationsCount = 0,
    this.inventoryBalancesCount = 0,
    this.ledgerRowsCount = 0,
    this.demandObservationsCount = 0,
    this.distinctDaysCount = 0,
    this.readinessConditions = const [],
    this.isReady = false,
    this.forecastedSales,
    this.recommendedOrders,
    this.highRiskSkus,
    this.productsRequiringAttention = const [],
    this.selectedProduct,
    this.aiInsight,
    this.errorMessage,
  });
}

class DemandForecastRepository {
  final SupabaseClient? client;

  DemandForecastRepository({this.client});

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<DemandForecastSummary> loadDemandForecast({String? locationId}) async {
    final sb = _resolvedClient;
    final businessId = CurrentBusinessService.instance.currentBusinessId;
    if (sb == null || businessId == null || businessId.isEmpty) {
      return _buildInsufficientState(
        businessId: businessId,
        locationId: locationId,
        productsCount: 0,
        variantsCount: 0,
        locationsCount: 0,
        balancesCount: 0,
        ledgerCount: 0,
        demandObservationsCount: 0,
        distinctDaysCount: 0,
      );
    }

    try {
      // 1. Fetch real products for current business
      final productsRes = await sb
          .from('products')
          .select('id, name, status')
          .eq('business_id', businessId);
      final productsList = (productsRes as List);
      final productsCount = productsList.length;

      // 2. Fetch variants
      int variantsCount = 0;
      if (productsCount > 0) {
        final productIds = productsList.map((p) => p['id'] as String).toList();
        final variantsRes = await sb
            .from('product_variants')
            .select('id, product_id, sku, retail_price_cents')
            .inFilter('product_id', productIds);
        variantsCount = (variantsRes as List).length;
      }

      // 3. Fetch locations
      final locationsRes = await sb
          .from('locations')
          .select('id, name')
          .eq('business_id', businessId);
      final locationsCount = (locationsRes as List).length;

      // 4. Fetch inventory balances
      var balancesQuery = sb
          .from('inventory_balances')
          .select('id, location_id, variant_id, available_qty')
          .eq('business_id', businessId);
      if (locationId != null && locationId != 'none' && locationId.isNotEmpty) {
        balancesQuery = balancesQuery.eq('location_id', locationId);
      }
      final balancesRes = await balancesQuery;
      final balancesCount = (balancesRes as List).length;

      // 5. Fetch inventory ledger transactions (demand events)
      var ledgerQuery = sb
          .from('inventory_ledger')
          .select('id, event_type, quantity_delta, occurred_at')
          .eq('business_id', businessId);
      if (locationId != null && locationId != 'none' && locationId.isNotEmpty) {
        ledgerQuery = ledgerQuery.eq('location_id', locationId);
      }
      final ledgerRes = await ledgerQuery;
      final ledgerList = (ledgerRes as List);
      final ledgerCount = ledgerList.length;

      // Identify real demand observations (sales or stock-outs)
      final demandTx = ledgerList.where((row) {
        final event = row['event_type'] as String?;
        return event == 'sale' || event == 'stock_out';
      }).toList();
      final demandObservationsCount = demandTx.length;

      // Calculate distinct dates of sales/demand activity
      final distinctDays = <String>{};
      for (final tx in demandTx) {
        final occurredAt = tx['occurred_at'] as String?;
        if (occurredAt != null && occurredAt.length >= 10) {
          distinctDays.add(occurredAt.substring(0, 10));
        }
      }
      final distinctDaysCount = distinctDays.length;

      return _buildInsufficientState(
        businessId: businessId,
        locationId: locationId,
        productsCount: productsCount,
        variantsCount: variantsCount,
        locationsCount: locationsCount,
        balancesCount: balancesCount,
        ledgerCount: ledgerCount,
        demandObservationsCount: demandObservationsCount,
        distinctDaysCount: distinctDaysCount,
      );
    } catch (e, st) {
      debugPrint(
        '[DemandForecastRepository] Error loading real forecast data: $e\n$st',
      );
      return DemandForecastSummary(
        state: ForecastUiState.error,
        businessId: businessId,
        locationId: locationId,
        errorMessage: 'Unable to query forecast parameters: $e',
      );
    }
  }

  DemandForecastSummary _buildInsufficientState({
    required String? businessId,
    required String? locationId,
    required int productsCount,
    required int variantsCount,
    required int locationsCount,
    required int balancesCount,
    required int ledgerCount,
    required int demandObservationsCount,
    required int distinctDaysCount,
  }) {
    // Deterministic readiness rules:
    // 1. Catalog created with at least 3 distinct active products
    final catalogReady = productsCount >= 3;
    // 2. Inventory tracking active across at least 1 real location and 1 balance
    final inventoryReady = locationsCount >= 1 && balancesCount >= 1;
    // 3. At least 14 historical sales / demand observations
    final salesHistoryReady = demandObservationsCount >= 14;
    // 4. Demand timeline spanning at least 7 distinct days
    final timelineReady = distinctDaysCount >= 7;

    final isReady =
        catalogReady && inventoryReady && salesHistoryReady && timelineReady;

    final conditions = [
      ForecastReadinessCondition(
        title: 'Product catalog created',
        isMet: productsCount > 0,
        details: productsCount > 0
            ? '$productsCount product${productsCount == 1 ? '' : 's'} being tracked'
            : 'Add products to begin tracking demand',
      ),
      ForecastReadinessCondition(
        title: 'Inventory tracking started',
        isMet: inventoryReady,
        details: inventoryReady
            ? '$balancesCount stock record${balancesCount == 1 ? '' : 's'} across $locationsCount location${locationsCount == 1 ? '' : 's'}'
            : 'Stock balance records needed',
      ),
      ForecastReadinessCondition(
        title: 'More sales history needed',
        isMet: salesHistoryReady,
        details: salesHistoryReady
            ? '$demandObservationsCount demand events recorded'
            : 'More sales history needed ($demandObservationsCount/14 records)',
      ),
      ForecastReadinessCondition(
        title: 'More demand observations needed',
        isMet: timelineReady,
        details: timelineReady
            ? '$distinctDaysCount active demand days observed'
            : 'More demand observations needed ($distinctDaysCount/7 days observed)',
      ),
    ];

    return DemandForecastSummary(
      state: isReady ? ForecastUiState.ready : ForecastUiState.insufficientData,
      businessId: businessId,
      locationId: locationId,
      productsCount: productsCount,
      variantsCount: variantsCount,
      locationsCount: locationsCount,
      inventoryBalancesCount: balancesCount,
      ledgerRowsCount: ledgerCount,
      demandObservationsCount: demandObservationsCount,
      distinctDaysCount: distinctDaysCount,
      readinessConditions: conditions,
      isReady: isReady,
      forecastedSales: null,
      recommendedOrders: null,
      highRiskSkus: null,
      productsRequiringAttention: const [],
      selectedProduct: null,
      aiInsight: null,
    );
  }
}
