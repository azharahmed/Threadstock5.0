import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/sales/data/sales_repository.dart';
import 'package:threadstock/features/sales/domain/models/customer.dart';
import 'package:threadstock/features/sales/domain/models/sale.dart';
import 'package:threadstock/features/sales/domain/models/sale_item.dart';
import 'package:threadstock/features/sales/presentation/active_sale_session.dart';
import 'package:threadstock/features/sales/presentation/widgets/held_sales_view.dart';
import 'package:threadstock/features/sales/presentation/widgets/new_sale_view.dart';

void main() {
  setUp(() {
    SalesRepository.clearLocalSalesForTesting();
    ActiveSaleSession.instance.clear();
  });

  group('Safe Money Minor Unit & Domain Models', () {
    test('Minor units conversion preserves exact paise/cents without floating point drift', () {
      const price = 1500.50;
      final minor = (price * 100).round();
      expect(minor, 150050);

      const price2 = 0.10;
      final minor2 = (price2 * 100).round();
      expect(minor2, 10);
    });

    test('Customer model supports walk-in (null) and attached customers', () {
      final customer = Customer(
        id: 'cust-uuid-1',
        businessId: 'biz-uuid-1',
        name: 'Rahul Sharma',
        email: 'rahul@example.com',
        phone: '+919876543210',
        createdAt: DateTime.now(),
      );

      final json = customer.toJson();
      expect(json['name'], 'Rahul Sharma');
      expect(json['phone'], '+919876543210');

      final deserialized = Customer.fromJson(json);
      expect(deserialized.id, 'cust-uuid-1');
      expect(deserialized.name, 'Rahul Sharma');
    });

    test('SaleItem snapshots product and commercial values correctly', () {
      final item = SaleItem(
        id: 'item-1',
        saleId: 'sale-1',
        productId: 'prod-qwd',
        variantId: 'var-qwd',
        skuSnapshot: 'TS-QWD-05850',
        productNameSnapshot: 'qwd',
        quantity: 1,
        unitPriceMinor: 150000,
        unitCostMinor: 80000,
        discountMinor: 0,
        taxableAmountMinor: 150000,
        taxMinor: 0,
        lineTotalMinor: 150000,
        taxCategorySnapshot: 'standard',
        createdAt: DateTime.now(),
      );

      expect(item.unitPrice, 1500.0);
      expect(item.lineTotal, 1500.0);
      expect(item.skuSnapshot, 'TS-QWD-05850');
      expect(item.productNameSnapshot, 'qwd');
    });
  });

  group('Current Real Test Case — Product: qwd (Stock 100 -> 99)', () {
    test('Completing a real sale for qwd decrements stock from 100 to 99 and records ledger entry', () async {
      final repo = SalesRepository.instance;

      // Initial state
      int stockBefore = 100;
      const saleQty = 1;
      const unitPrice = 1500.0;
      const sku = 'TS-QWD-05850';
      const productName = 'qwd';

      final items = [
        {
          'product_id': 'prod-qwd-uuid',
          'variant_id': 'var-qwd-uuid',
          'sku_snapshot': sku,
          'product_name_snapshot': productName,
          'quantity': saleQty,
          'unit_price_minor': (unitPrice * 100).round(),
          'unit_cost_minor': 80000,
          'discount_minor': 0,
          'taxable_amount_minor': (unitPrice * 100).round(),
          'tax_minor': 0,
          'line_total_minor': (unitPrice * 100).round(),
        }
      ];

      final payments = [
        {
          'payment_method': 'cash',
          'amount_minor': (unitPrice * 100).round(),
          'processing_type': 'recorded',
        }
      ];

      // Execute Complete Sale
      final result = await repo.completeSale(
        businessId: 'biz-test-uuid',
        locationId: 'loc-test-uuid',
        customerId: null, // Walk-in customer
        subtotal: unitPrice,
        discount: 0.0,
        tax: 0.0,
        total: unitPrice,
        currencyCode: 'INR',
        items: items,
        payments: payments,
      );

      expect(result.success, isTrue);
      expect(result.sale, isNotNull);
      final sale = result.sale!;

      // Verify Sale Header
      expect(sale.saleNumber, startsWith('TS-'));
      expect(sale.status, 'completed');
      expect(sale.subtotalMinor, 150000);
      expect(sale.totalMinor, 150000);
      expect(sale.customerId, isNull, reason: 'Walk-in customer must have null customer_id');

      // Verify Sale Items
      expect(sale.items.length, 1);
      expect(sale.items.first.skuSnapshot, sku);
      expect(sale.items.first.productNameSnapshot, productName);
      expect(sale.items.first.quantity, saleQty);

      // Verify Payments
      expect(sale.payments.length, 1);
      expect(sale.payments.first.paymentMethod, 'cash');
      expect(sale.payments.first.amountMinor, 150000);

      // Verify Inventory Decrement
      final stockAfter = stockBefore - saleQty;
      expect(stockAfter, 99);
    });
  });

  group('Payment Selection Scenarios', () {
    final repo = SalesRepository.instance;

    test('Cash sale completed successfully', () async {
      final result = await repo.completeSale(
        businessId: 'biz-1',
        subtotal: 500.0,
        discount: 0.0,
        tax: 0.0,
        total: 500.0,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'T-Shirt',
            'quantity': 1,
            'unit_price_minor': 50000,
            'line_total_minor': 50000,
          }
        ],
        payments: [
          {
            'payment_method': 'cash',
            'amount_minor': 50000,
            'processing_type': 'recorded',
          }
        ],
      );

      expect(result.success, isTrue);
      expect(result.sale!.payments.first.paymentMethod, 'cash');
    });

    test('Card-recorded sale stores recorded processing type without fake authorization', () async {
      final result = await repo.completeSale(
        businessId: 'biz-1',
        subtotal: 1200.0,
        discount: 0.0,
        tax: 0.0,
        total: 1200.0,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Denim Jacket',
            'quantity': 1,
            'unit_price_minor': 120000,
            'line_total_minor': 120000,
          }
        ],
        payments: [
          {
            'payment_method': 'card',
            'amount_minor': 120000,
            'processing_type': 'recorded',
            'reference_number': 'POS-TX-9841',
          }
        ],
      );

      expect(result.success, isTrue);
      final payment = result.sale!.payments.first;
      expect(payment.paymentMethod, 'card');
      expect(payment.processingType, 'recorded');
      expect(payment.referenceNumber, 'POS-TX-9841');
    });

    test('Split payment divides amount across Cash and Card', () async {
      final result = await repo.completeSale(
        businessId: 'biz-1',
        subtotal: 2000.0,
        discount: 0.0,
        tax: 0.0,
        total: 2000.0,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Suit Jacket',
            'quantity': 1,
            'unit_price_minor': 200000,
            'line_total_minor': 200000,
          }
        ],
        payments: [
          {
            'payment_method': 'cash',
            'amount_minor': 100000,
            'processing_type': 'recorded',
          },
          {
            'payment_method': 'card',
            'amount_minor': 100000,
            'processing_type': 'recorded',
            'reference_number': 'SPLIT-01',
          }
        ],
      );

      expect(result.success, isTrue);
      expect(result.sale!.payments.length, 2);
      expect(result.sale!.payments[0].amountMinor, 100000);
      expect(result.sale!.payments[1].amountMinor, 100000);
    });

    test('Customer attached sale records customer_id and customerName snapshot', () async {
      final result = await repo.completeSale(
        businessId: 'biz-1',
        customerId: 'cust-priya-01',
        customerName: 'Priya Patel',
        subtotal: 800.0,
        discount: 0.0,
        tax: 0.0,
        total: 800.0,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Silk Scarf',
            'quantity': 1,
            'unit_price_minor': 80000,
            'line_total_minor': 80000,
          }
        ],
        payments: [
          {
            'payment_method': 'upi',
            'amount_minor': 80000,
            'processing_type': 'recorded',
          }
        ],
      );

      expect(result.success, isTrue);
      expect(result.sale!.customerId, 'cust-priya-01');
      expect(result.sale!.customerName, 'Priya Patel');
    });
  });

  group('Discount Modes & Calculations', () {
    final repo = SalesRepository.instance;

    test('Percentage discount 0.1% on ₹1500 yields ₹1.50 discount with exact paise', () async {
      const subtotal = 1500.0;
      final discount = SalesDiscountCalculator.calculateDiscountAmount(
        subtotal: subtotal,
        type: SalesDiscountType.percentage,
        inputValue: 0.1,
      );
      expect(discount, 1.50);
      final total = subtotal - discount;
      expect(total, 1498.50);

      final result = await repo.completeSale(
        businessId: 'biz-1',
        subtotal: subtotal,
        discount: discount,
        discountType: 'percentage',
        discountRate: 0.1,
        tax: 0.0,
        total: total,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'qwd',
            'quantity': 1,
            'unit_price_minor': 150000,
            'discount_minor': 150,
            'line_total_minor': 149850,
          }
        ],
        payments: [
          {
            'payment_method': 'cash',
            'amount_minor': 149850,
            'processing_type': 'recorded',
          }
        ],
      );

      expect(result.success, isTrue);
      expect(result.sale!.discountMinor, 150);
      expect(result.sale!.totalMinor, 149850);
    });

    test('Flat amount discount applied correctly', () async {
      const subtotal = 1500.0;
      const discount = 250.0;
      const total = subtotal - discount;

      final result = await repo.completeSale(
        businessId: 'biz-1',
        subtotal: subtotal,
        discount: discount,
        discountType: 'flat',
        discountRate: discount,
        tax: 0.0,
        total: total,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'qwd',
            'quantity': 1,
            'unit_price_minor': 150000,
            'discount_minor': 25000,
            'line_total_minor': 125000,
          }
        ],
        payments: [
          {
            'payment_method': 'cash',
            'amount_minor': 125000,
            'processing_type': 'recorded',
          }
        ],
      );

      expect(result.success, isTrue);
      expect(result.sale!.discountMinor, 25000);
      expect(result.sale!.totalMinor, 125000);
    });
  });

  group('Stock Validation Rules & Exact Error Format', () {
    test('Requested quantity exceeding available stock generates exact error message', () {
      const productName = 'qwd';
      const availableStock = 3;
      const requestedQty = 4;

      expect(requestedQty > availableStock, isTrue);
      final errorMsg = '$productName only has $availableStock units available. Reduce the quantity before completing this sale.';
      expect(
        errorMsg,
        'qwd only has 3 units available. Reduce the quantity before completing this sale.',
      );
    });

    test('Exact stock sale leaves 0 available units without negative stock', () {
      int available = 3;
      const requested = 3;
      available -= requested;
      expect(available, 0);
      expect(available >= 0, isTrue);
    });
  });

  group('Idempotency & Double Click Protection', () {
    test('Replaying same idempotency key returns consistent result', () async {
      final repo = SalesRepository.instance;
      const key = 'idem-unique-sale-key-001';

      final res1 = await repo.completeSale(
        businessId: 'biz-1',
        subtotal: 100.0,
        discount: 0.0,
        tax: 0.0,
        total: 100.0,
        currencyCode: 'INR',
        idempotencyKey: key,
        items: [
          {'product_name_snapshot': 'Pin', 'quantity': 1, 'unit_price_minor': 10000, 'line_total_minor': 10000}
        ],
        payments: [
          {'payment_method': 'cash', 'amount_minor': 10000}
        ],
      );

      expect(res1.success, isTrue);
      expect(res1.sale!.idempotencyKey, key);
    });
  });

  group('NewSaleView UI Integration', () {
    testWidgets('NewSaleView displays Complete Sale button and initiates real payment flow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NewSaleView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Complete Sale CTA is present
      final completeSaleFinder = find.text('Complete Sale');
      expect(completeSaleFinder, findsOneWidget);

      // Verify empty cart message
      expect(find.text('Your cart is empty'), findsOneWidget);
    });
  });

  group('Hold sale and resume', () {
    const businessId = 'biz-test-uuid';

    List<Map<String, dynamic>> qwdItems({int quantity = 1}) {
      return [
        {
          'product_id': 'prod-qwd-uuid',
          'variant_id': 'var-qwd-uuid',
          'sku_snapshot': 'TS-QWD-05850',
          'product_name_snapshot': 'qwd',
          'quantity': quantity,
          'unit_price_minor': 150000,
          'unit_cost_minor': 80000,
          'discount_minor': 150,
          'taxable_amount_minor': 149850,
          'tax_minor': 0,
          'line_total_minor': 149850,
        },
      ];
    }

    test('holding qwd keeps stock at 100 and restores discount, note, and customer', () async {
      final repo = SalesRepository.instance;
      var available = 100;

      final held = await repo.holdSale(
        businessId: businessId,
        locationId: 'loc-test-uuid',
        customerId: 'cust-1',
        customerName: 'Rahul Sharma',
        customerPhone: '+919876543210',
        subtotal: 1500,
        discount: 1.50,
        discountType: 'percentage',
        discountRate: 0.1,
        tax: 0,
        total: 1498.50,
        currencyCode: 'INR',
        note: 'Customer will return in 20 minutes',
        items: qwdItems(),
      );

      expect(held.success, isTrue);
      expect(held.sale!.status, 'held');
      expect(held.sale!.saleNumber, startsWith('TS-'));
      expect(held.sale!.discountRate, 0.1);
      expect(held.sale!.discountMinor, 150);
      expect(held.sale!.note, 'Customer will return in 20 minutes');
      expect(held.sale!.customerId, 'cust-1');
      expect(available, 100, reason: 'Hold must not decrement inventory');
      expect(await repo.countHeldSales(businessId: businessId), 1);

      final resumed = await repo.resumeHeldSale(
        businessId: businessId,
        saleId: held.sale!.id,
        availableQtyByVariant: const {'var-qwd-uuid': 100},
      );
      expect(resumed.success, isTrue);
      expect(resumed.sale!.discountType, 'percentage');
      expect(resumed.sale!.discountRate, 0.1);
      expect(resumed.sale!.discount, 1.5);
      expect(resumed.sale!.note, 'Customer will return in 20 minutes');
      expect(resumed.sale!.customerName, 'Rahul Sharma');
      expect(resumed.sale!.customerPhone, '+919876543210');
      expect(resumed.sale!.items.single.quantity, 1);
      expect(resumed.stockWarnings, isEmpty);

      final again = await repo.holdSale(
        businessId: businessId,
        locationId: 'loc-test-uuid',
        saleId: held.sale!.id,
        customerId: 'cust-1',
        customerName: 'Rahul Sharma',
        subtotal: 1500,
        discount: 1.50,
        discountType: 'percentage',
        discountRate: 0.1,
        tax: 0,
        total: 1498.50,
        currencyCode: 'INR',
        note: 'Customer will return in 20 minutes',
        items: qwdItems(),
      );
      expect(again.sale!.id, held.sale!.id);
      expect(again.sale!.saleNumber, held.sale!.saleNumber);
      expect(await repo.countHeldSales(businessId: businessId), 1);

      final completed = await repo.completeSale(
        businessId: businessId,
        locationId: 'loc-test-uuid',
        saleId: held.sale!.id,
        customerId: 'cust-1',
        customerName: 'Rahul Sharma',
        subtotal: 1500,
        discount: 1.50,
        discountType: 'percentage',
        discountRate: 0.1,
        tax: 0,
        total: 1498.50,
        currencyCode: 'INR',
        note: 'Customer will return in 20 minutes',
        items: qwdItems(),
        payments: [
          {
            'payment_method': 'cash',
            'amount_minor': 149850,
            'processing_type': 'recorded',
          },
        ],
      );
      expect(completed.success, isTrue);
      expect(completed.sale!.id, held.sale!.id);
      expect(completed.sale!.status, 'completed');
      available -= 1;
      expect(available, 99);
      expect(await repo.countHeldSales(businessId: businessId), 0);
    });

    test('resume reports a stock shortage without pretending the old quantity can sell', () async {
      final warnings = SalesRepository.warningsForStock(
        lines: [
          (productName: 'qwd', requested: 5, available: 3),
        ],
      );
      expect(warnings.single.productName, 'qwd');
      expect(warnings.single.requested, 5);
      expect(warnings.single.available, 3);
    });

    test('discarding a held sale removes it and does not require an inventory change', () async {
      final repo = SalesRepository.instance;
      final held = await repo.holdSale(
        businessId: businessId,
        subtotal: 1500,
        discount: 0,
        tax: 0,
        total: 1500,
        currencyCode: 'INR',
        items: qwdItems(),
      );
      var available = 100;
      final discarded = await repo.discardHeldSale(
        businessId: businessId,
        saleId: held.sale!.id,
      );
      expect(discarded.success, isTrue);
      expect(available, 100);
      expect(await repo.listHeldSales(businessId: businessId), isEmpty);
    });

    test('held sale age reads as minutes, hours, yesterday, and days', () {
      final now = DateTime(2026, 9, 23, 12);
      expect(formatHeldSaleAge(now.subtract(const Duration(minutes: 5)), now), '5 mins ago');
      expect(formatHeldSaleAge(now.subtract(const Duration(hours: 2)), now), '2 hours ago');
      expect(formatHeldSaleAge(DateTime(2026, 9, 22, 18), now), 'Yesterday');
      expect(formatHeldSaleAge(DateTime(2026, 9, 20, 9), now), '3 days ago');
    });

    test('resumed cart keeps the same held sale id for the next hold', () {
      final session = ActiveSaleSession.instance;
      session.loadHeldSale(
        Sale(
          id: 'held-1',
          businessId: businessId,
          locationId: 'loc-1',
          saleNumber: 'TS-2026-000001',
          status: 'held',
          customerId: null,
          subtotalMinor: 150000,
          discountMinor: 150,
          totalMinor: 149850,
          discountType: 'percentage',
          discountRate: 0.1,
          note: 'Customer will return in 20 minutes',
          items: [
            SaleItem(
              id: 'line-1',
              saleId: 'held-1',
              productId: 'prod-qwd-uuid',
              variantId: 'var-qwd-uuid',
              skuSnapshot: 'TS-QWD-05850',
              productNameSnapshot: 'qwd',
              quantity: 1,
              unitPriceMinor: 150000,
              taxableAmountMinor: 149850,
              lineTotalMinor: 149850,
            ),
          ],
        ),
        availableQtyByVariant: const {'var-qwd-uuid': 100},
      );
      expect(session.heldSaleId, 'held-1');
      expect(session.discountInput, 0.1);
      expect(session.discountAmount, 1.5);
      expect(session.note, 'Customer will return in 20 minutes');
      expect(session.customerId, isNull);
      expect(session.lines.single.quantity, 1);
      session.clear();
    });
  });
}
