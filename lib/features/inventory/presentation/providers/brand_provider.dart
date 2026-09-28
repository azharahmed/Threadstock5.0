import 'package:flutter/foundation.dart';
import '../../data/brand_repository.dart';
import '../../domain/models/brand.dart';

/// Single shared provider for Brand data across ThreadStock (Create Product, Inventory, Purchasing, Filters).
class BrandProvider extends ChangeNotifier {
  final BrandRepository _repository;

  BrandProvider({BrandRepository? repository})
    : _repository = repository ?? BrandRepository();

  static BrandProvider? _sharedInstance;
  static BrandProvider get shared => _sharedInstance ??= BrandProvider();

  @visibleForTesting
  static void setSharedInstance(BrandProvider provider) {
    _sharedInstance = provider;
  }

  @visibleForTesting
  static void resetSharedInstance() {
    _sharedInstance = null;
  }

  List<Brand> _brands = [];
  List<Brand> get brands => List.unmodifiable(_brands);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _currentBusinessId;
  String? get currentBusinessId => _currentBusinessId;

  BrandRepository get repository => _repository;

  /// Loads brands for the specified or current business.
  Future<List<Brand>> loadBrands({
    String? businessId,
    bool forceRefresh = false,
  }) async {
    final targetBusinessId =
        businessId ?? await _repository.resolveCurrentBusinessId();
    if (!forceRefresh &&
        _currentBusinessId == targetBusinessId &&
        _brands.isNotEmpty &&
        !_isLoading) {
      return _brands;
    }

    _isLoading = true;
    _error = null;
    _currentBusinessId = targetBusinessId;
    notifyListeners();

    try {
      final list = await _repository.getBrands(businessId: targetBusinessId);
      _brands = list;
      _isLoading = false;
      notifyListeners();
      return _brands;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return _brands;
    }
  }

  /// Creates a new brand, persists to Supabase/repository, and refreshes the shared brand list.
  Future<Brand> createBrand({required String name, String? businessId}) async {
    final targetBusinessId =
        businessId ??
        _currentBusinessId ??
        await _repository.resolveCurrentBusinessId();
    final newBrand = await _repository.createBrand(
      name: name,
      businessId: targetBusinessId,
    );

    // Refresh brands list for the target business immediately
    await loadBrands(businessId: targetBusinessId, forceRefresh: true);
    return newBrand;
  }

  /// Clears brand cache (e.g. when switching businesses).
  void clear() {
    _brands = [];
    _isLoading = false;
    _error = null;
    _currentBusinessId = null;
    notifyListeners();
  }
}
