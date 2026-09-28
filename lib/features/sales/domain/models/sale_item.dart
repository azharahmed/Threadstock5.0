class SaleItem {
  final String id;
  final String saleId;
  final String? productId;
  final String? variantId;
  final String skuSnapshot;
  final String productNameSnapshot;
  final String? variantTitleSnapshot;
  final int quantity;
  final int unitPriceMinor;
  final int unitCostMinor;
  final int discountMinor;
  final int taxableAmountMinor;
  final int taxMinor;
  final int lineTotalMinor;
  final String? taxCategorySnapshot;
  final DateTime? createdAt;

  const SaleItem({
    required this.id,
    required this.saleId,
    this.productId,
    this.variantId,
    required this.skuSnapshot,
    required this.productNameSnapshot,
    this.variantTitleSnapshot,
    required this.quantity,
    required this.unitPriceMinor,
    this.unitCostMinor = 0,
    this.discountMinor = 0,
    required this.taxableAmountMinor,
    this.taxMinor = 0,
    required this.lineTotalMinor,
    this.taxCategorySnapshot,
    this.createdAt,
  });

  double get unitPrice => unitPriceMinor / 100.0;
  double get lineTotal => lineTotalMinor / 100.0;
  double get discount => discountMinor / 100.0;
  double get tax => taxMinor / 100.0;

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] as String? ?? '',
      saleId: json['sale_id'] as String? ?? '',
      productId: json['product_id'] as String?,
      variantId: json['variant_id'] as String?,
      skuSnapshot: json['sku_snapshot'] as String? ?? '',
      productNameSnapshot: json['product_name_snapshot'] as String? ?? '',
      variantTitleSnapshot: json['variant_title_snapshot'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPriceMinor: (json['unit_price_minor'] as num?)?.toInt() ?? 0,
      unitCostMinor: (json['unit_cost_minor'] as num?)?.toInt() ?? 0,
      discountMinor: (json['discount_minor'] as num?)?.toInt() ?? 0,
      taxableAmountMinor: (json['taxable_amount_minor'] as num?)?.toInt() ?? 0,
      taxMinor: (json['tax_minor'] as num?)?.toInt() ?? 0,
      lineTotalMinor: (json['line_total_minor'] as num?)?.toInt() ?? 0,
      taxCategorySnapshot: json['tax_category_snapshot'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'product_id': productId,
      'variant_id': variantId,
      'sku_snapshot': skuSnapshot,
      'product_name_snapshot': productNameSnapshot,
      'variant_title_snapshot': variantTitleSnapshot,
      'quantity': quantity,
      'unit_price_minor': unitPriceMinor,
      'unit_cost_minor': unitCostMinor,
      'discount_minor': discountMinor,
      'taxable_amount_minor': taxableAmountMinor,
      'tax_minor': taxMinor,
      'line_total_minor': lineTotalMinor,
      'tax_category_snapshot': taxCategorySnapshot,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
