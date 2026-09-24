import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AppPreferencesService {
  AppPreferencesService._();
  static final AppPreferencesService instance = AppPreferencesService._();

  static bool _dashboardSearchShortcutHintSeen = false;
  static String? _currentBusinessId;
  static bool _loaded = false;

  static File? _resolvePrefsFile() {
    try {
      final configDir = Directory('config');
      if (!configDir.existsSync()) {
        configDir.createSync(recursive: true);
      }
      return File('config/user_preferences.json');
    } catch (_) {
      return null;
    }
  }

  /// Whether the user has already seen the Dashboard search shortcut coachmark hint.
  Future<bool> hasSeenDashboardSearchShortcutHint() async {
    if (!_loaded) {
      _loadFromDisk();
    }
    return _dashboardSearchShortcutHintSeen;
  }

  bool get isDashboardSearchShortcutHintSeenSync {
    if (!_loaded) {
      _loadFromDisk();
    }
    return _dashboardSearchShortcutHintSeen;
  }

  /// Marks the Dashboard search shortcut hint as seen.
  Future<void> markDashboardSearchShortcutHintSeen() async {
    _dashboardSearchShortcutHintSeen = true;
    _saveToDisk();
  }

  /// The active business ID saved from user preference or previous session.
  String? get currentBusinessId {
    if (!_loaded) {
      _loadFromDisk();
    }
    return _currentBusinessId;
  }

  /// Saves the active business ID to preferences.
  Future<void> setCurrentBusinessId(String? businessId) async {
    if (!_loaded) {
      _loadFromDisk();
    }
    _currentBusinessId = businessId;
    _saveToDisk();
  }

  void _loadFromDisk() {
    _loaded = true;
    try {
      final file = _resolvePrefsFile();
      if (file == null || !file.existsSync()) return;
      final content = file.readAsStringSync();
      if (content.isEmpty) return;
      final data = jsonDecode(content) as Map<String, dynamic>;
      _dashboardSearchShortcutHintSeen =
          data['dashboardSearchShortcutHintSeen'] == true;
      final rawBizId = data['currentBusinessId'];
      if (rawBizId is String && rawBizId.trim().isNotEmpty) {
        _currentBusinessId = rawBizId.trim();
      }
    } catch (e) {
      debugPrint('[AppPreferencesService] Error loading preferences: $e');
    }
  }

  void _saveToDisk() {
    try {
      final file = _resolvePrefsFile();
      if (file == null) return;
      final data = {
        'dashboardSearchShortcutHintSeen': _dashboardSearchShortcutHintSeen,
        'currentBusinessId': _currentBusinessId,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      file.writeAsStringSync(jsonEncode(data), flush: true);
    } catch (e) {
      debugPrint('[AppPreferencesService] Error saving preferences: $e');
    }
  }

  bool get dashboardSearchShortcutHintSeen =>
      isDashboardSearchShortcutHintSeenSync;

  Future<void> setDashboardSearchShortcutHintSeen(bool seen) async {
    _dashboardSearchShortcutHintSeen = seen;
    _loaded = true;
    _saveToDisk();
  }

  @visibleForTesting
  static void reloadForTesting() {
    _loaded = false;
    _currentBusinessId = null;
  }

  @visibleForTesting
  static void resetForTesting({bool seen = false, String? businessId}) {
    _dashboardSearchShortcutHintSeen = seen;
    _currentBusinessId = businessId;
    _loaded = true;
  }

  @visibleForTesting
  void reset({bool seen = false, String? businessId}) {
    resetForTesting(seen: seen, businessId: businessId);
  }
}
