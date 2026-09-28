import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:threadstock/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  testWidgets(
    'Business step keeps country and currency empty until the user makes a selection',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingPage(initialStep: 1)),
      );

      expect(find.text('Select country'), findsOneWidget);
      expect(find.text('Select currency'), findsOneWidget);
      final countryDropdowns = find.byType(DropdownButtonFormField<String>);
      expect(countryDropdowns, findsAtLeastNWidgets(2));
    },
  );

  testWidgets(
    'Choosing a country auto-populates its standard primary currency',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingPage(initialStep: 1)),
      );

      final countryDropdowns = find.byType(DropdownButtonFormField<String>);
      final countryDropdown = tester.widget<DropdownButtonFormField<String>>(
        countryDropdowns.at(1),
      );
      countryDropdown.onChanged?.call('IN');
      await tester.pumpAndSettle();

      expect(find.text('INR (₹)'), findsOneWidget);
    },
  );

  testWidgets(
    'Manual currency edits are preserved and a suggestion is shown when the country changes',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: OnboardingPage(initialStep: 1)),
      );

      final countryDropdowns = find.byType(DropdownButtonFormField<String>);
      final countryDropdown = tester.widget<DropdownButtonFormField<String>>(
        countryDropdowns.at(1),
      );
      countryDropdown.onChanged?.call('IN');
      await tester.pumpAndSettle();

      final currencyDropdown = tester.widget<DropdownButtonFormField<String>>(
        countryDropdowns.at(2),
      );
      currencyDropdown.onChanged?.call('USD');
      await tester.pumpAndSettle();

      expect(find.text('USD (\$)'), findsOneWidget);

      countryDropdown.onChanged?.call('AU');
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Suggested: AUD (\$) is the standard currency for Australia.',
        ),
        findsOneWidget,
      );
    },
  );
}
