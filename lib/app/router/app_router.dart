import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_service.dart';
import '../../features/ai_studio/presentation/pages/ai_studio_page.dart';
import '../../features/auth/presentation/pages/accept_invitation_page.dart';
import '../../features/auth/presentation/pages/check_email_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/automations/presentation/pages/automations_page.dart';
import '../../features/insights/presentation/pages/insights_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/onboarding/data/onboarding_repository.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/purchasing/presentation/pages/purchasing_page.dart';
import '../../features/sales/presentation/pages/sales_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/transfers/presentation/pages/transfers_page.dart';
import '../shell/app_shell.dart';

class AppRoutes {
  // Public Authentication Routes
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const checkEmail = '/auth/check-email';
  static const acceptInvite = '/invite/accept';

  // Onboarding Routes
  static const onboarding = '/onboarding';
  static const onboardingWelcome = '/onboarding/welcome';
  static const onboardingBusiness = '/onboarding/business';
  static const onboardingLocation = '/onboarding/location';
  static const onboardingCommerce = '/onboarding/commerce';
  static const onboardingInventory = '/onboarding/inventory';
  static const onboardingTeam = '/onboarding/team';
  static const onboardingComplete = '/onboarding/complete';

  // Protected Dashboard & Core Feature Routes
  static const overview = '/overview';
  static const inventory = '/inventory';
  static const sales = '/sales';
  static const purchasing = '/purchasing';
  static const transfers = '/transfers';
  static const aiStudio = '/ai';
  static const automations = '/automations';
  static const insights = '/insights';
  static const settings = '/settings';
  static const profile = '/profile';

  static const List<String> publicRoutes = [
    login,
    signup,
    forgotPassword,
    checkEmail,
    acceptInvite,
  ];
}

class AppRouter {
  static OnboardingRepository? _testRepository;
  static bool? _testAuthOverride;

  @visibleForTesting
  static void setRepositoryForTesting(OnboardingRepository? repo) {
    _testRepository = repo;
  }

  @visibleForTesting
  static void setAuthOverrideForTesting(bool? isAuthed) {
    _testAuthOverride = isAuthed;
  }

  static OnboardingRepository get _activeRepository =>
      _testRepository ?? OnboardingRepository.instance;

  static bool get _isUserAuthenticated {
    if (_testAuthOverride != null) return _testAuthOverride!;
    if (AuthService.instance.isAuthenticated) return true;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      return user != null;
    } catch (_) {
      // If client not initialized and test repo was provided in unit tests, allow
      if (_testRepository != null) return true;
      return false;
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final repository = _activeRepository;
    final progress = repository.currentProgress;
    final isAuthed = _isUserAuthenticated;
    final routeName = settings.name ?? AppRoutes.login;

    // 1. PUBLIC ROUTES
    if (routeName == AppRoutes.login) {
      if (isAuthed) {
        if (progress.isOnboardingCompleted) {
          return MaterialPageRoute(
            settings: const RouteSettings(name: AppRoutes.overview),
            builder: (_) => const AppShell(),
          );
        } else {
          final resumeStep = progress.firstIncompleteStep;
          return MaterialPageRoute(
            settings: RouteSettings(name: _routeForStep(resumeStep)),
            builder: (_) => OnboardingPage(
              initialStep: resumeStep,
              repository: repository,
            ),
          );
        }
      }
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const LoginPage(),
      );
    }

    if (routeName == AppRoutes.signup) {
      if (isAuthed) {
        if (progress.isOnboardingCompleted) {
          return MaterialPageRoute(
            settings: const RouteSettings(name: AppRoutes.overview),
            builder: (_) => const AppShell(),
          );
        } else {
          final resumeStep = progress.firstIncompleteStep;
          return MaterialPageRoute(
            settings: RouteSettings(name: _routeForStep(resumeStep)),
            builder: (_) => OnboardingPage(
              initialStep: resumeStep,
              repository: repository,
            ),
          );
        }
      }
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const SignupPage(),
      );
    }

    if (routeName == AppRoutes.forgotPassword) {
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const ForgotPasswordPage(),
      );
    }

    if (routeName == AppRoutes.checkEmail) {
      final emailArg = settings.arguments as String?;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => CheckEmailPage(email: emailArg),
      );
    }

    if (routeName == AppRoutes.acceptInvite) {
      final token = settings.arguments is String ? settings.arguments as String : null;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AcceptInvitationPage(initialToken: token),
      );
    }

    // 2. AUTH GUARD: UNTOUCHABLE BOUNDARY
    // Any other route requires an active authenticated session
    if (!isAuthed) {
      return MaterialPageRoute(
        settings: const RouteSettings(name: AppRoutes.login),
        builder: (_) => const LoginPage(),
      );
    }

    // 3. ONBOARDING GUARD & STEPS FOR AUTHENTICATED USERS
    MaterialPageRoute<dynamic> guardedOnboardingStep(int targetStep) {
      if (progress.isOnboardingCompleted) {
        return MaterialPageRoute(
          settings: const RouteSettings(name: AppRoutes.overview),
          builder: (_) => const AppShell(),
        );
      }
      if (!progress.isStepAccessible(targetStep)) {
        final fallbackStep = progress.firstIncompleteStep;
        return MaterialPageRoute(
          settings: RouteSettings(
            name: _routeForStep(fallbackStep),
            arguments: settings.arguments,
          ),
          builder: (_) => OnboardingPage(
            initialStep: fallbackStep,
            repository: repository,
            enforceStepPrerequisites: true,
          ),
        );
      }

      return MaterialPageRoute(
        settings: settings,
        builder: (_) => OnboardingPage(
          initialStep: targetStep,
          repository: repository,
          enforceStepPrerequisites: true,
        ),
      );
    }

    switch (routeName) {
      case AppRoutes.onboardingWelcome:
        if (progress.isOnboardingCompleted) {
          return MaterialPageRoute(
            settings: const RouteSettings(name: AppRoutes.overview),
            builder: (_) => const AppShell(),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              OnboardingPage(initialStep: 0, repository: repository),
        );

      case AppRoutes.onboarding:
        if (progress.isOnboardingCompleted) {
          return MaterialPageRoute(
            settings: const RouteSettings(name: AppRoutes.overview),
            builder: (_) => const AppShell(),
          );
        }
        final resumeStep = progress.firstIncompleteStep;
        if (resumeStep > 1) {
          return MaterialPageRoute(
            settings: RouteSettings(name: _routeForStep(resumeStep)),
            builder: (_) =>
                OnboardingPage(initialStep: resumeStep, repository: repository),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) =>
              OnboardingPage(initialStep: 0, repository: repository),
        );

      case AppRoutes.onboardingBusiness:
        return guardedOnboardingStep(1);

      case AppRoutes.onboardingLocation:
        return guardedOnboardingStep(2);

      case AppRoutes.onboardingCommerce:
        return guardedOnboardingStep(3);

      case AppRoutes.onboardingInventory:
        return guardedOnboardingStep(4);

      case AppRoutes.onboardingTeam:
        return guardedOnboardingStep(5);

      case AppRoutes.onboardingComplete:
        return guardedOnboardingStep(6);

      // 4. PROTECTED APP SHELL & DASHBOARD
      case AppRoutes.overview:
      case '/':
      case AppRoutes.inventory:
      case AppRoutes.sales:
      case AppRoutes.purchasing:
      case AppRoutes.transfers:
      case AppRoutes.aiStudio:
      case AppRoutes.automations:
      case AppRoutes.insights:
      case AppRoutes.settings:
      case AppRoutes.profile:
      default:
        // Guard: merchant must complete onboarding before reaching dashboard
        if (!progress.isOnboardingCompleted) {
          final firstIncomplete = progress.firstIncompleteStep;
          return MaterialPageRoute(
            settings: RouteSettings(name: _routeForStep(firstIncomplete)),
            builder: (_) => OnboardingPage(
              initialStep: firstIncomplete,
              repository: repository,
            ),
          );
        }

        if (routeName == AppRoutes.inventory) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const InventoryPage(),
          );
        }
        if (routeName == AppRoutes.sales) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const SalesPage(),
          );
        }
        if (routeName == AppRoutes.purchasing) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const PurchasingPage(),
          );
        }
        if (routeName == AppRoutes.transfers) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const TransfersPage(),
          );
        }
        if (routeName == AppRoutes.aiStudio) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const AiStudioPage(),
          );
        }
        if (routeName == AppRoutes.automations) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const AutomationsPage(),
          );
        }
        if (routeName == AppRoutes.insights) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const InsightsPage(),
          );
        }
        if (routeName == AppRoutes.settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const SettingsPage(),
          );
        }
        if (routeName == AppRoutes.profile) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const ProfilePage(),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AppShell(),
        );
    }
  }

  static String _routeForStep(int step) {
    switch (step) {
      case 1:
        return AppRoutes.onboardingBusiness;
      case 2:
        return AppRoutes.onboardingLocation;
      case 3:
        return AppRoutes.onboardingCommerce;
      case 4:
        return AppRoutes.onboardingInventory;
      case 5:
        return AppRoutes.onboardingTeam;
      case 6:
        return AppRoutes.onboardingComplete;
      default:
        return AppRoutes.onboardingBusiness;
    }
  }
}
