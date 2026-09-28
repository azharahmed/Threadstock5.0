import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/business/current_business_service.dart';
import '../domain/models/inventory_ledger_entry.dart';

class InventoryLedgerRepository {
  final SupabaseClient? client;

  InventoryLedgerRepository({this.client});

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
      debugPrint('[InventoryLedgerRepository] Error resolving business ID: $e');
      return null;
    }
  }

  Future<List<InventoryLedgerEntry>> getLedgerEntries({
    String? locationId,
    String? variantId,
    String? eventType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final sb = _resolvedClient;
    if (sb == null) return [];

    final businessId = await _resolveBusinessId();
    if (businessId == null) return [];

    try {
      var query = sb.from('inventory_ledger').select('''
        id,
        business_id,
        location_id,
        variant_id,
        event_type,
        quantity_delta,
        available_delta,
        committed_delta,
        damaged_delta,
        balance_after,
        reference_type,
        reference_id,
        notes,
        actor_id,
        metadata,
        created_at,
        profiles:actor_id (
          full_name,
          email
        ),
        stock_locations:location_id (
          name
        ),
        product_variants:variant_id (
          sku,
          products:product_id (
            name
          )
        )
      ''').eq('business_id', businessId);

      if (locationId != null && locationId.isNotEmpty) {
        query = query.eq('location_id', locationId);
      }

      if (variantId != null && variantId.isNotEmpty) {
        query = query.eq('variant_id', variantId);
      }

      if (eventType != null && eventType.isNotEmpty && eventType != 'all') {
        query = query.eq('event_type', eventType);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>)
          .map((row) => InventoryLedgerEntry.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[InventoryLedgerRepository] Error fetching ledger entries: $e');
      return [];
    }
  }
}
