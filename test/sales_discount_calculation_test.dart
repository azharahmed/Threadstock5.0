import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/sales/presentation/active_sale_session.dart';
import 'package:threadstock/features/sales/presentation/widgets/new_sale_view.dart';

void main() {
  group('SalesDiscountCalculator - Subtotal = 1500', () {
    const double subtotal = 1500.0;

    test('Percentage: 0.1% -> 1.50', () {
      final amount = SalesDiscountCalculator.calculateDiscountAmount(
        subtotal: subtotal,
        type: SalesDiscountType.percentage,
        inputValue: 0.1,
      );
      expect(amount, 1.50);
    });

    test('Percentage: 0.5% -> 7.50', () {
      final amount = SalesDiscountCalculator.calculateDiscountAmount(
        subtotal: subtotal,
        type: SalesDiscountType.percentage,
        inputValue: 0.5,
      );
      expect(amount, 7.50);
    });

    test('Percentage: 1% -> 15.00', () {
      final amount = SalesDiscountCalculator.calculateDiscountAmount(
        subtotal: subtotal,
        type: SalesDiscountType.percentage,
        inputValue: 1.0,
      );
      expect(amount, 15.00);
    });

    test('Percentage: 10% -> 150.00', () {
      final amount = SalesDiscountCalculator.calculateDiscountAmount(
        subtotal: subtotal,
        type: SalesDiscountType.percentage,
        inputValue: 10.0,
      );
      expect(amount, 150.00);
    });

    test('Percentage: 100% -> 1500.00', () {
      final amount = SalesDiscountCalculator.calculateDiscountAmount(
        subtotal: subtotal,
        type: SalesDiscountType.percentage,
        inputValue: 100.0,
      );
      expect(amount, 1500.00);
    });

    test('Flat: 0.50 -> 0.50', () {
      final amount = SalesDiscountCalculator.calculateDiscountAmount(
        subtotal: subtotal,
        type: SalesDiscountType.flat,
        inputValue: 0.50,
      );
      expect(amount, 0.50);
    });

    test('Flat: 1.50 -> 1.50', () {
      final amount = SalesDiscountCalculator.calculateDiscountAmount(
        subtotal: subtotal,
        type: SalesDiscountType.flat,
        inputValue: 1.50,
      );
      expect(amount, 1.50);
    });

    test('Flat: 50 -> 50.00', () {
      final amount = SalesDiscountCalculator.calculateDiscountAmount(
        subtotal: subtotal,
        type: SalesDiscountType.flat,
        inputValue: 50.0,
      );
      expect(amount, 50.00);
    });

    test('Flat: 1500 -> 1500.00', () {
      final amount = SalesDiscountCalculator.calculateDiscountAmount(
        subtotal: subtotal,
        type: SalesDiscountType.flat,
        inputValue: 1500.0,
      );
      expect(amount, 1500.00);
    });
  });

  group('SalesDiscountCalculator - Validation tests', () {
    const double subtotal = 1500.0;

    test('Blank text validation', () {
      final err = SalesDiscountCalculator.validateDiscount(
        subtotal: subtotal,
        type: SalesDiscountType.percentage,
        text: '   ',
      );
      expect(err, 'Please enter a discount value');
    });

    test('Negative value validation', () {
      final err = SalesDiscountCalculator.validateDiscount(
        subtotal: subtotal,
        type: SalesDiscountType.percentage,
        text: '-5',
      );
      expect(err, 'Discount cannot be negative');
    });

    test('>100% percentage validation', () {
      final err = SalesDiscountCalculator.validateDiscount(
        subtotal: subtotal,
        type: SalesDiscountType.percentage,
        text: '105',
      );
      expect(err, 'Discount cannot exceed 100%');
    });

    test('Flat amount > subtotal validation', () {
      final err = SalesDiscountCalculator.validateDiscount(
        subtotal: subtotal,
        type: SalesDiscountType.flat,
        text: '1600',
      );
      expect(err, 'Discount cannot exceed the order subtotal.');
    });

    test('Malformed text validation', () {
      final err = SalesDiscountCalculator.validateDiscount(
        subtotal: subtotal,
        type: SalesDiscountType.percentage,
        text: 'abc',
      );
      expect(err, 'Enter a valid number');
    });

    test('Value 0 returns null (allowed, triggers discount removal)', () {
      final err = SalesDiscountCalculator.validateDiscount(
        subtotal: subtotal,
        type: SalesDiscountType.percentage,
        text: '0',
      );
      expect(err, isNull);
    });
  });

  group('NewSaleView State and Calculation tests', () {
    setUp(() => ActiveSaleSession.instance.clear());

    testWidgets('Subtotal = 1500 and 0.1% discount displays ₹1.50 and total ₹1,498.50', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final newSaleKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewSaleView(key: newSaleKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state(find.byKey(newSaleKey)) as dynamic;

      // Set items with total = 1500
      const product = PosProduct(
        id: 'p1',
        title: 'Test Garment',
        variantSubtitle: 'Blue • M',
        imageAsset: 'assets/images/placeholder.png',
        price: 1500,
        stockCount: 10,
        normalTags: [],
        highlightTag: '',
      );
      state.setCartItemsForTesting([
        PosCartItem(product: product, quantity: 1),
      ]);
      await tester.pumpAndSettle();

      expect(state.subtotalForTesting, 1500.0);

      // Apply 0.1% discount
      state.applyDiscountForTesting(
        type: SalesDiscountType.percentage,
        inputValue: 0.1,
      );
      await tester.pumpAndSettle();

      expect(state.calculatedDiscountAmountForTesting, 1.50);
      expect(state.taxableSubtotalForTesting, 1498.50);
      expect(state.taxAmountForTesting, 0.0);
      expect(state.totalAmountForTesting, 1498.50);

      // Verify UI text in cart summary
      expect(find.text('Discount (0.1%)'), findsOneWidget);
      expect(find.text('-₹1.50'), findsOneWidget);
      expect(find.text('₹1,498.50'), findsOneWidget);

      // Verify removal
      state.removeDiscountForTesting();
      await tester.pumpAndSettle();

      expect(state.calculatedDiscountAmountForTesting, 0.0);
      expect(state.totalAmountForTesting, 1500.0);
      expect(find.text('₹1,500'), findsWidgets);
    });

    testWidgets('Subtotal = 1500 and flat ₹50 discount displays ₹50 and total ₹1,450', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final newSaleKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewSaleView(key: newSaleKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state(find.byKey(newSaleKey)) as dynamic;

      const product = PosProduct(
        id: 'p1',
        title: 'Test Garment',
        variantSubtitle: 'Blue • M',
        imageAsset: 'assets/images/placeholder.png',
        price: 1500,
        stockCount: 10,
        normalTags: [],
        highlightTag: '',
      );
      state.setCartItemsForTesting([
        PosCartItem(product: product, quantity: 1),
      ]);
      await tester.pumpAndSettle();

      // Apply ₹50 flat discount
      state.applyDiscountForTesting(
        type: SalesDiscountType.flat,
        inputValue: 50.0,
      );
      await tester.pumpAndSettle();

      expect(state.calculatedDiscountAmountForTesting, 50.0);
      expect(state.taxableSubtotalForTesting, 1450.0);
      expect(state.taxAmountForTesting, 0.0);
      expect(state.totalAmountForTesting, 1450.0);

      expect(find.text('Discount'), findsOneWidget);
      expect(find.text('-₹50'), findsOneWidget);
      expect(find.text('₹1,450'), findsOneWidget);
    });

    testWidgets('Apply Discount Modal flow: Percentage, Flat, Validation, and Removal', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final newSaleKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NewSaleView(key: newSaleKey),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final state = tester.state(find.byKey(newSaleKey)) as dynamic;
      state.removeDiscountForTesting();
      await tester.pumpAndSettle();

      const product = PosProduct(
        id: 'p1',
        title: 'Test Garment',
        variantSubtitle: 'Blue • M',
        imageAsset: 'assets/images/placeholder.png',
        price: 1500,
        stockCount: 10,
        normalTags: [],
        highlightTag: '',
      );
      state.setCartItemsForTesting([
        PosCartItem(product: product, quantity: 1),
      ]);
      await tester.pumpAndSettle();

      // 1. Open Apply Discount Dialog
      await tester.tap(find.text('Apply Discount'));
      await tester.pumpAndSettle();

      expect(find.text('Discount Type'), findsOneWidget);
      expect(find.text('Percentage %'), findsOneWidget);
      expect(find.text('Flat Amount'), findsOneWidget);

      // 2. Test Blank Validation
      await tester.enterText(find.byType(TextField).last, '   ');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a discount value'), findsOneWidget);

      // 3. Test Negative Validation
      await tester.enterText(find.byType(TextField).last, '-5');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Discount cannot be negative'), findsOneWidget);

      // 4. Test >100% Validation
      await tester.enterText(find.byType(TextField).last, '120');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Discount cannot exceed 100%'), findsOneWidget);

      // 5. Test Valid Percentage: 0.1%
      await tester.enterText(find.byType(TextField).last, '0.1');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Apply'));
      await tester.pumpAndSettle();

      expect(state.calculatedDiscountAmountForTesting, 1.50);
      expect(state.totalAmountForTesting, 1498.50);
      expect(find.text('0.1% discount applied'), findsOneWidget);
      expect(find.text('Discount (0.1%)'), findsOneWidget);
      expect(find.text('-₹1.50'), findsOneWidget);
      expect(find.text('₹1,498.50'), findsOneWidget);

      // 6. Re-open modal and switch to Flat Amount
      await tester.tap(find.text('Edit Discount'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Flat Amount'));
      await tester.pumpAndSettle();

      // Test flat amount > subtotal
      await tester.enterText(find.byType(TextField).last, '2000');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Apply'));
      await tester.pumpAndSettle();
      expect(find.text('Discount cannot exceed the order subtotal.'), findsOneWidget);

      // Apply flat 0.50
      await tester.enterText(find.byType(TextField).last, '0.50');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Apply'));
      await tester.pumpAndSettle();

      expect(state.calculatedDiscountAmountForTesting, 0.50);
      expect(state.totalAmountForTesting, 1499.50);
      expect(find.text('₹0.50 discount applied'), findsOneWidget);
      expect(find.text('-₹0.50'), findsOneWidget);
      expect(find.text('₹1,499.50'), findsOneWidget);

      // Wait for previous snackbar to dismiss
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // 7. Remove Discount via Remove button
      await tester.tap(find.text('Edit Discount'));
      await tester.pumpAndSettle();

      expect(find.text('Remove Discount'), findsOneWidget);
      await tester.tap(find.text('Remove Discount'));
      await tester.pumpAndSettle();

      expect(state.calculatedDiscountAmountForTesting, 0.0);
      expect(state.totalAmountForTesting, 1500.0);
      expect(find.text('Discount removed'), findsOneWidget);
      expect(find.text('₹1,500'), findsWidgets);
    });
  });
}
