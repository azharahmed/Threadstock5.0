import 'package:flutter/foundation.dart';
import '../../data/category_repository.dart';
import '../../domain/models/product_category.dart';

/// Single shared provider for Category data across ThreadStock (Create Product, Catalog Manager, Filters).
class CategoryProvider extends ChangeNotifier {
  final CategoryRepository _repository;

  CategoryProvider({CategoryRepository? repository})
    : _repository = repository ?? CategoryRepository();

  static CategoryProvider? _sharedInstance;
  static CategoryProvider get shared => _sharedInstance ??= CategoryProvider();

  @visibleForTesting
  static void setSharedInstance(CategoryProvider provider) {
    _sharedInstance = provider;
  }

  @visibleForTesting
  static void resetSharedInstance() {
    _sharedInstance = null;
  }

  List<ProductCategory> _categories = [];
  List<ProductCategory> get categories => List.unmodifiable(_categories);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _currentBusinessId;
  String? get currentBusinessId => _currentBusinessId;

  CategoryRepository get repository => _repository;

  /// Loads categories for the specified or current business.
  Future<List<ProductCategory>> loadCategories({
    String? businessId,
    bool forceRefresh = false,
  }) async {
    final targetBusinessId =
        businessId ?? await _repository.resolveCurrentBusinessId();
    if (!forceRefresh &&
        _currentBusinessId == targetBusinessId &&
        _categories.isNotEmpty &&
        !_isLoading) {
      return _categories;
    }

    _isLoading = true;
    _error = null;
    _currentBusinessId = targetBusinessId;
    notifyListeners();

    try {
      final list = await _repository.getCategories(
        businessId: targetBusinessId,
      );
      _categories = list;
      _isLoading = false;
      notifyListeners();
      return _categories;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return _categories;
    }
  }

  /// Creates a new category, persists to Supabase/repository, and refreshes the shared category list.
  Future<ProductCategory> createCategory({
    required String name,
    String? businessId,
    String? parentCategoryId,
  }) async {
    final targetBusinessId =
        businessId ??
        _currentBusinessId ??
        await _repository.resolveCurrentBusinessId();
    final newCategory = await _repository.createCategory(
      name: name,
      businessId: targetBusinessId,
      parentCategoryId: parentCategoryId,
    );

    // Refresh categories list for the target business immediately
    await loadCategories(businessId: targetBusinessId, forceRefresh: true);
    return newCategory;
  }

  /// Clears category cache (e.g. when switching businesses).
  void clear() {
    _categories = [];
    _isLoading = false;
    _error = null;
    _currentBusinessId = null;
    notifyListeners();
  }
}
