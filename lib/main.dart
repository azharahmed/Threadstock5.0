import 'package:flutter/material.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/business/app_bootstrap_service.dart';
import 'core/config/app_environment.dart';
import 'core/navigation/navigation_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppEnvironment.initializeSupabase();
    final bootstrapResult = await AppBootstrapService.bootstrap();
    runApp(ThreadStockApp(initialRoute: bootstrapResult.initialRoute));
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'ThreadStock startup',
        context: ErrorDescription(
          'Failed to initialize the application configuration.',
        ),
      ),
    );

    final message = error is AppConfigurationException
        ? error.message
        : 'ThreadStock configuration is invalid.\n'
              'Check the workspace connection settings and restart the application.';

    runApp(ThreadStockConfigErrorApp(message: message));
  }
}

class ThreadStockApp extends StatelessWidget {
  const ThreadStockApp({this.initialRoute, super.key});

  final String? initialRoute;

  @override
  Widget build(BuildContext context) {
    // The initialRoute from AppBootstrapService.bootstrap() is always
    // authoritative — it was determined by a fresh Supabase query scoped
    // to the resolved current business.
    //
    // The fallback (initialRoute == null) should only trigger if bootstrap
    // failed catastrophically, in which case we route to login so the user
    // can re-authenticate and get a fresh authoritative state. We never use
    // the disk-cached onboarding progress as a fallback authority here,
    // because the cache may belong to a different business.
    final effectiveRoute = initialRoute ?? AppRoutes.login;

    return MaterialApp(
      title: 'ThreadStock',
      debugShowCheckedModeBanner: false,
      theme: ThreadStockTheme.light(),
      darkTheme: ThreadStockTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: effectiveRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
      navigatorObservers: [NavigationGuard.observer],
    );
  }
}

class ThreadStockConfigErrorApp extends StatelessWidget {
  const ThreadStockConfigErrorApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThreadStock',
      debugShowCheckedModeBanner: false,
      theme: ThreadStockTheme.light(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
