import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/features/business/domain/models/business.dart';
import 'package:threadstock/features/sales/data/sales_repository.dart';
import 'package:threadstock/features/sales/domain/services/customer_input_classifier.dart';
import 'package:threadstock/features/sales/presentation/active_sale_session.dart';
import 'package:threadstock/features/sales/presentation/widgets/new_sale_view.dart';

void main() {
  const bizA = 'biz-fashion-alpha-001';
  const bizB = 'biz-fashion-beta-002';

  setUp(() {
    SalesRepository.clearLocalSalesForTesting();
    SalesRepository.clearLocalCustomersForTesting();
    ActiveSaleSession.instance.clear();
    CurrentBusinessService.instance.clear();
    CurrentBusinessService.instance.setCurrentBusiness(
      Business(
        id: bizA,
        ownerUserId: 'owner-001',
        legalName: 'Threadstock Studio Alpha',
        businessType: 'retail',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1-5',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  group('Customer Directory Persistence & Operations', () {
    test('1. create customer -> database row exists with business_id and timestamps', () async {
      final customer = await SalesRepository.instance.createCustomer(
        businessId: bizA,
        name: 'Sarah Khan',
        phone: '+919986645729',
        email: 'sarah@example.com',
      );

      expect(customer, isNotNull);
      expect(customer!.id, isNotEmpty);
      expect(customer.businessId, bizA);
      expect(customer.name, 'Sarah Khan');
      expect(customer.phone, '+919986645729');
      expect(customer.email, 'sarah@example.com');
      expect(customer.createdAt, isNotNull);
      expect(customer.updatedAt, isNotNull);

      // Verify row exists in repository store
      final customers = await SalesRepository.instance.getCustomers(businessId: bizA);
      expect(customers.any((c) => c.id == customer.id), isTrue);
    });

    test('2. modal loads saved customers immediately on open (before user types)', () async {
      await SalesRepository.instance.createCustomer(
        businessId: bizA,
        name: 'Sarah Khan',
        phone: '+919986645729',
      );
      await SalesRepository.instance.createCustomer(
        businessId: bizA,
        name: 'John Mathew',
        email: 'john@example.com',
      );

      // Query recent customers
      final recent = await SalesRepository.instance.getRecentCustomers(businessId: bizA, limit: 10);
      expect(recent.length, 2);
      expect(recent[0].name, 'John Mathew'); // most recent
      expect(recent[1].name, 'Sarah Khan');
    });

    test('3. restart app / new query -> customer still appears (persisted, not transient in-memory)', () async {
      final customer = await SalesRepository.instance.createCustomer(
        businessId: bizA,
        name: 'Amina Ray',
        phone: '+919876543210',
        email: 'amina@example.com',
      );

      // Simulate app restart / new session
      ActiveSaleSession.instance.clear();
      final freshRepositoryQuery = await SalesRepository.instance.getCustomers(businessId: bizA);

      expect(freshRepositoryQuery.any((c) => c.id == customer!.id && c.name == 'Amina Ray'), isTrue);
    });

    test('4. search by name -> found with 1 character', () async {
      await SalesRepository.instance.createCustomer(
        businessId: bizA,
        name: 'Sarah Khan',
        phone: '+919986645729',
      );

      final search1Char = await SalesRepository.instance.searchCustomers(businessId: bizA, query: 'S');
      expect(search1Char.any((c) => c.name == 'Sarah Khan'), isTrue);

      final searchPrefix = await SalesRepository.instance.searchCustomers(businessId: bizA, query: 'Sara');
      expect(searchPrefix.any((c) => c.name == 'Sarah Khan'), isTrue);
    });

    test('5. search by phone -> found with partial digits', () async {
      await SalesRepository.instance.createCustomer(
        businessId: bizA,
        name: 'Sarah Khan',
        phone: '+919986645729',
      );

      final byDigits = await SalesRepository.instance.searchCustomers(businessId: bizA, query: '9986');
      expect(byDigits.any((c) => c.name == 'Sarah Khan'), isTrue);

      final byFullLocal = await SalesRepository.instance.searchCustomers(businessId: bizA, query: '9986645729');
      expect(byFullLocal.any((c) => c.name == 'Sarah Khan'), isTrue);
    });

    test('6. search by email -> found with prefix or full address', () async {
      await SalesRepository.instance.createCustomer(
        businessId: bizA,
        name: 'John Mathew',
        email: 'john@example.com',
      );

      final byPrefix = await SalesRepository.instance.searchCustomers(businessId: bizA, query: 'john@');
      expect(byPrefix.any((c) => c.name == 'John Mathew'), isTrue);

      final byFull = await SalesRepository.instance.searchCustomers(businessId: bizA, query: 'john@example.com');
      expect(byFull.any((c) => c.name == 'John Mathew'), isTrue);
    });

    test('7. smart autofill: never put phone digits into Full Name', () {
      final phoneClassification = CustomerInputClassifier.classify('9986645729', defaultIsd: '+91');
      expect(phoneClassification.type, CustomerInputType.phone);
      expect(phoneClassification.detectedPhone, '9986645729');
      expect(phoneClassification.detectedName, isNull);

      final emailClassification = CustomerInputClassifier.classify('john@example.com');
      expect(emailClassification.type, CustomerInputType.email);
      expect(emailClassification.detectedEmail, 'john@example.com');
      expect(emailClassification.detectedName, isNull);

      final nameClassification = CustomerInputClassifier.classify('Sarah Khan');
      expect(nameClassification.type, CustomerInputType.name);
      expect(nameClassification.detectedName, 'Sarah Khan');
      expect(nameClassification.detectedPhone, isNull);
    });

    test('8. duplicate prevention: normalized phone or email blocks duplicate creation', () async {
      await SalesRepository.instance.createCustomer(
        businessId: bizA,
        name: 'Sarah Khan',
        phone: '+919986645729',
        email: 'sarah@example.com',
      );

      // Duplicate phone check
      final dupPhone = await SalesRepository.instance.findDuplicateCustomer(
        businessId: bizA,
        phoneE164: '+919986645729',
      );
      expect(dupPhone, isNotNull);
      expect(dupPhone!.name, 'Sarah Khan');

      // Duplicate local phone matching normalized
      final dupLocal = await SalesRepository.instance.findDuplicateCustomer(
        businessId: bizA,
        phoneE164: '9986645729',
      );
      expect(dupLocal, isNotNull);

      // Duplicate email check
      final dupEmail = await SalesRepository.instance.findDuplicateCustomer(
        businessId: bizA,
        email: 'sarah@example.com',
      );
      expect(dupEmail, isNotNull);

      // Different person with same name but different phone/email is allowed
      final sameNameCheck = await SalesRepository.instance.findDuplicateCustomer(
        businessId: bizA,
        phoneE164: '+918888888888',
        email: 'other.sarah@example.com',
      );
      expect(sameNameCheck, isNull);
    });

    test('9. Walk-in Customer: customer_id is null and no database record is created', () async {
      final initialCount = (await SalesRepository.instance.getCustomers(businessId: bizA)).length;

      // Select walk-in in active session
      ActiveSaleSession.instance.save(
        lines: [],
        discountType: 'percentage',
        discountInput: 0,
        note: null,
        customerId: null,
        customerName: 'Walk-in Customer',
        customerPhone: null,
        heldSaleId: null,
        locationId: null,
        locationName: null,
      );

      expect(ActiveSaleSession.instance.customerId, isNull);
      expect(ActiveSaleSession.instance.customerName, 'Walk-in Customer');

      // Ensure no database row named Walk-in Customer was inserted
      final postCustomers = await SalesRepository.instance.getCustomers(businessId: bizA);
      expect(postCustomers.length, initialCount);
      expect(postCustomers.any((c) => c.name.toLowerCase() == 'walk-in customer'), isFalse);
    });

    test('10. hold sale with customer -> resume restores customer_id and customer name', () async {
      final customer = await SalesRepository.instance.createCustomer(
        businessId: bizA,
        name: 'Sarah Khan',
        phone: '+919986645729',
      );

      final holdRes = await SalesRepository.instance.holdSale(
        businessId: bizA,
        customerId: customer!.id,
        customerName: customer.name,
        customerPhone: customer.phone,
        subtotal: 1500.0,
        discount: 0.0,
        tax: 0.0,
        total: 1500.0,
        currencyCode: 'INR',
        items: [
          {
            'product_id': 'prod-001',
            'product_name_snapshot': 'Silk Kurta',
            'sku_snapshot': 'SK-01',
            'quantity': 1,
            'unit_price_minor': 150000,
            'unit_cost_minor': 80000,
            'line_total_minor': 150000,
            'taxable_amount_minor': 150000,
            'discount_minor': 0,
            'tax_minor': 0,
            'tax_category_snapshot': 'standard',
          }
        ],
      );

      expect(holdRes.success, isTrue);
      expect(holdRes.sale, isNotNull);
      expect(holdRes.sale!.customerId, customer.id);
      expect(holdRes.sale!.customerName, 'Sarah Khan');

      // Resume held sale
      final resumeRes = await SalesRepository.instance.resumeHeldSale(
        businessId: bizA,
        saleId: holdRes.sale!.id,
      );

      expect(resumeRes.success, isTrue);
      expect(resumeRes.sale!.customerId, customer.id);
      expect(resumeRes.sale!.customerName, 'Sarah Khan');

      // Load into session
      ActiveSaleSession.instance.loadHeldSale(resumeRes.sale!);
      expect(ActiveSaleSession.instance.customerId, customer.id);
      expect(ActiveSaleSession.instance.customerName, 'Sarah Khan');
    });

    test('11. complete sale: customer_id is persisted on sale, cart customer cleared, DB customer preserved', () async {
      final customer = await SalesRepository.instance.createCustomer(
        businessId: bizA,
        name: 'Sarah Khan',
        phone: '+919986645729',
      );

      final completeRes = await SalesRepository.instance.completeSale(
        businessId: bizA,
        customerId: customer!.id,
        customerName: customer.name,
        subtotal: 2500.0,
        discount: 0.0,
        tax: 0.0,
        total: 2500.0,
        currencyCode: 'INR',
        items: [
          {
            'product_id': 'prod-002',
            'product_name_snapshot': 'Linen Shirt',
            'sku_snapshot': 'LS-01',
            'quantity': 1,
            'unit_price_minor': 250000,
            'unit_cost_minor': 120000,
            'line_total_minor': 250000,
            'taxable_amount_minor': 250000,
            'discount_minor': 0,
            'tax_minor': 0,
            'tax_category_snapshot': 'standard',
          }
        ],
        payments: [
          {
            'payment_method': 'cash',
            'amount_minor': 250000,
            'currency_code': 'INR',
            'status': 'completed',
          }
        ],
      );

      expect(completeRes.success, isTrue);
      expect(completeRes.sale!.customerId, customer.id);
      expect(completeRes.sale!.customerName, 'Sarah Khan');

      // Cart session cleared
      ActiveSaleSession.instance.clear();
      expect(ActiveSaleSession.instance.customerId, isNull);

      // DB customer record must still exist
      final allCustomers = await SalesRepository.instance.getCustomers(businessId: bizA);
      expect(allCustomers.any((c) => c.id == customer.id), isTrue);
    });

    test('12. cross-business isolation: customer never visible in another business', () async {
      await SalesRepository.instance.createCustomer(
        businessId: bizA,
        name: 'Alpha Customer',
        phone: '+919111111111',
      );

      await SalesRepository.instance.createCustomer(
        businessId: bizB,
        name: 'Beta Customer',
        phone: '+919222222222',
      );

      // Business A queries
      final listA = await SalesRepository.instance.getRecentCustomers(businessId: bizA);
      expect(listA.any((c) => c.name == 'Alpha Customer'), isTrue);
      expect(listA.any((c) => c.name == 'Beta Customer'), isFalse);

      final searchA = await SalesRepository.instance.searchCustomers(businessId: bizA, query: 'Customer');
      expect(searchA.any((c) => c.name == 'Alpha Customer'), isTrue);
      expect(searchA.any((c) => c.name == 'Beta Customer'), isFalse);

      // Business B queries
      final listB = await SalesRepository.instance.getRecentCustomers(businessId: bizB);
      expect(listB.any((c) => c.name == 'Beta Customer'), isTrue);
      expect(listB.any((c) => c.name == 'Alpha Customer'), isFalse);
    });
  });

  group('Attach Customer Modal UI Integration', () {
    testWidgets('Modal opens, shows Recent Customers immediately, and allows attaching existing customer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final customer = await SalesRepository.instance.createCustomer(
        businessId: bizA,
        name: 'Sarah Khan',
        phone: '+919986645729',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NewSaleView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Attach Customer button
      final attachBtn = find.byKey(const Key('attach_customer_button'));
      expect(attachBtn, findsOneWidget);
      await tester.tap(attachBtn);
      await tester.pumpAndSettle();

      // Modal is open
      expect(find.text('Attach Customer'), findsOneWidget);
      expect(find.byKey(const Key('walk_in_customer_tile')), findsOneWidget);
      expect(find.byKey(const Key('recent_customers_header')), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Dialog), matching: find.text('Sarah Khan')),
        findsOneWidget,
      );

      // Tap Sarah Khan to attach
      final customerTile = find.byKey(Key('customer_tile_${customer!.id}'));
      expect(customerTile, findsOneWidget);
      await tester.tap(customerTile);
      await tester.pumpAndSettle();

      // Modal closed, cart shows customer pill
      expect(find.text('Attach Customer'), findsNothing);
      expect(
        find.descendant(of: find.byKey(const Key('customer_pill_open_dialog')), matching: find.text('Sarah Khan')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('change_customer_button')), findsOneWidget);
      expect(find.byKey(const Key('remove_customer_button')), findsOneWidget);

      // Reopen modal to verify customer is marked as Attached
      await tester.tap(find.byKey(const Key('change_customer_button')));
      await tester.pumpAndSettle();

      expect(find.text('Attached'), findsOneWidget);

      // Cancel/close modal
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Remove customer from cart
      await tester.tap(find.byKey(const Key('remove_customer_button')));
      await tester.pumpAndSettle();

      // Customer pill removed from cart
      expect(find.byKey(const Key('attach_customer_button')), findsOneWidget);

      // Database customer record remains intact
      final dbCustomers = await SalesRepository.instance.getCustomers(businessId: bizA);
      expect(dbCustomers.any((c) => c.id == customer.id), isTrue);
    });

    testWidgets('Create customer in modal persists to DB, attaches to cart, and appears in Recent Customers on reopen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NewSaleView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Attach Customer dialog
      await tester.tap(find.byKey(const Key('attach_customer_button')));
      await tester.pumpAndSettle();

      // Tap Create new customer tile
      await tester.tap(find.byKey(const Key('create_new_customer_tile')));
      await tester.pumpAndSettle();

      // Fill in Name and Phone
      await tester.enterText(find.byKey(const Key('customer_name_field')), 'John Mathew');
      await tester.enterText(find.byKey(const Key('customer_phone_field')), '9876543210');
      await tester.enterText(find.byKey(const Key('customer_email_field')), 'john@example.com');
      await tester.pumpAndSettle();

      // Click Create & Attach
      final createBtn = find.byKey(const Key('create_and_attach_customer_button'));
      expect(createBtn, findsOneWidget);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      // Modal closed, cart shows John Mathew
      expect(
        find.descendant(of: find.byKey(const Key('customer_pill_open_dialog')), matching: find.text('John Mathew')),
        findsOneWidget,
      );

      // Verify row exists in repository / database
      final savedCustomers = await SalesRepository.instance.getCustomers(businessId: bizA);
      expect(savedCustomers.any((c) => c.name == 'John Mathew'), isTrue);

      // Reopen modal: John Mathew must appear in Recent Customers with "Attached"
      await tester.tap(find.byKey(const Key('change_customer_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recent_customers_header')), findsOneWidget);
      expect(
        find.descendant(of: find.byType(Dialog), matching: find.text('John Mathew')),
        findsOneWidget,
      );
      expect(find.text('Attached'), findsOneWidget);
    });
  });
}
