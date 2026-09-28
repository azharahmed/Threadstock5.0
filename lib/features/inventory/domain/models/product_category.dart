class ProductCategory {
  final String id;
  final String businessId;
  final String name;
  final String? parentCategoryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductCategory({
    required this.id,
    required this.businessId,
    required this.name,
    this.parentCategoryId,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      parentCategoryId: json['parent_category_id'] as String?,
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
      'business_id': businessId,
      'name': name,
      if (parentCategoryId != null) 'parent_category_id': parentCategoryId,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
