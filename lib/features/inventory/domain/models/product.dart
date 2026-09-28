class Product {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final String? brandId;
  final String? categoryId;
  final String? supplierId;
  final String? taxCategory;
  final List<String> tags;
  final String status; // 'draft', 'active', 'archived'
  final bool trackStockLevels;
  final int? lowStockThreshold;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  const Product({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    this.brandId,
    this.categoryId,
    this.supplierId,
    this.taxCategory,
    this.tags = const [],
    this.status = 'draft',
    this.trackStockLevels = false,
    this.lowStockThreshold,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  bool get isDraft => status == 'draft';
  bool get isActive => status == 'active';
  bool get isArchived => status == 'archived';

  factory Product.fromJson(Map<String, dynamic> json) {
    List<String> parsedTags = [];
    if (json['tags'] is List) {
      parsedTags = (json['tags'] as List).map((t) => t.toString()).toList();
    }

    return Product(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      brandId: json['brand_id'] as String?,
      categoryId: json['category_id'] as String?,
      supplierId: json['supplier_id'] as String?,
      taxCategory: json['tax_category'] as String?,
      tags: parsedTags,
      status: json['status'] as String? ?? 'draft',
      trackStockLevels: json['track_stock_levels'] as bool? ?? false,
      lowStockThreshold: (json['low_stock_threshold'] as num?)?.toInt(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      if (description != null) 'description': description,
      if (brandId != null) 'brand_id': brandId,
      if (categoryId != null) 'category_id': categoryId,
      if (supplierId != null) 'supplier_id': supplierId,
      if (taxCategory != null) 'tax_category': taxCategory,
      'tags': tags,
      'status': status,
      'track_stock_levels': trackStockLevels,
      if (lowStockThreshold != null) 'low_stock_threshold': lowStockThreshold,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (publishedAt != null) 'published_at': publishedAt!.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? businessId,
    String? name,
    String? description,
    String? brandId,
    String? categoryId,
    String? supplierId,
    String? taxCategory,
    List<String>? tags,
    String? status,
    bool? trackStockLevels,
    int? lowStockThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return Product(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      description: description ?? this.description,
      brandId: brandId ?? this.brandId,
      categoryId: categoryId ?? this.categoryId,
      supplierId: supplierId ?? this.supplierId,
      taxCategory: taxCategory ?? this.taxCategory,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      trackStockLevels: trackStockLevels ?? this.trackStockLevels,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
