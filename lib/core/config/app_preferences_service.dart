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

  static bool _isValidUuid(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.length != 36) return false;
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(trimmed);
  }

  /// Saves the active business ID to preferences.
  Future<void> setCurrentBusinessId(String? businessId) async {
    if (!_loaded) {
      _loadFromDisk();
    }
    if (businessId != null && businessId.isNotEmpty) {
      final trimmed = businessId.trim();
      if (!_isValidUuid(trimmed)) {
        debugPrint(
          '[AppPreferencesService] Refusing to persist non-UUID business ID: "$trimmed". Purging.',
        );
        _currentBusinessId = null;
      } else {
        _currentBusinessId = trimmed;
      }
    } else {
      _currentBusinessId = null;
    }
    _saveToDisk();
  }

  static final Map<String, String> _companyLogoUrls = {};

  /// Gets the persisted company logo URL for the given business.
  String? getCompanyLogoUrl(String businessId) {
    if (!_loaded) {
      _loadFromDisk();
    }
    return _companyLogoUrls[businessId];
  }

  /// Sets the company logo URL for the given business.
  Future<void> setCompanyLogoUrl(String businessId, String? url) async {
    if (!_loaded) {
      _loadFromDisk();
    }
    if (url == null || url.isEmpty) {
      _companyLogoUrls.remove(businessId);
    } else {
      _companyLogoUrls[businessId] = url;
    }
    _saveToDisk();
  }

  static final Map<String, String> _currentLocationByBusiness = {};

  /// Gets the persisted active location ID for the given business.
  String? getCurrentLocationId(String businessId) {
    if (!_loaded) {
      _loadFromDisk();
    }
    return _currentLocationByBusiness[businessId];
  }

  /// Sets the active location ID for the given business.
  Future<void> setCurrentLocationId(String businessId, String? locationId) async {
    if (!_loaded) {
      _loadFromDisk();
    }
    final trimmedBizId = businessId.trim();
    if (!_isValidUuid(trimmedBizId)) {
      debugPrint(
        '[AppPreferencesService] Ignoring location preference for non-UUID business: "$trimmedBizId"',
      );
      return;
    }
    if (locationId == null || locationId.isEmpty) {
      _currentLocationByBusiness.remove(trimmedBizId);
    } else {
      _currentLocationByBusiness[trimmedBizId] = locationId;
    }
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
        final trimmed = rawBizId.trim();
        if (_isValidUuid(trimmed)) {
          _currentBusinessId = trimmed;
        } else {
          debugPrint(
            '[AppPreferencesService] Discarding non-UUID currentBusinessId from disk: "$trimmed"',
          );
          _currentBusinessId = null;
        }
      }
      final rawLogos = data['companyLogoUrls'];
      if (rawLogos is Map) {
        _companyLogoUrls.clear();
        for (final entry in rawLogos.entries) {
          if (entry.key is String && entry.value is String) {
            _companyLogoUrls[entry.key as String] = entry.value as String;
          }
        }
      }
      final rawLocs = data['currentLocationByBusiness'];
      if (rawLocs is Map) {
        _currentLocationByBusiness.clear();
        for (final entry in rawLocs.entries) {
          if (entry.key is String && entry.value is String) {
            final k = (entry.key as String).trim();
            if (_isValidUuid(k)) {
              _currentLocationByBusiness[k] = entry.value as String;
            }
          }
        }
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
        'companyLogoUrls': _companyLogoUrls,
        'currentLocationByBusiness': _currentLocationByBusiness,
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
    _currentLocationByBusiness.clear();
  }

  @visibleForTesting
  static void resetForTesting({bool seen = false, String? businessId}) {
    _dashboardSearchShortcutHintSeen = seen;
    _currentBusinessId = businessId;
    _currentLocationByBusiness.clear();
    _loaded = true;
  }

  @visibleForTesting
  void reset({bool seen = false, String? businessId}) {
    resetForTesting(seen: seen, businessId: businessId);
  }
}
