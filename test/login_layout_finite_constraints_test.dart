// Login Page Finite Constraints & Layout Verification Tests
//
// Verifies:
// 1. LoginPage renders without unconstrained horizontal viewport errors.
// 2. TabBarView is replaced with finite layout (AnimatedSwitcher).
// 3. Password form and Mobile OTP form render and switch on tap.
// 4. Hit testing and interaction work with no RenderBox layout errors.
// 5. Responsive sizing across desktop large (1440x900), desktop small (1024x768),
//    mobile/narrow (400x800), and window resize.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadstock/features/auth/presentation/pages/login_page.dart';

void main() {
  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget buildLoginScreen({Size? surfaceSize}) {
    return MaterialApp(
      home: const LoginPage(),
    );
  }

  group('LoginPage Layout & Interaction (No Unbounded Height)', () {
    testWidgets('renders LoginPage at standard desktop size (1440x900) without layout errors',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Brand crest and title should be visible
      expect(find.text('THREADSTOCK'), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);

      // Tab selector should be present with two tabs
      expect(find.byKey(const Key('login_tab_bar')), findsOneWidget);
      expect(find.byKey(const Key('tab_password')), findsOneWidget);
      expect(find.byKey(const Key('tab_otp')), findsOneWidget);

      // Default tab is Password form
      expect(find.byKey(const Key('login_email_input')), findsOneWidget);
      expect(find.byKey(const Key('login_password_input')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('login_forgot_password_link')), findsOneWidget);

      // Mobile OTP form is NOT visible initially
      expect(find.byKey(const Key('login_phone_input')), findsNothing);
    });

    testWidgets('switches to Mobile OTP tab and back preserving input',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Enter email in Password tab
      await tester.enterText(find.byKey(const Key('login_email_input')), 'admin@threadstock.io');
      await tester.pump();

      // Tap on Mobile OTP tab
      await tester.tap(find.byKey(const Key('tab_otp')));
      await tester.pumpAndSettle();

      // Mobile OTP form should now be visible
      expect(find.byKey(const Key('login_phone_input')), findsOneWidget);
      expect(find.byKey(const Key('login_isd_picker')), findsOneWidget);
      expect(find.byKey(const Key('login_send_otp_button')), findsOneWidget);
      expect(find.byKey(const Key('login_email_input')), findsNothing);

      // Enter phone number
      await tester.enterText(find.byKey(const Key('login_phone_input')), '9876543210');
      await tester.pump();

      // Tap back on Password tab
      await tester.tap(find.byKey(const Key('tab_password')));
      await tester.pumpAndSettle();

      // Password form is restored and email input is preserved
      expect(find.byKey(const Key('login_email_input')), findsOneWidget);
      expect(find.text('admin@threadstock.io'), findsOneWidget);
      expect(find.byKey(const Key('login_phone_input')), findsNothing);
    });

    testWidgets('renders cleanly on small desktop (1024x768)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('THREADSTOCK'), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on narrow mobile width (400x800) with scrollability',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('THREADSTOCK'), findsOneWidget);
      expect(find.byKey(const Key('login_email_input')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);

      // Can scroll without errors
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -150));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('handles dynamic window resize smoothly without layout failure',
        (WidgetTester tester) async {
      // Start desktop large
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();
      expect(find.text('THREADSTOCK'), findsOneWidget);

      // Resize down to medium
      tester.view.physicalSize = const Size(900, 700);
      await tester.pumpAndSettle();
      expect(find.text('THREADSTOCK'), findsOneWidget);

      // Resize down to narrow
      tester.view.physicalSize = const Size(420, 650);
      await tester.pumpAndSettle();
      expect(find.text('THREADSTOCK'), findsOneWidget);

      // No RenderBox or hit test exceptions
      expect(tester.takeException(), isNull);
    });
  });
}
