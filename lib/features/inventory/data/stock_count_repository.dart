import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/business/current_business_service.dart';
import '../domain/models/stock_count.dart';
import '../domain/models/stock_count_line.dart';
import '../domain/inventory_change_notifier.dart';

class StockCountRepository {
  final SupabaseClient? client;

  StockCountRepository({this.client});

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveBusinessId() async {
    final centralId = CurrentBusinessService.instance.currentBusinessId;
    if (centralId != null && centralId.isNotEmpty && !centralId.startsWith('biz_')) {
      return centralId;
    }
    final sb = _resolvedClient;
    if (sb == null) return null;
    final user = sb.auth.currentUser;
    if (user == null) return null;

    try {
      final membership = await sb
          .from('memberships')
          .select('business_id')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();

      if (membership != null && membership['business_id'] != null) {
        return membership['business_id'] as String;
      }

      final business = await sb
          .from('businesses')
          .select('id')
          .eq('owner_user_id', user.id)
          .limit(1)
          .maybeSingle();

      return business?['id'] as String?;
    } catch (e) {
      debugPrint('[StockCountRepository] Error resolving business ID: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> startStockCount({
    required String locationId,
    String countType = 'full',
    String? notes,
  }) async {
    final sb = _resolvedClient;
    if (sb == null) throw Exception('Database connection not available');

    final payload = {
      'location_id': locationId,
      'count_type': countType,
      'notes': ?notes,
    };

    final res = await sb.rpc('start_stock_count', params: {'payload': payload});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> submitStockCount({
    required String countId,
    required List<Map<String, dynamic>> lines,
  }) async {
    final sb = _resolvedClient;
    if (sb == null) throw Exception('Database connection not available');

    final payload = {
      'count_id': countId,
      'lines': lines,
    };

    final res = await sb.rpc('submit_stock_count', params: {'payload': payload});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> completeStockCount({
    required String countId,
    List<Map<String, dynamic>>? lines,
  }) async {
    final sb = _resolvedClient;
    if (sb == null) throw Exception('Database connection not available');

    final payload = {
      'count_id': countId,
      'lines': ?lines,
    };

    final res = await sb.rpc('complete_stock_count', params: {'payload': payload});
    InventoryChangeNotifier.instance.notifyInventoryChanged();
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> cancelStockCount({
    required String countId,
    String? reason,
  }) async {
    final sb = _resolvedClient;
    if (sb == null) throw Exception('Database connection not available');

    final payload = {
      'count_id': countId,
      'reason': ?reason,
    };

    final res = await sb.rpc('cancel_stock_count', params: {'payload': payload});
    return Map<String, dynamic>.from(res as Map);
  }

  Future<List<StockCount>> getStockCounts({
    String? status,
    String? locationId,
    int limit = 50,
  }) async {
    final sb = _resolvedClient;
    if (sb == null) return [];

    final businessId = await _resolveBusinessId();
    if (businessId == null) return [];

    try {
      var query = sb.from('stock_counts').select('''
        id,
        business_id,
        location_id,
        count_number,
        count_type,
        status,
        notes,
        started_by,
        started_at,
        submitted_by,
        submitted_at,
        completed_by,
        completed_at,
        cancelled_by,
        cancelled_at,
        created_at,
        updated_at,
        stock_locations:location_id (
          name
        )
      ''').eq('business_id', businessId);

      if (status != null && status.isNotEmpty && status != 'all') {
        query = query.eq('status', status);
      }

      if (locationId != null && locationId.isNotEmpty) {
        query = query.eq('location_id', locationId);
      }

      final response = await query.order('created_at', ascending: false).limit(limit);

      return (response as List<dynamic>)
          .map((row) => StockCount.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[StockCountRepository] Error fetching stock counts: $e');
      return [];
    }
  }

  Future<List<StockCountLine>> getStockCountLines({
    required String countId,
  }) async {
    final sb = _resolvedClient;
    if (sb == null) return [];

    try {
      final response = await sb.from('stock_count_lines').select('''
        id,
        business_id,
        count_id,
        variant_id,
        expected_qty,
        counted_qty,
        reconciled_qty,
        discrepancy,
        reason,
        status,
        counted_by,
        counted_at,
        created_at,
        updated_at,
        product_variants:variant_id (
          sku,
          barcode,
          products:product_id (
            name,
            image_url
          )
        )
      ''').eq('count_id', countId).order('created_at', ascending: true);

      return (response as List<dynamic>)
          .map((row) => StockCountLine.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[StockCountRepository] Error fetching count lines: $e');
      return [];
    }
  }
}
