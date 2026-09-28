import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/business/current_business_service.dart';
import '../domain/inventory_change_notifier.dart';
import '../domain/models/stock_location.dart';

class LocationRepository {
  final SupabaseClient? client;

  LocationRepository({this.client});

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // In-memory local fallback store by businessId
  static final Map<String, List<StockLocation>>
  _localFallbackLocationsByBusiness = {};

  @visibleForTesting
  static void setLocationsForTesting(String businessId, List<StockLocation> locations) {
    _localFallbackLocationsByBusiness[businessId] = List.from(locations);
  }

  @visibleForTesting
  static void clearTestingLocations() {
    _localFallbackLocationsByBusiness.clear();
  }


  // Persistent disk cache file for surviving restarts in offline / local development mode
  static File? _resolveCacheFile() {
    try {
      final configDir = Directory('config');
      if (!configDir.existsSync()) {
        configDir.createSync(recursive: true);
      }
      return File('config/locations_cache.json');
    } catch (_) {
      return null;
    }
  }

  static void _saveToDiskCache(
    String businessId,
    List<StockLocation> locations,
  ) {
    try {
      final file = _resolveCacheFile();
      if (file == null) return;

      Map<String, dynamic> data = {};
      if (file.existsSync()) {
        try {
          final content = file.readAsStringSync();
          if (content.isNotEmpty) {
            data = jsonDecode(content) as Map<String, dynamic>;
          }
        } catch (_) {}
      }

      data[businessId] = locations.map((l) => l.toJson()).toList();
      file.writeAsStringSync(jsonEncode(data), flush: true);
    } catch (e) {
      debugPrint('Error saving locations cache: $e');
    }
  }

  static List<StockLocation>? _loadFromDiskCache(String businessId) {
    try {
      final file = _resolveCacheFile();
      if (file == null || !file.existsSync()) return null;

      final content = file.readAsStringSync();
      if (content.isEmpty) return null;

      final data = jsonDecode(content) as Map<String, dynamic>;
      final listJson = data[businessId] as List<dynamic>?;
      if (listJson == null) return null;

      return listJson
          .map(
            (row) =>
                StockLocation.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading locations cache: $e');
      return null;
    }
  }

  /// Resolves the active business ID for the current authenticated user or returns fallback.
  Future<String?> resolveCurrentBusinessId() async {
    final centralId = CurrentBusinessService.instance.currentBusinessId;
    if (centralId != null &&
        centralId.isNotEmpty &&
        !centralId.startsWith('biz_')) {
      return centralId;
    }

    final sb = _resolvedClient;
    if (sb == null) return 'default_business';
    final user = sb.auth.currentUser;
    if (user == null) {
      try {
        final biz = await sb
            .from('businesses')
            .select('id')
            .limit(1)
            .maybeSingle();
        final id = biz?['id'] as String?;
        if (id != null && id.isNotEmpty) return id;
      } catch (_) {}
      return 'default_business';
    }

    try {
      final membership = await sb
          .from('memberships')
          .select('business_id')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();

      final businessId = membership?['business_id'] as String?;
      if (businessId != null && businessId.isNotEmpty) {
        return businessId;
      }

      final business = await sb
          .from('businesses')
          .select('id')
          .eq('owner_user_id', user.id)
          .limit(1)
          .maybeSingle();

      return business?['id'] as String? ?? 'default_business';
    } catch (e) {
      debugPrint('Error resolving business_id: $e');
      return 'default_business';
    }
  }

  /// Fetches all active locations for the specified business. Starts with 0 locations.
  Future<List<StockLocation>> getLocations({
    String? businessId,
    bool onlyActive = true,
  }) async {
    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';
    final sb = _resolvedClient;

    // Load from disk cache if not already in memory
    if (!_localFallbackLocationsByBusiness.containsKey(resolvedBusinessId)) {
      final diskList = _loadFromDiskCache(resolvedBusinessId);
      if (diskList != null) {
        _localFallbackLocationsByBusiness[resolvedBusinessId] = diskList;
      }
    }

    if (sb == null || sb.auth.currentUser == null) {
      final all =
          _localFallbackLocationsByBusiness[resolvedBusinessId] ?? const [];
      return onlyActive
          ? all.where((l) => l.status == 'active').toList()
          : List<StockLocation>.from(all);
    }

    try {
      var query = sb
          .from('locations')
          .select()
          .eq('business_id', resolvedBusinessId);

      if (onlyActive) {
        query = query.eq('status', 'active');
      }

      final response = await query.order('name', ascending: true);
      final remoteList = (response as List)
          .map((row) => StockLocation.fromJson(row as Map<String, dynamic>))
          .toList();
      _localFallbackLocationsByBusiness[resolvedBusinessId] = remoteList;
      _saveToDiskCache(resolvedBusinessId, remoteList);
      return remoteList;
    } catch (e) {
      debugPrint('Error fetching locations from Supabase: $e');
      final all =
          _localFallbackLocationsByBusiness[resolvedBusinessId] ?? const [];
      return onlyActive
          ? all.where((l) => l.status == 'active').toList()
          : List<StockLocation>.from(all);
    }
  }

  static String normalizeLocationType(String type) {
    final lower = type.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    if (lower.contains('store') || lower.contains('retail') || lower.contains('flagship') || lower.contains('boutique')) {
      return 'retail_store';
    }
    if (lower.contains('showroom')) {
      return 'showroom';
    }
    if (lower.contains('hub') || lower.contains('distribution')) {
      return 'distribution_hub';
    }
    if (lower.contains('pop')) {
      return 'pop_up';
    }
    if (lower.contains('office') || lower.contains('headquarters')) {
      return 'office';
    }
    if (lower.contains('warehouse') || lower.contains('stockroom') || lower.contains('storage')) {
      return 'warehouse';
    }
    const allowed = ['retail_store', 'warehouse', 'showroom', 'distribution_hub', 'pop_up', 'office'];
    if (allowed.contains(lower)) return lower;
    return 'retail_store';
  }

  /// Creates a new location for the business in Supabase.
  Future<StockLocation> createLocation({
    required String name,
    String locationType = 'warehouse',
    String? businessId,
    String? streetAddress,
    String? city,
    String? postalCode,
    String? countryCode,
    String? timezone,
    String? googlePlaceId,
    double? latitude,
    double? longitude,
    String? formattedAddress,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Enter a location name.');
    }

    final normalizedType = normalizeLocationType(locationType);
    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';

    // Verify duplicate within same business (case-insensitive and trimmed)
    final currentLocations = await getLocations(
      businessId: resolvedBusinessId,
      onlyActive: false,
    );
    if (currentLocations.any(
      (l) => l.name.trim().toLowerCase() == trimmedName.toLowerCase(),
    )) {
      throw StateError('A location with this name already exists.');
    }

    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final payload = <String, dynamic>{
          'business_id': resolvedBusinessId,
          'name': trimmedName,
          'location_type': normalizedType,
          'status': 'active',
        };
        if (streetAddress != null && streetAddress.trim().isNotEmpty) {
          payload['street_address'] = streetAddress.trim();
        }
        if (city != null && city.trim().isNotEmpty) {
          payload['city'] = city.trim();
        }
        if (postalCode != null && postalCode.trim().isNotEmpty) {
          payload['postal_code'] = postalCode.trim();
        }
        if (countryCode != null && countryCode.trim().isNotEmpty) {
          payload['country_code'] = countryCode.trim().toUpperCase();
        }
        if (timezone != null && timezone.trim().isNotEmpty) {
          payload['timezone'] = timezone.trim();
        }
        if (googlePlaceId != null && googlePlaceId.trim().isNotEmpty) {
          payload['google_place_id'] = googlePlaceId.trim();
        }
        if (latitude != null) {
          payload['latitude'] = latitude;
        }
        if (longitude != null) {
          payload['longitude'] = longitude;
        }
        if (formattedAddress != null && formattedAddress.trim().isNotEmpty) {
          payload['formatted_address'] = formattedAddress.trim();
        }

        Map<String, dynamic>? inserted;
        try {
          inserted = await sb
              .from('locations')
              .insert(payload)
              .select()
              .single();
        } on PostgrestException catch (pe) {
          // If remote schema does not yet have Google columns (migration prepared but not deployed),
          // fallback to inserting standard columns
          if (pe.code == '42703' || pe.message.toLowerCase().contains('column')) {
            final fallbackPayload = Map<String, dynamic>.from(payload)
              ..remove('google_place_id')
              ..remove('latitude')
              ..remove('longitude')
              ..remove('formatted_address');
            inserted = await sb
                .from('locations')
                .insert(fallbackPayload)
                .select()
                .single();
          } else {
            rethrow;
          }
        }

        var location = StockLocation.fromJson(inserted);
        // Ensure local instance retains coordinates and place identity
        location = location.copyWith(
          googlePlaceId: googlePlaceId?.trim(),
          latitude: latitude,
          longitude: longitude,
          formattedAddress: formattedAddress?.trim(),
        );

        final list = _localFallbackLocationsByBusiness.putIfAbsent(
          resolvedBusinessId,
          () => [],
        );
        list.removeWhere((l) => l.id == location.id);
        list.add(location);
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        _saveToDiskCache(resolvedBusinessId, list);
        InventoryChangeNotifier.instance.notifyInventoryChanged();
        return location;
      } on PostgrestException catch (pe) {
        debugPrint(
          'PostgrestException insert location: ${pe.code} - ${pe.message}',
        );
        if (pe.code == '23505' ||
            pe.message.toLowerCase().contains('unique') ||
            pe.message.toLowerCase().contains('duplicate')) {
          throw StateError('A location with this name already exists.');
        }
        throw Exception("We couldn't save this location. Please try again.");
      } catch (e) {
        debugPrint('Supabase insert location error: $e');
        if (e is StateError || e is ArgumentError) rethrow;
        throw Exception("We couldn't save this location. Please try again.");
      }
    }

    // Fallback when Supabase client is not configured (e.g. unit tests without remote connection)
    final newLocation = StockLocation(
      id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
      businessId: resolvedBusinessId,
      name: trimmedName,
      locationType: normalizedType,
      status: 'active',
      streetAddress: streetAddress?.trim(),
      city: city?.trim(),
      postalCode: postalCode?.trim(),
      countryCode: countryCode?.trim().toUpperCase(),
      timezone: timezone?.trim(),
      googlePlaceId: googlePlaceId?.trim(),
      latitude: latitude,
      longitude: longitude,
      formattedAddress: formattedAddress?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final list = _localFallbackLocationsByBusiness.putIfAbsent(
      resolvedBusinessId,
      () => [],
    );
    list.add(newLocation);
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _saveToDiskCache(resolvedBusinessId, list);
    InventoryChangeNotifier.instance.notifyInventoryChanged();
    return newLocation;
  }

  /// Updates status of a location and notifies listeners across the app.
  Future<void> updateLocationStatus({
    required String locationId,
    required String status,
    String? businessId,
  }) async {
    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';
    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        await sb
            .from('locations')
            .update({
              'status': status,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', locationId)
            .eq('business_id', resolvedBusinessId);
      } catch (e) {
        debugPrint('Supabase update location error: $e');
      }
    }

    final list = _localFallbackLocationsByBusiness[resolvedBusinessId];
    if (list != null) {
      final idx = list.indexWhere((l) => l.id == locationId);
      if (idx >= 0) {
        list[idx] = list[idx].copyWith(status: status);
        _saveToDiskCache(resolvedBusinessId, list);
      }
    }
    InventoryChangeNotifier.instance.notifyInventoryChanged();
  }

  @visibleForTesting
  static void setMockLocations(String businessId, List<StockLocation> locations) {
    _localFallbackLocationsByBusiness[businessId] = List.from(locations);
    _saveToDiskCache(businessId, locations);
    InventoryChangeNotifier.instance.notifyInventoryChanged();
  }

  /// Purges in-memory location fallback store and disk cache across sign-out.
  static void clearCache() => clearLocalState();

  @visibleForTesting
  static void clearLocalState() {
    _localFallbackLocationsByBusiness.clear();
    try {
      final file = _resolveCacheFile();
      if (file != null && file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }
}
