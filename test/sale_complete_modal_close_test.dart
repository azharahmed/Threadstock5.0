import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/sales/domain/models/customer.dart';
import 'package:threadstock/features/sales/domain/models/invoice_data.dart';
import 'package:threadstock/features/sales/domain/models/sale.dart';
import 'package:threadstock/features/sales/domain/models/sale_item.dart';
import 'package:threadstock/features/sales/domain/models/sale_payment.dart';
import 'package:threadstock/features/sales/presentation/widgets/sale_complete_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testSale = Sale(
    id: 'sale-test-001',
    businessId: '863b4f7b-7a8e-4ffa-a4aa-e4cd453613af',
    locationId: 'bf4f8239-a054-4248-bce0-506c686549dd',
    saleNumber: 'TS-2026-000001',
    status: 'completed',
    subtotalMinor: 450000,
    discountMinor: 4500,
    taxMinor: 0,
    totalMinor: 445500,
    currencyCode: 'INR',
    createdAt: DateTime(2026, 9, 26, 14, 30),
    completedAt: DateTime(2026, 9, 26, 14, 30),
  );

  final testItem = SaleItem(
    id: 'item-001',
    saleId: 'sale-test-001',
    skuSnapshot: 'KUR-IVR-M',
    productNameSnapshot: 'Silk Kurta',
    variantTitleSnapshot: 'Ivory / M',
    quantity: 1,
    unitPriceMinor: 450000,
    discountMinor: 4500,
    taxableAmountMinor: 445500,
    taxMinor: 0,
    lineTotalMinor: 445500,
  );

  final testPayment = SalePayment(
    id: 'pay-001',
    saleId: 'sale-test-001',
    businessId: '863b4f7b-7a8e-4ffa-a4aa-e4cd453613af',
    paymentMethod: 'cash',
    amountMinor: 445500,
  );

  final testInvoice = InvoiceData(
    sale: testSale,
    items: [testItem],
    payments: [testPayment],
    business: const InvoiceBusinessInfo(
      id: '863b4f7b-7a8e-4ffa-a4aa-e4cd453613af',
      displayName: 'LaunchGrid',
    ),
    location: const InvoiceLocationInfo(
      id: 'bf4f8239-a054-4248-bce0-506c686549dd',
      name: 'Main Store',
    ),
    customer: InvoiceCustomerInfo.fromCustomer(
      const Customer(
        id: 'cust-001',
        businessId: '863b4f7b-7a8e-4ffa-a4aa-e4cd453613af',
        name: 'Aditi Sharma',
      ),
    ),
  );

  group('THREADSTOCK SALE COMPLETED MODAL — CLOSE & DISMISS ACTION TESTS', () {
    testWidgets('1. Modal renders close button (✕) in the top-right corner', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SaleCompleteModal.show(
                  context: ctx,
                  invoice: testInvoice,
                  onStartNewSale: () {},
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open the modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byType(SaleCompleteModal), findsOneWidget);
      expect(find.text('Sale Completed'), findsOneWidget);

      // Verify close button exists with Key
      final closeButtonFinder = find.byKey(const Key('sale_complete_modal_close_button'));
      expect(closeButtonFinder, findsOneWidget);

      // Verify icon is close_rounded
      expect(find.descendant(of: closeButtonFinder, matching: find.byIcon(Icons.close_rounded)), findsOneWidget);
    });

    testWidgets('2. Clicking ✕ dismisses modal without triggering Start New Sale', (tester) async {
      bool newSaleStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SaleCompleteModal.show(
                  context: ctx,
                  invoice: testInvoice,
                  onStartNewSale: () => newSaleStarted = true,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();
      expect(find.byType(SaleCompleteModal), findsOneWidget);

      // Click close button (✕)
      await tester.tap(find.byKey(const Key('sale_complete_modal_close_button')));
      await tester.pumpAndSettle();

      // Modal is dismissed
      expect(find.byType(SaleCompleteModal), findsNothing);
      // Start New Sale was NOT called
      expect(newSaleStarted, isFalse);
    });

    testWidgets('3. Pressing Escape key dismisses modal without triggering Start New Sale', (tester) async {
      bool newSaleStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SaleCompleteModal.show(
                  context: ctx,
                  invoice: testInvoice,
                  onStartNewSale: () => newSaleStarted = true,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();
      expect(find.byType(SaleCompleteModal), findsOneWidget);

      // Simulate Escape key press
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      // Modal is dismissed
      expect(find.byType(SaleCompleteModal), findsNothing);
      // Start New Sale was NOT called
      expect(newSaleStarted, isFalse);
    });

    testWidgets('4. Clicking outside modal barrier dismisses modal', (tester) async {
      bool newSaleStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SaleCompleteModal.show(
                  context: ctx,
                  invoice: testInvoice,
                  onStartNewSale: () => newSaleStarted = true,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();
      expect(find.byType(SaleCompleteModal), findsOneWidget);

      // Tap on modal barrier (top-left outside the dialog)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Modal is dismissed
      expect(find.byType(SaleCompleteModal), findsNothing);
      expect(newSaleStarted, isFalse);
    });

    testWidgets('5. Clicking Start New Sale dismisses modal AND triggers onStartNewSale', (tester) async {
      bool newSaleStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => SaleCompleteModal.show(
                  context: ctx,
                  invoice: testInvoice,
                  onStartNewSale: () => newSaleStarted = true,
                ),
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();
      expect(find.byType(SaleCompleteModal), findsOneWidget);

      // Scroll to and click Start New Sale CTA
      await tester.ensureVisible(find.text('Start New Sale'));
      await tester.tap(find.text('Start New Sale'));
      await tester.pumpAndSettle();

      // Modal is dismissed
      expect(find.byType(SaleCompleteModal), findsNothing);
      // onStartNewSale callback was called
      expect(newSaleStarted, isTrue);
    });
  });
}
