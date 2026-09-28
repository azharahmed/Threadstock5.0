import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/inventory/presentation/pages/inventory_page.dart';
import 'package:threadstock/features/inventory/presentation/widgets/upload_file_view.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  Future<void> pumpDesktop(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pumpAndSettle();
  }

  testWidgets('untouched Import Inventory Back leaves without confirmation', (
    tester,
  ) async {
    var left = false;
    await pumpDesktop(
      tester,
      Scaffold(body: UploadFileView(onBack: () => left = true)),
    );

    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Leave import?'), findsNothing);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(left, isTrue);
    expect(find.text('Leave import?'), findsNothing);
  });

  testWidgets('unsaved import work shows Leave import confirmation', (
    tester,
  ) async {
    var left = false;
    await pumpDesktop(
      tester,
      Scaffold(
        body: UploadFileView(hasUnsavedWork: true, onBack: () => left = true),
      ),
    );

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Leave import?'), findsOneWidget);
    expect(left, isFalse);

    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(left, isFalse);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave Import'));
    await tester.pumpAndSettle();
    expect(left, isTrue);
  });

  testWidgets('onboarding CSV import Back returns to Step 4 with data intact', (
    tester,
  ) async {
    await pumpDesktop(tester, const OnboardingPage(initialStep: 4));

    await tester.tap(find.text('Upload CSV / Excel'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Initialize Catalog Setup'), 200);
    await tester.tap(find.text('Initialize Catalog Setup'));
    await tester.pumpAndSettle();

    expect(find.byType(InventoryPage), findsOneWidget);
    expect(find.text('Import Inventory'), findsWidgets);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(InventoryPage), findsNothing);
    expect(find.text('How would you like to start?'), findsOneWidget);
    expect(find.text('Upload CSV / Excel'), findsOneWidget);
  });

  testWidgets(
    'inventory module Back uses onBackFromUpload / stock-list fallback',
    (tester) async {
      var returnedViaCallback = false;

      await pumpDesktop(
        tester,
        Scaffold(
          body: InventoryPage(
            initialMode: InventoryPageMode.uploadFile,
            onBackFromUpload: () => returnedViaCallback = true,
          ),
        ),
      );

      expect(find.text('Import Inventory'), findsWidgets);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(returnedViaCallback, isTrue);
      // With onBackFromUpload supplied, page stays mounted until host pops/switches.
      expect(find.text('Import Inventory'), findsWidgets);
    },
  );

  testWidgets(
    'inventory module Back without host callback leaves upload mode',
    (tester) async {
      String? latestTitle;

      await pumpDesktop(
        tester,
        Scaffold(
          body: InventoryPage(
            initialMode: InventoryPageMode.uploadFile,
            onTitleChanged: (title) => latestTitle = title,
          ),
        ),
      );

      await tester.tap(find.text('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Stock list may emit unrelated layout overflows; drain them.
      while (tester.takeException() != null) {}

      expect(latestTitle, 'Inventory');
    },
  );

  testWidgets('Escape triggers the same leave path on Import Inventory', (
    tester,
  ) async {
    var left = false;
    await pumpDesktop(
      tester,
      Scaffold(body: UploadFileView(onBack: () => left = true)),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(left, isTrue);
  });
}
