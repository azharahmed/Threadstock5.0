import 'dart:typed_data';
import 'package:intl/intl.dart' as intl;

import 'sale.dart';
import 'sale_item.dart';
import 'sale_payment.dart';
import 'customer.dart';
import '../../../inventory/domain/models/stock_location.dart';

enum InvoiceFormat {
  a4,
  thermal80mm,
}

class InvoiceBusinessInfo {
  final String id;
  final String displayName;
  final String legalName;
  final String? logoUrl;
  final Uint8List? logoBytes;
  final String? streetAddress;
  final String? city;
  final String? postalCode;
  final String? phone;
  final String? email;
  final String? website;
  final bool isGstRegistered;
  final String? gstin;

  const InvoiceBusinessInfo({
    required this.id,
    required this.displayName,
    this.legalName = '',
    this.logoUrl,
    this.logoBytes,
    this.streetAddress,
    this.city,
    this.postalCode,
    this.phone,
    this.email,
    this.website,
    this.isGstRegistered = false,
    this.gstin,
  });

  String get effectiveName =>
      displayName.isNotEmpty ? displayName : (legalName.isNotEmpty ? legalName : 'ThreadStock');

  String get addressLine {
    final parts = [
      if (streetAddress != null && streetAddress!.trim().isNotEmpty) streetAddress!.trim(),
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
      if (postalCode != null && postalCode!.trim().isNotEmpty) postalCode!.trim(),
    ];
    return parts.join(', ');
  }
}

class InvoiceCustomerInfo {
  final String? id;
  final String name;
  final String? phone;
  final String? email;
  final bool isWalkIn;

  const InvoiceCustomerInfo({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.isWalkIn = false,
  });

  factory InvoiceCustomerInfo.walkIn() {
    return const InvoiceCustomerInfo(
      name: 'Walk-in Customer',
      isWalkIn: true,
    );
  }

  factory InvoiceCustomerInfo.fromCustomer(Customer customer) {
    return InvoiceCustomerInfo(
      id: customer.id,
      name: customer.name.isNotEmpty ? customer.name : 'Customer',
      phone: customer.phone,
      email: customer.email,
      isWalkIn: false,
    );
  }
}

class InvoiceLocationInfo {
  final String id;
  final String name;
  final String? streetAddress;
  final String? city;
  final String? postalCode;

  const InvoiceLocationInfo({
    required this.id,
    required this.name,
    this.streetAddress,
    this.city,
    this.postalCode,
  });

  factory InvoiceLocationInfo.fromLocation(StockLocation loc) {
    return InvoiceLocationInfo(
      id: loc.id,
      name: loc.name,
      streetAddress: loc.streetAddress,
      city: loc.city,
      postalCode: loc.postalCode,
    );
  }

  String get addressLine {
    final parts = [
      if (streetAddress != null && streetAddress!.trim().isNotEmpty) streetAddress!.trim(),
      if (city != null && city!.trim().isNotEmpty) city!.trim(),
      if (postalCode != null && postalCode!.trim().isNotEmpty) postalCode!.trim(),
    ];
    return parts.join(', ');
  }
}

/// Authoritative aggregate model constructed strictly from persisted records.
class InvoiceData {
  final Sale sale;
  final List<SaleItem> items;
  final List<SalePayment> payments;
  final InvoiceBusinessInfo business;
  final InvoiceLocationInfo location;
  final InvoiceCustomerInfo customer;
  final String cashierName;

  const InvoiceData({
    required this.sale,
    required this.items,
    required this.payments,
    required this.business,
    required this.location,
    required this.customer,
    this.cashierName = 'Cashier',
  });

  String get saleNumber => sale.saleNumber;
  DateTime get saleDate => sale.completedAt ?? sale.createdAt ?? DateTime.now();
  String get currencyCode => sale.currencyCode;

  // Authoritative minor values directly from snapshots (never re-calculated)
  int get subtotalMinor => sale.subtotalMinor;
  int get discountMinor => sale.discountMinor;
  int get taxMinor => sale.taxMinor;
  int get totalMinor => sale.totalMinor;

  double get subtotal => subtotalMinor / 100.0;
  double get discount => discountMinor / 100.0;
  double get tax => taxMinor / 100.0;
  double get total => totalMinor / 100.0;

  bool get hasDiscount => discountMinor > 0;
  bool get hasTax => taxMinor > 0;
  bool get isSplitPayment => payments.length > 1;

  int get totalPaidMinor {
    if (payments.isEmpty) return totalMinor;
    return payments.fold<int>(0, (sum, p) => sum + p.amountMinor);
  }

  double get totalPaid => totalPaidMinor / 100.0;

  String formatCurrency(num amount) {
    final hasDecimals = (amount % 1) != 0;
    final formatter = hasDecimals
        ? intl.NumberFormat('#,##,##0.00', 'en_IN')
        : intl.NumberFormat('#,##,##0', 'en_IN');
    final symbol = currencyCode.toUpperCase() == 'INR' ? '₹' : '';
    return '$symbol${formatter.format(amount)}';
  }

  String formatCurrencyMinor(int minorAmount) {
    return formatCurrency(minorAmount / 100.0);
  }

  String get formattedDate {
    return intl.DateFormat('d MMM yyyy • h:mm a').format(saleDate);
  }

  String get formattedShortDate {
    return intl.DateFormat('dd/MM/yyyy HH:mm').format(saleDate);
  }

  String get suggestedPdfFileName {
    final sanitizedBiz = business.effectiveName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final sanitizedSaleNum = saleNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${sanitizedBiz}_$sanitizedSaleNum.pdf';
  }

  String generateWhatsAppMessage() {
    final amountStr = formatCurrency(total);
    final bizName = business.effectiveName;
    return 'Thank you for shopping with $bizName.\n\n'
        'Invoice: $saleNumber\n'
        'Amount: $amountStr\n\n'
        'Please find your receipt attached.';
  }

  static String normalizePhone(String rawPhone) {
    final digitsOnly = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (digitsOnly.startsWith('+')) {
      return digitsOnly.substring(1);
    }
    if (digitsOnly.length == 10) {
      return '91$digitsOnly';
    }
    return digitsOnly;
  }
}
