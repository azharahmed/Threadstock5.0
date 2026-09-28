class Supplier {
  final String id;
  final String businessId;
  final String name;
  final String? contactEmail;
  final String? contactPhone;
  final String? taxIdentifier;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Supplier({
    required this.id,
    required this.businessId,
    required this.name,
    this.contactEmail,
    this.contactPhone,
    this.taxIdentifier,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      taxIdentifier: json['tax_identifier'] as String?,
      status: json['status'] as String? ?? 'active',
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
      if (contactEmail != null) 'contact_email': contactEmail,
      if (contactPhone != null) 'contact_phone': contactPhone,
      if (taxIdentifier != null) 'tax_identifier': taxIdentifier,
      'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Supplier copyWith({
    String? id,
    String? businessId,
    String? name,
    String? contactEmail,
    String? contactPhone,
    String? taxIdentifier,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      taxIdentifier: taxIdentifier ?? this.taxIdentifier,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Supplier && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
