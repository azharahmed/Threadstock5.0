class StockLocation {
  final String id;
  final String businessId;
  final String name;
  final String locationType;
  final String status;
  final String? streetAddress;
  final String? city;
  final String? postalCode;
  final String? countryCode;
  final String? timezone;
  final String? googlePlaceId;
  final double? latitude;
  final double? longitude;
  final String? formattedAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StockLocation({
    required this.id,
    required this.businessId,
    required this.name,
    this.locationType = 'warehouse',
    this.status = 'active',
    this.streetAddress,
    this.city,
    this.postalCode,
    this.countryCode,
    this.timezone,
    this.googlePlaceId,
    this.latitude,
    this.longitude,
    this.formattedAddress,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  factory StockLocation.fromJson(Map<String, dynamic> json) {
    return StockLocation(
      id: json['id'] as String,
      businessId: json['business_id'] as String,
      name: json['name'] as String,
      locationType: json['location_type'] as String? ?? 'warehouse',
      status: json['status'] as String? ?? 'active',
      streetAddress: json['street_address'] as String?,
      city: json['city'] as String?,
      postalCode: json['postal_code'] as String?,
      countryCode: json['country_code'] as String?,
      timezone: json['timezone'] as String?,
      googlePlaceId: json['google_place_id'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      formattedAddress: json['formatted_address'] as String?,
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
      'location_type': locationType,
      'status': status,
      if (streetAddress != null) 'street_address': streetAddress,
      if (city != null) 'city': city,
      if (postalCode != null) 'postal_code': postalCode,
      if (countryCode != null) 'country_code': countryCode,
      if (timezone != null) 'timezone': timezone,
      if (googlePlaceId != null) 'google_place_id': googlePlaceId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (formattedAddress != null) 'formatted_address': formattedAddress,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  StockLocation copyWith({
    String? id,
    String? businessId,
    String? name,
    String? locationType,
    String? status,
    String? streetAddress,
    String? city,
    String? postalCode,
    String? countryCode,
    String? timezone,
    String? googlePlaceId,
    double? latitude,
    double? longitude,
    String? formattedAddress,
  }) {
    return StockLocation(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      locationType: locationType ?? this.locationType,
      status: status ?? this.status,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      countryCode: countryCode ?? this.countryCode,
      timezone: timezone ?? this.timezone,
      googlePlaceId: googlePlaceId ?? this.googlePlaceId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      formattedAddress: formattedAddress ?? this.formattedAddress,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
