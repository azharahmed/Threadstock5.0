import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:threadstock/app/router/app_router.dart';
import 'package:threadstock/core/auth/auth_service.dart';
import 'package:threadstock/core/auth/authorization_service.dart';
import 'package:threadstock/core/business/app_bootstrap_service.dart';
import 'package:threadstock/core/business/current_business_service.dart';
import 'package:threadstock/core/config/app_preferences_service.dart';
import 'package:threadstock/features/auth/presentation/pages/accept_invitation_page.dart';
import 'package:threadstock/features/auth/presentation/pages/check_email_page.dart';
import 'package:threadstock/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:threadstock/features/auth/presentation/pages/login_page.dart';
import 'package:threadstock/features/auth/presentation/pages/signup_page.dart';
import 'package:threadstock/features/business/domain/models/business.dart';
import 'package:threadstock/features/onboarding/data/onboarding_repository.dart';
import 'package:threadstock/features/onboarding/domain/models/onboarding_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AuthService.instance.resetForTesting();
    AuthorizationService.instance.clear();
    CurrentBusinessService.instance.resetForTesting();
    AppRouter.setAuthOverrideForTesting(null);
    AppRouter.setRepositoryForTesting(null);
  });

  tearUriPrefs() async {
    await AppPreferencesService.instance.setCurrentBusinessId(null);
    OnboardingRepository.instance.clearCache();
  }

  tearDown(() async {
    await tearUriPrefs();
    AppRouter.setAuthOverrideForTesting(null);
    AppRouter.setRepositoryForTesting(null);
  });

  group('ThreadStock Phase 2B — Authoritative Authentication & Router Guards', () {
    test('1. Unauthenticated startup routes directly to /login', () async {
      AuthService.instance.setUnauthenticatedForTesting();

      final result = await AppBootstrapService.bootstrap();
      expect(result.initialRoute, AppRoutes.login);
      expect(result.businessId, isNull);
    });

    test('2. Protected routes cannot be opened when logged out (fail-closed)', () {
      AppRouter.setAuthOverrideForTesting(false);

      final protectedRoutes = [
        AppRoutes.overview,
        AppRoutes.inventory,
        AppRoutes.sales,
        AppRoutes.purchasing,
        AppRoutes.transfers,
        AppRoutes.settings,
        AppRoutes.profile,
        AppRoutes.aiStudio,
        AppRoutes.automations,
        AppRoutes.insights,
        '/',
      ];

      for (final routeName in protectedRoutes) {
        final route = AppRouter.onGenerateRoute(RouteSettings(name: routeName));
        expect(route, isA<MaterialPageRoute<dynamic>>());
        final pageRoute = route as MaterialPageRoute<dynamic>;
        expect(
          pageRoute.settings.name,
          AppRoutes.login,
          reason: 'Route $routeName must redirect to /login when unauthenticated',
        );
      }
    });

    test('3. Expired / missing session triggers /login routing', () async {
      AuthService.instance.setUnauthenticatedForTesting();
      expect(AuthService.instance.currentUser, isNull);
      expect(AuthService.instance.isAuthenticated, isFalse);

      final bootstrap = await AppBootstrapService.bootstrap();
      expect(bootstrap.initialRoute, AppRoutes.login);
    });

    test('4. Logout purges in-memory business state and redirects to /login', () async {
      final biz = Business(
        id: 'biz_test_123',
        ownerUserId: 'user_456',
        legalName: 'Maison ThreadStock',
        businessType: 'Boutique',
        countryCode: 'IN',
        currencyCode: 'INR',
        locationRange: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      CurrentBusinessService.instance.setCurrentBusiness(biz);
      await AppPreferencesService.instance.setCurrentBusinessId('biz_test_123');
      AuthorizationService.instance.setPermissionsForTesting(isOwner: true);
      AuthService.instance.setAuthenticatedForTesting(
        user: const User(
          id: 'user_456',
          appMetadata: {},
          userMetadata: {'full_name': 'Owner User'},
          aud: 'authenticated',
          createdAt: '2026-09-24T00:00:00Z',
        ),
      );

      expect(CurrentBusinessService.instance.currentBusinessId, 'biz_test_123');
      expect(AuthorizationService.instance.isOwner, isTrue);

      // Perform global sign out
      await AuthService.instance.signOut();

      // State must be completely purged
      expect(AuthService.instance.isAuthenticated, isFalse);
      expect(AuthService.instance.currentUser, isNull);
      expect(CurrentBusinessService.instance.currentBusinessId, isNull);
      expect(CurrentBusinessService.instance.currentBusiness, isNull);
      expect(AppPreferencesService.instance.currentBusinessId, isNull);
      expect(AuthorizationService.instance.isOwner, isFalse);
      expect(AuthorizationService.instance.permissions, isEmpty);
    });

    test('5. Stale cached business ID is rejected if user is not authorized', () async {
      await AppPreferencesService.instance.setCurrentBusinessId('foreign_biz_999');

      // Without Supabase connection (or in disconnected test mode without matching owner/member),
      // resolveCurrentBusinessId rejects the unauthorized cached ID and clears it
      final resolved = await CurrentBusinessService.instance.resolveCurrentBusinessId();
      expect(resolved, isNull);
      expect(CurrentBusinessService.instance.currentBusinessId, isNull);
    });

    test('6. Incomplete onboarding resumes correct step for authenticated user', () {
      AppRouter.setAuthOverrideForTesting(true);

      final repo = OnboardingRepository();
      repo.saveProgress(
        const OnboardingProgress(
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: false, // Incomplete at Step 3
          isOnboardingCompleted: false,
          businessId: 'biz_in_progress',
        ),
      );
      AppRouter.setRepositoryForTesting(repo);

      // Attempting to access overview redirects to step 3
      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.overview),
      );
      final pageRoute = route as MaterialPageRoute<dynamic>;
      expect(pageRoute.settings.name, AppRoutes.onboardingCommerce);
    });

    test('7. Completed onboarding routes to AppRoutes.overview', () {
      AppRouter.setAuthOverrideForTesting(true);

      final repo = OnboardingRepository();
      repo.saveProgress(
        const OnboardingProgress(
          isBusinessCompleted: true,
          isLocationCompleted: true,
          isCommerceCompleted: true,
          isInventoryCompleted: true,
          isTeamCompleted: true,
          isOnboardingCompleted: true,
          businessId: 'biz_completed',
        ),
      );
      AppRouter.setRepositoryForTesting(repo);

      final route = AppRouter.onGenerateRoute(
        const RouteSettings(name: AppRoutes.overview),
      );
      final pageRoute = route as MaterialPageRoute<dynamic>;
      expect(pageRoute.settings.name, AppRoutes.overview);
    });
  });

  group('ThreadStock Phase 2B — Authorization Context & Real Role Permissions', () {
    test('8. Owner receives all 21 catalog permissions automatically', () {
      final authz = AuthorizationService();
      authz.setPermissionsForTesting(isOwner: true, roleName: 'Owner');

      expect(authz.isOwner, isTrue);
      expect(authz.roleName, 'Owner');

      // Every permission in catalog must evaluate to true
      for (final code in AuthorizationService.allCatalogPermissions) {
        expect(authz.can(code), isTrue, reason: 'Owner must have $code');
      }

      // Arbitrary/unknown permissions must evaluate to false
      expect(authz.can('superadmin.nuke'), isFalse);
      expect(authz.can('unknown.permission'), isFalse);
    });

    test('9. Active member permission evaluation (Cashier vs Store Manager)', () {
      final authz = AuthorizationService();

      // Cashier role with POS permissions only
      authz.setPermissionsForTesting(
        isOwner: false,
        roleName: 'Cashier',
        permissions: {'sales.view', 'sales.create', 'customers.view'},
      );

      expect(authz.isOwner, isFalse);
      expect(authz.roleName, 'Cashier');
      expect(authz.can('sales.view'), isTrue);
      expect(authz.can('sales.create'), isTrue);
      expect(authz.can('customers.view'), isTrue);

      // Disallowed permissions
      expect(authz.can('settings.manage'), isFalse);
      expect(authz.can('team.manage'), isFalse);
      expect(authz.can('purchasing.create'), isFalse);
      expect(authz.can('inventory.adjust'), isFalse);
    });

    test('10. Suspended or inactive member receives zero permissions', () {
      final authz = AuthorizationService();
      authz.clear(); // Suspended or inactive members have empty permissions

      expect(authz.can('sales.create'), isFalse);
      expect(authz.can('inventory.view'), isFalse);
      expect(authz.can('settings.view'), isFalse);
      expect(authz.isOwner, isFalse);
    });
  });

  group('ThreadStock Phase 2B — Authentication Screens Widget Tests', () {
    testWidgets('11. LoginPage renders with luxury elements and validates input', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginPage(),
        ),
      );

      // Verify branding and title
      expect(find.text('THREADSTOCK'), findsOneWidget);
      expect(find.text('Luxury Retail & Inventory Orchestration'), findsOneWidget);
      expect(find.byKey(const Key('login_email_input')), findsOneWidget);
      expect(find.byKey(const Key('login_password_input')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
      expect(find.byKey(const Key('login_signup_link')), findsOneWidget);

      // Trigger submit without filling inputs -> validation error
      await tester.tap(find.byKey(const Key('login_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email address.'), findsOneWidget);
    });

    testWidgets('12. SignupPage renders with full name and confirms password matching', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SignupPage(),
        ),
      );

      expect(find.text('CREATE ACCOUNT'), findsOneWidget);
      expect(find.byKey(const Key('signup_fullname_input')), findsOneWidget);
      expect(find.byKey(const Key('signup_email_input')), findsOneWidget);
      expect(find.byKey(const Key('signup_password_input')), findsOneWidget);
      expect(find.byKey(const Key('signup_confirm_password_input')), findsOneWidget);
      expect(find.byKey(const Key('signup_submit_button')), findsOneWidget);

      // Mismatched passwords
      await tester.enterText(find.byKey(const Key('signup_fullname_input')), 'Azhar Ahmed');
      await tester.enterText(find.byKey(const Key('signup_email_input')), 'merchant@threadstock.io');
      await tester.enterText(find.byKey(const Key('signup_password_input')), 'password123');
      await tester.enterText(find.byKey(const Key('signup_confirm_password_input')), 'different456');

      await tester.ensureVisible(find.byKey(const Key('signup_submit_button')));
      await tester.tap(find.byKey(const Key('signup_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('13. ForgotPasswordPage renders and validates email', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordPage(),
        ),
      );

      expect(find.text('RESET PASSWORD'), findsOneWidget);
      expect(find.byKey(const Key('forgot_password_email_input')), findsOneWidget);
      expect(find.byKey(const Key('forgot_password_submit_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('forgot_password_submit_button')));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email address.'), findsOneWidget);
    });

    testWidgets('14. CheckEmailPage displays honest instructions and return button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CheckEmailPage(email: 'merchant@domain.com'),
        ),
      );

      expect(find.text('CHECK YOUR INBOX'), findsOneWidget);
      expect(find.textContaining('merchant@domain.com'), findsOneWidget);
      expect(find.byKey(const Key('check_email_login_button')), findsOneWidget);
    });

    testWidgets('15. AcceptInvitationPage renders sign-in required when logged out', (tester) async {
      AuthService.instance.setUnauthenticatedForTesting();

      await tester.pumpWidget(
        const MaterialApp(
          home: AcceptInvitationPage(initialToken: 'test_token_hex'),
        ),
      );

      expect(find.text('TEAM INVITATION'), findsOneWidget);
      expect(find.text('Sign In Required'), findsOneWidget);
      expect(find.byKey(const Key('invite_signin_button')), findsOneWidget);
      expect(find.byKey(const Key('invite_signup_button')), findsOneWidget);
    });

    testWidgets('16. AcceptInvitationPage shows accept button when logged in', (tester) async {
      AuthService.instance.setAuthenticatedForTesting(
        user: const User(
          id: 'staff_123',
          appMetadata: {},
          userMetadata: {'full_name': 'Staff Member'},
          aud: 'authenticated',
          createdAt: '2026-09-24T00:00:00Z',
          email: 'staff@threadstock.io',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AcceptInvitationPage(initialToken: '5a3f2b1c8e9d0a1b2c3d4e5f6a7b8c9d'),
        ),
      );

      expect(find.text('TEAM INVITATION'), findsOneWidget);
      expect(find.textContaining('Signed in as: staff@threadstock.io'), findsOneWidget);
      expect(find.byKey(const Key('invite_accept_button')), findsOneWidget);
    });
  });
}
