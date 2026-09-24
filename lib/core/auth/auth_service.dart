import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../business/current_business_service.dart';
import '../config/app_preferences_service.dart';
import '../../features/onboarding/data/onboarding_repository.dart';
import 'authorization_service.dart';

enum AuthStatus {
  initializing,
  authenticated,
  unauthenticated,
}

class AuthService extends ChangeNotifier {
  AuthService({this.client});

  final SupabaseClient? client;

  static final AuthService instance = AuthService();

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  AuthStatus _status = AuthStatus.initializing;
  User? _currentUser;
  Session? _currentSession;
  String? _lastAuthError;
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;

  AuthStatus get status => _status;
  User? get currentUser => _currentUser ?? _resolvedClient?.auth.currentUser;
  Session? get currentSession => _currentSession ?? _resolvedClient?.auth.currentSession;
  String? get lastAuthError => _lastAuthError;
  bool get isAuthenticated => _status == AuthStatus.authenticated && currentUser != null;
  bool get isInitializing => _status == AuthStatus.initializing;

  /// Initializes authoritative auth state and listens to session changes.
  Future<void> initialize({SupabaseClient? overrideClient}) async {
    final sb = overrideClient ?? _resolvedClient;
    if (sb == null) {
      _status = AuthStatus.unauthenticated;
      _initialized = true;
      notifyListeners();
      return;
    }

    if (_initialized && _authSubscription != null) {
      return;
    }

    try {
      final session = sb.auth.currentSession;
      final user = sb.auth.currentUser;

      if (session != null && user != null) {
        _currentSession = session;
        _currentUser = user;
        _status = AuthStatus.authenticated;
      } else {
        _currentSession = null;
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      }

      await _authSubscription?.cancel();
      _authSubscription = sb.auth.onAuthStateChange.listen((data) {
        _handleAuthStateChange(data.event, data.session);
      });

      _initialized = true;
      _lastAuthError = null;
    } catch (e) {
      debugPrint('[AuthService] Error during auth initialization: $e');
      _status = AuthStatus.unauthenticated;
      _lastAuthError = e.toString();
    } finally {
      notifyListeners();
    }
  }

  void _handleAuthStateChange(AuthChangeEvent event, Session? session) {
    debugPrint('[AuthService] onAuthStateChange event: $event');
    _currentSession = session;
    _currentUser = session?.user;

    switch (event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
        if (session != null && session.user != null) {
          _status = AuthStatus.authenticated;
          _lastAuthError = null;
        } else {
          _status = AuthStatus.unauthenticated;
        }
        break;

      case AuthChangeEvent.signedOut:
        _status = AuthStatus.unauthenticated;
        _currentUser = null;
        _currentSession = null;
        _lastAuthError = null;
        break;

      case AuthChangeEvent.passwordRecovery:
        _status = AuthStatus.authenticated;
        break;

      case AuthChangeEvent.initialSession:
        if (session != null && session.user != null) {
          _status = AuthStatus.authenticated;
        } else {
          _status = AuthStatus.unauthenticated;
        }
        break;

      default:
        break;
    }

    notifyListeners();
  }

  /// Production sign-in with email and password.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final sb = _resolvedClient;
    if (sb == null) {
      throw StateError('Supabase client is not available.');
    }

    _lastAuthError = null;
    notifyListeners();

    try {
      final response = await sb.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      final session = response.session;

      if (user != null && session != null) {
        _currentUser = user;
        _currentSession = session;
        _status = AuthStatus.authenticated;
        _lastAuthError = null;
        notifyListeners();
      }

      return response;
    } on AuthException catch (e) {
      _lastAuthError = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _lastAuthError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Production sign-up with email, password, and full name.
  /// The backend trigger `handle_new_user()` automatically provisions public.profiles.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final sb = _resolvedClient;
    if (sb == null) {
      throw StateError('Supabase client is not available.');
    }

    _lastAuthError = null;
    notifyListeners();

    try {
      final response = await sb.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );

      final user = response.user;
      final session = response.session;

      if (user != null && session != null) {
        _currentUser = user;
        _currentSession = session;
        _status = AuthStatus.authenticated;
        _lastAuthError = null;
        notifyListeners();
      }

      return response;
    } on AuthException catch (e) {
      _lastAuthError = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _lastAuthError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Sends a password reset email.
  Future<void> resetPasswordForEmail({
    required String email,
    String? redirectTo,
  }) async {
    final sb = _resolvedClient;
    if (sb == null) {
      throw StateError('Supabase client is not available.');
    }

    _lastAuthError = null;
    notifyListeners();

    try {
      await sb.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: redirectTo,
      );
    } on AuthException catch (e) {
      _lastAuthError = e.message;
      notifyListeners();
      rethrow;
    } catch (e) {
      _lastAuthError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Global sign-out: revokes Supabase session, purges in-memory business state,
  /// clears persisted caches, and sets status to unauthenticated.
  Future<void> signOut() async {
    final sb = _resolvedClient;
    try {
      if (sb != null) {
        await sb.auth.signOut();
      }
    } catch (e) {
      debugPrint('[AuthService] Error during Supabase signOut: $e');
    } finally {
      // Purge business-scoped and user-scoped data across sign-out
      CurrentBusinessService.instance.clear();
      await AppPreferencesService.instance.setCurrentBusinessId(null);
      OnboardingRepository.instance.clearCache();
      AuthorizationService.instance.clear();

      _currentUser = null;
      _currentSession = null;
      _status = AuthStatus.unauthenticated;
      _lastAuthError = null;
      notifyListeners();
    }
  }

  @visibleForTesting
  void setAuthenticatedForTesting({User? user, Session? session}) {
    _currentUser = user;
    _currentSession = session;
    _status = AuthStatus.authenticated;
    _lastAuthError = null;
    notifyListeners();
  }

  @visibleForTesting
  void setUnauthenticatedForTesting() {
    _currentUser = null;
    _currentSession = null;
    _status = AuthStatus.unauthenticated;
    _lastAuthError = null;
    notifyListeners();
  }

  @visibleForTesting
  void resetForTesting() {
    _authSubscription?.cancel();
    _authSubscription = null;
    _currentUser = null;
    _currentSession = null;
    _status = AuthStatus.initializing;
    _lastAuthError = null;
    _initialized = false;
  }
}
