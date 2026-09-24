// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadstock/core/auth/auth_service.dart';
import 'package:threadstock/features/inventory/presentation/widgets/upload_file_view.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/main.dart';

void main() {
  setUp(() {
    OnboardingRepository.instance.reset();
    AuthService.instance.setAuthenticatedForTesting(
      user: const User(
        id: 'widget-test-user',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-09-24T00:00:00Z',
      ),
    );
  });

  tearDown(() {
    AuthService.instance.setUnauthenticatedForTesting();
    OnboardingRepository.instance.reset();
  });

  testWidgets('ThreadStock app boots with onboarding shell', (tester) async {
    await tester.pumpWidget(
      const ThreadStockApp(initialRoute: '/onboarding/welcome'),
    );

    expect(find.text('Welcome to ThreadStock'), findsOneWidget);
    expect(find.textContaining('ThreadStock'), findsWidgets);
  });

  testWidgets('UploadFileView shows a back control and calls the callback', (
    tester,
  ) async {
    var wasBackPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: UploadFileView(onBack: () => wasBackPressed = true),
        ),
      ),
    );

    expect(find.text('Back'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pump();

    expect(wasBackPressed, isTrue);
  });
}
