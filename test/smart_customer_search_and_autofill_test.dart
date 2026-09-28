import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/features/business/domain/models/business.dart';
import 'package:threadstock/features/sales/data/sales_repository.dart';
import 'package:threadstock/features/sales/domain/models/customer.dart';
import 'package:threadstock/features/sales/domain/services/customer_input_classifier.dart';
import 'package:threadstock/features/sales/presentation/active_sale_session.dart';
import 'package:threadstock/features/sales/presentation/widgets/new_sale_view.dart';

void main() {
  setUp(() {
    SalesRepository.clearLocalSalesForTesting();
    SalesRepository.clearLocalCustomersForTesting();
    ActiveSaleSession.instance.clear();
    CurrentBusinessService.instance.clear();
  });

  group('CustomerInputClassifier — Phone, Name, Email, ISD, E.164', () {
    test('9986645729 classifies as Phone and normalizes to E.164 with default IN ISD (+91)', () {
      final res = CustomerInputClassifier.classify('9986645729', defaultIsd: '+91');
      expect(res.type, CustomerInputType.phone);
      expect(res.detectedPhone, '9986645729');
      expect(res.detectedName, isNull);
      expect(res.detectedEmail, isNull);
      expect(res.normalizedE164, '+919986645729');
    });

    test('+919986645729 classifies as Phone and splits detected ISD (+91) and local phone', () {
      final res = CustomerInputClassifier.classify('+919986645729', defaultIsd: '+91');
      expect(res.type, CustomerInputType.phone);
      expect(res.detectedPhone, '9986645729');
      expect(res.detectedIsd, '+91');
      expect(res.detectedName, isNull);
      expect(res.detectedEmail, isNull);
      expect(res.normalizedE164, '+919986645729');
    });

    test('99866 45729 classifies as Phone with spaces and normalizes to E.164', () {
      final res = CustomerInputClassifier.classify('99866 45729', defaultIsd: '+91');
      expect(res.type, CustomerInputType.phone);
      expect(res.detectedPhone, '99866 45729');
      expect(res.normalizedE164, '+919986645729');
    });

    test('Aisha Khan classifies as Full Name with phone and email blank', () {
      final res = CustomerInputClassifier.classify('Aisha Khan', defaultIsd: '+91');
      expect(res.type, CustomerInputType.name);
      expect(res.detectedName, 'Aisha Khan');
      expect(res.detectedPhone, isNull);
      expect(res.detectedEmail, isNull);
    });

    test('John Mathew classifies as Full Name with phone and email blank', () {
      final res = CustomerInputClassifier.classify('John Mathew', defaultIsd: '+91');
      expect(res.type, CustomerInputType.name);
      expect(res.detectedName, 'John Mathew');
      expect(res.detectedPhone, isNull);
      expect(res.detectedEmail, isNull);
    });

    test('aisha@gmail.com classifies as Email with full name and phone blank', () {
      final res = CustomerInputClassifier.classify('aisha@gmail.com', defaultIsd: '+91');
      expect(res.type, CustomerInputType.email);
      expect(res.detectedEmail, 'aisha@gmail.com');
      expect(res.detectedName, isNull);
      expect(res.detectedPhone, isNull);
    });

    test('Business country defaults: IN -> +91 default, AE -> +971 default', () {
      expect(CustomerInputClassifier.defaultIsdForCountryCode('IN'), '+91');
      expect(CustomerInputClassifier.defaultIsdForCountryCode('in'), '+91');
      expect(CustomerInputClassifier.defaultIsdForCountryCode('India'), '+91');

      expect(CustomerInputClassifier.defaultIsdForCountryCode('AE'), '+971');
      expect(CustomerInputClassifier.defaultIsdForCountryCode('ae'), '+971');
      expect(CustomerInputClassifier.defaultIsdForCountryCode('UAE'), '+971');

      expect(CustomerInputClassifier.defaultIsdForCountryCode('US'), '+1');
      expect(CustomerInputClassifier.defaultIsdForCountryCode('GB'), '+44');
    });

    test('AE business country normalizes local UAE number to +971', () {
      final res = CustomerInputClassifier.classify('501234567', defaultIsd: '+971');
      expect(res.type, CustomerInputType.phone);
      expect(res.detectedPhone, '501234567');
      expect(res.normalizedE164, '+971501234567');
    });
  });

  group('SalesRepository — Customer Search, Duplicate Prevention & Cross-Business Isolation', () {
    const bizA = 'biz-alpha-123';
    const bizB = 'biz-beta-456';

    setUp(() {
      SalesRepository.clearLocalCustomersForTesting();

      // Seed customers for Biz A
      SalesRepository.addLocalCustomerForTesting(
        Customer(
          id: 'cust-1',
          businessId: bizA,
          name: 'Aisha Khan',
          email: 'aisha@gmail.com',
          phone: '+919986645729',
          createdAt: DateTime.now(),
        ),
      );

      SalesRepository.addLocalCustomerForTesting(
        Customer(
          id: 'cust-2',
          businessId: bizA,
          name: 'John Mathew',
          email: 'john@example.com',
          phone: '+919876543210',
          createdAt: DateTime.now(),
        ),
      );

      // Seed customer for Biz B (cross-business test)
      SalesRepository.addLocalCustomerForTesting(
        Customer(
          id: 'cust-3',
          businessId: bizB,
          name: 'Aisha Secret',
          email: 'secret@competitor.com',
          phone: '+919986645729',
          createdAt: DateTime.now(),
        ),
      );
    });

    test('Phone search finds existing customer by normalized and local formats', () async {
      final repo = SalesRepository.instance;

      // 1. Search by local digits without +91
      final res1 = await repo.searchCustomers(businessId: bizA, query: '9986645729', defaultIsd: '+91');
      expect(res1.length, 1);
      expect(res1.first.name, 'Aisha Khan');

      // 2. Search by full E.164
      final res2 = await repo.searchCustomers(businessId: bizA, query: '+919986645729', defaultIsd: '+91');
      expect(res2.length, 1);
      expect(res2.first.name, 'Aisha Khan');

      // 3. Search with spaces
      final res3 = await repo.searchCustomers(businessId: bizA, query: '99866 45729', defaultIsd: '+91');
      expect(res3.length, 1);
      expect(res3.first.name, 'Aisha Khan');

      // 4. Single digit search
      final res4 = await repo.searchCustomers(businessId: bizA, query: '9', defaultIsd: '+91');
      expect(res4.isNotEmpty, isTrue);
      expect(res4.any((c) => c.name == 'Aisha Khan'), isTrue);
    });

    test('Email search finds existing customer', () async {
      final repo = SalesRepository.instance;

      final res1 = await repo.searchCustomers(businessId: bizA, query: 'aisha@gmail.com');
      expect(res1.length, 1);
      expect(res1.first.name, 'Aisha Khan');

      final res2 = await repo.searchCustomers(businessId: bizA, query: 'john@');
      expect(res2.length, 1);
      expect(res2.first.name, 'John Mathew');
    });

    test('Name search finds existing customer (including 1-character search)', () async {
      final repo = SalesRepository.instance;

      final res1 = await repo.searchCustomers(businessId: bizA, query: 'Aisha Khan');
      expect(res1.length, 1);
      expect(res1.first.name, 'Aisha Khan');

      final res2 = await repo.searchCustomers(businessId: bizA, query: 'A');
      expect(res2.any((c) => c.name == 'Aisha Khan'), isTrue);
    });

    test('Cross-business customer is NEVER shown to another business', () async {
      final repo = SalesRepository.instance;

      // Search Biz A for phone '+919986645729' which exists in both bizA and bizB
      final resA = await repo.searchCustomers(businessId: bizA, query: '9986645729');
      expect(resA.length, 1);
      expect(resA.first.name, 'Aisha Khan');
      expect(resA.any((c) => c.businessId == bizB), isFalse);

      // Search Biz B for 'Aisha'
      final resB = await repo.searchCustomers(businessId: bizB, query: 'Aisha');
      expect(resB.length, 1);
      expect(resB.first.name, 'Aisha Secret');
      expect(resB.any((c) => c.businessId == bizA), isFalse);
    });

    test('Duplicate phone check detects existing customer and prevents duplicate creation', () async {
      final repo = SalesRepository.instance;

      final dup = await repo.findDuplicateCustomer(
        businessId: bizA,
        phoneE164: '+919986645729',
      );
      expect(dup, isNotNull);
      expect(dup!.name, 'Aisha Khan');

      // Duplicate check across businesses should not block Biz B
      final dupOther = await repo.findDuplicateCustomer(
        businessId: 'biz-other-999',
        phoneE164: '+919986645729',
      );
      expect(dupOther, isNull);
    });

    test('Duplicate email check detects existing customer and prevents duplicate creation', () async {
      final repo = SalesRepository.instance;

      final dup = await repo.findDuplicateCustomer(
        businessId: bizA,
        email: 'aisha@gmail.com',
      );
      expect(dup, isNotNull);
      expect(dup!.name, 'Aisha Khan');

      final dupCaseInsensitive = await repo.findDuplicateCustomer(
        businessId: bizA,
        email: 'AISHA@GMAIL.COM',
      );
      expect(dupCaseInsensitive, isNotNull);
      expect(dupCaseInsensitive!.name, 'Aisha Khan');
    });
  });

  group('Attach Customer Modal UI — Auto-Fill & Duplicate Prevention', () {
    const testBizId = 'biz-ui-test-1';

    setUp(() {
      SalesRepository.clearLocalCustomersForTesting();
      final business = Business(
        id: testBizId,
        ownerUserId: 'user-1',
        legalName: 'ThreadStock Apparel',
        businessType: 'Retail',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      CurrentBusinessService.instance.setCurrentBusiness(business);

      SalesRepository.addLocalCustomerForTesting(
        Customer(
          id: 'cust-existing-1',
          businessId: testBizId,
          name: 'Existing Customer',
          email: 'existing@threadstock.com',
          phone: '+919986645729',
          createdAt: DateTime.now(),
        ),
      );
    });

    testWidgets('9986645729 entered in search auto-fills Phone (NOT Full Name) and disables Create & Attach until name is entered', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NewSaleView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open Attach Customer dialog
      await tester.tap(find.text('Attach Customer...'));
      await tester.pumpAndSettle();

      expect(find.text('Attach Customer'), findsOneWidget);

      // Type 9986645729 into search
      final searchField = find.byKey(const Key('customer_search_field'));
      await tester.enterText(searchField, '9986645729');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // The existing customer matches this phone!
      expect(find.text('Existing Customer'), findsOneWidget);

      // Now test with a non-duplicate phone number
      await tester.enterText(searchField, '9888877777');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // "Create new customer" option appears
      final createNewOption = find.byKey(const Key('create_new_customer_tile'));
      expect(createNewOption, findsOneWidget);

      // Expand Create new customer
      await tester.tap(createNewOption);
      await tester.pumpAndSettle();

      // Verify Auto-Fill mapping:
      // Phone must contain '9888877777'
      // Full Name must be BLANK!
      // Email must be BLANK!
      final nameField = find.byKey(const Key('customer_name_field'));
      final phoneField = find.byKey(const Key('customer_phone_field'));
      final emailField = find.byKey(const Key('customer_email_field'));

      final nameCtrl = (tester.widget(nameField) as TextField).controller;
      final phoneCtrl = (tester.widget(phoneField) as TextField).controller;
      final emailCtrl = (tester.widget(emailField) as TextField).controller;

      expect(nameCtrl?.text, isEmpty, reason: 'Full Name must be blank when phone number was typed');
      expect(phoneCtrl?.text, '9888877777', reason: 'Phone must be auto-filled with detected phone');
      expect(emailCtrl?.text, isEmpty, reason: 'Email must be blank when phone number was typed');

      // Verify Create & Attach button is DISABLED because Full Name is required
      final createButtonFinder = find.byKey(const Key('create_and_attach_customer_button'));
      ElevatedButton createBtn = tester.widget(createButtonFinder);
      expect(createBtn.onPressed, isNull, reason: 'Create & Attach must be disabled until a valid name is entered');

      // Now enter a name
      await tester.enterText(nameField, 'Rahul Verma');
      await tester.pumpAndSettle();

      createBtn = tester.widget(createButtonFinder);
      expect(createBtn.onPressed, isNotNull, reason: 'Create & Attach must enable once Full Name is provided');

      // Click Create & Attach
      await tester.tap(createButtonFinder);
      await tester.pumpAndSettle();

      // Dialog should be dismissed and customer attached to the sale
      expect(find.text('Rahul Verma'), findsOneWidget);
    });

    testWidgets('aisha@gmail.com entered in search auto-fills Email (NOT Full Name)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NewSaleView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Attach Customer...'));
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('customer_search_field'));
      await tester.enterText(searchField, 'newuser@threadstock.com');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      final createNewOption = find.byKey(const Key('create_new_customer_tile'));
      expect(createNewOption, findsOneWidget);

      await tester.tap(createNewOption);
      await tester.pumpAndSettle();

      final nameField = find.byKey(const Key('customer_name_field'));
      final phoneField = find.byKey(const Key('customer_phone_field'));
      final emailField = find.byKey(const Key('customer_email_field'));

      final nameCtrl = (tester.widget(nameField) as TextField).controller;
      final phoneCtrl = (tester.widget(phoneField) as TextField).controller;
      final emailCtrl = (tester.widget(emailField) as TextField).controller;

      expect(nameCtrl?.text, isEmpty, reason: 'Full Name must be blank when email was typed');
      expect(emailCtrl?.text, 'newuser@threadstock.com', reason: 'Email must be auto-filled with detected email');
      expect(phoneCtrl?.text, isEmpty, reason: 'Phone must be blank when email was typed');
    });

    testWidgets('Duplicate phone blocks creation and offers Attach button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NewSaleView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Attach Customer...'));
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('customer_search_field'));
      // Search a new name so "Create new customer" shows up
      await tester.enterText(searchField, 'Fresh Name');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      final createNewOption = find.byKey(const Key('create_new_customer_tile'));
      expect(createNewOption, findsOneWidget);

      await tester.tap(createNewOption);
      await tester.pumpAndSettle();

      final nameField = find.byKey(const Key('customer_name_field'));
      final phoneField = find.byKey(const Key('customer_phone_field'));

      // Full Name is 'Fresh Name'
      expect((tester.widget(nameField) as TextField).controller?.text, 'Fresh Name');

      // Now enter the duplicate phone 9986645729
      await tester.enterText(phoneField, '9986645729');
      await tester.pumpAndSettle();

      final createButtonFinder = find.byKey(const Key('create_and_attach_customer_button'));
      await tester.tap(createButtonFinder);
      await tester.pumpAndSettle();

      // Duplicate alert should appear and no duplicate created
      expect(find.byKey(const Key('customer_duplicate_alert')), findsOneWidget);
      expect(find.textContaining('already exists'), findsOneWidget);
      expect(find.textContaining('Existing Customer'), findsWidgets);

      // Click "Attach Existing Customer"
      final attachDupBtn = find.byKey(const Key('attach_duplicate_customer_button'));
      expect(attachDupBtn, findsOneWidget);

      await tester.ensureVisible(attachDupBtn);
      await tester.pumpAndSettle();
      await tester.tap(attachDupBtn);
      await tester.pumpAndSettle();

      // Dialog is dismissed and Existing Customer is attached!
      expect(find.text('Existing Customer'), findsOneWidget);
    });

    testWidgets('Manual edits by user are never overwritten when search text updates', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NewSaleView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Attach Customer...'));
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('customer_search_field'));
      await tester.enterText(searchField, '9871112222');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      final createNewOption = find.byKey(const Key('create_new_customer_tile'));
      await tester.tap(createNewOption);
      await tester.pumpAndSettle();

      final nameField = find.byKey(const Key('customer_name_field'));
      // Manually type a custom name
      await tester.enterText(nameField, 'Custom Edited Name');
      await tester.pumpAndSettle();

      // Now update the search field
      await tester.enterText(searchField, '9871113333');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Phone is updated because phone was not manually edited
      final phoneField = find.byKey(const Key('customer_phone_field'));
      expect((tester.widget(phoneField) as TextField).controller?.text, '9871113333');

      // Full Name is PRESERVED because user manually edited it!
      expect((tester.widget(nameField) as TextField).controller?.text, 'Custom Edited Name');
    });

    testWidgets('UAE business default ISD (+971) preselected in country dropdown', (tester) async {
      SalesRepository.clearLocalCustomersForTesting();
      final uaeBiz = Business(
        id: 'biz-uae-1',
        ownerUserId: 'user-uae',
        legalName: 'ThreadStock Dubai',
        businessType: 'Retail',
        countryCode: 'AE',
        currencyCode: 'AED',
        locationRange: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      CurrentBusinessService.instance.setCurrentBusiness(uaeBiz);

      await tester.binding.setSurfaceSize(const Size(1400, 900));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NewSaleView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Attach Customer...'));
      await tester.pumpAndSettle();

      final searchField = find.byKey(const Key('customer_search_field'));
      await tester.enterText(searchField, '501234567');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      final createNewOption = find.byKey(const Key('create_new_customer_tile'));
      await tester.tap(createNewOption);
      await tester.pumpAndSettle();

      // Verify +971 AE is pre-selected for UAE business
      expect(find.text('+971 AE'), findsOneWidget);
    });
  });
}
