import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/business/current_business_service.dart';
import '../domain/models/product_category.dart';

class CategoryRepository {
  final SupabaseClient? client;

  CategoryRepository({this.client});

  SupabaseClient? get _resolvedClient {
    if (client != null) return client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // In-memory local fallback store by businessId (for offline / unauthenticated preview / tests)
  static final Map<String, List<ProductCategory>>
  _localFallbackCategoriesByBusiness = {};

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
    if (user == null) return 'default_business';

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

      // Check owned business
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

  /// Fetches all categories for the current or given business. Starts with 0 categories.
  Future<List<ProductCategory>> getCategories({String? businessId}) async {
    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';
    final sb = _resolvedClient;

    if (sb == null || sb.auth.currentUser == null) {
      return List<ProductCategory>.from(
        _localFallbackCategoriesByBusiness[resolvedBusinessId] ?? const [],
      );
    }

    try {
      final response = await sb
          .from('categories')
          .select()
          .eq('business_id', resolvedBusinessId)
          .order('name', ascending: true);

      final remoteList = (response as List)
          .map((row) => ProductCategory.fromJson(row as Map<String, dynamic>))
          .toList();
      _localFallbackCategoriesByBusiness[resolvedBusinessId] = remoteList;
      return remoteList;
    } catch (e) {
      debugPrint('Error fetching categories from Supabase: $e');
      return List<ProductCategory>.from(
        _localFallbackCategoriesByBusiness[resolvedBusinessId] ?? const [],
      );
    }
  }

  /// Creates a new category for the business in Supabase.
  Future<ProductCategory> createCategory({
    required String name,
    String? businessId,
    String? parentCategoryId,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Enter a category name.');
    }

    final resolvedBusinessId =
        businessId ?? await resolveCurrentBusinessId() ?? 'default_business';

    // Verify duplicate within same business
    final currentCategories = await getCategories(
      businessId: resolvedBusinessId,
    );
    if (currentCategories.any(
      (c) => c.name.trim().toLowerCase() == trimmedName.toLowerCase(),
    )) {
      throw StateError('A category with this name already exists.');
    }

    final sb = _resolvedClient;
    if (sb != null && sb.auth.currentUser != null) {
      try {
        final payload = <String, dynamic>{
          'business_id': resolvedBusinessId,
          'name': trimmedName,
        };
        if (parentCategoryId != null) {
          payload['parent_category_id'] = parentCategoryId;
        }
        final inserted = await sb
            .from('categories')
            .insert(payload)
            .select()
            .single();

        final cat = ProductCategory.fromJson(inserted);
        final list = _localFallbackCategoriesByBusiness.putIfAbsent(
          resolvedBusinessId,
          () => [],
        );
        list.removeWhere((c) => c.id == cat.id);
        list.add(cat);
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        return cat;
      } catch (e) {
        debugPrint('Supabase insert category error: $e');
        rethrow;
      }
    }

    // Fallback when Supabase is not logged in / testing
    final newCategory = ProductCategory(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      businessId: resolvedBusinessId,
      name: trimmedName,
      parentCategoryId: parentCategoryId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final list = _localFallbackCategoriesByBusiness.putIfAbsent(
      resolvedBusinessId,
      () => [],
    );
    list.add(newCategory);
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return newCategory;
  }

  @visibleForTesting
  static void clearLocalState() {
    _localFallbackCategoriesByBusiness.clear();
  }
}
