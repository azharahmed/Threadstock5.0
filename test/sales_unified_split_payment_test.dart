import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/features/business/domain/models/business.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/domain/models/stock_location.dart';
import 'package:threadstock/features/sales/data/sales_repository.dart';
import 'package:threadstock/features/sales/presentation/active_sale_session.dart';
import 'package:threadstock/features/sales/presentation/widgets/new_sale_view.dart';

void main() {
  const testBusinessId = '863b4f7b-7a8e-4ffa-a4aa-e4cd453613af';
  const testLocationId = 'bf4f8239-a054-4248-bce0-506c686549dd';

  final testLocation = StockLocation(
    id: testLocationId,
    businessId: testBusinessId,
    name: 'Stock location',
    locationType: 'warehouse',
    status: 'active',
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
  });

  tearDown(() {
    LocationRepository.clearLocalState();
    SalesRepository.clearLocalSalesForTesting();
    ActiveSaleSession.instance.clear();
    CurrentBusinessService.instance.clear();
  });

  group('THREADSTOCK UNIFIED SPLIT PAYMENT — Domain & Minor Unit Math', () {
    test('Minor-unit arithmetic: Total ₹4455, Cash ₹2228, UPI ₹2227 matches exact paise', () {
      const totalPayable = 4455.0;
      final totalPayableMinor = (totalPayable * 100).round();
      expect(totalPayableMinor, 445500);

      final cashAlloc = PaymentAllocation(method: 'cash', amountMinor: 222800);
      final upiAlloc = PaymentAllocation(method: 'upi', amountMinor: 222700);

      expect(cashAlloc.amount, 2228.0);
      expect(cashAlloc.displayName, 'Cash');
      expect(cashAlloc.group, 'Cash');

      expect(upiAlloc.amount, 2227.0);
      expect(upiAlloc.displayName, 'UPI');
      expect(upiAlloc.group, 'Online');

      final state = CartPaymentState(
        mode: PaymentMode.split,
        allocations: [cashAlloc, upiAlloc],
        isConfirmed: true,
        confirmedTotalMinor: totalPayableMinor,
      );

      expect(state.totalAllocatedMinor, 445500);
      expect(state.totalAllocated, 4455.0);
      expect(state.remainingFor(totalPayableMinor), 0);
      expect(state.isValidForTotal(totalPayableMinor), isTrue);
      expect(state.isStale(totalPayableMinor), isFalse);
    });

    test('Online channel selection is never persisted as generic online', () {
      final channels = ['upi', 'card', 'bank_transfer', 'other'];
      for (final ch in channels) {
        final alloc = PaymentAllocation(method: ch, amountMinor: 100000);
        expect(alloc.method, ch);
        expect(alloc.method, isNot('online'));
        expect(alloc.group, 'Online');
      }
    });

    test('Cart total change invalidation (Needs Update)', () {
      final state = CartPaymentState(
        mode: PaymentMode.split,
        allocations: [
          PaymentAllocation(method: 'cash', amountMinor: 222800),
          PaymentAllocation(method: 'upi', amountMinor: 222700),
        ],
        isConfirmed: true,
        confirmedTotalMinor: 445500,
      );

      // Cart total changes to ₹4700 (470000 minor)
      const newTotalMinor = 470000;
      expect(state.isStale(newTotalMinor), isTrue);
      expect(state.isValidForTotal(newTotalMinor), isFalse);
      expect(state.remainingFor(newTotalMinor), 24500); // ₹245 remaining
    });

    test('Support multi-split: Cash + Card + UPI', () {
      final multiState = CartPaymentState(
        mode: PaymentMode.split,
        allocations: [
          PaymentAllocation(method: 'cash', amountMinor: 200000),
          PaymentAllocation(method: 'card', amountMinor: 145500),
          PaymentAllocation(method: 'upi', amountMinor: 100000),
        ],
        isConfirmed: true,
        confirmedTotalMinor: 445500,
      );

      expect(multiState.allocations.length, 3);
      expect(multiState.totalAllocatedMinor, 445500);
      expect(multiState.isValidForTotal(445500), isTrue);
      expect(multiState.allocations.map((a) => a.method).toList(), ['cash', 'card', 'upi']);
    });
  });

  group('THREADSTOCK UNIFIED SPLIT PAYMENT — UI & Complete Sale Flow', () {
    Widget buildTestHarness() {
      return const MaterialApp(
        home: Scaffold(
          body: NewSaleView(),
        ),
      );
    }

    testWidgets('1. Configure Split from Quick Actions: Cash ₹2228 + UPI ₹2227 -> remaining ₹0 -> Confirm Split', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      // Setup session with ₹4,455 cart (1 item at ₹4,500 with flat discount of ₹45)
      ActiveSaleSession.instance.save(
        customerId: null,
        lines: [
          const ActiveCartLine(
            productId: 'prod-shirt-001',
            variantId: 'var-shirt-001',
            title: 'Silk Evening Shirt',
            sku: 'SES-001',
            variantSubtitle: 'Navy • Size L',
            unitPriceMinor: 450000,
            quantity: 1,
            stockCount: 10,
            availableQty: 10,
          ),
        ],
        discountType: 'flat',
        discountInput: 45.0,
        locationId: testLocationId,
        locationName: 'Stock location',
      );

      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Total payable is ₹4,455
      expect(find.text('₹4,455'), findsWidgets);

      // Generic Quick Action "Split Payment" is visible
      final splitQuickAction = find.text('Split Payment');
      expect(splitQuickAction, findsWidgets);

      // Click Quick Actions -> Split Payment
      await tester.tap(splitQuickAction.first);
      await tester.pumpAndSettle();

      // Split Payment dialog opens with Total Payable ₹4455
      expect(find.text('Split Payment'), findsWidgets);
      expect(find.text('Total Payable'), findsWidgets);
      expect(find.text('₹4455'), findsWidgets);

      // Default split divides ₹4455 into Cash ₹2227 + Online (UPI) ₹2228
      // Let's type Cash ₹2228 and UPI ₹2227 explicitly
      final textFields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
      expect(textFields, findsNWidgets(2)); // Cash amount, UPI amount

      // Change Cash to 3000 to verify live remaining calculation
      await tester.enterText(textFields.first, '3000');
      await tester.enterText(textFields.last, '0');
      await tester.pumpAndSettle();

      expect(find.text('Allocated'), findsOneWidget);
      expect(find.text('₹3000'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('₹1455'), findsOneWidget);

      // Confirm Split is DISABLED because allocated (3000) != total (4455)
      final confirmBtnFinder = find.widgetWithText(ElevatedButton, 'Confirm Split');
      expect(confirmBtnFinder, findsOneWidget);
      final ElevatedButton disabledConfirmBtn = tester.widget(confirmBtnFinder);
      expect(disabledConfirmBtn.onPressed, isNull);

      // Now set Cash = 2228 and UPI = 2227
      await tester.enterText(textFields.first, '2228');
      await tester.enterText(textFields.last, '2227');
      await tester.pumpAndSettle();

      // Allocated = ₹4455, Remaining = ₹0
      expect(find.text('₹4455'), findsWidgets);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('₹0')), findsOneWidget);

      // Confirm Split is now ENABLED
      final ElevatedButton enabledConfirmBtn = tester.widget(confirmBtnFinder);
      expect(enabledConfirmBtn.onPressed, isNotNull);

      // Click Confirm Split
      await tester.tap(confirmBtnFinder);
      await tester.pumpAndSettle();

      // Dialog is closed; sale is NOT completed yet
      expect(find.byType(AlertDialog), findsNothing);

      // Sales screen now displays Confirmed Split breakdown!
      expect(find.text('Split Payment ✓'), findsOneWidget);
      expect(find.text('Cash ₹2,228'), findsOneWidget);
      expect(find.text('UPI ₹2,227'), findsOneWidget);
      expect(find.text('Edit Split'), findsOneWidget);

      // Shared CartPaymentState is confirmed
      expect(ActiveSaleSession.instance.paymentState.isConfirmed, isTrue);
      expect(ActiveSaleSession.instance.paymentState.allocations.length, 2);
    });

    testWidgets('2. Click Complete Sale with confirmed split: directly shows confirmed split without asking to select Split again', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      // Setup session with confirmed split
      ActiveSaleSession.instance.save(
        customerId: null,
        lines: [
          const ActiveCartLine(
            productId: 'prod-shirt-001',
            variantId: 'var-shirt-001',
            title: 'Silk Evening Shirt',
            sku: 'SES-001',
            variantSubtitle: 'Navy • Size L',
            unitPriceMinor: 450000,
            quantity: 1,
            stockCount: 10,
            availableQty: 10,
          ),
        ],
        discountType: 'flat',
        discountInput: 45.0,
        paymentState: const CartPaymentState(
          mode: PaymentMode.split,
          allocations: [
            PaymentAllocation(method: 'cash', amountMinor: 222800),
            PaymentAllocation(method: 'upi', amountMinor: 222700),
          ],
          isConfirmed: true,
          confirmedTotalMinor: 445500,
        ),
        locationId: testLocationId,
        locationName: 'Stock location',
      );

      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Click Complete Sale CTA at bottom right
      final completeSaleBtn = find.text('Complete Sale');
      expect(completeSaleBtn, findsOneWidget);
      await tester.tap(completeSaleBtn);
      await tester.pumpAndSettle();

      // Opens directly with Complete Sale — Payment dialog
      expect(find.text('Complete Sale — Payment'), findsOneWidget);

      // Directly shows confirmed split breakdown:
      // It does NOT ask the user to select Split again!
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Cash')), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('UPI')), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Total Allocated')), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Remaining')), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('₹0')), findsOneWidget);

      // Edit Split button is present
      expect(find.widgetWithText(OutlinedButton, 'Edit Split'), findsOneWidget);

      // Confirm & Complete ₹4,455 button is ENABLED
      final confirmCompleteBtn = find.widgetWithText(ElevatedButton, 'Confirm & Complete ₹4,455');
      expect(confirmCompleteBtn, findsOneWidget);
      final ElevatedButton btn = tester.widget(confirmCompleteBtn);
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('3. Edit Split pre-fills existing amounts and re-calculates remaining when updated', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      ActiveSaleSession.instance.save(
        customerId: null,
        lines: [
          const ActiveCartLine(
            productId: 'prod-shirt-001',
            variantId: 'var-shirt-001',
            title: 'Silk Evening Shirt',
            sku: 'SES-001',
            variantSubtitle: 'Navy • Size L',
            unitPriceMinor: 450000,
            quantity: 1,
            stockCount: 10,
            availableQty: 10,
          ),
        ],
        discountType: 'flat',
        discountInput: 45.0,
        paymentState: const CartPaymentState(
          mode: PaymentMode.split,
          allocations: [
            PaymentAllocation(method: 'cash', amountMinor: 222800),
            PaymentAllocation(method: 'upi', amountMinor: 222700),
          ],
          isConfirmed: true,
          confirmedTotalMinor: 445500,
        ),
        locationId: testLocationId,
        locationName: 'Stock location',
      );

      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Click Edit Split on Sales Screen
      final editSplitBtn = find.text('Edit Split');
      expect(editSplitBtn, findsOneWidget);
      await tester.tap(editSplitBtn);
      await tester.pumpAndSettle();

      // Split Editor opens with existing amounts prefilled
      final textFields = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField));
      expect(textFields, findsNWidgets(2));
      final TextField cashField = tester.widget(textFields.first);
      final TextField upiField = tester.widget(textFields.last);
      expect(cashField.controller?.text, '2228');
      expect(upiField.controller?.text, '2227');

      // Update cash amount to 2000
      await tester.enterText(textFields.first, '2000');
      await tester.pumpAndSettle();

      // Remaining recalculates to ₹228
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Allocated')), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('₹4227')), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Remaining')), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('₹228')), findsOneWidget);

      // Now set UPI to 2455 -> sum = 2000 + 2455 = 4455
      await tester.enterText(textFields.last, '2455');
      await tester.pumpAndSettle();

      expect(find.text('₹4455'), findsWidgets);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('₹0')), findsOneWidget);

      // Confirm Split
      await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Split'));
      await tester.pumpAndSettle();

      // Sales screen displays updated split
      expect(find.text('Cash ₹2,000'), findsOneWidget);
      expect(find.text('UPI ₹2,455'), findsOneWidget);
    });

    testWidgets('4. Cart total changes after split: marked Needs Update, Complete Sale disabled until corrected', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      ActiveSaleSession.instance.save(
        customerId: null,
        lines: [
          const ActiveCartLine(
            productId: 'prod-shirt-001',
            variantId: 'var-shirt-001',
            title: 'Silk Evening Shirt',
            sku: 'SES-001',
            variantSubtitle: 'Navy • Size L',
            unitPriceMinor: 450000,
            quantity: 1,
            stockCount: 10,
            availableQty: 10,
          ),
        ],
        discountType: 'flat',
        discountInput: 45.0, // Total = 4500 - 45 = 4455
        paymentState: const CartPaymentState(
          mode: PaymentMode.split,
          allocations: [
            PaymentAllocation(method: 'cash', amountMinor: 222800),
            PaymentAllocation(method: 'upi', amountMinor: 222700),
          ],
          isConfirmed: true,
          confirmedTotalMinor: 445500,
        ),
        locationId: testLocationId,
        locationName: 'Stock location',
      );

      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Verify initial confirmed state
      expect(find.text('Split Payment ✓'), findsOneWidget);

      // Now simulate user changing discount to 0 via session (or adding an item)
      // Total changes from 4455 to 4500
      ActiveSaleSession.instance.save(
        customerId: null,
        lines: ActiveSaleSession.instance.lines,
        discountType: 'percentage',
        discountInput: 0.0,
        paymentState: ActiveSaleSession.instance.paymentState,
        locationId: testLocationId,
        locationName: 'Stock location',
      );
      await tester.pumpAndSettle();

      // Total is now ₹4,500
      expect(find.text('₹4,500'), findsWidgets);

      // Sales screen shows "Split (Needs Update)"
      expect(find.text('Split (Needs Update)'), findsOneWidget);
      expect(find.text('Remaining: ₹45'), findsOneWidget);

      // Click Complete Sale
      await tester.tap(find.text('Complete Sale'));
      await tester.pumpAndSettle();

      // Modal shows Needs Update badge and message
      expect(find.text('Needs Update'), findsOneWidget);
      expect(find.text('Total Payable changed. Please update payment allocations before completing.'), findsOneWidget);

      // Complete Sale button is DISABLED
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Confirm & Complete ₹4,500');
      expect(confirmBtn, findsOneWidget);
      final ElevatedButton btn = tester.widget(confirmBtn);
      expect(btn.onPressed, isNull);

      // Click Edit Split inside Complete Sale modal
      await tester.tap(find.widgetWithText(OutlinedButton, 'Edit Split'));
      await tester.pumpAndSettle();

      // Prefilled amounts: Cash 2228, UPI 2227 (sum 4455). Target is 4500. Remaining: 45.
      expect(find.descendant(of: find.byType(AlertDialog).last, matching: find.text('Remaining')), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog).last, matching: find.text('₹45')), findsOneWidget);

      // Adjust Cash to 2273 -> sum = 2273 + 2227 = 4500
      final fields = find.descendant(of: find.byType(AlertDialog).last, matching: find.byType(TextField));
      await tester.enterText(fields.first, '2273');
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(AlertDialog).last, matching: find.text('₹0')), findsOneWidget);

      // Confirm Split
      await tester.tap(find.descendant(of: find.byType(AlertDialog).last, matching: find.widgetWithText(ElevatedButton, 'Confirm Split')));
      await tester.pumpAndSettle();

      // Complete Sale modal updates immediately: Needs Update is gone, remaining is ₹0
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Needs Update')), findsNothing);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('Total Allocated')), findsOneWidget);
      expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('₹0')), findsOneWidget);

      // Confirm & Complete ₹4,500 is now ENABLED!
      final ElevatedButton enabledBtn = tester.widget(confirmBtn);
      expect(enabledBtn.onPressed, isNotNull);
    });

    testWidgets('5. Completed split sale persists two sale_payments rows (Cash + UPI, NOT online)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      ActiveSaleSession.instance.save(
        customerId: null,
        lines: [
          const ActiveCartLine(
            productId: 'prod-shirt-001',
            variantId: 'var-shirt-001',
            title: 'Silk Evening Shirt',
            sku: 'SES-001',
            variantSubtitle: 'Navy • Size L',
            unitPriceMinor: 450000,
            quantity: 1,
            stockCount: 10,
            availableQty: 10,
          ),
        ],
        discountType: 'flat',
        discountInput: 45.0,
        paymentState: const CartPaymentState(
          mode: PaymentMode.split,
          allocations: [
            PaymentAllocation(method: 'cash', amountMinor: 222800),
            PaymentAllocation(method: 'upi', amountMinor: 222700),
          ],
          isConfirmed: true,
          confirmedTotalMinor: 445500,
        ),
        locationId: testLocationId,
        locationName: 'Stock location',
      );

      await tester.pumpWidget(buildTestHarness());
      await tester.pumpAndSettle();

      // Open Complete Sale
      await tester.tap(find.text('Complete Sale'));
      await tester.pumpAndSettle();

      // Click Confirm & Complete ₹4,455
      final confirmBtn = find.widgetWithText(ElevatedButton, 'Confirm & Complete ₹4,455');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Check persisted sales in repository
      final completedSales = SalesRepository.localSalesForTesting;
      expect(completedSales.length, 1);
      final completedSale = completedSales.first;
      expect(completedSale.total, 4455.0);

      // Verify two payments rows were persisted:
      expect(completedSale.payments.length, 2);
      final cashPayment = completedSale.payments.firstWhere((p) => p.paymentMethod == 'cash');
      final upiPayment = completedSale.payments.firstWhere((p) => p.paymentMethod == 'upi');

      expect(cashPayment.amountMinor, 222800);
      expect(cashPayment.amount, 2228.0);

      expect(upiPayment.amountMinor, 222700);
      expect(upiPayment.amount, 2227.0);

      // Verification: sum equals authoritative sale total
      expect(cashPayment.amountMinor + upiPayment.amountMinor, 445500);

      // Verification: none persisted as generic "online"
      expect(completedSale.payments.any((p) => p.paymentMethod == 'online'), isFalse);
    });
  });
}
