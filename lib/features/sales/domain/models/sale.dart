import 'sale_item.dart';
import 'sale_payment.dart';

class Sale {
  final String id;
  final String businessId;
  final String locationId;
  final String saleNumber;
  final String? customerId;
  final String status;
  final int subtotalMinor;
  final int discountMinor;
  final int taxMinor;
  final int totalMinor;
  final String currencyCode;
  final String? discountType;
  final double? discountRate;
  final String? note;
  final String? idempotencyKey;
  final String? createdBy;
  final String? heldBy;
  final String? heldByName;
  final DateTime? heldAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final List<SaleItem> items;
  final List<SalePayment> payments;
  final String? customerName;
  final String? customerPhone;
  final String? locationName;

  const Sale({
    required this.id,
    required this.businessId,
    required this.locationId,
    required this.saleNumber,
    this.customerId,
    this.status = 'completed',
    required this.subtotalMinor,
    this.discountMinor = 0,
    this.taxMinor = 0,
    required this.totalMinor,
    this.currencyCode = 'INR',
    this.discountType,
    this.discountRate,
    this.note,
    this.idempotencyKey,
    this.createdBy,
    this.heldBy,
    this.heldByName,
    this.heldAt,
    this.completedAt,
    this.createdAt,
    this.items = const [],
    this.payments = const [],
    this.customerName,
    this.customerPhone,
    this.locationName,
  });

  double get subtotal => subtotalMinor / 100.0;
  double get discount => discountMinor / 100.0;
  double get tax => taxMinor / 100.0;
  double get total => totalMinor / 100.0;

  factory Sale.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['sale_items'] as List<dynamic>?)
            ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        (json['items'] as List<dynamic>?)
            ?.map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final paymentsList = (json['sale_payments'] as List<dynamic>?)
            ?.map((e) => SalePayment.fromJson(e as Map<String, dynamic>))
            .toList() ??
        (json['payments'] as List<dynamic>?)
            ?.map((e) => SalePayment.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    final customerEmbed = json['customers'];
    final locationEmbed = json['locations'];
    final customerName = json['customer_name'] as String? ??
        (customerEmbed is Map ? customerEmbed['name'] as String? : null);
    final customerPhone = json['customer_phone'] as String? ??
        (customerEmbed is Map ? customerEmbed['phone'] as String? : null);
    final locationName = json['location_name'] as String? ??
        (locationEmbed is Map ? locationEmbed['name'] as String? : null);

    return Sale(
      id: json['id'] as String? ?? '',
      businessId: json['business_id'] as String? ?? '',
      locationId: json['location_id'] as String? ?? '',
      saleNumber: json['sale_number'] as String? ?? '',
      customerId: json['customer_id'] as String?,
      status: json['status'] as String? ?? 'completed',
      subtotalMinor: (json['subtotal_minor'] as num?)?.toInt() ?? 0,
      discountMinor: (json['discount_minor'] as num?)?.toInt() ?? 0,
      taxMinor: (json['tax_minor'] as num?)?.toInt() ?? 0,
      totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
      currencyCode: json['currency_code'] as String? ?? 'INR',
      discountType: json['discount_type'] as String?,
      discountRate: json['discount_rate'] == null
          ? null
          : double.tryParse(json['discount_rate'].toString()),
      note: json['note'] as String?,
      idempotencyKey: json['idempotency_key'] as String?,
      createdBy: json['created_by'] as String?,
      heldBy: json['held_by'] as String?,
      heldByName: json['held_by_name'] as String?,
      heldAt: json['held_at'] != null
          ? DateTime.tryParse(json['held_at'].toString())
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      items: itemsList,
      payments: paymentsList,
      customerName: customerName,
      customerPhone: customerPhone,
      locationName: locationName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'location_id': locationId,
      'sale_number': saleNumber,
      'customer_id': customerId,
      'status': status,
      'subtotal_minor': subtotalMinor,
      'discount_minor': discountMinor,
      'tax_minor': taxMinor,
      'total_minor': totalMinor,
      'currency_code': currencyCode,
      'discount_type': discountType,
      'discount_rate': discountRate,
      'note': note,
      'idempotency_key': idempotencyKey,
      'created_by': createdBy,
      'held_by': heldBy,
      'held_by_name': heldByName,
      if (heldAt != null) 'held_at': heldAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'payments': payments.map((p) => p.toJson()).toList(),
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'location_name': locationName,
    };
  }
}
