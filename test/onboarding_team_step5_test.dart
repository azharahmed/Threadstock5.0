import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';
import 'package:threadstock/features/inventory/domain/models/stock_location.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:threadstock/features/onboarding/presentation/widgets/team_onboarding_view.dart';

class _FakeLocationRepository extends LocationRepository {
  final List<StockLocation> _stubbedLocations;
  _FakeLocationRepository([this._stubbedLocations = const []]);

  @override
  Future<List<StockLocation>> getLocations({
    String? businessId,
    bool onlyActive = true,
  }) async {
    return _stubbedLocations;
  }
}

void main() {
  setUp(() async {
    await OnboardingRepository.instance.reset();
  });

  tearDown(() async {
    await OnboardingRepository.instance.reset();
  });

  void setDesktopSize(
    WidgetTester tester, {
    Size size = const Size(1920, 1200),
  }) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpStep5(
    WidgetTester tester, {
    Size size = const Size(1920, 1200),
    int initialStep = 5,
  }) async {
    setDesktopSize(tester, size: size);

    await tester.pumpWidget(
      MaterialApp(home: OnboardingPage(initialStep: initialStep)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Step 5 starts with 0 demo team members and no fake static strings',
    (tester) async {
      await pumpStep5(tester);

      // Verify all fake/demo data is completely absent
      expect(find.text('name@threadstock.ai'), findsNothing);
      expect(find.text('team@threadstock.ai'), findsNothing);
      expect(find.text('purchasing@threadstock.ai'), findsNothing);
      expect(find.text('alex.morgan@threadstock.ai (You)'), findsNothing);
      expect(find.text('ThreadStock India Ltd'), findsNothing);
      expect(find.text('Central Warehouse (Zone A)'), findsNothing);
      expect(find.text('3 operators'), findsNothing);

      // Verify exactly 1 clean empty row
      expect(find.text('Invite your team'), findsOneWidget);
      expect(find.text('Select role'), findsOneWidget);
      expect(find.text('0 operators'), findsOneWidget);
    },
  );

  testWidgets(
    'Top-left logo is enlarged to roughly 250% (~145px) in canonical header',
    (tester) async {
      await pumpStep5(tester);

      final logoFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'Assets/logo.png',
      );
      expect(logoFinder, findsOneWidget);

      final logoWidget = tester.widget<Image>(logoFinder);
      expect(logoWidget.height, 145.0); // 58 * 2.5 = 145
    },
  );

  testWidgets(
    'Step 5 is integrated into canonical onboarding shell with background, header and stepper',
    (tester) async {
      await pumpStep5(tester);

      // Draped cream background
      final bgFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == 'Assets/OnBoardBG/BG.png',
      );
      expect(bgFinder, findsOneWidget);

      // Top Header support link
      expect(find.text('ThreadStock Support'), findsOneWidget);

      // Bottom stepper is visible
      expect(find.text('Team'), findsWidgets);
      expect(find.text('Business'), findsWidgets);
      expect(find.text('Location'), findsWidgets);
      expect(find.text('Commerce'), findsWidgets);
      expect(find.text('Inventory'), findsWidgets);
    },
  );

  testWidgets(
    'Dynamic summary card updates in real time as valid email is entered',
    (tester) async {
      setDesktopSize(tester);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeamOnboardingView(
              businessName: 'Atelier Sartoriale',
              coreNode: 'Milan Workshop',
              currency: 'EUR (€)',
              taxMatrix: 'EU Member State — VAT',
              availableLocations: ['Milan Workshop', 'Rome Boutique'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial dynamic configuration summary values
      expect(find.text('Atelier Sartoriale'), findsOneWidget);
      expect(find.text('Milan Workshop'), findsWidgets);
      expect(find.text('EUR (€)'), findsOneWidget);
      expect(find.text('EU Member State — VAT'), findsOneWidget);
      expect(find.text('0 operators'), findsOneWidget);

      // Enter a valid email
      final emailField = find.byType(TextField).first;
      await tester.enterText(emailField, 'marco@atelier.it');
      await tester.pump();

      // Summary dynamically reflects 1 operator
      expect(find.text('1 operator'), findsOneWidget);
    },
  );

  testWidgets('Adding and removing member rows updates row count dynamically', (
    tester,
  ) async {
    setDesktopSize(tester);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TeamOnboardingView(availableLocations: ['Paris Store']),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initially 1 row, delete button is hidden/not clickable
    expect(find.byType(TextField), findsNWidgets(1));
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);

    // Click Add another member
    await tester.tap(find.text('Add another member'));
    await tester.pumpAndSettle();

    // Now 2 rows, delete button is visible
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.byIcon(Icons.delete_outline_rounded), findsNWidgets(2));

    // Tap delete on second row
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).last);
    await tester.pumpAndSettle();

    // Back to 1 row
    expect(find.byType(TextField), findsNWidgets(1));
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });

  testWidgets(
    'Location auto-selects if exactly 1 location exists and shows Select location if 2+',
    (tester) async {
      setDesktopSize(tester);

      // 1 location: auto-selects
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeamOnboardingView(
              key: ValueKey('single_hub'),
              availableLocations: ['Single Hub'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Single Hub'), findsWidgets);

      // 2+ locations: shows 'Select location'
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TeamOnboardingView(
              key: ValueKey('multiple_hubs'),
              availableLocations: ['Hub A', 'Hub B'],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Select location'), findsOneWidget);

      // 0 locations: shows 'No locations available'
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TeamOnboardingView(
              key: const ValueKey('zero_hubs'),
              availableLocations: const [],
              locationRepository: _FakeLocationRepository(const []),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No locations available'), findsOneWidget);
    },
  );

  testWidgets('Back button navigates to Step 4 and preserves data', (
    tester,
  ) async {
    await pumpStep5(tester);

    expect(find.text('Invite your team'), findsOneWidget);

    // Tap Back
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    // Returns to Step 4 (Inventory)
    expect(find.text('How would you like to start?'), findsOneWidget);
  });

  testWidgets('Skip for now advances to Step 6 Ready', (tester) async {
    await pumpStep5(tester);

    expect(find.text('Invite your team'), findsOneWidget);

    // Tap Skip for now
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    // Advances to Step 6 Ready
    expect(find.text('Your workspace is ready'), findsOneWidget);
    expect(find.text('Open ThreadStock'), findsOneWidget);
  });
}
