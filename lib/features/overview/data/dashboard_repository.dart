import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/business/current_business_service.dart';
import '../../inventory/data/category_repository.dart';
import '../../inventory/data/location_repository.dart';
import '../../inventory/data/product_repository.dart';
import '../../inventory/data/supplier_repository.dart';
import '../../sales/data/sales_repository.dart';
import '../../settings/data/business_profile_repository.dart';

class DashboardData {
  final String? userName;
  final String? locationName;
  final String currencySymbol;
  final int todaySalesCents;
  final int totalStockCount;
  final int lowStockCount;
  final int? pendingTransfersCount;
  final String pendingTransfersDisplay;
  final List<Map<String, dynamic>> recentActivities;
  final List<Map<String, dynamic>> salesTrend;
  final List<Map<String, dynamic>> topCategories;
  final Map<String, int> stockHealth;
  final Map<String, double> stockHealthRatios;
  final Map<String, String> stockHealthPercentages;
  final String? aiInsight;
  final String? timezone;
  final Duration timezoneOffset;
  final int totalProductsCount;
  final int supplierCount;
  final int completedSalesCount;
  final String? firstProductId;
  final String? firstProductName;

  const DashboardData({
    this.userName,
    this.locationName,
    this.currencySymbol = '₹',
    this.todaySalesCents = 0,
    this.totalStockCount = 0,
    this.lowStockCount = 0,
    this.pendingTransfersCount,
    this.pendingTransfersDisplay = '—',
    this.recentActivities = const [],
    this.salesTrend = const [],
    this.topCategories = const [],
    this.stockHealth = const {},
    this.stockHealthRatios = const {},
    this.stockHealthPercentages = const {},
    this.aiInsight,
    this.timezone,
    this.timezoneOffset = const Duration(hours: 5, minutes: 30),
    this.totalProductsCount = 0,
    this.supplierCount = 0,
    this.completedSalesCount = 0,
    this.firstProductId,
    this.firstProductName,
  });

  String get resolvedPendingTransfers =>
      pendingTransfersCount != null ? '$pendingTransfersCount' : pendingTransfersDisplay;

  bool get hasSalesData =>
      salesTrend.any((p) => (p['amountCents'] as num? ?? 0) > 0) ||
      todaySalesCents > 0 ||
      completedSalesCount > 0;

  bool get hasActivity => recentActivities.isNotEmpty;
  bool get hasCategories => topCategories.isNotEmpty;
  bool get hasInventory =>
      totalStockCount > 0 || stockHealth.values.any((v) => v > 0);

  bool get hasProducts => totalProductsCount > 0;
  bool get hasStock => totalStockCount > 0;
  bool get hasSuppliers => supplierCount > 0;
  bool get hasCompletedSale => hasSalesData;

  /// Derived fresh-workspace mode:
  /// products == 0 -> fresh setup
  /// product exists but no stock -> setup focused on stock
  /// stock exists but no sale -> setup focused on first sale
  /// completed sale exists -> normal operational dashboard
  bool get isFreshWorkspace => !hasCompletedSale;
}

class DashboardRepository {
  final SupabaseClient? client;
  final LocationRepository _locationRepository;
  String chartRange = '7D';
  String? locationId;

  DashboardRepository({
    this.client,
    LocationRepository? locationRepository,
    ProductRepository? productRepository,
  }) : _locationRepository =
           locationRepository ?? LocationRepository(client: client);

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<DashboardData> fetchDashboardData({
    String? businessId,
  }) async {
    final resolvedBusinessId =
        businessId ??
        CurrentBusinessService.instance.currentBusinessId ??
        await CurrentBusinessService.instance.resolveCurrentBusinessId();

    final activeLocId = locationId ?? CurrentBusinessService.instance.currentLocationId;
    final resolvedLocationId =
        (activeLocId != null &&
         activeLocId.isNotEmpty &&
         activeLocId != 'all' &&
         activeLocId != 'All Locations' &&
         activeLocId != 'none')
            ? activeLocId
            : null;

    final currencyCode =
        CurrentBusinessService.instance.currentBusiness?.currencyCode ?? 'INR';
    final currencySymbol = _resolveCurrencySymbol(currencyCode);

    // 1. User Name
    final userName = await _resolveUserName();

    // 2. Primary Location Name & Locations Map
    String? locationName;
    final Map<String, String> locationNameMap = {};
    try {
      final locations = await _locationRepository.getLocations(
        businessId: resolvedBusinessId,
      );
      for (final loc in locations) {
        locationNameMap[loc.id] = loc.name;
      }
      if (resolvedLocationId != null && locationNameMap.containsKey(resolvedLocationId)) {
        locationName = locationNameMap[resolvedLocationId];
      } else if (locations.isNotEmpty) {
        locationName = locations.first.name;
      }
    } catch (_) {}

    // 3. Timezone Resolution
    final tzInfo = await _resolveBusinessTimezone(
      businessId: resolvedBusinessId ?? '',
      locationId: resolvedLocationId,
    );
    final businessOffset = tzInfo.offset;
    final nowUtc = DateTime.now().toUtc();
    final nowBusiness = nowUtc.add(businessOffset);
    final todayBusinessDate = DateTime.utc(
      nowBusiness.year,
      nowBusiness.month,
      nowBusiness.day,
    );

    int totalStock = 0;
    int lowStock = 0;
    final Map<String, int> stockHealth = {
      'inStock': 0,
      'lowStock': 0,
      'outOfStock': 0,
    };
    final Map<String, double> stockHealthRatios = {};
    final Map<String, String> stockHealthPercentages = {};
    final List<Map<String, dynamic>> topCategories = [];

    int todaySalesCents = 0;
    int totalProductsCount = 0;
    int supplierCount = 0;
    int completedSalesCount = 0;
    String? firstProductId;
    String? firstProductName;
    final List<Map<String, dynamic>> salesTrend = [];
    final List<Map<String, dynamic>> recentActivities = [];

    final sb = _resolvedClient;
    final isOnline = sb != null &&
        sb.auth.currentUser != null &&
        resolvedBusinessId != null &&
        !resolvedBusinessId.startsWith('biz_');

    if (isOnline) {
      // -----------------------------------------------------------------------
      // A. INVENTORY / TOTAL STOCK / LOW STOCK
      // -----------------------------------------------------------------------
      final Map<String, String> variantProductNameMap = {};
      try {
        // Query active products for this business
        final productRows = await sb
            .from('products')
            .select('id, name, status, track_stock_levels, low_stock_threshold')
            .eq('business_id', resolvedBusinessId)
            .eq('status', 'active');

        totalProductsCount = (productRows as List).length;
        if (totalProductsCount > 0) {
          final first = (productRows as List).first as Map<String, dynamic>;
          firstProductId = first['id'] as String?;
          firstProductName = first['name'] as String?;
        }

        final Map<String, ({bool trackStockLevels, int? lowStockThreshold, String name})> productMetaMap = {};
        final List<String> trackedProductIds = [];

        for (final p in (productRows as List)) {
          final pMap = p as Map<String, dynamic>;
          final pId = pMap['id'] as String;
          final pName = pMap['name'] as String? ?? 'Product';
          final track = pMap['track_stock_levels'] == true;
          final threshold = (pMap['low_stock_threshold'] as num?)?.toInt();
          productMetaMap[pId] = (
            trackStockLevels: track,
            lowStockThreshold: threshold,
            name: pName,
          );
          if (track) {
            trackedProductIds.add(pId);
          }
        }

        // Query active variants for tracked active products
        final List<Map<String, dynamic>> activeTrackedVariants = [];
        if (trackedProductIds.isNotEmpty) {
          final variantRows = await sb
              .from('product_variants')
              .select('id, product_id, sku, status')
              .inFilter('product_id', trackedProductIds)
              .eq('status', 'active');

          for (final v in (variantRows as List)) {
            final vMap = v as Map<String, dynamic>;
            activeTrackedVariants.add(vMap);
            final vId = vMap['id'] as String;
            final pId = vMap['product_id'] as String;
            final pMeta = productMetaMap[pId];
            if (pMeta != null) {
              variantProductNameMap[vId] = pMeta.name;
            }
          }
        }

        // Query inventory balances for this business
        var balanceQuery = sb
            .from('inventory_balances')
            .select('variant_id, location_id, available_qty')
            .eq('business_id', resolvedBusinessId);

        if (resolvedLocationId != null) {
          balanceQuery = balanceQuery.eq('location_id', resolvedLocationId);
        }

        final balanceRows = await balanceQuery;

        // Group balances by variant_id
        final Map<String, int> availableByVariant = {};
        for (final b in (balanceRows as List)) {
          final bMap = b as Map<String, dynamic>;
          final vId = bMap['variant_id'] as String?;
          final qty = (bMap['available_qty'] as num?)?.toInt() ?? 0;
          if (vId != null) {
            availableByVariant[vId] = (availableByVariant[vId] ?? 0) + qty;
          }
        }

        int inStockCount = 0;
        int lowStockCount = 0;
        int outOfStockCount = 0;

        for (final variant in activeTrackedVariants) {
          final vId = variant['id'] as String;
          final pId = variant['product_id'] as String;
          final pMeta = productMetaMap[pId];
          final availableQty = availableByVariant[vId] ?? 0;

          totalStock += availableQty;

          final threshold = pMeta?.lowStockThreshold;
          if (pMeta?.trackStockLevels == true && threshold != null) {
            if (availableQty > 0 && availableQty <= threshold) {
              lowStockCount++;
            } else if (availableQty > threshold) {
              inStockCount++;
            } else {
              outOfStockCount++;
            }
          } else {
            if (availableQty > 0) {
              inStockCount++;
            } else {
              outOfStockCount++;
            }
          }
        }

        lowStock = lowStockCount;
        stockHealth['inStock'] = inStockCount;
        stockHealth['lowStock'] = lowStockCount;
        stockHealth['outOfStock'] = outOfStockCount;

        final totalVariants = inStockCount + lowStockCount + outOfStockCount;
        if (totalVariants > 0) {
          final inRatio = inStockCount / totalVariants;
          final lowRatio = lowStockCount / totalVariants;
          final outRatio = outOfStockCount / totalVariants;
          stockHealthRatios['inStock'] = inRatio;
          stockHealthRatios['lowStock'] = lowRatio;
          stockHealthRatios['outOfStock'] = outRatio;
          stockHealthPercentages['inStock'] = '${(inRatio * 100).round()}%';
          stockHealthPercentages['lowStock'] = '${(lowRatio * 100).round()}%';
          stockHealthPercentages['outOfStock'] = '${(outRatio * 100).round()}%';
        }
      } catch (e) {
        debugPrint('[DashboardRepository] Error fetching inventory: $e');
      }

      // -----------------------------------------------------------------------
      // B. CATEGORIES & PRODUCTS
      // -----------------------------------------------------------------------
      try {
        final categories = await sb
            .from('categories')
            .select('id, name')
            .eq('business_id', resolvedBusinessId);

        final products = await sb
            .from('products')
            .select('id, category_id')
            .eq('business_id', resolvedBusinessId);

        if (categories.isNotEmpty) {
          final categoryProductsCount = products.length;
          for (final cat in categories) {
            final catId = cat['id'] as String;
            final catName = cat['name'] as String;
            final catProductCount = products
                .where((p) => p['category_id'] == catId)
                .length;
            final percent = categoryProductsCount > 0
                ? '${((catProductCount / categoryProductsCount) * 100).round()}%'
                : '0%';
            topCategories.add({
              'name': catName,
              'count': catProductCount,
              'percent': percent,
            });
          }
          topCategories.sort(
            (a, b) => (b['count'] as int).compareTo(a['count'] as int),
          );
        }
      } catch (e) {
        debugPrint('[DashboardRepository] Error calculating categories: $e');
      }

      // Query suppliers for this business
      try {
        final supplierRows = await sb
            .from('suppliers')
            .select('id')
            .eq('business_id', resolvedBusinessId);
        supplierCount = (supplierRows as List).length;
      } catch (e) {
        debugPrint('[DashboardRepository] Error fetching suppliers: $e');
      }

      // -----------------------------------------------------------------------
      // C. SALES / TODAY'S SALES / SALES TREND
      // -----------------------------------------------------------------------
      final List<Map<String, dynamic>> completedSales = [];
      try {
        var salesQuery = sb
            .from('sales')
            .select('id, sale_number, total_minor, currency_code, status, completed_at, created_at, created_by, location_id')
            .eq('business_id', resolvedBusinessId)
            .eq('status', 'completed');

        if (resolvedLocationId != null) {
          salesQuery = salesQuery.eq('location_id', resolvedLocationId);
        }

        final salesRows = await salesQuery.order('created_at', ascending: false);

        for (final row in (salesRows as List)) {
          final sMap = row as Map<String, dynamic>;
          completedSales.add(sMap);

          final rawTime = sMap['completed_at'] ?? sMap['created_at'];
          if (rawTime != null) {
            final saleUtc = DateTime.tryParse(rawTime.toString())?.toUtc();
            if (saleUtc != null) {
              final saleBusiness = saleUtc.add(businessOffset);
              final saleDate = DateTime.utc(
                saleBusiness.year,
                saleBusiness.month,
                saleBusiness.day,
              );
              if (saleDate.isAtSameMomentAs(todayBusinessDate)) {
                final totalMinor = (sMap['total_minor'] as num?)?.toInt() ?? 0;
                todaySalesCents += totalMinor;
              }
            }
          }
        }
        completedSalesCount = completedSales.length;
      } catch (e) {
        debugPrint('[DashboardRepository] Error fetching sales: $e');
      }

      // Build continuous daily trend series
      final int dayCount = chartRange == '90D' ? 90 : (chartRange == '30D' ? 30 : 7);
      final Map<String, int> salesByDay = {};
      for (final sale in completedSales) {
        final rawTime = sale['completed_at'] ?? sale['created_at'];
        if (rawTime != null) {
          final saleUtc = DateTime.tryParse(rawTime.toString())?.toUtc();
          if (saleUtc != null) {
            final saleBusiness = saleUtc.add(businessOffset);
            final key = _formatIsoDate(DateTime.utc(
              saleBusiness.year,
              saleBusiness.month,
              saleBusiness.day,
            ));
            final totalMinor = (sale['total_minor'] as num?)?.toInt() ?? 0;
            salesByDay[key] = (salesByDay[key] ?? 0) + totalMinor;
          }
        }
      }

      for (int i = dayCount - 1; i >= 0; i--) {
        final day = todayBusinessDate.subtract(Duration(days: i));
        final key = _formatIsoDate(day);
        final minor = salesByDay[key] ?? 0;
        final label = _formatChartDayLabel(day, dayCount);
        salesTrend.add({
          'date': label,
          'fullDate': key,
          'amountCents': minor,
          'amount': minor / 100.0,
        });
      }

      // -----------------------------------------------------------------------
      // D. RECENT ACTIVITY
      // -----------------------------------------------------------------------
      final List<Map<String, dynamic>> rawActivities = [];

      // 1. Completed sales activity
      for (final sale in completedSales.take(10)) {
        final rawTime = sale['completed_at'] ?? sale['created_at'];
        if (rawTime != null) {
          final saleUtc = DateTime.tryParse(rawTime.toString())?.toUtc();
          if (saleUtc != null) {
            final saleNumber = sale['sale_number'] as String? ?? 'Sale';
            final totalMinor = (sale['total_minor'] as num?)?.toInt() ?? 0;
            final curr = _resolveCurrencySymbol(sale['currency_code'] as String? ?? 'INR');
            final formattedTotal = '$curr${(totalMinor / 100).toStringAsFixed(0)}';
            final locId = sale['location_id'] as String?;
            final locName = (locId != null ? locationNameMap[locId] : null) ?? locationName ?? 'Stock location';
            final actor = userName ?? 'Owner';

            rawActivities.add({
              'id': 'sale_${sale['id']}',
              'type': 'sale',
              'title': 'Sale completed',
              'subtitle': '$saleNumber • $formattedTotal',
              'detail': '$actor • $locName',
              'time': _formatRelativeTime(saleUtc.add(businessOffset), nowBusiness),
              'timestamp': saleUtc,
              'icon': Icons.verified_outlined,
              'iconColor': const Color(0xFF059669),
              'iconBg': const Color(0xFFD1FAE5),
            });
          }
        }
      }

      // 2. Inventory ledger operational activity (excluding sales)
      try {
        var ledgerQuery = sb
            .from('inventory_ledger')
            .select('id, event_type, available_delta, committed_delta, damaged_delta, occurred_at, created_at, variant_id, location_id, actor_id')
            .eq('business_id', resolvedBusinessId)
            .neq('event_type', 'sale');

        if (resolvedLocationId != null) {
          ledgerQuery = ledgerQuery.eq('location_id', resolvedLocationId);
        }

        final ledgerRows = await ledgerQuery.order('occurred_at', ascending: false).limit(15);

        for (final row in (ledgerRows as List)) {
          final lMap = row as Map<String, dynamic>;
          final eventType = lMap['event_type'] as String? ?? '';
          final rawTime = lMap['occurred_at'] ?? lMap['created_at'];
          final lUtc = rawTime != null ? DateTime.tryParse(rawTime.toString())?.toUtc() : null;
          if (lUtc == null) continue;

          final vId = lMap['variant_id'] as String?;
          final prodName = (vId != null ? variantProductNameMap[vId] : null) ?? 'Product';
          final locId = lMap['location_id'] as String?;
          final locName = (locId != null ? locationNameMap[locId] : null) ?? locationName ?? 'Stock location';
          final availDelta = (lMap['available_delta'] as num?)?.toInt() ?? 0;
          final damagedDelta = (lMap['damaged_delta'] as num?)?.toInt() ?? 0;
          final actor = userName ?? 'Staff';

          String title;
          String subtitle;
          IconData icon;
          Color iconColor;
          Color iconBg;

          switch (eventType) {
            case 'adjustment':
              title = 'Stock adjusted';
              subtitle = '$prodName (${availDelta >= 0 ? '+$availDelta' : '$availDelta'} units)';
              icon = Icons.tune_rounded;
              iconColor = const Color(0xFF2563EB);
              iconBg = const Color(0xFFDBEAFE);
              break;
            case 'damage':
              title = 'Damaged stock recorded';
              subtitle = '$prodName (-${damagedDelta.abs()} units)';
              icon = Icons.warning_amber_rounded;
              iconColor = const Color(0xFFDC2626);
              iconBg = const Color(0xFFFEE2E2);
              break;
            case 'count_reconciliation':
            case 'reconciliation':
              title = 'Stock count reconciled';
              subtitle = prodName;
              icon = Icons.fact_check_outlined;
              iconColor = const Color(0xFF059669);
              iconBg = const Color(0xFFD1FAE5);
              break;
            case 'receiving':
            case 'restock':
              title = 'Stock received';
              subtitle = '$prodName (+$availDelta units)';
              icon = Icons.inventory_2_outlined;
              iconColor = const Color(0xFFD97706);
              iconBg = const Color(0xFFFEF3C7);
              break;
            default:
              title = 'Inventory updated';
              subtitle = prodName;
              icon = Icons.history_rounded;
              iconColor = const Color(0xFF64748B);
              iconBg = const Color(0xFFF1F5F9);
          }

          rawActivities.add({
            'id': 'ledger_${lMap['id']}',
            'type': eventType,
            'title': title,
            'subtitle': subtitle,
            'detail': '$actor • $locName',
            'time': _formatRelativeTime(lUtc.add(businessOffset), nowBusiness),
            'timestamp': lUtc,
            'icon': icon,
            'iconColor': iconColor,
            'iconBg': iconBg,
          });
        }
      } catch (e) {
        debugPrint('[DashboardRepository] Error fetching ledger activity: $e');
      }

      // 3. Customer created activity
      try {
        final custRows = await sb
            .from('customers')
            .select('id, name, created_at')
            .eq('business_id', resolvedBusinessId)
            .order('created_at', ascending: false)
            .limit(5);

        for (final c in (custRows as List)) {
          final cMap = c as Map<String, dynamic>;
          final cName = cMap['name'] as String? ?? 'Customer';
          final rawTime = cMap['created_at'];
          final cUtc = rawTime != null ? DateTime.tryParse(rawTime.toString())?.toUtc() : null;
          if (cUtc == null) continue;

          rawActivities.add({
            'id': 'cust_${cMap['id']}',
            'type': 'customer',
            'title': 'Customer added',
            'subtitle': cName,
            'detail': userName ?? 'Staff',
            'time': _formatRelativeTime(cUtc.add(businessOffset), nowBusiness),
            'timestamp': cUtc,
            'icon': Icons.person_add_outlined,
            'iconColor': const Color(0xFF6366F1),
            'iconBg': const Color(0xFFEEF2FF),
          });
        }
      } catch (_) {}

      // 4. Product created / published activity
      try {
        final prodRows = await sb
            .from('products')
            .select('id, name, created_at, published_at, status')
            .eq('business_id', resolvedBusinessId)
            .eq('status', 'active')
            .order('created_at', ascending: false)
            .limit(5);

        for (final p in (prodRows as List)) {
          final pMap = p as Map<String, dynamic>;
          final pName = pMap['name'] as String? ?? 'Product';
          final rawTime = pMap['published_at'] ?? pMap['created_at'];
          final pUtc = rawTime != null ? DateTime.tryParse(rawTime.toString())?.toUtc() : null;
          if (pUtc == null) continue;

          rawActivities.add({
            'id': 'prod_${pMap['id']}',
            'type': 'product',
            'title': 'Product published',
            'subtitle': pName,
            'detail': userName ?? 'Owner',
            'time': _formatRelativeTime(pUtc.add(businessOffset), nowBusiness),
            'timestamp': pUtc,
            'icon': Icons.sell_outlined,
            'iconColor': const Color(0xFF0284C7),
            'iconBg': const Color(0xFFE0F2FE),
          });
        }
      } catch (_) {}

      // Sort all combined activities newest first
      rawActivities.sort((a, b) {
        final dtA = a['timestamp'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dtB = b['timestamp'] as DateTime? ?? DateTime.fromMillisecondsSinceEpoch(0);
        return dtB.compareTo(dtA);
      });

      recentActivities.addAll(rawActivities.take(8));
    } else {
      // -----------------------------------------------------------------------
      // IN-MEMORY / TEST FALLBACK
      // -----------------------------------------------------------------------
      // Fallback inventory calculation
      final fallbackProds = ProductRepository.localFallbackProducts.values
          .where((p) => p.businessId == resolvedBusinessId)
          .toList();

      int inStock = 0;
      int outOfStock = 0;

      for (final p in fallbackProds) {
        int pQty = 0;
        if (ProductRepository.localFallbackInventory.containsKey(p.id)) {
          pQty += ProductRepository.localFallbackInventory[p.id] ?? 0;
        }
        for (final entry in ProductRepository.localFallbackInventory.entries) {
          if (resolvedLocationId != null && resolvedLocationId != 'all') {
            if (entry.key == '${p.id}_$resolvedLocationId') {
              pQty += entry.value;
            }
          } else {
            if (entry.key.startsWith('${p.id}_')) {
              pQty += entry.value;
            }
          }
        }

        if (p.trackStockLevels) {
          totalStock += pQty;
          final threshold = p.lowStockThreshold;
          if (threshold != null) {
            if (pQty > 0 && pQty <= threshold) {
              lowStock++;
            } else if (pQty > threshold) {
              inStock++;
            } else {
              outOfStock++;
            }
          } else {
            if (pQty > 0) {
              inStock++;
            } else {
              outOfStock++;
            }
          }
        }
      }

      stockHealth['inStock'] = inStock;
      stockHealth['lowStock'] = lowStock;
      stockHealth['outOfStock'] = outOfStock;

      final totalTracked = inStock + lowStock + outOfStock;
      if (totalTracked > 0) {
        final inRatio = inStock / totalTracked;
        final lowRatio = lowStock / totalTracked;
        final outRatio = outOfStock / totalTracked;
        stockHealthRatios['inStock'] = inRatio;
        stockHealthRatios['lowStock'] = lowRatio;
        stockHealthRatios['outOfStock'] = outRatio;
        stockHealthPercentages['inStock'] = '${(inRatio * 100).round()}%';
        stockHealthPercentages['lowStock'] = '${(lowRatio * 100).round()}%';
        stockHealthPercentages['outOfStock'] = '${(outRatio * 100).round()}%';
      }

      final localSales = SalesRepository.getLocalSalesForBusiness(resolvedBusinessId)
          .where((s) => s.status == 'completed')
          .toList();

      for (final sale in localSales) {
        if (resolvedLocationId != null && sale.locationId != resolvedLocationId) {
          continue;
        }
        final saleTime = (sale.completedAt ?? sale.createdAt ?? DateTime.now()).toUtc();
        final saleBusiness = saleTime.add(businessOffset);
        final saleDate = DateTime.utc(
          saleBusiness.year,
          saleBusiness.month,
          saleBusiness.day,
        );
        if (saleDate.isAtSameMomentAs(todayBusinessDate)) {
          todaySalesCents += sale.totalMinor;
        }
      }

      // Continuous daily trend for local sales
      final int dayCount = chartRange == '90D' ? 90 : (chartRange == '30D' ? 30 : 7);
      final Map<String, int> salesByDay = {};
      for (final sale in localSales) {
        if (resolvedLocationId != null && sale.locationId != resolvedLocationId) {
          continue;
        }
        final saleTime = (sale.completedAt ?? sale.createdAt ?? DateTime.now()).toUtc();
        final saleBusiness = saleTime.add(businessOffset);
        final key = _formatIsoDate(DateTime.utc(
          saleBusiness.year,
          saleBusiness.month,
          saleBusiness.day,
        ));
        salesByDay[key] = (salesByDay[key] ?? 0) + sale.totalMinor;
      }

      for (int i = dayCount - 1; i >= 0; i--) {
        final day = todayBusinessDate.subtract(Duration(days: i));
        final key = _formatIsoDate(day);
        final minor = salesByDay[key] ?? 0;
        final label = _formatChartDayLabel(day, dayCount);
        salesTrend.add({
          'date': label,
          'fullDate': key,
          'amountCents': minor,
          'amount': minor / 100.0,
        });
      }

      // Recent activities from local sales & customers
      for (final sale in localSales.take(5)) {
        final curr = _resolveCurrencySymbol(sale.currencyCode);
        final saleTime = (sale.completedAt ?? sale.createdAt ?? DateTime.now()).toUtc();
        recentActivities.add({
          'id': 'sale_${sale.id}',
          'type': 'sale',
          'title': 'Sale completed',
          'subtitle': '${sale.saleNumber} • $curr${(sale.totalMinor / 100).toStringAsFixed(0)}',
          'detail': '${userName ?? 'Azhar'} • ${locationName ?? 'Stock location'}',
          'time': _formatRelativeTime(saleTime.add(businessOffset), nowBusiness),
          'timestamp': saleTime,
          'icon': Icons.verified_outlined,
          'iconColor': const Color(0xFF059669),
          'iconBg': const Color(0xFFD1FAE5),
        });
      }

      final fallbackCats = await CategoryRepository().getCategories(
        businessId: resolvedBusinessId,
      );

      totalProductsCount = fallbackProds.length;
      if (totalProductsCount > 0) {
        firstProductId = fallbackProds.first.id;
        firstProductName = fallbackProds.first.name;
      }
      try {
        final fallbackSuppliers = await SupplierRepository().getSuppliers(
          businessId: resolvedBusinessId,
        );
        supplierCount = fallbackSuppliers.length;
      } catch (_) {}
      completedSalesCount = localSales.where((s) => s.status == 'completed').length;

      if (fallbackCats.isNotEmpty) {
        final totalCount = fallbackProds.length;
        for (final cat in fallbackCats) {
          final cCount = fallbackProds
              .where((p) => p.categoryId == cat.id)
              .length;
          final percent = totalCount > 0
              ? '${((cCount / totalCount) * 100).round()}%'
              : '0%';
          topCategories.add({
            'name': cat.name,
            'count': cCount,
            'percent': percent,
          });
        }
        topCategories.sort(
          (a, b) => (b['count'] as int).compareTo(a['count'] as int),
        );
      }
    }

    return DashboardData(
      userName: userName,
      locationName: locationName,
      currencySymbol: currencySymbol,
      todaySalesCents: todaySalesCents,
      totalStockCount: totalStock,
      lowStockCount: lowStock,
      pendingTransfersCount: null, // Transfer backend not implemented; honest unavailable
      pendingTransfersDisplay: '—',
      recentActivities: recentActivities,
      salesTrend: salesTrend,
      topCategories: topCategories,
      stockHealth: stockHealth,
      stockHealthRatios: stockHealthRatios,
      stockHealthPercentages: stockHealthPercentages,
      aiInsight: null,
      timezone: tzInfo.timezoneName,
      timezoneOffset: businessOffset,
      totalProductsCount: totalProductsCount,
      supplierCount: supplierCount,
      completedSalesCount: completedSalesCount,
      firstProductId: firstProductId,
      firstProductName: firstProductName,
    );
  }

  Future<({String timezoneName, Duration offset})> _resolveBusinessTimezone({
    required String businessId,
    String? locationId,
  }) async {
    String? tzString;
    final sb = _resolvedClient;

    if (sb != null && sb.auth.currentUser != null && businessId.isNotEmpty && !businessId.startsWith('biz_')) {
      if (locationId != null && locationId.isNotEmpty) {
        try {
          final locRow = await sb
              .from('locations')
              .select('timezone')
              .eq('id', locationId)
              .maybeSingle();
          final ltz = locRow?['timezone'] as String?;
          if (ltz != null && ltz.trim().isNotEmpty) {
            tzString = ltz.trim();
          }
        } catch (_) {}
      }

      if (tzString == null) {
        try {
          final profileRow = await sb
              .from('business_profile_settings')
              .select('timezone')
              .eq('business_id', businessId)
              .maybeSingle();
          final btz = profileRow?['timezone'] as String?;
          if (btz != null && btz.trim().isNotEmpty) {
            tzString = btz.trim();
          }
        } catch (_) {}
      }
    }

    if (tzString == null && businessId.isNotEmpty) {
      final cached = await BusinessProfileRepository(client: sb).loadProfile(businessId: businessId);
      tzString = cached['timezone'] as String?;
    }

    final offset = _parseTimezoneOffset(tzString);
    return (
      timezoneName: tzString ?? 'India Standard Time (GMT+5:30)',
      offset: offset,
    );
  }

  static Duration _parseTimezoneOffset(String? tzString) {
    if (tzString == null || tzString.trim().isEmpty) {
      return const Duration(hours: 5, minutes: 30); // Default to IST for India-based Threadstock
    }

    final trimmed = tzString.trim();

    // Match GMT/UTC offset pattern: e.g. "GMT+5:30", "UTC+05:30", "GMT-5", "+05:30"
    final regex = RegExp(r'(?:GMT|UTC)?\s*([+-])(\d{1,2})(?::(\d{2}))?', caseSensitive: false);
    final match = regex.firstMatch(trimmed);
    if (match != null) {
      final sign = match.group(1) == '-' ? -1 : 1;
      final hours = int.parse(match.group(2)!);
      final minutes = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      return Duration(minutes: sign * (hours * 60 + minutes));
    }

    final lower = trimmed.toLowerCase();
    if (lower.contains('kolkata') || lower.contains('calcutta') || lower.contains('ist') || lower.contains('india')) {
      return const Duration(hours: 5, minutes: 30);
    }
    if (lower.contains('dubai') || lower.contains('uae') || lower.contains('gst')) {
      return const Duration(hours: 4);
    }
    if (lower.contains('singapore') || lower.contains('sgt')) {
      return const Duration(hours: 8);
    }
    if (lower.contains('london') || lower.contains('gmt') || lower.contains('bst') || lower.contains('utc')) {
      return Duration.zero;
    }
    if (lower.contains('new_york') || lower.contains('eastern') || lower.contains('est') || lower.contains('edt')) {
      return const Duration(hours: -5);
    }
    if (lower.contains('chicago') || lower.contains('central') || lower.contains('cst') || lower.contains('cdt')) {
      return const Duration(hours: -6);
    }
    if (lower.contains('denver') || lower.contains('mountain') || lower.contains('mst') || lower.contains('mdt')) {
      return const Duration(hours: -7);
    }
    if (lower.contains('los_angeles') || lower.contains('pacific') || lower.contains('pst') || lower.contains('pdt')) {
      return const Duration(hours: -8);
    }

    try {
      return DateTime.now().timeZoneOffset;
    } catch (_) {
      return const Duration(hours: 5, minutes: 30);
    }
  }

  static String _formatIsoDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatChartDayLabel(DateTime dt, int dayCount) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = months[dt.month - 1];
    return '$m ${dt.day}';
  }

  static String _formatRelativeTime(DateTime businessTime, DateTime nowBusiness) {
    final diff = nowBusiness.difference(businessTime);
    if (diff.inSeconds < 60 && diff.inSeconds >= -5) {
      return 'Just now';
    }
    if (diff.inMinutes < 60 && diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24 && diff.inHours > 0) {
      return '${diff.inHours}h ago';
    }

    final hour = businessTime.hour;
    final minute = businessTime.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final timeStr = '$h12:$minute $ampm';

    final isToday = businessTime.year == nowBusiness.year &&
        businessTime.month == nowBusiness.month &&
        businessTime.day == nowBusiness.day;
    if (isToday) {
      return 'Today, $timeStr';
    }

    final yesterday = nowBusiness.subtract(const Duration(days: 1));
    final isYesterday = businessTime.year == yesterday.year &&
        businessTime.month == yesterday.month &&
        businessTime.day == yesterday.day;
    if (isYesterday) {
      return 'Yesterday, $timeStr';
    }

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[businessTime.month - 1]} ${businessTime.day}, $timeStr';
  }

  Future<String?> _resolveUserName() async {
    final sb = _resolvedClient;
    if (sb == null) return null;
    final user = sb.auth.currentUser;
    if (user == null) return null;

    final metaName = user.userMetadata?['full_name'] as String?;
    if (metaName != null && metaName.trim().isNotEmpty) {
      return metaName.trim();
    }

    try {
      final profile = await sb
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      final pName = profile?['full_name'] as String?;
      if (pName != null && pName.trim().isNotEmpty) {
        return pName.trim();
      }
    } catch (_) {}

    return null;
  }

  static String _resolveCurrencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'AED':
        return 'AED ';
      case 'INR':
      default:
        return '₹';
    }
  }
}
