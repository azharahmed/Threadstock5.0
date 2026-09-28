import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlacePrediction {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlacePrediction({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structured = json['structured_formatting'] as Map<String, dynamic>?;
    return PlacePrediction(
      placeId: json['place_id'] as String? ?? json['placeId'] as String? ?? '',
      description: json['description'] as String? ?? '',
      mainText: json['main_text'] as String? ??
          json['mainText'] as String? ??
          json['primaryText'] as String? ??
          structured?['main_text'] as String? ??
          '',
      secondaryText: json['secondary_text'] as String? ??
          json['secondaryText'] as String? ??
          structured?['secondary_text'] as String? ??
          '',
    );
  }
}

class PlaceDetails {
  final String placeId;
  final String name;
  final String formattedAddress;
  final String streetAddress;
  final String city;
  final String state;
  final String postalCode;
  final String countryCode;
  final String countryName;
  final double? latitude;
  final double? longitude;

  const PlaceDetails({
    required this.placeId,
    required this.name,
    required this.formattedAddress,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.countryCode,
    required this.countryName,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>?;
    final location = geometry?['location'] as Map<String, dynamic>?;
    final lat = (json['latitude'] ?? location?['lat']) as num?;
    final lng = (json['longitude'] ?? location?['lng']) as num?;

    var streetAddress = json['street_address'] as String? ??
        json['streetAddress'] as String? ??
        '';
    var city = json['city'] as String? ?? '';
    var state = json['state'] as String? ?? '';
    var postalCode = json['postal_code'] as String? ??
        json['postalCode'] as String? ??
        '';
    var countryCode = json['country_code'] as String? ??
        json['countryCode'] as String? ??
        '';
    var countryName = json['country_name'] as String? ??
        json['countryName'] as String? ??
        '';

    if (json['address_components'] is List) {
      final components =
          (json['address_components'] as List).cast<Map<String, dynamic>>();

      String getComp(String type, [bool short = false]) {
        for (final c in components) {
          final types = (c['types'] as List?)?.cast<String>() ?? [];
          if (types.contains(type)) {
            return (short ? c['short_name'] : c['long_name']) as String? ?? '';
          }
        }
        return '';
      }

      if (city.isEmpty) {
        city = getComp('locality');
        if (city.isEmpty) city = getComp('sublocality');
        if (city.isEmpty) city = getComp('postal_town');
      }
      if (state.isEmpty) state = getComp('administrative_area_level_1');
      if (postalCode.isEmpty) postalCode = getComp('postal_code');
      if (countryCode.isEmpty) countryCode = getComp('country', true);
      if (countryName.isEmpty) countryName = getComp('country', false);
      if (streetAddress.isEmpty) {
        final num = getComp('street_number');
        final route = getComp('route');
        streetAddress = [num, route].where((s) => s.isNotEmpty).join(' ');
      }
    }

    return PlaceDetails(
      placeId: json['place_id'] as String? ?? json['placeId'] as String? ?? '',
      name: json['name'] as String? ?? json['displayName'] as String? ?? '',
      formattedAddress: json['formatted_address'] as String? ??
          json['formattedAddress'] as String? ??
          '',
      streetAddress: streetAddress,
      city: city,
      state: state,
      postalCode: postalCode,
      countryCode: countryCode,
      countryName: countryName,
      latitude: lat?.toDouble(),
      longitude: lng?.toDouble(),
    );
  }
}

enum PlacesSearchStatus {
  success,
  zeroResults,
  unavailable,
}

class PlacesSearchResult {
  final PlacesSearchStatus status;
  final List<PlacePrediction> predictions;
  final String? errorMessage;

  const PlacesSearchResult({
    required this.status,
    this.predictions = const [],
    this.errorMessage,
  });

  bool get isSuccess => status == PlacesSearchStatus.success;
  bool get isZeroResults => status == PlacesSearchStatus.zeroResults;
  bool get isUnavailable => status == PlacesSearchStatus.unavailable;
}

class PlacesSessionToken {
  static int _counter = 0;

  static String generate() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _counter++;
    return 'sess_${now}_$_counter';
  }
}

/// Lightweight counters tracking Google Places usage in development / debug mode.
class PlacesUsageCounters {
  final int autocomplete;
  final int details;
  final int cacheHits;
  final int failures;

  const PlacesUsageCounters({
    this.autocomplete = 0,
    this.details = 0,
    this.cacheHits = 0,
    this.failures = 0,
  });

  @override
  String toString() =>
      '[PlacesUsage] autocomplete=$autocomplete details=$details cacheHits=$cacheHits failures=$failures';
}

class GooglePlacesService {
  GooglePlacesService({this.client});

  final SupabaseClient? client;

  static final GooglePlacesService instance = GooglePlacesService();

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // Cost-control usage tracking counters
  int _autocompleteCount = 0;
  int _detailsCount = 0;
  int _cacheHitsCount = 0;
  int _failuresCount = 0;

  PlacesUsageCounters get usageCounters => PlacesUsageCounters(
        autocomplete: _autocompleteCount,
        details: _detailsCount,
        cacheHits: _cacheHitsCount,
        failures: _failuresCount,
      );

  void resetUsageCounters() {
    _autocompleteCount = 0;
    _detailsCount = 0;
    _cacheHitsCount = 0;
    _failuresCount = 0;
  }

  void _logUsage() {
    if (kDebugMode) {
      debugPrint(usageCounters.toString());
    }
  }

  // Session-level autocomplete cache: key = "${query.toLowerCase()}__${countryCode.toUpperCase()}"
  final Map<String, List<PlacePrediction>> _sessionCache = {};

  void clearSessionCache() {
    _sessionCache.clear();
  }

  // Monotonic query ID counter for cancelling / ignoring stale in-flight queries
  int _activeQueryId = 0;

  // Testing hooks for unit and widget tests
  @visibleForTesting
  static List<PlacePrediction>? mockPredictions;

  @visibleForTesting
  static PlaceDetails? mockDetails;

  @visibleForTesting
  static bool mockApiUnavailable = false;

  /// Queries Google Places Autocomplete through secure Supabase Edge Function.
  /// Handles zero results, network downtime, quota limits, and API denial gracefully.
  /// Enforces minimum 2-3 characters, session cache, 5-result limit, and stale query cancellation.
  Future<PlacesSearchResult> searchPlacesWithResult({
    required String query,
    String? countryCode,
    String? sessionToken,
    String? types,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      return const PlacesSearchResult(
        status: PlacesSearchStatus.success,
        predictions: [],
      );
    }

    // 1. Check in-session autocomplete cache
    final cacheKey =
        '${trimmed.toLowerCase()}__${countryCode?.toUpperCase() ?? ''}__${types ?? ''}';
    if (_sessionCache.containsKey(cacheKey)) {
      _cacheHitsCount++;
      _logUsage();
      return PlacesSearchResult(
        status: PlacesSearchStatus.success,
        predictions: _sessionCache[cacheKey]!,
      );
    }

    if (mockApiUnavailable) {
      _failuresCount++;
      _logUsage();
      return const PlacesSearchResult(
        status: PlacesSearchStatus.unavailable,
        errorMessage: 'Location search is temporarily unavailable. You can enter the address manually.',
      );
    }

    if (mockPredictions != null) {
      final matching = mockPredictions!
          .where((p) =>
              p.description.toLowerCase().contains(trimmed.toLowerCase()) ||
              p.mainText.toLowerCase().contains(trimmed.toLowerCase()))
          .take(5)
          .toList();
      _autocompleteCount++;
      _logUsage();
      if (matching.isEmpty) {
        return const PlacesSearchResult(
          status: PlacesSearchStatus.zeroResults,
          predictions: [],
          errorMessage: 'No matching locations found. Try another search or enter the address manually.',
        );
      }
      _sessionCache[cacheKey] = matching;
      return PlacesSearchResult(
        status: PlacesSearchStatus.success,
        predictions: matching,
      );
    }

    final sb = _resolvedClient;
    if (sb == null) {
      _failuresCount++;
      _logUsage();
      return const PlacesSearchResult(
        status: PlacesSearchStatus.unavailable,
        errorMessage:
            'Location search is temporarily unavailable. You can enter the address manually.',
      );
    }

    final currentQueryId = ++_activeQueryId;

    try {
      final res = await sb.functions.invoke(
        'places-search',
        body: {
          'action': 'autocomplete',
          'query': trimmed,
          'input': trimmed,
          if (countryCode != null && countryCode.isNotEmpty)
            'countryCode': countryCode,
          if (sessionToken != null && sessionToken.isNotEmpty)
            'sessionToken': sessionToken,
          if (types != null && types.isNotEmpty) 'types': types,
        },
      ).timeout(const Duration(seconds: 8));

      // Discard stale response if a newer query has been dispatched
      if (currentQueryId != _activeQueryId) {
        return const PlacesSearchResult(
          status: PlacesSearchStatus.success,
          predictions: [],
        );
      }

      final data = res.data;
      if (data is Map) {
        final bool isConfigured =
            data['googleKeyConfigured'] ?? data['configured'] ?? true;
        if (!isConfigured) {
          _failuresCount++;
          _logUsage();
          debugPrint(
            '[GooglePlacesService] Google Places failed: GOOGLE_MAPS_API_KEY missing from Supabase Edge Function secrets',
          );
          return const PlacesSearchResult(
            status: PlacesSearchStatus.unavailable,
            errorMessage:
                'Location search is temporarily unavailable. You can enter the address manually.',
          );
        }

        final bool isOk = data['ok'] == true;
        final String? statusStr = data['status'] as String?;
        final String? errorStr =
            (data['error'] as String?) ?? (data['message'] as String?);

        // Distinguish legitimate ZERO_RESULTS from API failure (do not increment failures)
        if (statusStr == 'ZERO_RESULTS') {
          _autocompleteCount++;
          _logUsage();
          return const PlacesSearchResult(
            status: PlacesSearchStatus.zeroResults,
            predictions: [],
            errorMessage:
                'No matching locations found. Try another search or enter the address manually.',
          );
        }

        if (!isOk ||
            statusStr == 'REQUEST_DENIED' ||
            statusStr == 'OVER_QUERY_LIMIT' ||
            statusStr == 'PERMISSION_DENIED') {
          _failuresCount++;
          _logUsage();
          final failureLog = statusStr != null && statusStr.isNotEmpty
              ? (errorStr != null && errorStr.isNotEmpty
                  ? '$statusStr: $errorStr'
                  : statusStr)
              : (errorStr ?? 'API Failure');
          debugPrint('[GooglePlacesService] Google Places failed: $failureLog');
          return const PlacesSearchResult(
            status: PlacesSearchStatus.unavailable,
            errorMessage:
                'Location search is temporarily unavailable. You can enter the address manually.',
          );
        }

        if (data['predictions'] is List) {
          final list = (data['predictions'] as List)
              .map((p) =>
                  PlacePrediction.fromJson(Map<String, dynamic>.from(p as Map)))
              .take(5)
              .toList();

          _autocompleteCount++;
          _logUsage();

          if (list.isEmpty) {
            return const PlacesSearchResult(
              status: PlacesSearchStatus.zeroResults,
              predictions: [],
              errorMessage:
                  'No matching locations found. Try another search or enter the address manually.',
            );
          }

          _sessionCache[cacheKey] = list;
          return PlacesSearchResult(
            status: PlacesSearchStatus.success,
            predictions: list,
          );
        }
      }

      _failuresCount++;
      _logUsage();
      return const PlacesSearchResult(
        status: PlacesSearchStatus.unavailable,
        errorMessage:
            'Location search is temporarily unavailable. You can enter the address manually.',
      );
    } catch (e) {
      if (currentQueryId != _activeQueryId) {
        return const PlacesSearchResult(
          status: PlacesSearchStatus.success,
          predictions: [],
        );
      }
      debugPrint('[GooglePlacesService] searchPlaces error: $e');
      _failuresCount++;
      _logUsage();
      return const PlacesSearchResult(
        status: PlacesSearchStatus.unavailable,
        errorMessage:
            'Location search is temporarily unavailable. You can enter the address manually.',
      );
    }
  }

  /// Convenience wrapper returning `List<PlacePrediction>` for direct callers.
  Future<List<PlacePrediction>> searchPlaces({
    required String query,
    String? countryCode,
    String? sessionToken,
    String? types,
  }) async {
    final result = await searchPlacesWithResult(
      query: query,
      countryCode: countryCode,
      sessionToken: sessionToken,
      types: types,
    );
    return result.predictions;
  }

  /// Resolves Place Details through secure Supabase Edge Function.
  /// Calls only on explicit selection with minimal fields to control API costs.
  Future<PlaceDetails?> getPlaceDetails(
    String placeId, {
    String? sessionToken,
  }) async {
    if (mockDetails != null) {
      _detailsCount++;
      _logUsage();
      return mockDetails;
    }

    if (placeId.trim().isEmpty) return null;

    final sb = _resolvedClient;
    if (sb == null) {
      _failuresCount++;
      _logUsage();
      return null;
    }

    try {
      final res = await sb.functions.invoke(
        'places-search',
        body: {
          'action': 'details',
          'placeId': placeId.trim(),
          if (sessionToken != null && sessionToken.isNotEmpty)
            'sessionToken': sessionToken,
        },
      ).timeout(const Duration(seconds: 8));

      final data = res.data;
      if (data is Map && data['ok'] == true) {
        _detailsCount++;
        _logUsage();
        return PlaceDetails.fromJson(Map<String, dynamic>.from(data));
      }
      final detailError =
          (data is Map ? (data['error'] ?? data['status']) : null) ?? 'Unknown error';
      debugPrint('[GooglePlacesService] Google Place Details failed: $detailError');
      _failuresCount++;
      _logUsage();
      return null;
    } catch (e) {
      debugPrint('[GooglePlacesService] getPlaceDetails error: $e');
      _failuresCount++;
      _logUsage();
      return null;
    }
  }
}
