import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_service.dart';

class AppConfigurationException implements Exception {
  const AppConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppEnvironment {
  const AppEnvironment._();

  static bool _supabaseInitialized = false;
  static String _supabaseUrlValue = '';
  static String _supabasePublishableKeyValue = '';

  static String get supabaseUrl => _supabaseUrlValue.trim();

  static String get supabasePublishableKey =>
      _supabasePublishableKeyValue.trim();

  static Uri? get validatedSupabaseUrl {
    final value = supabaseUrl;
    if (value.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(value);
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        !uri.host.contains('.')) {
      return null;
    }

    if (uri.scheme.toLowerCase() != 'https') {
      return null;
    }

    return uri;
  }

  static Future<void> initializeSupabase() async {
    if (_supabaseInitialized) {
      return;
    }

    final config = await _RuntimeSupabaseConfig.load();
    _supabaseUrlValue = config.url;
    _supabasePublishableKeyValue = config.publishableKey;

    final url = validatedSupabaseUrl;
    final key = supabasePublishableKey;

    if (url == null || !_isValidPublishableKey(key)) {
      throw const AppConfigurationException(
        'ThreadStock configuration is invalid.\n'
        'Check the workspace connection settings and restart the application.',
      );
    }

    await Supabase.initialize(url: url.toString(), publishableKey: key);
    _supabaseInitialized = true;

    // Initialize authoritative authentication state
    await AuthService.instance.initialize();
  }

  static bool _isValidPublishableKey(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return false;
    }

    final lower = normalized.toLowerCase();
    if (lower.contains('service_role') ||
        lower.contains('sb_secret_') ||
        lower.contains('postgresql://') ||
        lower.contains('jwt') ||
        lower.contains('database password') ||
        lower.contains('password') ||
        lower.contains('secret')) {
      return false;
    }

    if (normalized.startsWith('sb_publishable_') &&
        normalized.length > 'sb_publishable_'.length) {
      return true;
    }

    return false;
  }
}

class _RuntimeSupabaseConfig {
  const _RuntimeSupabaseConfig({
    required this.url,
    required this.publishableKey,
  });

  final String url;
  final String publishableKey;

  static Future<_RuntimeSupabaseConfig> load() async {
    final configFile = _resolveConfigFile();
    if (configFile == null) {
      throw const AppConfigurationException(
        'ThreadStock configuration is incomplete.\n'
        'Supabase configuration file was not found.\n\n'
        'Expected:\n'
        'config/supabase.local.json',
      );
    }

    final file = File(configFile);
    if (!await file.exists()) {
      throw const AppConfigurationException(
        'ThreadStock configuration is incomplete.\n'
        'Supabase configuration file was not found.\n\n'
        'Expected:\n'
        'config/supabase.local.json',
      );
    }

    try {
      final jsonContent = await file.readAsString();
      final decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        throw const AppConfigurationException(
          'ThreadStock configuration is invalid.\n'
          'Check the workspace connection settings and restart the application.',
        );
      }

      final map = Map<String, dynamic>.from(decoded);
      final url = _readRequiredField(map, 'SUPABASE_URL');
      final publishableKey = _readRequiredField(
        map,
        'SUPABASE_PUBLISHABLE_KEY',
      );

      final normalizedUrl = url.trim();
      final normalizedKey = publishableKey.trim();

      if (!_isValidSupabaseUrl(normalizedUrl)) {
        throw const AppConfigurationException(
          'ThreadStock configuration is invalid.\n'
          'Check the workspace connection settings and restart the application.',
        );
      }

      if (!AppEnvironment._isValidPublishableKey(normalizedKey)) {
        throw const AppConfigurationException(
          'ThreadStock configuration is invalid.\n'
          'Check the workspace connection settings and restart the application.',
        );
      }

      return _RuntimeSupabaseConfig(
        url: normalizedUrl,
        publishableKey: normalizedKey,
      );
    } on FormatException {
      throw const AppConfigurationException(
        'ThreadStock configuration is invalid.\n'
        'Check the workspace connection settings and restart the application.',
      );
    }
  }

  static String? _resolveConfigFile() {
    final workingDirectory = Directory.current.path;
    final executableDirectory = File(Platform.resolvedExecutable).parent.path;
    final roots = <String>{
      workingDirectory,
      executableDirectory,
      _parentDirectory(executableDirectory),
      _parentDirectory(_parentDirectory(executableDirectory)),
    };

    for (final root in roots) {
      final candidate = _joinPath(root, 'config', 'supabase.local.json');
      if (File(candidate).existsSync()) {
        return candidate;
      }
    }

    return null;
  }

  static String _readRequiredField(Map<String, dynamic> map, String key) {
    final value = map[key] ?? map[key.toLowerCase()] ?? map[key.toUpperCase()];
    if (value is! String) {
      throw const AppConfigurationException(
        'ThreadStock configuration is invalid.\n'
        'Check the workspace connection settings and restart the application.',
      );
    }

    return value;
  }

  static bool _isValidSupabaseUrl(String value) {
    if (value.trim().isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        !uri.hasScheme ||
        !uri.hasAuthority ||
        !uri.host.contains('.')) {
      return false;
    }

    return uri.scheme.toLowerCase() == 'https';
  }

  static String _joinPath(String base, String segment1, String segment2) {
    final cleanBase = base.endsWith(Platform.pathSeparator)
        ? base.substring(0, base.length - 1)
        : base;
    return '$cleanBase${Platform.pathSeparator}$segment1${Platform.pathSeparator}$segment2';
  }

  static String _parentDirectory(String path) {
    final normalized = path
        .replaceAll('/', Platform.pathSeparator)
        .replaceAll('\\', Platform.pathSeparator);
    final segments = normalized.split(Platform.pathSeparator);
    if (segments.length <= 1) {
      return path;
    }
    segments.removeLast();
    return segments.join(Platform.pathSeparator);
  }
}
