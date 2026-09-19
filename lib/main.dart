import 'package:flutter/material.dart';

import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/config/app_environment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppEnvironment.initializeSupabase();
    runApp(const ThreadStockApp());
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

    runApp(const ThreadStockConfigErrorApp());
  }
}

class ThreadStockApp extends StatelessWidget {
  const ThreadStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThreadStock',
      debugShowCheckedModeBanner: false,
      theme: ThreadStockTheme.light(),
      darkTheme: ThreadStockTheme.dark(),
      themeMode: ThemeMode.system,
      initialRoute: AppRoutes.onboarding,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}

class ThreadStockConfigErrorApp extends StatelessWidget {
  const ThreadStockConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThreadStock',
      debugShowCheckedModeBanner: false,
      theme: ThreadStockTheme.light(),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'ThreadStock configuration is incomplete.\n'
              'Please configure the workspace connection and restart the application.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}
