import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/business/current_business_service.dart';
import '../domain/models/product.dart';
import '../domain/models/product_inventory_summary.dart';
import '../domain/models/product_variant.dart';
import '../domain/inventory_change_notifier.dart';
import 'product_repository.dart';

class InventoryRepository {
  final SupabaseClient? client;

  InventoryRepository({this.client});

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<String?> resolveCurrentBusinessId() async {
    final centralId = CurrentBusinessService.instance.currentBusinessId;
    if (centralId != null &&
        centralId.isNotEmpty &&
        !centralId.startsWith('biz_')) {
      return centralId;
    }

    final sb = _resolvedClient;
    if (sb == null) return 'default_business';
    final user = sb.auth.currentUser;
    if (user == null) return 'default_business';

    try {
      final membership = await sb
          .from('memberships')
          .select('business_id')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();

      final businessId = membership?['business_id'] as String?;
      if (businessId != null && businessId.isNotEmpty) {
        return businessId;
      }

      final business = await sb
          .from('businesses')
          .select('id')
          .eq('owner_user_id', user.id)
          .limit(1)
          .maybeSingle();

      return business?['id'] as String? ?? 'default_business';
    } catch (e) {
      debugPrint('[InventoryRepository] Error resolving business_id: $e');
      return 'default_business';
    }
  }

  /// Fetches inventory summaries for all products scoped by business_id and optional location_id.
  /// If [locationId] is null or 'all', aggregates across all locations for the business.
  Future<Map<String, ProductInventorySummary>> getProductInventorySummaries({
    String? businessId,
    String? locationId,
    List<Product>? preloadedProducts,
  }) async {
    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';
    final sb = _resolvedClient;

    List<Product> products = preloadedProducts ?? [];

    if (sb != null && sb.auth.currentUser != null) {
      // 1. Fetch products if not supplied
      if (products.isEmpty) {
        final prodRows = await sb
            .from('products')
            .select()
            .eq('business_id', resolvedBusinessId)
            .order('created_at', ascending: false);
        products = (prodRows as List)
            .map((r) => Product.fromJson(r as Map<String, dynamic>))
            .toList();
      }

      if (products.isEmpty) {
        return {};
      }

      final productIds = products.map((p) => p.id).toList();

      // 2. Fetch product variants for these products
      final varRows = await sb
          .from('product_variants')
          .select()
          .inFilter('product_id', productIds);
      final variantsList = (varRows as List)
          .map((r) => ProductVariant.fromJson(r as Map<String, dynamic>))
          .toList();

      // Group variants by productId
      final Map<String, List<ProductVariant>> variantsByProduct = {};
      for (final v in variantsList) {
        variantsByProduct.putIfAbsent(v.productId, () => []).add(v);
      }

      // 3. Fetch inventory balances
      var balanceQuery = sb
          .from('inventory_balances')
          .select(
            'id, location_id, variant_id, available_qty, committed_qty, damaged_qty',
          )
          .eq('business_id', resolvedBusinessId);

      final isSpecificLocation =
          locationId != null &&
          locationId.isNotEmpty &&
          locationId != 'all' &&
          locationId != 'All Locations';

      if (isSpecificLocation) {
        balanceQuery = balanceQuery.eq('location_id', locationId);
      }

      final balanceRows = await balanceQuery;
      final Map<String, List<Map<String, dynamic>>> balancesByVariant = {};
      for (final b in (balanceRows as List)) {
        final map = b as Map<String, dynamic>;
        final varId = map['variant_id'] as String?;
        if (varId != null) {
          balancesByVariant.putIfAbsent(varId, () => []).add(map);
        }
      }

      // 4. Build summaries
      final Map<String, ProductInventorySummary> summaries = {};
      for (final p in products) {
        final pVariants = variantsByProduct[p.id] ?? [];
        int availableQty = 0;
        int committedQty = 0;
        int damagedQty = 0;

        for (final v in pVariants) {
          final bList = balancesByVariant[v.id] ?? [];
          for (final b in bList) {
            availableQty += (b['available_qty'] as num?)?.toInt() ?? 0;
            committedQty += (b['committed_qty'] as num?)?.toInt() ?? 0;
            damagedQty += (b['damaged_qty'] as num?)?.toInt() ?? 0;
          }
        }

        final threshold = p.lowStockThreshold;
        final stockStatus = ProductInventorySummary.calculateStockStatus(
          availableQty: availableQty,
          lowStockThreshold: threshold,
          trackStockLevels: p.trackStockLevels,
        );

        summaries[p.id] = ProductInventorySummary(
          productId: p.id,
          variantCount: pVariants.length,
          availableQty: availableQty,
          committedQty: committedQty,
          damagedQty: damagedQty,
          lowStockThreshold: threshold,
          trackStockLevels: p.trackStockLevels,
          stockStatus: stockStatus,
          variants: pVariants,
        );
      }

      return summaries;
    }

    // In-memory test environment fallback when running unit/widget tests
    if (ProductRepository.localFallbackProducts.isNotEmpty) {
      final prods = ProductRepository.localFallbackProducts.values
          .where((p) => p.businessId == resolvedBusinessId)
          .toList();
      final isSpecificLoc = locationId != null &&
          locationId.isNotEmpty &&
          locationId != 'all' &&
          locationId != 'All Locations';
      final Map<String, ProductInventorySummary> testSummaries = {};
      for (final p in prods) {
        final variants = ProductRepository.getFallbackVariants(p.id);
        final Map<String, int> locQuantities = {};
        for (final entry in ProductRepository.localFallbackInventory.entries) {
          if (entry.key.startsWith('${p.id}_')) {
            final loc = entry.key.substring('${p.id}_'.length);
            locQuantities[loc] = entry.value;
          }
          for (final v in variants) {
            if (entry.key.startsWith('${v.id}_')) {
              final loc = entry.key.substring('${v.id}_'.length);
              locQuantities[loc] = entry.value;
            }
          }
        }

        int availableQty = 0;
        if (isSpecificLoc) {
          availableQty = locQuantities[locationId] ?? 0;
        } else {
          availableQty = locQuantities.values.fold(0, (sum, val) => sum + val);
        }
        final threshold = p.lowStockThreshold;
        final status = ProductInventorySummary.calculateStockStatus(
          availableQty: availableQty,
          lowStockThreshold: threshold,
          trackStockLevels: p.trackStockLevels,
        );
        testSummaries[p.id] = ProductInventorySummary(
          productId: p.id,
          variantCount: variants.length,
          availableQty: availableQty,
          committedQty: 0,
          damagedQty: 0,
          lowStockThreshold: threshold,
          trackStockLevels: p.trackStockLevels,
          stockStatus: status,
          variants: variants,
        );
      }
      return testSummaries;
    }

    // Offline / unauthenticated honest empty state
    return {};
  }

  /// Fetches inventory summary for a single product.
  Future<ProductInventorySummary?> getProductInventorySummary(
    String productId, {
    String? businessId,
    String? locationId,
  }) async {
    final summaries = await getProductInventorySummaries(
      businessId: businessId,
      locationId: locationId,
    );
    return summaries[productId];
  }

  /// Authoritative server-side stock adjustment via adjust_stock RPC.
  Future<Map<String, dynamic>> adjustStock({
    String? businessId,
    required String locationId,
    required String variantId,
    required int quantityDelta,
    required String reason,
    String? notes,
    String? referenceType,
    String? referenceId,
    int? expectedCurrentQty,
  }) async {
    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';
    final sb = _resolvedClient;
    if (sb == null) {
      throw StateError('Supabase client not initialized');
    }

    final payload = {
      'business_id': resolvedBusinessId,
      'location_id': locationId,
      'variant_id': variantId,
      'quantity_delta': quantityDelta,
      'reason': reason.trim(),
      if (notes != null && notes.isNotEmpty) 'notes': notes.trim(),
      if (referenceType != null && referenceType.isNotEmpty)
        'reference_type': referenceType.trim(),
      if (referenceId != null && referenceId.isNotEmpty)
        'reference_id': referenceId,
      'expected_current_qty': ?expectedCurrentQty,
    };

    final res = await sb.rpc('adjust_stock', params: {'payload': payload});
    InventoryChangeNotifier.instance.notifyInventoryChanged();
    return Map<String, dynamic>.from(res as Map);
  }

  /// Authoritative server-side damaged stock lifecycle via record_damaged_stock RPC.
  Future<Map<String, dynamic>> recordDamagedStock({
    String? businessId,
    required String locationId,
    required String variantId,
    required String action, // 'mark_damaged' | 'restore_sellable' | 'write_off'
    required int quantity,
    required String reason,
    String? notes,
    String? referenceType,
    String? referenceId,
  }) async {
    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';
    final sb = _resolvedClient;
    if (sb == null) {
      throw StateError('Supabase client not initialized');
    }

    final payload = {
      'business_id': resolvedBusinessId,
      'location_id': locationId,
      'variant_id': variantId,
      'action': action,
      'quantity': quantity,
      'reason': reason.trim(),
      if (notes != null && notes.isNotEmpty) 'notes': notes.trim(),
      if (referenceType != null && referenceType.isNotEmpty)
        'reference_type': referenceType.trim(),
      if (referenceId != null && referenceId.isNotEmpty)
        'reference_id': referenceId,
    };

    final res = await sb.rpc('record_damaged_stock', params: {'payload': payload});
    InventoryChangeNotifier.instance.notifyInventoryChanged();
    return Map<String, dynamic>.from(res as Map);
  }

  /// Fetches balances for a specific variant at a location (or aggregated).
  Future<Map<String, int>> getVariantBalances({
    required String variantId,
    String? locationId,
    String? businessId,
  }) async {
    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';
    final sb = _resolvedClient;
    if (sb == null) {
      return {'available': 0, 'damaged': 0, 'committed': 0};
    }

    try {
      var query = sb
          .from('inventory_balances')
          .select('available_qty, committed_qty, damaged_qty')
          .eq('business_id', resolvedBusinessId)
          .eq('variant_id', variantId);

      if (locationId != null && locationId.isNotEmpty) {
        query = query.eq('location_id', locationId);
      }

      final rows = await query;
      int available = 0;
      int committed = 0;
      int damaged = 0;

      for (final r in (rows as List<dynamic>)) {
        available += (r['available_qty'] as num?)?.toInt() ?? 0;
        committed += (r['committed_qty'] as num?)?.toInt() ?? 0;
        damaged += (r['damaged_qty'] as num?)?.toInt() ?? 0;
      }

      return {
        'available': available,
        'committed': committed,
        'damaged': damaged,
      };
    } catch (e) {
      debugPrint('[InventoryRepository] getVariantBalances error: $e');
      return {'available': 0, 'damaged': 0, 'committed': 0};
    }
  }
}
