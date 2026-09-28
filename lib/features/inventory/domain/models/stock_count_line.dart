class StockCountLine {
  final String id;
  final String businessId;
  final String countId;
  final String variantId;
  final int expectedQty;
  final DateTime? snapshotBalanceUpdatedAt;
  final int? countedQty;
  final int? reconciledQty;
  final int? discrepancy;
  final String? reason;
  final String status; // 'pending', 'counted', 'verified', 'discrepancy', 'approved', 'rejected', 'requires_recount'
  final String? countedBy;
  final DateTime? countedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined display attributes
  final String? productName;
  final String? sku;
  final String? barcode;

  const StockCountLine({
    required this.id,
    required this.businessId,
    required this.countId,
    required this.variantId,
    required this.expectedQty,
    this.snapshotBalanceUpdatedAt,
    this.countedQty,
    this.reconciledQty,
    this.discrepancy,
    this.reason,
    required this.status,
    this.countedBy,
    this.countedAt,
    required this.createdAt,
    required this.updatedAt,
    this.productName,
    this.sku,
    this.barcode,
  });

  factory StockCountLine.fromJson(Map<String, dynamic> json) {
    String? pName;
    String? vSku;
    String? vBarcode;

    if (json['product_variants'] is Map) {
      final vMap = json['product_variants'] as Map<String, dynamic>;
      vSku = vMap['sku'] as String?;
      vBarcode = vMap['barcode'] as String?;
      if (vMap['products'] is Map) {
        pName = (vMap['products'] as Map<String, dynamic>)['name'] as String?;
      }
    }

    return StockCountLine(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      countId: json['count_id'] as String,
      variantId: json['variant_id'] as String,
      expectedQty: (json['expected_qty'] as num?)?.toInt() ?? 0,
      snapshotBalanceUpdatedAt: json['snapshot_balance_updated_at'] != null
          ? DateTime.tryParse(json['snapshot_balance_updated_at'] as String)
          : null,
      countedQty: (json['counted_qty'] as num?)?.toInt(),
      reconciledQty: (json['reconciled_qty'] as num?)?.toInt(),
      discrepancy: (json['discrepancy'] as num?)?.toInt(),
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'pending',
      countedBy: json['counted_by'] as String?,
      countedAt: json['counted_at'] != null
          ? DateTime.tryParse(json['counted_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      productName: pName,
      sku: vSku,
      barcode: vBarcode,
    );
  }

  int get variance => (countedQty ?? expectedQty) - expectedQty;
  bool get hasDiscrepancy => (countedQty != null) && (countedQty != expectedQty);
  String? get variantSku => sku;
}
