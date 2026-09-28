import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/inventory/presentation/pages/inventory_page.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';

import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';

void main() {
  setUp(() async {
    await OnboardingRepository.instance.reset();
  });

  tearDown(() async {
    await OnboardingRepository.instance.reset();
  });

  Future<void> pumpStep4(
    WidgetTester tester, {
    Size size = const Size(1920, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: OnboardingPage(initialStep: 4)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Step 4 starts with no selection, Initialize disabled, and Skip & Go to Dashboard enabled; selection enables Initialize',
    (tester) async {
      await pumpStep4(tester);

      expect(find.text('How would you like to start?'), findsOneWidget);

      final initFinder = find.widgetWithText(
        ElevatedButton,
        'Initialize Catalog Setup',
      );
      final skipFinder = find.widgetWithText(
        ElevatedButton,
        'Skip & Go to Dashboard',
      );

      expect(initFinder, findsOneWidget);
      expect(skipFinder, findsOneWidget);

      final initButton = tester.widget<ElevatedButton>(initFinder);
      final skipButton = tester.widget<ElevatedButton>(skipFinder);

      expect(initButton.onPressed, isNull);
      // Skip & Go to Dashboard must be always enabled on Step 4
      expect(skipButton.onPressed, isNotNull);

      // Select Create Manually
      await tester.tap(find.text('Create Manually'));
      await tester.pump();

      final initButtonAfterSelect = tester.widget<ElevatedButton>(initFinder);
      final skipButtonAfterSelect = tester.widget<ElevatedButton>(skipFinder);

      // Both Initialize and Skip & Go to Dashboard are now enabled
      expect(initButtonAfterSelect.onPressed, isNotNull);
      expect(skipButtonAfterSelect.onPressed, isNotNull);
    },
  );

  testWidgets('Manual selection opens the real Create Product inventory flow', (
    tester,
  ) async {
    await pumpStep4(tester, size: const Size(1920, 1200));

    await tester.tap(find.text('Create Manually'));
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Initialize Catalog Setup'), 200);
    await tester.tap(find.text('Initialize Catalog Setup'));
    await tester.pumpAndSettle();

    expect(find.byType(InventoryPage), findsOneWidget);
    expect(find.text('Create New Product'), findsWidgets);
  });

  testWidgets('CSV selection opens the real inventory import flow', (
    tester,
  ) async {
    await pumpStep4(tester, size: const Size(1920, 1200));

    await tester.tap(find.text('Upload CSV / Excel'));
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Initialize Catalog Setup'), 200);
    await tester.tap(find.text('Initialize Catalog Setup'));
    await tester.pumpAndSettle();

    expect(find.byType(InventoryPage), findsOneWidget);
    expect(find.text('Import Inventory'), findsWidgets);
  });

  testWidgets('Shopify selection reports integration not implemented', (
    tester,
  ) async {
    await pumpStep4(tester);

    await tester.tap(find.text('Connect Shopify'));
    await tester.pump();

    await tester.scrollUntilVisible(find.text('Initialize Catalog Setup'), 200);
    await tester.tap(find.text('Initialize Catalog Setup'));
    await tester.pump();

    expect(
      find.textContaining('SHOPIFY INTEGRATION NOT IMPLEMENTED'),
      findsOneWidget,
    );
    expect(find.byType(InventoryPage), findsNothing);
  });
}
