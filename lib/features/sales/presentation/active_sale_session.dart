import 'package:flutter/foundation.dart';

import '../data/sales_repository.dart';
import '../domain/models/cart_payment_state.dart';
import '../domain/models/sale.dart';

export '../domain/models/cart_payment_state.dart';

class ActiveCartLine {
  const ActiveCartLine({
    required this.productId,
    required this.title,
    required this.sku,
    required this.variantSubtitle,
    required this.unitPriceMinor,
    required this.quantity,
    required this.stockCount,
    this.variantId,
    this.availableQty,
    this.costPriceMinor = 0,
    this.taxCategory,
    this.imageAsset = '',
  });

  final String productId;
  final String? variantId;
  final String title;
  final String sku;
  final String variantSubtitle;
  final int unitPriceMinor;
  final int quantity;
  final int stockCount;
  final int? availableQty;
  final int costPriceMinor;
  final String? taxCategory;
  final String imageAsset;
}

/// In-memory cashier cart. Survives leaving New Sale so Resume can detect a conflict.
class ActiveSaleSession extends ChangeNotifier {
  ActiveSaleSession._();

  static final ActiveSaleSession instance = ActiveSaleSession._();

  List<ActiveCartLine> lines = const [];
  String discountType = 'percentage';
  double discountInput = 0;
  String? note;
  String? customerId;
  String? customerName;
  String? customerPhone;
  String? heldSaleId;
  String? locationId;
  String? locationName;
  List<HeldStockWarning> stockWarnings = const [];
  CartPaymentState paymentState = const CartPaymentState();

  bool get hasItems => lines.isNotEmpty;

  double get subtotal {
    var sum = 0.0;
    for (final line in lines) {
      sum += line.unitPriceMinor * line.quantity / 100;
    }
    return sum;
  }

  double get discountAmount {
    if (discountInput <= 0 || subtotal <= 0) return 0;
    final subtotalPaise = (subtotal * 100).round();
    if (discountType == 'flat') {
      final inputPaise = (discountInput * 100).round();
      final paise = inputPaise > subtotalPaise ? subtotalPaise : inputPaise;
      return paise / 100;
    }
    final paise = ((subtotalPaise * discountInput) / 100).round();
    final bounded = paise > subtotalPaise ? subtotalPaise : paise;
    return bounded / 100;
  }

  double get total => (subtotal - discountAmount).clamp(0, double.infinity);

  List<Map<String, dynamic>> itemPayload() {
    final subtotalMinor = (subtotal * 100).round();
    final discountMinor = (discountAmount * 100).round();
    return lines.map((line) {
      final lineSubtotalMinor = line.unitPriceMinor * line.quantity;
      final lineDiscountMinor = subtotalMinor > 0
          ? ((lineSubtotalMinor / subtotalMinor) * discountMinor).round()
          : 0;
      final taxableMinor = lineSubtotalMinor - lineDiscountMinor;
      return {
        'product_id': line.productId,
        'variant_id': line.variantId,
        'sku_snapshot': line.sku,
        'product_name_snapshot': line.title,
        'variant_title_snapshot': line.variantSubtitle,
        'quantity': line.quantity,
        'unit_price_minor': line.unitPriceMinor,
        'unit_cost_minor': line.costPriceMinor,
        'discount_minor': lineDiscountMinor,
        'taxable_amount_minor': taxableMinor,
        'tax_minor': 0,
        'line_total_minor': taxableMinor,
        'tax_category_snapshot': line.taxCategory ?? 'standard',
      };
    }).toList();
  }

  void save({
    required List<ActiveCartLine> lines,
    String discountType = 'percentage',
    double discountInput = 0.0,
    String? note,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? heldSaleId,
    String? locationId,
    String? locationName,
    List<HeldStockWarning> stockWarnings = const [],
    CartPaymentState? paymentState,
  }) {
    this.lines = List<ActiveCartLine>.from(lines);
    this.discountType = discountType;
    this.discountInput = discountInput;
    this.note = note;
    this.customerId = customerId;
    this.customerName = customerName;
    this.customerPhone = customerPhone;
    this.heldSaleId = heldSaleId;
    this.locationId = locationId;
    this.locationName = locationName;
    this.stockWarnings = List<HeldStockWarning>.from(stockWarnings);
    if (paymentState != null) {
      this.paymentState = paymentState;
    }
    notifyListeners();
  }

  void loadHeldSale(
    Sale sale, {
    List<HeldStockWarning> stockWarnings = const [],
    Map<String, int> availableQtyByVariant = const {},
  }) {
    lines = sale.items
        .map(
          (item) {
            final available = item.variantId == null
                ? null
                : availableQtyByVariant[item.variantId!];
            return ActiveCartLine(
              productId: item.productId ?? item.skuSnapshot,
              variantId: item.variantId,
              title: item.productNameSnapshot,
              sku: item.skuSnapshot,
              variantSubtitle: item.variantTitleSnapshot ?? item.skuSnapshot,
              unitPriceMinor: item.unitPriceMinor,
              quantity: item.quantity,
              stockCount: available ?? item.quantity,
              availableQty: available,
              costPriceMinor: item.unitCostMinor,
              taxCategory: item.taxCategorySnapshot,
            );
          },
        )
        .toList();
    discountType = (sale.discountType == null || sale.discountType == 'none')
        ? 'percentage'
        : sale.discountType!;
    discountInput = sale.discountRate ?? 0;
    note = sale.note;
    customerId = sale.customerId;
    customerName = sale.customerName;
    customerPhone = sale.customerPhone;
    heldSaleId = sale.id;
    locationId = sale.locationId;
    locationName = sale.locationName;
    this.stockWarnings = List<HeldStockWarning>.from(stockWarnings);
    paymentState = const CartPaymentState();
    notifyListeners();
  }

  void clear({bool preserveLocation = true}) {
    lines = const [];
    discountType = 'percentage';
    discountInput = 0;
    note = null;
    customerId = null;
    customerName = null;
    customerPhone = null;
    heldSaleId = null;
    if (!preserveLocation) {
      locationId = null;
      locationName = null;
    }
    stockWarnings = const [];
    paymentState = const CartPaymentState();
    notifyListeners();
  }
}
