import 'package:flutter/material.dart';

import '../../features/ai_studio/presentation/pages/ai_studio_page.dart';
import '../../features/automations/presentation/pages/automations_page.dart';
import '../../features/insights/presentation/pages/insights_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/purchasing/presentation/pages/purchasing_page.dart';
import '../../features/sales/presentation/pages/sales_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/transfers/presentation/pages/transfers_page.dart';
import '../shell/app_shell.dart';

class AppRoutes {
  static const onboarding = '/onboarding';
  static const onboardingWelcome = '/onboarding/welcome';
  static const onboardingBusiness = '/onboarding/business';
  static const onboardingLocation = '/onboarding/location';
  static const onboardingCommerce = '/onboarding/commerce';
  static const onboardingInventory = '/onboarding/inventory';
  static const onboardingTeam = '/onboarding/team';
  static const onboardingComplete = '/onboarding/complete';
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
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.onboarding:
      case AppRoutes.onboardingWelcome:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingPage(initialStep: 0),
        );
      case AppRoutes.onboardingBusiness:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingPage(initialStep: 1),
        );
      case AppRoutes.onboardingLocation:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingPage(initialStep: 2),
        );
      case AppRoutes.onboardingCommerce:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingPage(initialStep: 3),
        );
      case AppRoutes.onboardingInventory:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingPage(initialStep: 4),
        );
      case AppRoutes.onboardingTeam:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingPage(initialStep: 5),
        );
      case AppRoutes.onboardingComplete:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingPage(initialStep: 6),
        );
      case AppRoutes.inventory:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const InventoryPage(),
        );
      case AppRoutes.sales:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SalesPage(),
        );
      case AppRoutes.purchasing:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PurchasingPage(),
        );
      case AppRoutes.transfers:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TransfersPage(),
        );
      case AppRoutes.aiStudio:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AiStudioPage(),
        );
      case AppRoutes.automations:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AutomationsPage(),
        );
      case AppRoutes.insights:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const InsightsPage(),
        );
      case AppRoutes.settings:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SettingsPage(),
        );
      case AppRoutes.profile:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ProfilePage(),
        );
      case AppRoutes.overview:
      case '/':
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const AppShell(),
        );
    }
  }
}
