import 'package:flutter/material.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/auth/auth_service.dart';
import 'core/business/app_bootstrap_service.dart';
import 'core/config/app_environment.dart';
import 'features/onboarding/data/onboarding_repository.dart';

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
    final effectiveRoute =
        initialRoute ??
        (AuthService.instance.isAuthenticated
            ? (OnboardingRepository.instance.currentProgress.isOnboardingCompleted
                ? AppRoutes.overview
                : AppRoutes.onboarding)
            : AppRoutes.login);

    return MaterialApp(
      title: 'ThreadStock',
      debugShowCheckedModeBanner: false,
      theme: ThreadStockTheme.light(),
      darkTheme: ThreadStockTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: effectiveRoute,
      onGenerateRoute: AppRouter.onGenerateRoute,
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
