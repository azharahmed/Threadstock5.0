class InventoryLedgerEntry {
  final String id;
  final String businessId;
  final String locationId;
  final String variantId;
  final String eventType;
  final int quantityDelta;
  final int availableDelta;
  final int committedDelta;
  final int damagedDelta;
  final int? balanceAfter;
  final String? referenceType;
  final String? referenceId;
  final String? notes;
  final String? actorId;
  final String? actorName;
  final String? actorEmail;
  final String? locationName;
  final String? productName;
  final String? variantSku;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const InventoryLedgerEntry({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.variantId,
    required this.eventType,
    required this.quantityDelta,
    required this.availableDelta,
    required this.committedDelta,
    required this.damagedDelta,
    this.balanceAfter,
    this.referenceType,
    this.referenceId,
    this.notes,
    this.actorId,
    this.actorName,
    this.actorEmail,
    this.locationName,
    this.productName,
    this.variantSku,
    this.metadata,
    required this.createdAt,
  });

  factory InventoryLedgerEntry.fromJson(Map<String, dynamic> json) {
    String? actorName;
    String? actorEmail;
    if (json['profiles'] is Map) {
      final p = json['profiles'] as Map<String, dynamic>;
      actorName = p['full_name'] as String?;
      actorEmail = p['email'] as String?;
    } else if (json['actor'] is Map) {
      final p = json['actor'] as Map<String, dynamic>;
      actorName = p['full_name'] as String?;
      actorEmail = p['email'] as String?;
    }

    String? locationName;
    if (json['stock_locations'] is Map) {
      locationName = (json['stock_locations'] as Map<String, dynamic>)['name'] as String?;
    }

    String? productName;
    String? variantSku;
    if (json['product_variants'] is Map) {
      final v = json['product_variants'] as Map<String, dynamic>;
      variantSku = v['sku'] as String?;
      if (v['products'] is Map) {
        productName = (v['products'] as Map<String, dynamic>)['name'] as String?;
      }
    }

    return InventoryLedgerEntry(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      locationId: json['location_id'] as String,
      variantId: json['variant_id'] as String,
      eventType: json['event_type'] as String,
      quantityDelta: (json['quantity_delta'] as num?)?.toInt() ?? 0,
      availableDelta: (json['available_delta'] as num?)?.toInt() ?? 0,
      committedDelta: (json['committed_delta'] as num?)?.toInt() ?? 0,
      damagedDelta: (json['damaged_delta'] as num?)?.toInt() ?? 0,
      balanceAfter: (json['balance_after'] as num?)?.toInt(),
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      notes: json['notes'] as String?,
      actorId: json['actor_id'] as String?,
      actorName: actorName,
      actorEmail: actorEmail,
      locationName: locationName,
      productName: productName,
      variantSku: variantSku,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
