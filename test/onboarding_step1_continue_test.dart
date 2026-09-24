// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/core/auth/auth_bootstrap.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';

class _MockOnboardingRepository extends OnboardingRepository {
  OnboardingProgress _state = const OnboardingProgress();
  final bool shouldThrow;
  final Object? exceptionToThrow;
  final Completer<void>? saveCompleter;
  Map<String, dynamic>? lastStep1Data;

  _MockOnboardingRepository({
    this.shouldThrow = false,
    this.exceptionToThrow,
    this.saveCompleter,
  });

  @override
  OnboardingProgress get currentProgress => _state;

  @override
  OnboardingProgress loadProgressSync() => _state;

  @override
  Future<OnboardingProgress> loadProgress() async => _state;

  @override
  Future<void> saveProgress(OnboardingProgress progress) async {
    _state = progress;
  }

  @override
  Future<OnboardingProgress> markStepComplete(
    int step, {
    Map<String, dynamic>? data,
  }) async {
    if (saveCompleter != null) {
      await saveCompleter!.future;
    }
    if (shouldThrow) {
      throw exceptionToThrow ??
          StateError(
            'Cannot create business: Unable to establish authenticated Supabase identity.',
          );
    }
    if (step == 1) {
      lastStep1Data = data;
      _state = _state.copyWith(
        isBusinessCompleted: true,
        businessName: data?['businessName'] as String?,
        businessType: data?['businessType'] as String?,
        countryCode: data?['countryCode'] as String?,
        currencyCode: data?['currencyCode'] as String?,
        locationRange: data?['locationRange'] as String?,
      );
    }
    return _state;
  }
}

void main() {
  setUp(() {
    AuthBootstrapService.resetForTesting();
    CurrentBusinessService.instance.resetForTesting();
  });

  tearDown(() {
    AuthBootstrapService.resetForTesting();
    CurrentBusinessService.instance.resetForTesting();
  });

  testWidgets(
    '1. Step 1 Continue button: Missing fields trigger validation without navigating',
    (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1400, 1000);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final repo = _MockOnboardingRepository();
      await tester.pumpWidget(
        MaterialApp(home: OnboardingPage(repository: repo)),
      );
      await tester.pumpAndSettle();

      final continueBtn = find.widgetWithText(
        ElevatedButton,
        'Continue to Locations',
      );
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('Enter your legal business name.'), findsOneWidget);
      expect(repo.lastStep1Data, isNull);
    },
  );

  testWidgets(
    '2. Step 1 Continue button: Valid form saves business and navigates to Step 2',
    (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1400, 1000);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final repo = _MockOnboardingRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            repository: repo,
            initialSelectedCountry: 'AU',
            initialSelectedCurrency: 'AUD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill business name
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Atelier Lumiere');
      await tester.pumpAndSettle();

      // Select business type: Couture & Bespoke Studio
      final typeDropdown = find.text('Select business type');
      await tester.tap(typeDropdown, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Couture & Bespoke Studio').last);
      await tester.pumpAndSettle();

      // Select operational locations: '1'
      final locationOption1 = find.widgetWithText(InkWell, '1').first;
      await tester.tap(locationOption1);
      await tester.pumpAndSettle();

      // Click Continue to Locations
      final continueBtn = find.widgetWithText(
        ElevatedButton,
        'Continue to Locations',
      );
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Verify repository received sanitized mapped values
      expect(repo.lastStep1Data, isNotNull);
      expect(repo.lastStep1Data!['businessName'], 'Atelier Lumiere');
      expect(repo.lastStep1Data!['businessType'], 'Couture & Bespoke Studio');
      expect(repo.lastStep1Data!['countryCode'], 'AU');
      expect(repo.lastStep1Data!['currencyCode'], 'AUD');
      expect(repo.lastStep1Data!['locationRange'], '1');

      // Step 2 Locations should now be displayed
      expect(find.text('STEP 2 OF 5 — NODES'), findsOneWidget);
    },
  );

  testWidgets(
    '3. Step 1 Continue button: Loading state disables button and displays progress',
    (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1400, 1000);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final saveCompleter = Completer<void>();
      final repo = _MockOnboardingRepository(saveCompleter: saveCompleter);

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            repository: repo,
            initialSelectedCountry: 'AU',
            initialSelectedCurrency: 'AUD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Test Boutique');
      await tester.pumpAndSettle();

      final typeDropdown = find.text('Select business type');
      await tester.tap(typeDropdown, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Couture & Bespoke Studio').last);
      await tester.pumpAndSettle();

      // Tap '1' for locations
      await tester.tap(find.widgetWithText(InkWell, '1').first);
      await tester.pumpAndSettle();

      // Tap Continue
      final continueBtn = find.widgetWithText(
        ElevatedButton,
        'Continue to Locations',
      );
      await tester.tap(continueBtn);
      await tester.pump(); // Pump without settling to catch loading state

      // Button should now show "Saving Business..." and a CircularProgressIndicator
      expect(find.text('Saving Business...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete saving
      saveCompleter.complete();
      await tester.pumpAndSettle();

      // Should have advanced to Step 2
      expect(find.text('STEP 2 OF 5 — NODES'), findsOneWidget);
    },
  );

  testWidgets(
    '4. Step 1 Continue button: Failure displays error banner, re-enables button, preserves values',
    (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1400, 1000);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);

      final repo = _MockOnboardingRepository(
        shouldThrow: true,
        exceptionToThrow: StateError(
          'Cannot create business: Anonymous Sign-Ins are disabled in Supabase. '
          'Enable Anonymous Sign-Ins in Supabase Dashboard → Authentication → Providers.',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingPage(
            repository: repo,
            initialSelectedCountry: 'AU',
            initialSelectedCurrency: 'AUD',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'Preserved Studio');
      await tester.pumpAndSettle();

      final typeDropdown = find.text('Select business type');
      await tester.tap(typeDropdown, warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Couture & Bespoke Studio').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(InkWell, '1').first);
      await tester.pumpAndSettle();

      final continueBtn = find.widgetWithText(
        ElevatedButton,
        'Continue to Locations',
      );
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Should NOT advance to Step 2
      expect(find.text('STEP 2 OF 5 — NODES'), findsNothing);

      // Should display concise, actionable error banner
      expect(
        find.textContaining(
          'Anonymous Sign-Ins are disabled in your Supabase project',
        ),
        findsOneWidget,
      );

      // Button should be re-enabled
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Continue to Locations'),
      );
      expect(button.onPressed, isNotNull);

      // Form value should be preserved
      expect(find.text('Preserved Studio'), findsOneWidget);
    },
  );

  test(
    '5. CurrentBusinessService normalizeLocationRange accepts exact values',
    () {
      expect(CurrentBusinessService.normalizeLocationRange('1'), '1');
      expect(CurrentBusinessService.normalizeLocationRange('2-5'), '2-5');
      expect(CurrentBusinessService.normalizeLocationRange('2 - 5'), '2-5');
      expect(CurrentBusinessService.normalizeLocationRange('6-20'), '6-20');
      expect(CurrentBusinessService.normalizeLocationRange('6 - 20'), '6-20');
      expect(CurrentBusinessService.normalizeLocationRange('20+'), '20+');
      expect(CurrentBusinessService.normalizeLocationRange('invalid'), '1');
      expect(CurrentBusinessService.normalizeLocationRange(null), '1');
    },
  );
}
