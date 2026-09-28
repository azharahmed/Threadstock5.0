class Business {
  final String id;
  final String ownerUserId;
  final String legalName;
  final String businessType;
  final String countryCode;
  final String currencyCode;
  final String locationRange;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Business({
    required this.id,
    required this.ownerUserId,
    required this.legalName,
    required this.businessType,
    required this.countryCode,
    required this.currencyCode,
    required this.locationRange,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      ownerUserId: json['owner_user_id'] as String? ?? '',
      legalName: json['legal_name'] as String? ?? '',
      businessType: json['business_type'] as String? ?? '',
      countryCode: json['country_code'] as String? ?? '',
      currencyCode: json['currency_code'] as String? ?? '',
      locationRange: json['location_range'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_user_id': ownerUserId,
      'legal_name': legalName,
      'business_type': businessType,
      'country_code': countryCode,
      'currency_code': currencyCode,
      'location_range': locationRange,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Business copyWith({
    String? id,
    String? ownerUserId,
    String? legalName,
    String? businessType,
    String? countryCode,
    String? currencyCode,
    String? locationRange,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Business(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      legalName: legalName ?? this.legalName,
      businessType: businessType ?? this.businessType,
      countryCode: countryCode ?? this.countryCode,
      currencyCode: currencyCode ?? this.currencyCode,
      locationRange: locationRange ?? this.locationRange,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
