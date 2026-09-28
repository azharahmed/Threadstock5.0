import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/business/current_business_service.dart';

class StockAgeingItem {
  final String productId;
  final String variantId;
  final String name;
  final String sku;
  final String category;
  final int ageDays;
  final int qty;
  final double numericValue;
  final String valueFormatted;
  final String location;
  final String riskLevel;
  final Color riskBg;
  final Color riskColor;
  final String monthlyCarryingCost;
  final String aiSuggestion;
  final DateTime? stockInDate;

  const StockAgeingItem({
    required this.productId,
    required this.variantId,
    required this.name,
    required this.sku,
    required this.category,
    required this.ageDays,
    required this.qty,
    required this.numericValue,
    required this.valueFormatted,
    required this.location,
    required this.riskLevel,
    required this.riskBg,
    required this.riskColor,
    required this.monthlyCarryingCost,
    required this.aiSuggestion,
    this.stockInDate,
  });
}

class StockAgeingSummary {
  final List<StockAgeingItem> items;
  final double totalValue;
  final int totalUnits;
  final int trackedSkus;
  final double bucket0to30Value;
  final double bucket31to90Value;
  final double bucket91to180Value;
  final double bucket180PlusValue;
  final Map<String, double> categoryDistribution;
  final List<String> categories;

  const StockAgeingSummary({
    required this.items,
    required this.totalValue,
    required this.totalUnits,
    required this.trackedSkus,
    required this.bucket0to30Value,
    required this.bucket31to90Value,
    required this.bucket91to180Value,
    required this.bucket180PlusValue,
    required this.categoryDistribution,
    required this.categories,
  });

  static const empty = StockAgeingSummary(
    items: [],
    totalValue: 0,
    totalUnits: 0,
    trackedSkus: 0,
    bucket0to30Value: 0,
    bucket31to90Value: 0,
    bucket91to180Value: 0,
    bucket180PlusValue: 0,
    categoryDistribution: {},
    categories: ['All Categories'],
  );

  bool get isEmpty => items.isEmpty;
}

class StockAgeingRepository {
  final SupabaseClient? client;

  StockAgeingRepository({this.client});

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<StockAgeingSummary> loadStockAgeing({String? locationId}) async {
    final sb = _resolvedClient;
    final businessId = CurrentBusinessService.instance.currentBusinessId;

    if (sb == null || businessId == null || businessId.isEmpty) {
      return _buildEmptySummary();
    }

    try {
      // 1. Fetch real products for current business
      final productsRes = await sb
          .from('products')
          .select('id, name, category_id, created_at')
          .eq('business_id', businessId);
      final productsList = (productsRes as List);
      if (productsList.isEmpty) {
        return _buildEmptySummary();
      }

      final productIds = productsList.map((p) => p['id'] as String).toList();
      final productMap = {for (var p in productsList) p['id'] as String: p};

      // 2. Fetch real categories
      final categoriesRes = await sb
          .from('categories')
          .select('id, name')
          .eq('business_id', businessId);
      final categoryMap = {
        for (var c in (categoriesRes as List))
          c['id'] as String: c['name'] as String,
      };

      // 3. Fetch real locations
      final locationsRes = await sb
          .from('locations')
          .select('id, name')
          .eq('business_id', businessId);
      final locationMap = {
        for (var l in (locationsRes as List))
          l['id'] as String: l['name'] as String,
      };

      // 4. Fetch real product variants
      final variantsRes = await sb
          .from('product_variants')
          .select(
            'id, product_id, sku, cost_price_cents, retail_price_cents, created_at',
          )
          .inFilter('product_id', productIds);
      final variantsList = (variantsRes as List);
      if (variantsList.isEmpty) {
        return _buildEmptySummary();
      }

      final variantIds = variantsList.map((v) => v['id'] as String).toList();
      final variantMap = {for (var v in variantsList) v['id'] as String: v};

      // 5. Fetch inventory balances
      var balancesQuery = sb
          .from('inventory_balances')
          .select('id, location_id, variant_id, available_qty')
          .eq('business_id', businessId);
      if (locationId != null && locationId != 'none' && locationId.isNotEmpty) {
        balancesQuery = balancesQuery.eq('location_id', locationId);
      }
      final balancesRes = await balancesQuery;
      final balancesList = (balancesRes as List);

      // 6. Fetch inventory ledger for accurate stock-in / receipt dates
      var ledgerQuery = sb
          .from('inventory_ledger')
          .select(
            'id, variant_id, location_id, event_type, quantity_delta, occurred_at, created_at',
          )
          .eq('business_id', businessId)
          .inFilter('variant_id', variantIds)
          .order('occurred_at', ascending: true);
      final ledgerRes = await ledgerQuery;
      final ledgerList = (ledgerRes as List);

      // Map variant_id -> earliest / relevant stock_in date
      final Map<String, DateTime> variantStockInDates = {};
      for (final entry in ledgerList) {
        final vId = entry['variant_id'] as String?;
        final qtyDelta = (entry['quantity_delta'] as num?)?.toInt() ?? 0;
        if (vId != null && qtyDelta > 0) {
          final dateStr =
              entry['occurred_at'] as String? ?? entry['created_at'] as String?;
          if (dateStr != null) {
            final date = DateTime.tryParse(dateStr);
            if (date != null) {
              // Track stock receipt date
              variantStockInDates.putIfAbsent(vId, () => date);
            }
          }
        }
      }

      // Build ageing items
      final List<StockAgeingItem> items = [];
      final now = DateTime.now();

      for (final b in balancesList) {
        final availableQty = (b['available_qty'] as num?)?.toInt() ?? 0;
        if (availableQty <= 0) continue;

        final vId = b['variant_id'] as String?;
        if (vId == null || !variantMap.containsKey(vId)) continue;
        final v = variantMap[vId]!;

        final pId = v['product_id'] as String?;
        if (pId == null || !productMap.containsKey(pId)) continue;
        final p = productMap[pId]!;

        final catId = p['category_id'] as String?;
        final categoryName = (catId != null && categoryMap.containsKey(catId))
            ? categoryMap[catId]!
            : 'Uncategorized';

        final locId = b['location_id'] as String?;
        final locationName = (locId != null && locationMap.containsKey(locId))
            ? locationMap[locId]!
            : (locationsRes.isNotEmpty
                  ? locationsRes.first['name'] as String
                  : 'Main Store');

        // Determine stock age from inventory_ledger first, then variant/product creation
        final stockInDate =
            variantStockInDates[vId] ??
            DateTime.tryParse(v['created_at'] as String? ?? '') ??
            DateTime.tryParse(p['created_at'] as String? ?? '') ??
            now;

        final ageDays = now.difference(stockInDate).inDays.clamp(0, 9999);

        // Unit cost in INR
        final costPriceCents = v['cost_price_cents'] as num?;
        final retailPriceCents = v['retail_price_cents'] as num?;
        final unitCost = (costPriceCents != null && costPriceCents > 0)
            ? (costPriceCents / 100.0)
            : (retailPriceCents != null && retailPriceCents > 0
                  ? retailPriceCents / 100.0
                  : 0.0);

        final totalValue = availableQty * unitCost;

        // Risk buckets & colors
        String riskLevel;
        Color riskBg;
        Color riskColor;
        if (ageDays <= 30) {
          riskLevel = 'Fresh';
          riskBg = const Color(0xFFE6F4EA);
          riskColor = const Color(0xFF137333);
        } else if (ageDays <= 90) {
          riskLevel = 'Active';
          riskBg = const Color(0xFFFEF3C7);
          riskColor = const Color(0xFFB45309);
        } else if (ageDays <= 180) {
          riskLevel = 'Aging';
          riskBg = const Color(0xFFFFEDD5);
          riskColor = const Color(0xFFC2410C);
        } else {
          riskLevel = 'Critical';
          riskBg = const Color(0xFFFEE2E2);
          riskColor = const Color(0xFFDC2626);
        }

        // Monthly carrying cost estimated at ~1.8% of holding value
        final carryingCost = totalValue > 0
            ? '₹${(totalValue * 0.018).toStringAsFixed(0)} / mo'
            : '—';

        // Deterministic AI suggestion
        final String aiSuggestion;
        if (ageDays > 180) {
          aiSuggestion =
              'Static duration exceeds 180 days. Review promotional clearance markdown or location rebalance.';
        } else if (ageDays > 90) {
          aiSuggestion =
              'Inventory approaching aging threshold. Monitor weekly velocity.';
        } else {
          aiSuggestion = 'No AI recommendation available yet.';
        }

        items.add(
          StockAgeingItem(
            productId: p['id'] as String,
            variantId: vId,
            name: p['name'] as String? ?? 'Product',
            sku: v['sku'] as String? ?? '—',
            category: categoryName,
            ageDays: ageDays,
            qty: availableQty,
            numericValue: totalValue,
            valueFormatted: _formatCurrency(totalValue),
            location: locationName,
            riskLevel: riskLevel,
            riskBg: riskBg,
            riskColor: riskColor,
            monthlyCarryingCost: carryingCost,
            aiSuggestion: aiSuggestion,
            stockInDate: stockInDate,
          ),
        );
      }

      return _compileSummary(items);
    } catch (e, st) {
      debugPrint('[StockAgeingRepository] Error loading stock ageing: $e\n$st');
      return _buildEmptySummary();
    }
  }

  StockAgeingSummary _compileSummary(List<StockAgeingItem> items) {
    if (items.isEmpty) return _buildEmptySummary();

    double totalVal = 0;
    int totalUnits = 0;
    double b0 = 0;
    double b31 = 0;
    double b91 = 0;
    double b180 = 0;

    final Map<String, double> catValues = {};

    for (final item in items) {
      totalVal += item.numericValue;
      totalUnits += item.qty;

      if (item.ageDays <= 30) {
        b0 += item.numericValue;
      } else if (item.ageDays <= 90) {
        b31 += item.numericValue;
      } else if (item.ageDays <= 180) {
        b91 += item.numericValue;
      } else {
        b180 += item.numericValue;
      }

      catValues[item.category] =
          (catValues[item.category] ?? 0) + item.numericValue;
    }

    final Map<String, double> catDist = {};
    if (totalVal > 0) {
      for (final entry in catValues.entries) {
        catDist[entry.key] = (entry.value / totalVal) * 100.0;
      }
    } else {
      for (final cat in catValues.keys) {
        catDist[cat] = 100.0 / catValues.length;
      }
    }

    final categories = ['All Categories', ...catValues.keys];

    return StockAgeingSummary(
      items: items,
      totalValue: totalVal,
      totalUnits: totalUnits,
      trackedSkus: items.length,
      bucket0to30Value: b0,
      bucket31to90Value: b31,
      bucket91to180Value: b91,
      bucket180PlusValue: b180,
      categoryDistribution: catDist,
      categories: categories,
    );
  }

  StockAgeingSummary _buildEmptySummary() {
    return const StockAgeingSummary(
      items: [],
      totalValue: 0,
      totalUnits: 0,
      trackedSkus: 0,
      bucket0to30Value: 0,
      bucket31to90Value: 0,
      bucket91to180Value: 0,
      bucket180PlusValue: 0,
      categoryDistribution: {},
      categories: ['All Categories'],
    );
  }

  static String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'), (m) => '${m[1]},')}';
    } else {
      return '₹${amount.toStringAsFixed(0)}';
    }
  }
}
