import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for restoring real authenticated sessions on startup.
/// Automatic anonymous sign-ins have been completely removed.
class AuthBootstrapService {
  const AuthBootstrapService._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static String? _lastAuthError;
  static String? get lastAuthError => _lastAuthError;

  static SupabaseClient? _getClient(SupabaseClient? client) {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Restores an existing authenticated Supabase session at startup if present.
  /// Does NOT create anonymous sessions.
  /// If no valid session is present, returns null so the user is routed to /login.
  static Future<User?> initializeAuthSession({SupabaseClient? client}) async {
    final sb = _getClient(client);
    if (sb == null) {
      debugPrint(
        '[AuthBootstrap] Supabase client not initialized; skipping session restore.',
      );
      _initialized = true;
      return null;
    }

    try {
      final session = sb.auth.currentSession;
      final user = sb.auth.currentUser;

      if (session != null && user != null) {
        debugPrint(
          '[AuthBootstrap] Reusing existing persisted session for user: ${user.id}',
        );
        _initialized = true;
        _lastAuthError = null;
        return user;
      }

      debugPrint(
        '[AuthBootstrap] No active session found. Unauthenticated startup.',
      );
      _initialized = true;
      _lastAuthError = null;
      return null;
    } catch (e, st) {
      _lastAuthError = e.toString();
      debugPrint(
        '[AuthBootstrap] Unexpected error during session restore: $e\n$st',
      );
      _initialized = true;
      return null;
    }
  }

  /// Backward-compatible alias for existing call sites.
  /// Now only restores existing sessions without anonymous fallback.
  static Future<User?> initializeSilentAuth({SupabaseClient? client}) async {
    return initializeAuthSession(client: client);
  }

  @visibleForTesting
  static void resetForTesting() {
    _initialized = false;
    _lastAuthError = null;
  }
}
