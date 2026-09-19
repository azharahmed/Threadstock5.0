import 'package:supabase_flutter/supabase_flutter.dart';

class AppEnvironment {
  const AppEnvironment._();

  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static String get supabaseUrl => _supabaseUrl.trim();

  static String get supabasePublishableKey => _supabasePublishableKey.trim();

  static Uri? get validatedSupabaseUrl {
    final value = supabaseUrl;
    if (value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority || !uri.host.contains('.')) {
      return null;
    }

    return uri;
  }

  static Future<void> initializeSupabase() async {
    final url = validatedSupabaseUrl;
    final key = supabasePublishableKey;

    if (url == null || key.isEmpty || key.contains('YOUR_')) {
      throw StateError(
        'ThreadStock configuration is incomplete.\n'
        'Please configure the workspace connection and restart the application.',
      );
    }

    await Supabase.initialize(
      url: url.toString(),
      publishableKey: key,
    );
  }
}
