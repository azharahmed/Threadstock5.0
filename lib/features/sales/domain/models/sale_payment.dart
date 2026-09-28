class SalePayment {
  final String id;
  final String saleId;
  final String businessId;
  final String paymentMethod;
  final int amountMinor;
  final String currencyCode;
  final String status;
  final String processingType;
  final String? referenceNumber;
  final String? notes;
  final DateTime? createdAt;

  const SalePayment({
    required this.id,
    required this.saleId,
    required this.businessId,
    required this.paymentMethod,
    required this.amountMinor,
    this.currencyCode = 'INR',
    this.status = 'completed',
    this.processingType = 'recorded',
    this.referenceNumber,
    this.notes,
    this.createdAt,
  });

  double get amount => amountMinor / 100.0;

  factory SalePayment.fromJson(Map<String, dynamic> json) {
    return SalePayment(
      id: json['id'] as String? ?? '',
      saleId: json['sale_id'] as String? ?? '',
      businessId: json['business_id'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currencyCode: json['currency_code'] as String? ?? 'INR',
      status: json['status'] as String? ?? 'completed',
      processingType: json['processing_type'] as String? ?? 'recorded',
      referenceNumber: json['reference_number'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_id': saleId,
      'business_id': businessId,
      'payment_method': paymentMethod,
      'amount_minor': amountMinor,
      'currency_code': currencyCode,
      'status': status,
      'processing_type': processingType,
      'reference_number': referenceNumber,
      'notes': notes,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}
