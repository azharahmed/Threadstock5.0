import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/inventory/data/category_repository.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/data/product_media_repository.dart';
import 'package:threadstock/features/inventory/domain/models/product_image_item.dart';
import 'package:threadstock/features/inventory/presentation/widgets/create_new_product_view.dart';

class MockProductMediaRepository extends ProductMediaRepository {
  List<ProductImageItem> mockPickedFiles = [];

  @override
  Future<List<ProductImageItem>> pickImages({bool allowMultiple = true}) async {
    return mockPickedFiles;
  }
}

void main() {
  setUp(() {
    CategoryRepository.clearLocalState();
    ProductMediaRepository.clearLocalState();
    LocationRepository.clearLocalState();
  });

  tearDown(() {
    LocationRepository.clearLocalState();
  });

  Future<void> pumpDesktop(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: home));
    await tester.pumpAndSettle();
  }

  Finder findRichText(String text) => find.byWidgetPredicate(
    (w) => w is RichText && w.text.toPlainText().contains(text),
  );

  group('Product Imagery Tests', () {
    testWidgets(
      'Initial state starts with 0 images and shows Upload from computer CTA',
      (tester) async {
        await pumpDesktop(tester, const Scaffold(body: CreateNewProductView()));

        expect(find.text('No images yet'), findsOneWidget);
        expect(find.text('PNG, JPG or WEBP up to 10MB'), findsOneWidget);
        expect(find.text('Upload from computer'), findsOneWidget);
        expect(find.text('Primary'), findsNothing);
      },
    );

    testWidgets(
      'Adding images renders preview and thumbnail, auto-marking first as Primary',
      (tester) async {
        final mockRepo = MockProductMediaRepository();
        // Dummy 1x1 png bytes
        final dummyBytes = Uint8List.fromList([
          0x89,
          0x50,
          0x4E,
          0x47,
          0x0D,
          0x0A,
          0x1A,
          0x0A,
          0x00,
          0x00,
          0x00,
          0x0D,
          0x49,
          0x48,
          0x44,
          0x52,
          0x00,
          0x00,
          0x00,
          0x01,
          0x00,
          0x00,
          0x00,
          0x01,
          0x08,
          0x06,
          0x00,
          0x00,
          0x00,
          0x1F,
          0x15,
          0xC4,
          0x89,
          0x00,
          0x00,
          0x00,
          0x0A,
          0x49,
          0x44,
          0x41,
          0x54,
          0x78,
          0x9C,
          0x63,
          0x00,
          0x01,
          0x00,
          0x00,
          0x05,
          0x00,
          0x01,
          0x0D,
          0x0A,
          0x2D,
          0xB4,
          0x00,
          0x00,
          0x00,
          0x00,
          0x49,
          0x45,
          0x4E,
          0x44,
          0xAE,
          0x42,
          0x60,
          0x82,
        ]);

        mockRepo.mockPickedFiles = [
          ProductImageItem(
            id: 'test_1',
            name: 'suit_front.png',
            size: 1024,
            bytes: dummyBytes,
            createdAt: DateTime.now(),
          ),
        ];

        await pumpDesktop(
          tester,
          Scaffold(body: CreateNewProductView(mediaRepository: mockRepo)),
        );

        // Tap Upload from computer
        await tester.tap(find.text('Upload from computer'));
        await tester.pumpAndSettle();

        // Image preview exists and is primary
        expect(find.text('No images yet'), findsNothing);
        expect(find.text('Primary'), findsOneWidget);
        expect(find.text('Replace Image'), findsOneWidget);
      },
    );

    testWidgets('Removing image clears preview and resets state', (
      tester,
    ) async {
      final mockRepo = MockProductMediaRepository();
      final dummyBytes = Uint8List.fromList([
        0x89,
        0x50,
        0x4E,
        0x47,
        0x0D,
        0x0A,
        0x1A,
        0x0A,
        0x00,
        0x00,
        0x00,
        0x0D,
        0x49,
        0x48,
        0x44,
        0x52,
        0x00,
        0x00,
        0x00,
        0x01,
        0x00,
        0x00,
        0x00,
        0x01,
        0x08,
        0x06,
        0x00,
        0x00,
        0x00,
        0x1F,
        0x15,
        0xC4,
        0x89,
        0x00,
        0x00,
        0x00,
        0x0A,
        0x49,
        0x44,
        0x41,
        0x54,
        0x78,
        0x9C,
        0x63,
        0x00,
        0x01,
        0x00,
        0x00,
        0x05,
        0x00,
        0x01,
        0x0D,
        0x0A,
        0x2D,
        0xB4,
        0x00,
        0x00,
        0x00,
        0x00,
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);

      mockRepo.mockPickedFiles = [
        ProductImageItem(
          id: 'test_del',
          name: 'tuxedo.jpg',
          size: 2048,
          bytes: dummyBytes,
          createdAt: DateTime.now(),
        ),
      ];

      await pumpDesktop(
        tester,
        Scaffold(body: CreateNewProductView(mediaRepository: mockRepo)),
      );

      await tester.tap(find.text('Upload from computer'));
      await tester.pumpAndSettle();
      expect(find.text('Primary'), findsOneWidget);

      // Tap remove icon
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('No images yet'), findsOneWidget);
    });
  });

  group('Pricing Semantics & Gross Margin Tests', () {
    testWidgets(
      'Initial untouched state displays — for Gross Margin (not fake 0.0%)',
      (tester) async {
        await pumpDesktop(tester, const Scaffold(body: CreateNewProductView()));

        expect(findRichText('Unit Cost (INR)'), findsOneWidget);
        expect(findRichText('Selling Price (INR)'), findsOneWidget);
        expect(find.text('—'), findsOneWidget);
        expect(find.text('0.0%'), findsNothing);
      },
    );

    testWidgets(
      'Entering Cost 800 and Price 1500 displays 46.67% Gross Margin',
      (tester) async {
        await pumpDesktop(tester, const Scaffold(body: CreateNewProductView()));

        // Find Unit Cost and Selling Price fields
        final costField = find.widgetWithText(TextField, '0.00').first;
        final priceField = find.widgetWithText(TextField, '0.00').last;

        await tester.enterText(costField, '800');
        await tester.pumpAndSettle();
        // Still '—' because selling price is not entered yet
        expect(find.text('—'), findsOneWidget);

        await tester.enterText(priceField, '1500');
        await tester.pumpAndSettle();

        expect(find.text('46.67%'), findsOneWidget);
      },
    );

    testWidgets('Selling price below cost handles negative margin correctly', (
      tester,
    ) async {
      await pumpDesktop(tester, const Scaffold(body: CreateNewProductView()));

      final costField = find.widgetWithText(TextField, '0.00').first;
      final priceField = find.widgetWithText(TextField, '0.00').last;

      await tester.enterText(costField, '1000');
      await tester.enterText(priceField, '800');
      await tester.pumpAndSettle();

      // (800 - 1000) / 800 * 100 = -25.00%
      expect(find.text('-25.00%'), findsOneWidget);
    });

    testWidgets('Zero or negative selling price returns —', (tester) async {
      await pumpDesktop(tester, const Scaffold(body: CreateNewProductView()));

      final costField = find.widgetWithText(TextField, '0.00').first;
      final priceField = find.widgetWithText(TextField, '0.00').last;

      await tester.enterText(costField, '800');
      await tester.enterText(priceField, '0');
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
    });
  });

  group('System SKU & Barcode Tests', () {
    testWidgets(
      'System SKU shows Auto-generated SKU placeholder and supports manual entry',
      (tester) async {
        await pumpDesktop(tester, const Scaffold(body: CreateNewProductView()));

        expect(findRichText('System SKU Identifier'), findsOneWidget);
        expect(find.text('Auto-generated SKU'), findsOneWidget);

        // User types manual SKU
        final skuField = find.widgetWithText(TextField, 'Auto-generated SKU');
        await tester.enterText(skuField, 'MWB-20188-L');
        await tester.pumpAndSettle();

        expect(find.text('MWB-20188-L'), findsOneWidget);
      },
    );

    testWidgets('Auto-generate button populates valid SKU identifier', (
      tester,
    ) async {
      await pumpDesktop(tester, const Scaffold(body: CreateNewProductView()));

      // Enter product title
      await tester.enterText(
        find.widgetWithText(TextField, 'Enter product title'),
        'Loro Piana Blazer',
      );
      await tester.pumpAndSettle();

      // Click Auto-generate button
      expect(find.text('Auto-generate'), findsOneWidget);
      await tester.tap(find.text('Auto-generate'));
      await tester.pumpAndSettle();

      // SKU field should contain TS-LP-XXXXX
      expect(find.textContaining('TS-LP-'), findsOneWidget);
    });

    testWidgets('Barcode input supports manual entry', (tester) async {
      await pumpDesktop(tester, const Scaffold(body: CreateNewProductView()));

      expect(findRichText('Barcode (UPC/EAN)'), findsOneWidget);
      expect(find.text('Scan or type barcode'), findsOneWidget);

      final barcodeField = find.widgetWithText(
        TextField,
        'Scan or type barcode',
      );
      await tester.enterText(barcodeField, '8901234567890');
      await tester.pumpAndSettle();

      expect(find.text('8901234567890'), findsOneWidget);
    });
  });

  group('Track Stock Levels Tests', () {
    testWidgets(
      'Track Stock Levels defaults to false and does not fabricate stock',
      (tester) async {
        await pumpDesktop(tester, const Scaffold(body: CreateNewProductView()));

        expect(find.text('Track Stock Levels'), findsOneWidget);
        final switchFinder = find.byType(Switch);
        expect(switchFinder, findsOneWidget);

        final switchWidget = tester.widget<Switch>(switchFinder);
        expect(switchWidget.value, isFalse);

        // Stock configuration fields should be hidden
        expect(findRichText('Stock Location'), findsNothing);
        expect(findRichText('Opening Stock'), findsNothing);
        expect(findRichText('Low-Stock Threshold'), findsNothing);
      },
    );

    testWidgets(
      'Enabling Track Stock Levels exposes location and stock threshold fields',
      (tester) async {
        await pumpDesktop(tester, const Scaffold(body: CreateNewProductView()));

        // Toggle switch to ON
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, isTrue);

        // Stock configuration fields are now visible
        expect(findRichText('Stock Location'), findsOneWidget);
        expect(find.text('No locations available'), findsOneWidget);
        expect(findRichText('Opening Stock'), findsOneWidget);
        expect(findRichText('Low-Stock Threshold'), findsOneWidget);
      },
    );
  });
}
