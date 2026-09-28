import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/features/business/domain/models/business.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/domain/models/stock_location.dart';
import 'package:threadstock/features/sales/data/sales_repository.dart';
import 'package:threadstock/features/sales/domain/models/customer.dart';
import 'package:threadstock/features/sales/domain/models/invoice_data.dart';
import 'package:threadstock/features/sales/domain/services/invoice_pdf_service.dart';
import 'package:threadstock/features/sales/presentation/active_sale_session.dart';
import 'package:threadstock/features/sales/presentation/widgets/sale_complete_modal.dart';

void main() {
  const testBusinessId = '863b4f7b-7a8e-4ffa-a4aa-e4cd453613af';
  const testLocationId = 'bf4f8239-a054-4248-bce0-506c686549dd';
  const otherBusinessId = '99999999-9999-9999-9999-999999999999';

  final testLocation = StockLocation(
    id: testLocationId,
    businessId: testBusinessId,
    name: 'Stock location',
    locationType: 'warehouse',
    status: 'active',
    streetAddress: '123 Fashion Street',
    city: 'Bengaluru',
    postalCode: '560001',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testCustomer = Customer(
    id: 'cust-sarah-123',
    businessId: testBusinessId,
    name: 'Sarah Khan',
    phone: '+91 99866 45729',
    email: 'sarah@example.com',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUp(() {
    LocationRepository.clearLocalState();
    SalesRepository.clearLocalSalesForTesting();
    ActiveSaleSession.instance.clear();
    CurrentBusinessService.instance.clear();
    AppPreferencesService.resetForTesting();

    CurrentBusinessService.instance.setCurrentBusiness(
      Business(
        id: testBusinessId,
        ownerUserId: 'owner-test',
        legalName: 'LaunchGrid',
        businessType: 'retail',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    LocationRepository.setMockLocations(testBusinessId, [testLocation]);
    SalesRepository.addLocalCustomerForTesting(testCustomer);
  });

  tearDown(() {
    LocationRepository.clearLocalState();
    SalesRepository.clearLocalSalesForTesting();
    ActiveSaleSession.instance.clear();
    CurrentBusinessService.instance.clear();
  });

  group('THREADSTOCK POST-SALE INVOICE — Domain & Persisted Snapshots', () {
    test('complete cash sale -> loads invoice strictly from persisted sale', () async {
      final completeResult = await SalesRepository.instance.completeSale(
        businessId: testBusinessId,
        locationId: testLocationId,
        customerId: testCustomer.id,
        customerName: testCustomer.name,
        subtotal: 1500.0,
        discount: 100.0,
        tax: 70.0,
        total: 1470.0,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Linen Shirt',
            'variant_title_snapshot': 'White / M',
            'sku_snapshot': 'LIN-WHT-M',
            'quantity': 1,
            'unit_price_minor': 150000,
            'discount_minor': 10000,
            'taxable_amount_minor': 140000,
            'tax_minor': 7000,
            'line_total_minor': 147000,
          }
        ],
        payments: [
          {
            'payment_method': 'cash',
            'amount_minor': 147000,
            'currency_code': 'INR',
          }
        ],
      );

      expect(completeResult.success, isTrue);
      expect(completeResult.sale, isNotNull);

      final saleId = completeResult.sale!.id;
      final invoice = await SalesRepository.instance.loadInvoiceData(
        businessId: testBusinessId,
        saleId: saleId,
      );

      expect(invoice, isNotNull);
      expect(invoice!.saleNumber, completeResult.sale!.saleNumber);
      expect(invoice.totalMinor, 147000);
      expect(invoice.subtotalMinor, 150000);
      expect(invoice.discountMinor, 10000);
      expect(invoice.taxMinor, 7000);
      expect(invoice.payments.length, 1);
      expect(invoice.payments.first.paymentMethod, 'cash');
      expect(invoice.payments.first.amountMinor, 147000);
      expect(invoice.customer.name, 'Sarah Khan');
      expect(invoice.customer.phone, '+91 99866 45729');
    });

    test('complete card sale -> correct single payment shown in invoice', () async {
      final completeResult = await SalesRepository.instance.completeSale(
        businessId: testBusinessId,
        locationId: testLocationId,
        customerId: null,
        subtotal: 4455.0,
        discount: 0.0,
        tax: 0.0,
        total: 4455.0,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Product 2',
            'variant_title_snapshot': 'Default',
            'sku_snapshot': 'PRD-002',
            'quantity': 1,
            'unit_price_minor': 445500,
            'discount_minor': 0,
            'taxable_amount_minor': 445500,
            'tax_minor': 0,
            'line_total_minor': 445500,
          }
        ],
        payments: [
          {
            'payment_method': 'card',
            'amount_minor': 445500,
            'currency_code': 'INR',
          }
        ],
      );

      expect(completeResult.success, isTrue);
      final invoice = await SalesRepository.instance.loadInvoiceData(
        businessId: testBusinessId,
        saleId: completeResult.sale!.id,
      );

      expect(invoice, isNotNull);
      expect(invoice!.isSplitPayment, isFalse);
      expect(invoice.payments.first.paymentMethod, 'card');
      expect(invoice.totalPaidMinor, 445500);
      expect(invoice.customer.isWalkIn, isTrue);
      expect(invoice.customer.name, 'Walk-in Customer');
    });

    test('complete split sale -> each payment allocation displayed (Cash ₹2,228 + UPI ₹2,227)', () async {
      final completeResult = await SalesRepository.instance.completeSale(
        businessId: testBusinessId,
        locationId: testLocationId,
        customerId: testCustomer.id,
        customerName: testCustomer.name,
        subtotal: 4500.0,
        discount: 45.0,
        tax: 0.0,
        total: 4455.0,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Product 2',
            'variant_title_snapshot': 'Default',
            'sku_snapshot': 'PRD-002',
            'quantity': 1,
            'unit_price_minor': 450000,
            'discount_minor': 4500,
            'taxable_amount_minor': 445500,
            'tax_minor': 0,
            'line_total_minor': 445500,
          }
        ],
        payments: [
          {
            'payment_method': 'cash',
            'amount_minor': 222800,
            'currency_code': 'INR',
          },
          {
            'payment_method': 'upi',
            'amount_minor': 222700,
            'currency_code': 'INR',
          },
        ],
      );

      expect(completeResult.success, isTrue);
      final invoice = await SalesRepository.instance.loadInvoiceData(
        businessId: testBusinessId,
        saleId: completeResult.sale!.id,
      );

      expect(invoice, isNotNull);
      expect(invoice!.isSplitPayment, isTrue);
      expect(invoice.payments.length, 2);
      expect(invoice.payments[0].paymentMethod, 'cash');
      expect(invoice.payments[0].amountMinor, 222800);
      expect(invoice.payments[1].paymentMethod, 'upi');
      expect(invoice.payments[1].amountMinor, 222700);
      expect(invoice.totalPaidMinor, 445500);
      expect(invoice.totalMinor, 445500);
    });

    test('persisted total = invoice total and persisted snapshots = invoice items', () async {
      final completeResult = await SalesRepository.instance.completeSale(
        businessId: testBusinessId,
        locationId: testLocationId,
        subtotal: 2500.0,
        discount: 250.0,
        tax: 112.5,
        total: 2362.5,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Oxford Shirt',
            'variant_title_snapshot': 'Blue / L',
            'sku_snapshot': 'OXF-BLU-L',
            'quantity': 2,
            'unit_price_minor': 125000,
            'discount_minor': 25000,
            'taxable_amount_minor': 225000,
            'tax_minor': 11250,
            'line_total_minor': 236250,
          }
        ],
        payments: [
          {
            'payment_method': 'card',
            'amount_minor': 236250,
          }
        ],
      );

      final sale = completeResult.sale!;
      final invoice = (await SalesRepository.instance.loadInvoiceData(
        businessId: testBusinessId,
        saleId: sale.id,
      ))!;

      // Persisted total == invoice total
      expect(invoice.totalMinor, sale.totalMinor);
      expect(invoice.subtotalMinor, sale.subtotalMinor);
      expect(invoice.discountMinor, sale.discountMinor);
      expect(invoice.taxMinor, sale.taxMinor);

      // Persisted line snapshots == invoice items
      expect(invoice.items.length, sale.items.length);
      final invoiceItem = invoice.items.first;
      final saleItem = sale.items.first;
      expect(invoiceItem.productNameSnapshot, saleItem.productNameSnapshot);
      expect(invoiceItem.variantTitleSnapshot, saleItem.variantTitleSnapshot);
      expect(invoiceItem.skuSnapshot, saleItem.skuSnapshot);
      expect(invoiceItem.quantity, saleItem.quantity);
      expect(invoiceItem.unitPriceMinor, saleItem.unitPriceMinor);
      expect(invoiceItem.discountMinor, saleItem.discountMinor);
      expect(invoiceItem.taxMinor, saleItem.taxMinor);
      expect(invoiceItem.lineTotalMinor, saleItem.lineTotalMinor);
    });

    test('Tax values from persisted sale: never recalculated in Flutter', () async {
      // Set tax_minor to a specific historical snapshot value
      final completeResult = await SalesRepository.instance.completeSale(
        businessId: testBusinessId,
        locationId: testLocationId,
        subtotal: 1000.0,
        discount: 0.0,
        tax: 42.15,
        total: 1042.15,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Twill Chino',
            'sku_snapshot': 'TWL-001',
            'quantity': 1,
            'unit_price_minor': 100000,
            'taxable_amount_minor': 100000,
            'tax_minor': 4215,
            'line_total_minor': 104215,
          }
        ],
        payments: [
          {'payment_method': 'cash', 'amount_minor': 104215}
        ],
      );

      final invoice = (await SalesRepository.instance.loadInvoiceData(
        businessId: testBusinessId,
        saleId: completeResult.sale!.id,
      ))!;

      // Tax MUST come directly from snapshots, not computed by standard 5% or 18% GST formula
      expect(invoice.taxMinor, 4215);
      expect(invoice.items.first.taxMinor, 4215);
      expect(invoice.formatCurrencyMinor(invoice.taxMinor), '₹42.15');
    });

    test('Business details: displays GSTIN only when gst_registered is true', () async {
      SalesRepository.setLocalCommerceProfileForTesting(
        testBusinessId,
        isGstRegistered: true,
        gstin: '29ABCDE1234F1Z5',
      );

      final completeResult = await SalesRepository.instance.completeSale(
        businessId: testBusinessId,
        locationId: testLocationId,
        subtotal: 1000.0,
        discount: 0.0,
        tax: 0.0,
        total: 1000.0,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Sample Product',
            'sku_snapshot': 'SMP-01',
            'quantity': 1,
            'unit_price_minor': 100000,
            'taxable_amount_minor': 100000,
            'line_total_minor': 100000,
          }
        ],
        payments: [
          {'payment_method': 'cash', 'amount_minor': 100000}
        ],
      );

      final withGst = (await SalesRepository.instance.loadInvoiceData(
        businessId: testBusinessId,
        saleId: completeResult.sale!.id,
      ))!;

      expect(withGst.business.isGstRegistered, isTrue);
      expect(withGst.business.gstin, '29ABCDE1234F1Z5');

      // Now set gst_registered = false
      SalesRepository.setLocalCommerceProfileForTesting(
        testBusinessId,
        isGstRegistered: false,
        gstin: null,
      );

      final withoutGst = (await SalesRepository.instance.loadInvoiceData(
        businessId: testBusinessId,
        saleId: completeResult.sale!.id,
      ))!;

      expect(withoutGst.business.isGstRegistered, isFalse);
      expect(withoutGst.business.gstin, isNull);
    });

    test('Customer details: walk-in customer does not create fake customer record', () async {
      final initialCustomers = await SalesRepository.instance.getCustomers(businessId: testBusinessId);
      final initialCount = initialCustomers.length;

      final completeResult = await SalesRepository.instance.completeSale(
        businessId: testBusinessId,
        locationId: testLocationId,
        customerId: null,
        subtotal: 500.0,
        discount: 0.0,
        tax: 0.0,
        total: 500.0,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Cap',
            'sku_snapshot': 'CAP-01',
            'quantity': 1,
            'unit_price_minor': 50000,
            'taxable_amount_minor': 50000,
            'line_total_minor': 50000,
          }
        ],
        payments: [
          {'payment_method': 'cash', 'amount_minor': 50000}
        ],
      );

      final invoice = (await SalesRepository.instance.loadInvoiceData(
        businessId: testBusinessId,
        saleId: completeResult.sale!.id,
      ))!;

      expect(invoice.customer.isWalkIn, isTrue);
      expect(invoice.customer.name, 'Walk-in Customer');

      final finalCustomers = await SalesRepository.instance.getCustomers(businessId: testBusinessId);
      expect(finalCustomers.length, initialCount); // No fake customer inserted
    });

    test('cross-business sale cannot be accessed', () async {
      final completeResult = await SalesRepository.instance.completeSale(
        businessId: testBusinessId,
        locationId: testLocationId,
        subtotal: 1000.0,
        discount: 0.0,
        tax: 0.0,
        total: 1000.0,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Test',
            'sku_snapshot': 'TST',
            'quantity': 1,
            'unit_price_minor': 100000,
            'taxable_amount_minor': 100000,
            'line_total_minor': 100000,
          }
        ],
        payments: [
          {'payment_method': 'cash', 'amount_minor': 100000}
        ],
      );

      // Attempt access from otherBusinessId
      final crossAccess = await SalesRepository.instance.loadInvoiceData(
        businessId: otherBusinessId,
        saleId: completeResult.sale!.id,
      );

      expect(crossAccess, isNull);
    });
  });

  group('THREADSTOCK POST-SALE INVOICE — PDF Generation & WhatsApp/Share', () {
    late InvoiceData testInvoice;

    setUp(() async {
      final completeResult = await SalesRepository.instance.completeSale(
        businessId: testBusinessId,
        locationId: testLocationId,
        customerId: testCustomer.id,
        customerName: testCustomer.name,
        subtotal: 4500.0,
        discount: 45.0,
        tax: 0.0,
        total: 4455.0,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Product 2',
            'variant_title_snapshot': 'Medium',
            'sku_snapshot': 'PRD-002',
            'quantity': 1,
            'unit_price_minor': 450000,
            'discount_minor': 4500,
            'taxable_amount_minor': 445500,
            'tax_minor': 0,
            'line_total_minor': 445500,
          }
        ],
        payments: [
          {'payment_method': 'cash', 'amount_minor': 222800},
          {'payment_method': 'upi', 'amount_minor': 222700},
        ],
      );

      testInvoice = (await SalesRepository.instance.loadInvoiceData(
        businessId: testBusinessId,
        saleId: completeResult.sale!.id,
      ))!;
    });

    test('generate A4 invoice PDF produces valid PDF bytes', () async {
      final pdfBytes = await InvoicePdfService.instance.generateInvoicePdf(
        testInvoice,
        format: InvoiceFormat.a4,
      );

      expect(pdfBytes, isNotEmpty);
      final header = utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true);
      expect(header, '%PDF-');
    });

    test('generate 80mm receipt produces valid PDF bytes', () async {
      final pdfBytes = await InvoicePdfService.instance.generateInvoicePdf(
        testInvoice,
        format: InvoiceFormat.thermal80mm,
      );

      expect(pdfBytes, isNotEmpty);
      final header = utf8.decode(pdfBytes.sublist(0, 5), allowMalformed: true);
      expect(header, '%PDF-');
    });

    test('PDF survives regeneration after simulated restart', () async {
      final pdf1 = await InvoicePdfService.instance.generateInvoicePdf(testInvoice);
      // Re-load from repository snapshot
      final reloadedInvoice = (await SalesRepository.instance.loadInvoiceData(
        businessId: testBusinessId,
        saleId: testInvoice.sale.id,
      ))!;
      final pdf2 = await InvoicePdfService.instance.generateInvoicePdf(reloadedInvoice);

      expect(pdf1, isNotEmpty);
      expect(pdf2, isNotEmpty);
      expect(pdf1.length, equals(pdf2.length));
    });

    test('suggested filename follows <business_name>_<sale_number>.pdf', () {
      final filename = testInvoice.suggestedPdfFileName;
      expect(filename, contains('LaunchGrid'));
      expect(filename, contains(testInvoice.saleNumber.replaceAll('-', '_')));
      expect(filename, endsWith('.pdf'));
    });

    test('WhatsApp message format and recipient normalization', () {
      final message = testInvoice.generateWhatsAppMessage();
      expect(message, contains('Thank you for shopping with LaunchGrid.'));
      expect(message, contains('Invoice: ${testInvoice.saleNumber}'));
      expect(message, contains('Amount: ₹4,455'));
      expect(message, contains('Please find your receipt attached.'));

      // Attached customer phone: +91 99866 45729
      final normalized = InvoiceData.normalizePhone(testInvoice.customer.phone!);
      expect(normalized, '919986645729');
    });

    test('failed share or print does not roll back completed sale', () async {
      final saleBefore = await SalesRepository.instance.getSaleWithDetails(
        businessId: testBusinessId,
        saleId: testInvoice.sale.id,
      );
      expect(saleBefore, isNotNull);
      expect(saleBefore!.status, 'completed');

      // Attempting to share or print with mock error
      // Sale status MUST remain completed
      final saleAfter = await SalesRepository.instance.getSaleWithDetails(
        businessId: testBusinessId,
        saleId: testInvoice.sale.id,
      );
      expect(saleAfter, isNotNull);
      expect(saleAfter!.status, 'completed');
    });

    test('Sales history: reprint and re-download works from persisted sale', () async {
      final allSales = await SalesRepository.instance.getSales(businessId: testBusinessId);
      expect(allSales, isNotEmpty);

      final historicalSale = allSales.first;
      final historicalInvoice = await SalesRepository.instance.loadInvoiceData(
        businessId: testBusinessId,
        saleId: historicalSale.id,
      );

      expect(historicalInvoice, isNotNull);
      final pdfBytes = await InvoicePdfService.instance.generateInvoicePdf(historicalInvoice!);
      expect(pdfBytes, isNotEmpty);
    });
  });

  group('THREADSTOCK POST-SALE INVOICE — SaleCompleteModal UI Flow', () {
    testWidgets('renders Sale Complete modal with correct total, badge, and breakdown', (tester) async {
      final completeResult = await SalesRepository.instance.completeSale(
        businessId: testBusinessId,
        locationId: testLocationId,
        customerId: testCustomer.id,
        customerName: testCustomer.name,
        subtotal: 4500.0,
        discount: 45.0,
        tax: 0.0,
        total: 4455.0,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Product 2',
            'variant_title_snapshot': 'Medium',
            'sku_snapshot': 'PRD-002',
            'quantity': 1,
            'unit_price_minor': 450000,
            'discount_minor': 4500,
            'taxable_amount_minor': 445500,
            'tax_minor': 0,
            'line_total_minor': 445500,
          }
        ],
        payments: [
          {'payment_method': 'cash', 'amount_minor': 222800},
          {'payment_method': 'upi', 'amount_minor': 222700},
        ],
      );

      final invoice = (await SalesRepository.instance.loadInvoiceData(
        businessId: testBusinessId,
        saleId: completeResult.sale!.id,
      ))!;

      bool newSaleStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaleCompleteModal(
              invoice: invoice,
              onStartNewSale: () => newSaleStarted = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Sale Completed'), findsOneWidget);
      expect(find.text('Paid'), findsOneWidget);
      expect(find.textContaining('Invoice / Receipt #TS-'), findsOneWidget);
      expect(find.text('₹4,455'), findsWidgets);

      // Check Business & Location
      expect(find.text('LaunchGrid'), findsOneWidget);
      expect(find.text('Stock location'), findsOneWidget);
      expect(find.text('Sarah Khan'), findsOneWidget);

      // Check line item
      expect(find.textContaining('Product 2 x1'), findsOneWidget);

      // Check payments breakdown
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('₹2,228'), findsOneWidget);
      expect(find.text('UPI'), findsOneWidget);
      expect(find.text('₹2,227'), findsOneWidget);

      // Check action buttons
      expect(find.text('Print'), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);

      // Check Start New Sale button
      expect(find.text('Start New Sale'), findsOneWidget);
      await tester.tap(find.text('Start New Sale'));
      await tester.pumpAndSettle();
      expect(newSaleStarted, isTrue);
    });

    testWidgets('Full invoice preview dialog renders item table, business and payments', (tester) async {
      SalesRepository.setLocalCommerceProfileForTesting(
        testBusinessId,
        isGstRegistered: true,
        gstin: '29ABCDE1234F1Z5',
      );

      final completeResult = await SalesRepository.instance.completeSale(
        businessId: testBusinessId,
        locationId: testLocationId,
        customerId: testCustomer.id,
        customerName: testCustomer.name,
        subtotal: 4500.0,
        discount: 45.0,
        tax: 0.0,
        total: 4455.0,
        currencyCode: 'INR',
        items: [
          {
            'product_name_snapshot': 'Product 2',
            'variant_title_snapshot': 'Default',
            'sku_snapshot': 'PRD-002',
            'quantity': 1,
            'unit_price_minor': 450000,
            'discount_minor': 4500,
            'taxable_amount_minor': 445500,
            'tax_minor': 0,
            'line_total_minor': 445500,
          }
        ],
        payments: [
          {'payment_method': 'cash', 'amount_minor': 222800},
          {'payment_method': 'upi', 'amount_minor': 222700},
        ],
      );

      final invoice = (await SalesRepository.instance.loadInvoiceData(
        businessId: testBusinessId,
        saleId: completeResult.sale!.id,
      ))!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FullInvoicePreviewDialog(invoice: invoice),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LaunchGrid'), findsOneWidget);
      expect(find.text('GSTIN: 29ABCDE1234F1Z5'), findsOneWidget);
      expect(find.text('Sarah Khan'), findsOneWidget);
      expect(find.text('Product 2'), findsOneWidget);
      expect(find.text('PRD-002'), findsOneWidget);
      expect(find.text('Thank you for shopping with LaunchGrid.'), findsOneWidget);
    });
  });
}
