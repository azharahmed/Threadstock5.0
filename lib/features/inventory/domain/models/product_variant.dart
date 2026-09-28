class ProductVariant {
  final String id;
  final String productId;
  final String sku;
  final String? barcode;
  final int retailPriceCents;
  final int costPriceCents;
  final String status;
  final String? color;
  final String? size;
  final String? material;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.sku,
    this.barcode,
    this.retailPriceCents = 0,
    this.costPriceCents = 0,
    this.status = 'active',
    this.color,
    this.size,
    this.material,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String?,
      retailPriceCents: (json['retail_price_cents'] as num?)?.toInt() ?? 0,
      costPriceCents: (json['cost_price_cents'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
      color: json['color'] as String?,
      size: json['size'] as String?,
      material: json['material'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'sku': sku,
      if (barcode != null) 'barcode': barcode,
      'retail_price_cents': retailPriceCents,
      'cost_price_cents': costPriceCents,
      'status': status,
      if (color != null) 'color': color,
      if (size != null) 'size': size,
      if (material != null) 'material': material,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  ProductVariant copyWith({
    String? id,
    String? productId,
    String? sku,
    String? barcode,
    int? retailPriceCents,
    int? costPriceCents,
    String? status,
    String? color,
    String? size,
    String? material,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      retailPriceCents: retailPriceCents ?? this.retailPriceCents,
      costPriceCents: costPriceCents ?? this.costPriceCents,
      status: status ?? this.status,
      color: color ?? this.color,
      size: size ?? this.size,
      material: material ?? this.material,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductVariant &&
          runtimeType == other.runtimeType &&
          id == other.id;

  String get title {
    final parts = [
      if (color != null && color!.isNotEmpty) color!,
      if (size != null && size!.isNotEmpty) size!,
      if (material != null && material!.isNotEmpty) material!,
    ];
    return parts.isEmpty ? sku : parts.join(' / ');
  }

  @override
  int get hashCode => id.hashCode;
}
