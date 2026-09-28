import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/business/current_business_service.dart';
import '../../onboarding/data/onboarding_repository.dart';
import '../domain/models/brand.dart';

class BrandRepository {
  final SupabaseClient? client;
  BrandRepository({this.client});

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // In-memory local fallback store by businessId
  static final Map<String, List<Brand>> _localFallbackBrandsByBusiness = {};

  // Persistent disk cache file for surviving restarts in offline / local development mode
  static File? _resolveCacheFile() {
    try {
      final configDir = Directory('config');
      if (!configDir.existsSync()) {
        configDir.createSync(recursive: true);
      }
      return File('config/brands_cache.json');
    } catch (_) {
      return null;
    }
  }

  static void _saveToDiskCache(String businessId, List<Brand> brands) {
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

      data[businessId] = brands.map((b) => b.toJson()).toList();
      file.writeAsStringSync(jsonEncode(data), flush: true);
    } catch (e) {
      debugPrint('Error saving brands cache: $e');
    }
  }

  static List<Brand>? _loadFromDiskCache(String businessId) {
    try {
      final file = _resolveCacheFile();
      if (file == null || !file.existsSync()) return null;

      final content = file.readAsStringSync();
      if (content.isEmpty) return null;

      final data = jsonDecode(content) as Map<String, dynamic>;
      final listJson = data[businessId] as List<dynamic>?;
      if (listJson == null) return null;

      return listJson
          .map((row) => Brand.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (e) {
      debugPrint('Error loading brands cache: $e');
      return null;
    }
  }

  /// Resolves the active business ID for the current authenticated user.
  Future<String?> resolveCurrentBusinessId() async {
    // 1. Check central business service
    final centralId = CurrentBusinessService.instance.currentBusinessId;
    if (centralId != null &&
        centralId.isNotEmpty &&
        !centralId.startsWith('biz_')) {
      return centralId;
    }

    // 2. Check onboarding progress
    final progressId = OnboardingRepository.instance.currentProgress.businessId;
    if (progressId != null &&
        progressId.isNotEmpty &&
        !progressId.startsWith('biz_')) {
      CurrentBusinessService.instance.setCurrentBusinessId(progressId);
      return progressId;
    }

    // 3. Query Supabase via CurrentBusinessService
    final resolved = await CurrentBusinessService.instance
        .resolveCurrentBusinessId();
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }

    final sb = _resolvedClient;
    if (sb == null) {
      // In offline / mock test environments without Supabase
      return centralId ?? progressId ?? 'default_business';
    }

    return null;
  }

  /// Fetches all brands for the specified business. Starts with 0 brands.
  Future<List<Brand>> getBrands({String? businessId}) async {
    final resolvedBusinessId = businessId ?? await resolveCurrentBusinessId();
    if (resolvedBusinessId == null || resolvedBusinessId.isEmpty) {
      return const [];
    }

    final sb = _resolvedClient;

    // First ensure disk cache is loaded into memory if available
    if (!_localFallbackBrandsByBusiness.containsKey(resolvedBusinessId)) {
      final diskList = _loadFromDiskCache(resolvedBusinessId);
      if (diskList != null) {
        _localFallbackBrandsByBusiness[resolvedBusinessId] = diskList;
      }
    }

    if (sb == null || resolvedBusinessId == 'default_business') {
      return List<Brand>.from(
        _localFallbackBrandsByBusiness[resolvedBusinessId] ?? const [],
      );
    }

    try {
      final response = await sb
          .from('brands')
          .select()
          .eq('business_id', resolvedBusinessId)
          .order('name', ascending: true);

      final remoteList = (response as List)
          .map((row) => Brand.fromJson(row as Map<String, dynamic>))
          .toList();
      _localFallbackBrandsByBusiness[resolvedBusinessId] = remoteList;
      _saveToDiskCache(resolvedBusinessId, remoteList);
      return remoteList;
    } catch (e) {
      debugPrint(
        '[BrandRepository.getBrands] Error fetching brands from Supabase: $e',
      );
      return List<Brand>.from(
        _localFallbackBrandsByBusiness[resolvedBusinessId] ?? const [],
      );
    }
  }

  /// Creates a new brand for the business in Supabase.
  Future<Brand> createBrand({required String name, String? businessId}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Enter a brand name.');
    }

    final resolvedBusinessId = businessId ?? await resolveCurrentBusinessId();
    if (resolvedBusinessId == null || resolvedBusinessId.isEmpty) {
      debugPrint(
        '[BrandRepository.createBrand] Cannot save brand: No active business context found for current user.',
      );
      throw StateError(
        'No active business found. Please complete business setup first.',
      );
    }

    // Verify duplicate within same business (case-insensitive and trimmed)
    final currentBrands = await getBrands(businessId: resolvedBusinessId);
    if (currentBrands.any(
      (b) => b.name.trim().toLowerCase() == trimmedName.toLowerCase(),
    )) {
      throw StateError('A brand with this name already exists.');
    }

    final sb = _resolvedClient;
    if (sb != null && resolvedBusinessId != 'default_business') {
      try {
        final inserted = await sb
            .from('brands')
            .insert({'business_id': resolvedBusinessId, 'name': trimmedName})
            .select()
            .single();

        final brand = Brand.fromJson(inserted);
        final list = _localFallbackBrandsByBusiness.putIfAbsent(
          resolvedBusinessId,
          () => [],
        );
        list.removeWhere((b) => b.id == brand.id);
        list.add(brand);
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        _saveToDiskCache(resolvedBusinessId, list);
        return brand;
      } on PostgrestException catch (pe) {
        final code = pe.code;
        final message = pe.message;
        final details = pe.details?.toString() ?? '';
        debugPrint(
          '[BrandRepository.createBrand] PostgrestException [table: brands, op: insert]: '
          'code=$code, message=$message, details=$details, hint=${pe.hint}',
        );

        if (code == '23505' ||
            message.toLowerCase().contains('unique') ||
            message.toLowerCase().contains('duplicate') ||
            details.toLowerCase().contains('already exists')) {
          throw StateError('A brand with this name already exists.');
        }

        if (code == '42501' ||
            message.toLowerCase().contains('row-level security') ||
            message.toLowerCase().contains('policy')) {
          debugPrint(
            '[BrandRepository.createBrand] RLS policy violation: User ${sb.auth.currentUser?.id} '
            'is not an owner or active member of business $resolvedBusinessId.',
          );
        }

        // Return concise user-facing error while maintaining sanitized logs
        throw Exception("We couldn't save this brand. Please try again.");
      } catch (e, st) {
        debugPrint(
          '[BrandRepository.createBrand] Unexpected error inserting brand: $e\n$st',
        );
        if (e is StateError || e is ArgumentError) rethrow;
        throw Exception("We couldn't save this brand. Please try again.");
      }
    }

    // Fallback when Supabase client is not configured or in mock test mode
    final newBrand = Brand(
      id: 'brand_${DateTime.now().millisecondsSinceEpoch}',
      businessId: resolvedBusinessId,
      name: trimmedName,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final list = _localFallbackBrandsByBusiness.putIfAbsent(
      resolvedBusinessId,
      () => [],
    );
    list.add(newBrand);
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _saveToDiskCache(resolvedBusinessId, list);
    return newBrand;
  }

  @visibleForTesting
  static void clearLocalState() {
    _localFallbackBrandsByBusiness.clear();
    try {
      final file = _resolveCacheFile();
      if (file != null && file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {}
  }
}
