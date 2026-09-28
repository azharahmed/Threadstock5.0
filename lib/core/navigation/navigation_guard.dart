import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../auth/auth_service.dart';
import '../../features/onboarding/data/onboarding_repository.dart';

/// Central navigation coordinator and race prevention guard for ThreadStock.
///
/// Prevents:
/// - Flutter Navigator `!navigator._debugLocked` assertion crashes
/// - Duplicate push / pushReplacement calls from competing state listeners
/// - Navigating during active build / layout phases
/// - Stuck lock state when routes replace or fail
/// - Idempotent no-op for redundant navigation to same active route
class NavigationGuard {
  static bool _isNavigating = false;
  static String? _currentRoute;

  /// Returns true if a navigation operation is currently being dispatched.
  static bool get isNavigating => _isNavigating;

  /// The active route tracked by the navigation guard.
  static String? get currentRoute => _currentRoute;

  /// Sets the active route tracked by the navigation guard.
  static void setCurrentRoute(String? route) {
    _currentRoute = route;
  }

  /// Global route observer for synchronizing `currentRoute`.
  static final NavigatorObserver observer = NavigationGuardObserver();

  /// Logs structured navigation trace per specification.
  static void trace({
    required String source,
    required String targetRoute,
    String? currentRoute,
    String? authState,
    String? onboardingStatus,
  }) {
    final auth = authState ??
        (AuthService.instance.isAuthenticated
            ? 'authenticated'
            : 'unauthenticated');
    final onboarding = onboardingStatus ??
        (OnboardingRepository.instance.currentProgress.isOnboardingCompleted
            ? 'complete'
            : 'in_progress');

    debugPrint(
      '[NavigationTrace]\n'
      '  source: $source\n'
      '  currentRoute: ${currentRoute ?? _currentRoute ?? "unknown"}\n'
      '  targetRoute: $targetRoute\n'
      '  authState: $auth\n'
      '  onboardingStatus: $onboarding\n'
      '  timestamp: ${DateTime.now().toIso8601String()}',
    );
  }

  /// Safely performs pushReplacementNamed with idempotency lock and post-frame guarantee.
  static Future<T?> safePushReplacementNamed<T extends Object?, TO extends Object?>(
    BuildContext context,
    String routeName, {
    required String source,
    TO? result,
    Object? arguments,
  }) async {
    // Idempotent check: if already on target route, no action required
    if (_currentRoute == routeName) {
      debugPrint(
        '[NavigationGuard] Already on $routeName from $source (idempotent no-op)',
      );
      return null;
    }

    if (_isNavigating) {
      debugPrint(
        '[NavigationGuard] Blocked duplicate navigation to $routeName from $source (already navigating)',
      );
      return null;
    }
    _isNavigating = true;
    _currentRoute = routeName;
    trace(source: source, targetRoute: routeName);

    try {
      if (!context.mounted) {
        _isNavigating = false;
        return null;
      }

      final phase = WidgetsBinding.instance.schedulerPhase;
      final isBuilding = phase == SchedulerPhase.persistentCallbacks;

      if (isBuilding) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            _isNavigating = false;
            return;
          }
          try {
            Navigator.of(context).pushReplacementNamed<T, TO>(
              routeName,
              result: result,
              arguments: arguments,
            );
          } catch (e) {
            debugPrint('[NavigationGuard] Error during pushReplacementNamed: $e');
          } finally {
            _isNavigating = false;
          }
        });
      } else {
        Navigator.of(context).pushReplacementNamed<T, TO>(
          routeName,
          result: result,
          arguments: arguments,
        );
        _isNavigating = false;
      }
      return null;
    } catch (e) {
      debugPrint('[NavigationGuard] Exception in safePushReplacementNamed: $e');
      _isNavigating = false;
      return null;
    }
  }

  /// Safely performs pushNamedAndRemoveUntil with idempotency lock and post-frame guarantee.
  static Future<T?> safePushNamedAndRemoveUntil<T extends Object?>(
    BuildContext context,
    String newRouteName,
    RoutePredicate predicate, {
    required String source,
    Object? arguments,
  }) async {
    // Idempotent check: if already on target route, no action required
    if (_currentRoute == newRouteName) {
      debugPrint(
        '[NavigationGuard] Already on $newRouteName from $source (idempotent no-op)',
      );
      return null;
    }

    if (_isNavigating) {
      debugPrint(
        '[NavigationGuard] Blocked duplicate navigation to $newRouteName from $source (already navigating)',
      );
      return null;
    }
    _isNavigating = true;
    _currentRoute = newRouteName;
    trace(source: source, targetRoute: newRouteName);

    try {
      if (!context.mounted) {
        _isNavigating = false;
        return null;
      }

      final phase = WidgetsBinding.instance.schedulerPhase;
      final isBuilding = phase == SchedulerPhase.persistentCallbacks;

      if (isBuilding) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            _isNavigating = false;
            return;
          }
          try {
            Navigator.of(context).pushNamedAndRemoveUntil<T>(
              newRouteName,
              predicate,
              arguments: arguments,
            );
          } catch (e) {
            debugPrint('[NavigationGuard] Error during pushNamedAndRemoveUntil: $e');
          } finally {
            _isNavigating = false;
          }
        });
      } else {
        Navigator.of(context).pushNamedAndRemoveUntil<T>(
          newRouteName,
          predicate,
          arguments: arguments,
        );
        _isNavigating = false;
      }
      return null;
    } catch (e) {
      debugPrint('[NavigationGuard] Exception in safePushNamedAndRemoveUntil: $e');
      _isNavigating = false;
      return null;
    }
  }

  /// Safely performs pushNamed with idempotency lock and post-frame guarantee.
  static Future<T?> safePushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    required String source,
    Object? arguments,
  }) async {
    if (_currentRoute == routeName) {
      debugPrint(
        '[NavigationGuard] Already on $routeName from $source (idempotent no-op)',
      );
      return null;
    }

    if (_isNavigating) {
      debugPrint(
        '[NavigationGuard] Blocked duplicate navigation to $routeName from $source (already navigating)',
      );
      return null;
    }
    _isNavigating = true;
    _currentRoute = routeName;
    trace(source: source, targetRoute: routeName);

    try {
      if (!context.mounted) {
        _isNavigating = false;
        return null;
      }

      final phase = WidgetsBinding.instance.schedulerPhase;
      final isBuilding = phase == SchedulerPhase.persistentCallbacks;

      if (isBuilding) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            _isNavigating = false;
            return;
          }
          try {
            Navigator.of(context).pushNamed<T>(
              routeName,
              arguments: arguments,
            );
          } catch (e) {
            debugPrint('[NavigationGuard] Error during pushNamed: $e');
          } finally {
            _isNavigating = false;
          }
        });
      } else {
        Navigator.of(context).pushNamed<T>(
          routeName,
          arguments: arguments,
        );
        _isNavigating = false;
      }
      return null;
    } catch (e) {
      debugPrint('[NavigationGuard] Exception in safePushNamed: $e');
      _isNavigating = false;
      return null;
    }
  }

  /// Safely closes a dialog and then navigates to target route after frame settles.
  static void safePopAndNavigate(
    BuildContext context, {
    required String targetRoute,
    required String source,
  }) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        safePushReplacementNamed(context, targetRoute, source: source);
      }
    });
  }

  /// Reset navigation state (for testing)
  @visibleForTesting
  static void resetForTesting() {
    _isNavigating = false;
    _currentRoute = null;
  }
}

/// NavigatorObserver for automatically updating `NavigationGuard.currentRoute`.
class NavigationGuardObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    if (route.settings.name != null) {
      NavigationGuard.setCurrentRoute(route.settings.name);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute?.settings.name != null) {
      NavigationGuard.setCurrentRoute(newRoute!.settings.name);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute?.settings.name != null) {
      NavigationGuard.setCurrentRoute(previousRoute!.settings.name);
    }
  }
}
