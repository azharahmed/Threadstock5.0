import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/brand_repository.dart';
import '../../data/category_repository.dart';
import '../../data/location_repository.dart';
import '../../data/product_media_repository.dart';
import '../../data/product_repository.dart';
import '../../data/supplier_repository.dart';
import '../../domain/models/brand.dart';
import '../../domain/models/product.dart';
import '../../domain/models/product_category.dart';
import '../../domain/models/product_image_item.dart';
import '../../domain/models/stock_location.dart';
import '../../domain/models/supplier.dart';
import '../../domain/models/product_variant.dart';
import '../../../../core/widgets/safe_image.dart';
import '../../../../core/business/current_business_service.dart';
import '../providers/brand_provider.dart';
import '../providers/category_provider.dart';

class CreateNewProductView extends StatefulWidget {
  const CreateNewProductView({
    super.key,
    this.onSaveDraft,
    this.onPublishProduct,
    this.onBack,
    this.brandRepository,
    this.brandProvider,
    this.categoryRepository,
    this.categoryProvider,
    this.mediaRepository,
    this.productRepository,
    this.supplierRepository,
    this.locationRepository,
    this.initialProductId,
    this.businessId,
    this.onPublishSuccess,
    this.onDraftSaved,
  });

  final VoidCallback? onSaveDraft;
  final FutureOr<void> Function()? onPublishProduct;
  final VoidCallback? onBack;
  final BrandRepository? brandRepository;
  final BrandProvider? brandProvider;
  final CategoryRepository? categoryRepository;
  final CategoryProvider? categoryProvider;
  final ProductMediaRepository? mediaRepository;
  final ProductRepository? productRepository;
  final SupplierRepository? supplierRepository;
  final LocationRepository? locationRepository;
  final String? initialProductId;
  final String? businessId;
  final ValueChanged<Product>? onPublishSuccess;
  final ValueChanged<Product>? onDraftSaved;

  @override
  State<CreateNewProductView> createState() => _CreateNewProductViewState();
}

class _CreateNewProductViewState extends State<CreateNewProductView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _retailPriceController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _openingStockController = TextEditingController();
  final TextEditingController _reorderPointController = TextEditingController();

  late final BrandProvider _brandProvider;
  List<Brand> _brands = [];
  bool _isLoadingBrands = true;
  String? _selectedBrandId;
  String? _selectedBrand;
  String? _brandError;

  late final CategoryProvider _categoryProvider;
  List<ProductCategory> _categories = [];
  bool _isLoadingCategories = true;
  String? _selectedCategoryId;
  String? _selectedCategory;
  String? _categoryError;

  late final ProductMediaRepository _mediaRepository;
  final List<ProductImageItem> _images = [];
  int _selectedImageIndex = 0;
  bool _isPickingImages = false;

  late final SupplierRepository _supplierRepository;
  List<Supplier> _suppliers = [];
  bool _isLoadingSuppliers = false;
  String? _selectedSupplierId;
  String? _selectedSupplier;
  String? _supplierError;

  String? _selectedTaxCategory;
  String? _taxCategoryError;

  String? _nameError;
  String? _pricingError;
  String? _skuError;

  late final ProductRepository _productRepository;
  String? _savedProductId;
  bool _isSavingDraft = false;
  bool _isPublishing = false;
  Map<String, dynamic>? _lastSavedSnapshot;

  final List<String> _tags = [];

  bool _trackStockLevels = true;
  late final LocationRepository _locationRepository;
  List<StockLocation> _locations = [];
  bool _isLoadingLocations = true;
  String? _selectedLocationId;
  String? _selectedLocationName;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _brandProvider =
        widget.brandProvider ??
        (widget.brandRepository != null
            ? BrandProvider(repository: widget.brandRepository)
            : BrandProvider.shared);
    _brands = _brandProvider.brands;
    _isLoadingBrands = _brands.isEmpty;
    _brandProvider.addListener(_onBrandProviderChanged);

    _categoryProvider =
        widget.categoryProvider ??
        (widget.categoryRepository != null
            ? CategoryProvider(repository: widget.categoryRepository)
            : CategoryProvider.shared);
    _categories = _categoryProvider.categories;
    _isLoadingCategories = _categories.isEmpty;
    _categoryProvider.addListener(_onCategoryProviderChanged);

    _mediaRepository = widget.mediaRepository ?? ProductMediaRepository();
    _supplierRepository = widget.supplierRepository ?? SupplierRepository();
    _locationRepository = widget.locationRepository ?? LocationRepository();
    _productRepository = widget.productRepository ?? ProductRepository();
    _savedProductId = widget.initialProductId;
    _loadBrands();
    _loadCategories();
    _loadSuppliers();
    _loadLocations();
    if (widget.initialProductId != null &&
        widget.initialProductId!.isNotEmpty) {
      _loadInitialProductData();
    } else {
      _lastSavedSnapshot = _takeFormSnapshot();
    }
  }

  void _onBrandProviderChanged() {
    if (!mounted) return;
    setState(() {
      _brands = _brandProvider.brands;
      _isLoadingBrands = _brandProvider.isLoading;
      if (_selectedBrandId != null &&
          !_brands.any((b) => b.id == _selectedBrandId)) {
        _selectedBrandId = null;
        _selectedBrand = null;
      }
    });
  }

  void _onCategoryProviderChanged() {
    if (!mounted) return;
    setState(() {
      _categories = _categoryProvider.categories;
      _isLoadingCategories = _categoryProvider.isLoading;
      if (_selectedCategoryId != null &&
          !_categories.any((c) => c.id == _selectedCategoryId)) {
        _selectedCategoryId = null;
        _selectedCategory = null;
      }
    });
  }

  Future<void> _loadBrands() async {
    try {
      final list = await _brandProvider.loadBrands(
        businessId: widget.businessId,
      );
      if (!mounted) return;
      setState(() {
        _brands = list;
        _isLoadingBrands = false;
        if (_selectedBrandId != null &&
            !_brands.any((b) => b.id == _selectedBrandId)) {
          _selectedBrandId = null;
          _selectedBrand = null;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingBrands = false);
      }
    }
  }

  Future<void> _loadCategories() async {
    try {
      final list = await _categoryProvider.loadCategories(
        businessId: widget.businessId,
      );
      if (!mounted) return;
      setState(() {
        _categories = list;
        _isLoadingCategories = false;
        if (_selectedCategoryId != null &&
            !_categories.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = null;
          _selectedCategory = null;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingCategories = false);
      }
    }
  }

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  Future<void> _loadSuppliers() async {
    setState(() => _isLoadingSuppliers = true);
    try {
      final list = await _supplierRepository.getSuppliers(
        businessId: widget.businessId,
      );
      if (!mounted) return;
      setState(() {
        _suppliers = list;
        _isLoadingSuppliers = false;
        if (_selectedSupplierId != null) {
          final matched = _suppliers
              .where((s) => s.id == _selectedSupplierId)
              .firstOrNull;
          if (matched != null) {
            _selectedSupplier = matched.name;
          } else {
            _selectedSupplierId = null;
            _selectedSupplier = null;
          }
        } else if (_selectedSupplier != null) {
          final matched = _suppliers
              .where((s) => s.name == _selectedSupplier)
              .firstOrNull;
          if (matched != null) {
            _selectedSupplierId = matched.id;
          }
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSuppliers = false);
      }
    }
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoadingLocations = true;
      _locationError = null;
    });

    try {
      final locs = await _locationRepository.getLocations(
        businessId: widget.businessId,
        onlyActive: true,
      );
      if (!mounted) return;
      setState(() {
        _locations = locs;
        _isLoadingLocations = false;
        if (locs.length == 1) {
          _selectedLocationId = locs.first.id;
          _selectedLocationName = locs.first.name;
        } else if (_selectedLocationId != null &&
            !locs.any((l) => l.id == _selectedLocationId)) {
          _selectedLocationId = null;
          _selectedLocationName = null;
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
        });
      }
    }
  }

  Future<void> _loadInitialProductData() async {
    final pid = widget.initialProductId;
    if (pid == null || pid.isEmpty) return;

    try {
      final details = await _productRepository.getProductDetails(pid);
      if (details != null && mounted) {
        final prod = details['product'] as Product?;
        final variants = (details['variants'] as List<ProductVariant>?) ?? [];
        final mediaList = (details['media'] as List<ProductImageItem>?) ?? [];

        if (prod != null) {
          _nameController.text = prod.name;
          _descriptionController.text = prod.description ?? '';
          _selectedBrandId = prod.brandId;
          _selectedCategoryId = prod.categoryId;
          _selectedSupplierId = prod.supplierId;
          _selectedTaxCategory = prod.taxCategory;
          _tags.clear();
          _tags.addAll(prod.tags);
          _trackStockLevels = prod.trackStockLevels;
          if (prod.lowStockThreshold != null) {
            _reorderPointController.text = prod.lowStockThreshold.toString();
          }
        }

        if (variants.isNotEmpty) {
          final v = variants.first;
          _skuController.text = v.sku;
          _barcodeController.text = v.barcode ?? '';
          if (v.costPriceCents > 0) {
            _costPriceController.text =
                (v.costPriceCents / 100).toStringAsFixed(2);
          }
          if (v.retailPriceCents > 0) {
            _retailPriceController.text =
                (v.retailPriceCents / 100).toStringAsFixed(2);
          }
        }

        if (mediaList.isNotEmpty) {
          _images.clear();
          _images.addAll(mediaList);
        } else {
          final fallback =
              ProductMediaRepository.instance.getMediaForProduct(pid);
          if (fallback.isNotEmpty) {
            _images.clear();
            _images.addAll(fallback);
          }
        }

        setState(() {
          _lastSavedSnapshot = _takeFormSnapshot();
        });
      }
    } catch (e) {
      debugPrint('[CreateNewProductView] Error loading initial product: $e');
    }
  }

  @override
  void dispose() {
    _brandProvider.removeListener(_onBrandProviderChanged);
    _categoryProvider.removeListener(_onCategoryProviderChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _retailPriceController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _openingStockController.dispose();
    _reorderPointController.dispose();
    super.dispose();
  }

  String get _calculatedMarginDisplay {
    final costStr = _costPriceController.text.replaceAll(',', '').trim();
    final retailStr = _retailPriceController.text.replaceAll(',', '').trim();
    if (costStr.isEmpty || retailStr.isEmpty) return '—';
    final cost = double.tryParse(costStr);
    final retail = double.tryParse(retailStr);
    if (cost == null || retail == null) return '—';
    if (retail <= 0 || cost < 0) return '—';
    final margin = ((retail - cost) / retail) * 100;
    return '${margin.toStringAsFixed(2)}%';
  }

  Map<String, dynamic> _takeFormSnapshot() {
    return {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'cost': _costPriceController.text.trim(),
      'retail': _retailPriceController.text.trim(),
      'sku': _skuController.text.trim(),
      'barcode': _barcodeController.text.trim(),
      'brandId': _selectedBrandId ?? _selectedBrand,
      'categoryId': _selectedCategoryId ?? _selectedCategory,
      'supplierId': _selectedSupplierId ?? _selectedSupplier,
      'taxCategory': _selectedTaxCategory,
      'imagesCount': _images.length,
      'tagsCount': _tags.length,
      'trackStock': _trackStockLevels,
      'locationId': _selectedLocationId,
      'openingStock': _openingStockController.text.trim(),
      'reorderPoint': _reorderPointController.text.trim(),
    };
  }

  bool get _isFormBlank =>
      _nameController.text.trim().isEmpty &&
      _descriptionController.text.trim().isEmpty &&
      _costPriceController.text.trim().isEmpty &&
      _retailPriceController.text.trim().isEmpty &&
      _skuController.text.trim().isEmpty &&
      _barcodeController.text.trim().isEmpty &&
      _openingStockController.text.trim().isEmpty &&
      _reorderPointController.text.trim().isEmpty &&
      _images.isEmpty &&
      _tags.isEmpty;

  bool get _hasUnsavedWork {
    if (_isFormBlank) {
      return false;
    }
    if (_lastSavedSnapshot != null) {
      final current = _takeFormSnapshot();
      for (final key in current.keys) {
        if (current[key] != _lastSavedSnapshot![key]) {
          return true;
        }
      }
      return false;
    }
    return true;
  }

  Future<void> _handleSaveDraft() async {
    if (_isSavingDraft || _isPublishing) return;

    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      setState(() => _nameError = 'Enter a product name.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a product name to save draft.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final costStr = _costPriceController.text.replaceAll(',', '').trim();
    final retailStr = _retailPriceController.text.replaceAll(',', '').trim();
    final costVal = costStr.isNotEmpty ? double.tryParse(costStr) : null;
    final retailVal = retailStr.isNotEmpty ? double.tryParse(retailStr) : null;

    if (costVal != null && costVal < 0) {
      setState(() => _pricingError = 'Unit cost cannot be negative.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unit cost cannot be negative.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (retailVal != null && retailVal < 0) {
      setState(() => _pricingError = 'Selling price cannot be negative.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selling price cannot be negative.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSavingDraft = true;
      _nameError = null;
      _pricingError = null;
    });

    try {
      final costCents = costVal != null ? (costVal * 100).round() : 0;
      final retailCents = retailVal != null ? (retailVal * 100).round() : 0;

      String? draftSupplierId = _selectedSupplierId;
      if (draftSupplierId != null && !_uuidRegex.hasMatch(draftSupplierId)) {
        draftSupplierId = null;
      }

      final saved = await _productRepository.saveDraft(
        productId: _savedProductId,
        businessId: widget.businessId,
        name: trimmedName,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        brandId: _selectedBrandId ?? _selectedBrand,
        categoryId: _selectedCategoryId ?? _selectedCategory,
        supplierId: draftSupplierId,
        taxCategory: _selectedTaxCategory,
        tags: _tags,
        costPriceCents: costCents,
        retailPriceCents: retailCents,
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        trackStockLevels: _trackStockLevels,
        locationId: _selectedLocationId,
        lowStockThreshold: int.tryParse(_reorderPointController.text.trim()),
        images: _images,
      );

      if (!mounted) return;

      setState(() {
        _savedProductId = saved.id;
        _lastSavedSnapshot = _takeFormSnapshot();
        _isSavingDraft = false;
      });

      if (widget.onSaveDraft != null) {
        widget.onSaveDraft!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft saved'),
          backgroundColor: Color(0xFF181513),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on PostgrestException catch (pe) {
      if (!mounted) return;
      setState(() => _isSavingDraft = false);
      debugPrint(
        '[CreateNewProductView.saveDraft] PostgrestException: code=${pe.code}, message=${pe.message}',
      );
      final isUuidError = pe.code == '22P02' || pe.message.contains('uuid');
      final errorMsg = isUuidError
          ? 'Select a valid supplier.'
          : "We couldn't save this product. Please review the highlighted fields and try again.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingDraft = false);
      debugPrint('[CreateNewProductView.saveDraft] Error: $e');
      final raw = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ArgumentError: ', '');
      final isTechnical =
          raw.contains('PostgrestException') ||
          raw.contains('22P02') ||
          raw.contains('SocketException');
      final errorMsg = isTechnical
          ? "We couldn't save this product. Please review the highlighted fields and try again."
          : raw;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handlePublishProduct() async {
    if (_isSavingDraft || _isPublishing) return;

    final trimmedName = _nameController.text.trim();
    final missingName = trimmedName.isEmpty;
    final missingBrand = _selectedBrandId == null && _selectedBrand == null;
    final missingCategory =
        _selectedCategoryId == null && _selectedCategory == null;
    final missingSupplier =
        _selectedSupplierId == null && _selectedSupplier == null;
    final missingTax =
        _selectedTaxCategory == null || _selectedTaxCategory!.trim().isEmpty;
    final missingLocation = _trackStockLevels && (_selectedLocationId == null || _locations.isEmpty);

    final costStr = _costPriceController.text.replaceAll(',', '').trim();
    final retailStr = _retailPriceController.text.replaceAll(',', '').trim();
    final costVal = double.tryParse(costStr);
    final retailVal = double.tryParse(retailStr);

    final invalidCost = costVal == null || costVal < 0;
    final invalidRetail = retailVal == null || retailVal <= 0;

    final trimmedSku = _skuController.text.trim();
    final missingSku = trimmedSku.isEmpty;

    setState(() {
      _nameError = missingName ? 'Enter a product name.' : null;
      _brandError = missingBrand ? 'Select a brand.' : null;
      _categoryError = missingCategory ? 'Select a category.' : null;
      _supplierError = missingSupplier ? 'Select a valid supplier.' : null;
      _taxCategoryError = missingTax ? 'Select a tax category.' : null;
      _locationError = missingLocation
          ? (_locations.isEmpty
                ? 'Create a location before adding stock.'
                : 'Select a stock location.')
          : null;
      _pricingError = invalidRetail
          ? 'Enter a selling price greater than 0.'
          : (invalidCost ? 'Unit cost cannot be negative.' : null);
      _skuError = missingSku
          ? 'Enter a System SKU or click Auto-generate.'
          : null;
    });

    if (missingName ||
        missingBrand ||
        missingCategory ||
        missingSupplier ||
        missingTax ||
        invalidCost ||
        invalidRetail ||
        missingSku ||
        missingLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the required fields before publishing.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (retailVal < costVal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Warning: Selling price is below unit cost.'),
          backgroundColor: Color(0xFFB45309),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    int openingStock = 0;
    if (_trackStockLevels) {
      final stockStr = _openingStockController.text.trim();
      if (stockStr.isNotEmpty) {
        final parsed = int.tryParse(stockStr);
        if (parsed == null || parsed < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening stock cannot be negative.'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        openingStock = parsed;
      }
    }

    setState(() => _isPublishing = true);

    try {
      String? resolvedSupplierId = _selectedSupplierId;
      if (resolvedSupplierId == null && _selectedSupplier != null) {
        final match = _suppliers
            .where((s) => s.name == _selectedSupplier)
            .firstOrNull;
        if (match != null) {
          resolvedSupplierId = match.id;
        }
      }

      if (resolvedSupplierId == null ||
          !_uuidRegex.hasMatch(resolvedSupplierId)) {
        setState(() {
          _isPublishing = false;
          _supplierError = 'Select a valid supplier.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select a valid supplier.'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final costCents = (costVal * 100).round();
      final retailCents = (retailVal * 100).round();

      final published = await _productRepository.publishProduct(
        productId: _savedProductId,
        businessId: widget.businessId,
        name: trimmedName,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        brandId: _selectedBrandId ?? _selectedBrand,
        categoryId: _selectedCategoryId ?? _selectedCategory,
        supplierId: resolvedSupplierId,
        taxCategory: _selectedTaxCategory,
        tags: _tags,
        costPriceCents: costCents,
        retailPriceCents: retailCents,
        sku: trimmedSku,
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        trackStockLevels: _trackStockLevels,
        locationId: _selectedLocationId,
        locationName: _selectedLocationName,
        openingStock: openingStock,
        lowStockThreshold: int.tryParse(_reorderPointController.text.trim()),
        images: _images,
      );

      if (!mounted) return;

      setState(() {
        _savedProductId = published.id;
        _lastSavedSnapshot = _takeFormSnapshot();
        _isPublishing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product published'),
          backgroundColor: Color(0xFF181513),
          behavior: SnackBarBehavior.floating,
        ),
      );

      widget.onPublishSuccess?.call(published);

      if (widget.onPublishProduct != null) {
        await widget.onPublishProduct!();
      } else if (Navigator.canPop(context)) {
        Navigator.maybePop(context);
      }
    } on PostgrestException catch (pe) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      debugPrint(
        '[CreateNewProductView.publishProduct] PostgrestException: code=${pe.code}, message=${pe.message}',
      );
      final isUuidError = pe.code == '22P02' || pe.message.contains('uuid');
      final errorMsg = isUuidError
          ? 'Select a valid supplier.'
          : "We couldn't save this product. Please review the highlighted fields and try again.";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPublishing = false);
      debugPrint('[CreateNewProductView.publishProduct] Error: $e');
      final raw = e
          .toString()
          .replaceAll('Exception: ', '')
          .replaceAll('ArgumentError: ', '');
      final isTechnical =
          raw.contains('PostgrestException') ||
          raw.contains('22P02') ||
          raw.contains('SocketException');
      final errorMsg = isTechnical
          ? "We couldn't save this product. Please review the highlighted fields and try again."
          : raw;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    if (_isPickingImages) return;
    setState(() => _isPickingImages = true);
    try {
      final picked = await _mediaRepository.pickImages(allowMultiple: true);
      if (!mounted) return;
      if (picked.isNotEmpty) {
        setState(() {
          final wasEmpty = _images.isEmpty;
          for (final item in picked) {
            _images.add(item.copyWith(isPrimary: wasEmpty && _images.isEmpty));
          }
          if (wasEmpty) {
            _selectedImageIndex = 0;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e
                  .toString()
                  .replaceAll('Exception: ', '')
                  .replaceAll('ArgumentError: ', ''),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  Future<void> _replaceCurrentImage() async {
    if (_images.isEmpty || _isPickingImages) return;
    setState(() => _isPickingImages = true);
    try {
      final picked = await _mediaRepository.pickImages(allowMultiple: false);
      if (!mounted) return;
      if (picked.isNotEmpty) {
        final isCurrentPrimary = _images[_selectedImageIndex].isPrimary;
        setState(() {
          _images[_selectedImageIndex] = picked.first.copyWith(
            isPrimary: isCurrentPrimary,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e
                  .toString()
                  .replaceAll('Exception: ', '')
                  .replaceAll('ArgumentError: ', ''),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImages = false);
      }
    }
  }

  void _removeCurrentImage() {
    if (_images.isEmpty) return;
    setState(() {
      final wasPrimary = _images[_selectedImageIndex].isPrimary;
      _images.removeAt(_selectedImageIndex);
      if (_images.isNotEmpty) {
        if (_selectedImageIndex >= _images.length) {
          _selectedImageIndex = _images.length - 1;
        }
        if (wasPrimary && !_images.any((img) => img.isPrimary)) {
          _images[0] = _images[0].copyWith(isPrimary: true);
        }
      } else {
        _selectedImageIndex = 0;
      }
    });
  }

  void _setCurrentImagePrimary() {
    if (_images.isEmpty) return;
    setState(() {
      for (int i = 0; i < _images.length; i++) {
        _images[i] = _images[i].copyWith(isPrimary: i == _selectedImageIndex);
      }
    });
  }

  void _generateSku() {
    final title = _nameController.text.trim();
    String prefix = 'PRD';
    if (title.isNotEmpty) {
      final words = title
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      if (words.length >= 2) {
        prefix = '${words[0][0]}${words[1][0]}'.toUpperCase();
      } else if (words.isNotEmpty && words.first.length >= 3) {
        prefix = words.first.substring(0, 3).toUpperCase();
      }
    }
    final code = (DateTime.now().millisecondsSinceEpoch % 100000)
        .toString()
        .padLeft(5, '0');
    final generated = 'TS-$prefix-$code';
    setState(() {
      _skuController.text = generated;
    });
  }

  Future<void> _handleBack() async {
    if (_hasUnsavedWork) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Leave product setup?',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181614),
            ),
          ),
          content: Text(
            'Your unsaved product information will be lost.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF5E574E),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Stay',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Leave',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldLeave != true) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    if (widget.onBack != null) {
      widget.onBack!.call();
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row
          _buildHeader(),
          const SizedBox(height: 20),

          // 2. Main Two-Column Layout (Left ~60%, Right ~40%)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      flex: 58,
                      child: Column(
                        children: [
                          _buildProductInfoCard(),
                          const SizedBox(height: 20),
                          _buildSupplierTaxCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right Column
                    Expanded(
                      flex: 42,
                      child: Column(
                        children: [
                          _buildProductImageryCard(),
                          const SizedBox(height: 20),
                          _buildPricingCard(),
                          const SizedBox(height: 20),
                          _buildInventorySettingsCard(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Stacked on smaller screens
              return Column(
                children: [
                  _buildProductInfoCard(),
                  const SizedBox(height: 20),
                  _buildSupplierTaxCard(),
                  const SizedBox(height: 20),
                  _buildProductImageryCard(),
                  const SizedBox(height: 20),
                  _buildPricingCard(),
                  const SizedBox(height: 20),
                  _buildInventorySettingsCard(),
                ],
              );
            },
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // 1. Header Row
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                button: true,
                label: 'Back to inventory',
                child: Tooltip(
                  message: 'Back to inventory',
                  child: TextButton.icon(
                    onPressed: _handleBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(
                      'Back',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF5E574E),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create New Product',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Add product details, pricing, and inventory settings to your catalog.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Row(
          children: [
            OutlinedButton(
              onPressed: (_isSavingDraft || _isPublishing)
                  ? null
                  : _handleSaveDraft,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1F2937),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                backgroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFF9FAFB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: _isSavingDraft
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF181513),
                      ),
                    )
                  : const Text('Save Draft'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: (_isSavingDraft || _isPublishing)
                  ? null
                  : _handlePublishProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF6B7280),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: _isPublishing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Publish Product'),
            ),
          ],
        ),
      ],
    );
  }

  // Card 1: Product Information
  Widget _buildProductInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          _buildCardHeader(
            icon: Icons.inventory_2_outlined,
            title: 'Product Information',
            subtitle: 'Basic details about your product.',
          ),
          const SizedBox(height: 20),

          // Product Name
          _buildFieldLabel('Product Name', isRequired: true),
          const SizedBox(height: 6),
          _buildTextInput(
            controller: _nameController,
            hint: 'Enter product title',
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          if (_nameError != null) ...[
            const SizedBox(height: 4),
            Text(
              _nameError!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Brand and Category
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Brand', isRequired: true),
                    const SizedBox(height: 6),
                    _buildBrandDropdown(),
                    if (_brandError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _brandError!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Category', isRequired: true),
                    const SizedBox(height: 6),
                    _buildCategoryDropdown(),
                    if (_categoryError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _categoryError!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          _buildFieldLabel('Description'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  buildCounter:
                      (
                        _, {
                        required currentLength,
                        required isFocused,
                        maxLength,
                      }) => null,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF1F2937),
                    height: 1.4,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 8),
                  child: Text(
                    '${_descriptionController.text.length}/500',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Workspace Tags
          _buildFieldLabel('Workspace Tags'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _tags)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF374151),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => setState(() => _tags.remove(tag)),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),
              InkWell(
                onTap: _showAddTagDialog,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFD97706),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 14,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Add Tag',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFB45309),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 2: Supplier & Tax Compliance
  Widget _buildSupplierTaxCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.local_shipping_outlined,
            title: 'Supplier & Tax Compliance',
            subtitle:
                'Link supplier and tax details for seamless purchasing and reporting.',
          ),
          const SizedBox(height: 20),

          // Supplier & Tax Category
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Primary Supplier', isRequired: true),
                    const SizedBox(height: 6),
                    _buildSupplierDropdown(),
                    if (_supplierError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _supplierError!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Tax Category', isRequired: true),
                    const SizedBox(height: 6),
                    _buildNullableDropdown(
                      value: _selectedTaxCategory,
                      hint: 'Select tax category',
                      items: const [
                        'Apparel Standard (12% GST)',
                        'Luxury Apparel (18% GST)',
                        'Export Zero-Rated (0% GST)',
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedTaxCategory = val;
                          _taxCategoryError = null;
                        });
                      },
                    ),
                    if (_taxCategoryError != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _taxCategoryError!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 3: Product Imagery
  Widget _buildProductImageryCard() {
    final hasImages = _images.isNotEmpty;
    final currentImage = hasImages ? _images[_selectedImageIndex] : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.photo_library_outlined,
            title: 'Product Imagery',
            subtitle: 'Add high-quality images to showcase your product.',
          ),
          const SizedBox(height: 18),

          // Image Gallery & Thumbnails Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Image Box
              Expanded(
                child: Container(
                  height: 230,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: !hasImages
                            ? InkWell(
                                onTap: _pickImages,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 40,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No images yet',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF4B5563),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'PNG, JPG or WEBP up to 10MB',
                                        style: GoogleFonts.inter(
                                          fontSize: 11.5,
                                          color: const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFD1D5DB),
                                          ),
                                        ),
                                        child: Text(
                                          'Upload from computer',
                                          style: GoogleFonts.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF374151),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: currentImage!.bytes != null
                                    ? Image.memory(
                                        currentImage.bytes!,
                                        fit: BoxFit.contain,
                                        height: 220,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.checkroom_rounded,
                                                  size: 48,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                      )
                                    : SafeImage(
                                        source: currentImage.remoteUrl ??
                                            currentImage.storagePath,
                                        height: 220,
                                        fit: BoxFit.contain,
                                        fallback: const Icon(
                                          Icons.checkroom_rounded,
                                          size: 48,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                              ),
                      ),
                      if (hasImages && currentImage != null) ...[
                        // Primary badge or Set as Primary action
                        Positioned(
                          top: 10,
                          left: 10,
                          child: currentImage.isPrimary
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  child: Text(
                                    'Primary',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFB45309),
                                    ),
                                  ),
                                )
                              : InkWell(
                                  onTap: _setCurrentImagePrimary,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xE6FFFFFF),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(0xFFD1D5DB),
                                      ),
                                    ),
                                    child: Text(
                                      'Set as Primary',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF4B5563),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        // Remove image action
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Tooltip(
                            message: 'Remove image',
                            child: InkWell(
                              onTap: _removeCurrentImage,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Color(0xE6FFFFFF),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Thumbnail Strip (Vertical)
              Column(
                children: [
                  for (int i = 0; i < _images.length; i++) ...[
                    InkWell(
                      onTap: () => setState(() => _selectedImageIndex = i),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _selectedImageIndex == i
                                ? const Color(0xFFD97706)
                                : const Color(0xFFE5E7EB),
                            width: _selectedImageIndex == i ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: _images[i].bytes != null
                              ? Image.memory(
                                  _images[i].bytes!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.image_outlined,
                                        size: 18,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                )
                              : SafeImage(
                                  source: _images[i].remoteUrl ??
                                      _images[i].storagePath,
                                  fit: BoxFit.cover,
                                  fallback: const Icon(
                                    Icons.image_outlined,
                                    size: 18,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  // Add image tile
                  InkWell(
                    onTap: _pickImages,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Replace Image Button & Specs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.file_upload_outlined, size: 15),
                    label: const Text('Add Image'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF374151),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (hasImages)
                    OutlinedButton.icon(
                      onPressed: _replaceCurrentImage,
                      icon: const Icon(Icons.sync_rounded, size: 15),
                      label: const Text('Replace Image'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'PNG, JPG, WEBP up to 10MB  •  800 × 1000 recommended',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 4: Cost & Selling Pricing
  Widget _buildPricingCard() {
    final marginDisplay = _calculatedMarginDisplay;
    final isUntouched = marginDisplay == '—';
    final isNegative = !isUntouched && marginDisplay.startsWith('-');

    final bannerBg = isUntouched
        ? const Color(0xFFF9FAFB)
        : (isNegative ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4));
    final bannerBorder = isUntouched
        ? const Color(0xFFE5E7EB)
        : (isNegative ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0));
    final iconBg = isUntouched
        ? const Color(0xFFF3F4F6)
        : (isNegative ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7));
    final iconColor = isUntouched
        ? const Color(0xFF6B7280)
        : (isNegative ? const Color(0xFFDC2626) : const Color(0xFF15803D));
    final valueColor = isUntouched
        ? const Color(0xFF9CA3AF)
        : (isNegative ? const Color(0xFFDC2626) : const Color(0xFF15803D));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.sell_outlined,
            title: 'Cost & Selling Pricing',
            subtitle: 'Unit pricing for one sellable piece.',
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Unit Cost (INR)', isRequired: true),
                    const SizedBox(height: 6),
                    _buildTextInput(
                      controller: _costPriceController,
                      prefixText: '₹ ',
                      hint: '0.00',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Selling Price (INR)', isRequired: true),
                    const SizedBox(height: 6),
                    _buildTextInput(
                      controller: _retailPriceController,
                      prefixText: '₹ ',
                      hint: '0.00',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_pricingError != null) ...[
            const SizedBox(height: 6),
            Text(
              _pricingError!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Calculated Gross Margin Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bannerBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: bannerBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.bar_chart_rounded,
                    size: 20,
                    color: iconColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculated Gross Margin',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '(Selling Price – Unit Cost) / Selling Price × 100',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isUntouched
                              ? const Color(0xFF6B7280)
                              : iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  marginDisplay,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 5: Inventory Settings
  Widget _buildInventorySettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.settings_outlined,
            title: 'Inventory Settings',
            subtitle: 'Configure SKU, barcode and stock tracking.',
          ),
          const SizedBox(height: 18),

          _buildFieldLabel('System SKU Identifier', isRequired: true),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildTextInput(
                  controller: _skuController,
                  hint: 'Auto-generated SKU',
                  onChanged: (_) {
                    if (_skuError != null) setState(() => _skuError = null);
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _generateSku,
                icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                label: const Text('Auto-generate'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                  backgroundColor: const Color(0xFFFFFBEB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_skuError != null) ...[
            const SizedBox(height: 4),
            Text(
              _skuError!,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
          const SizedBox(height: 16),

          _buildFieldLabel('Barcode (UPC/EAN)'),
          const SizedBox(height: 6),
          _buildTextInput(
            controller: _barcodeController,
            hint: 'Scan or type barcode',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 18),

          // Track Stock Levels Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Stock Levels',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Enable real-time inventory decrementing',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _trackStockLevels,
                onChanged: (val) => setState(() => _trackStockLevels = val),
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFFB45309),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFD1D5DB),
              ),
            ],
          ),

          // Exposed Stock Tracking Configuration
          if (_trackStockLevels) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFieldLabel('Location', isRequired: true),
                      InkWell(
                        onTap: _showAddLocationModal,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_rounded,
                                size: 14,
                                color: Color(0xFFB45309),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+ Add location',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_locations.isEmpty && !_isLoadingLocations) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 18,
                            color: Color(0xFFB45309),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No location configured',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Create a location before adding stock.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _showAddLocationModal,
                                  icon: const Icon(Icons.add_rounded, size: 14),
                                  label: const Text('Create Location'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF92400E),
                                    side: const BorderSide(
                                      color: Color(0xFFB45309),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _locationError != null
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value:
                            (_selectedLocationId != null &&
                                _locations.any(
                                  (l) => l.id == _selectedLocationId,
                                ))
                            ? _selectedLocationId
                            : null,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: Color(0xFF6B7280),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                        ),
                        hint: Text(
                          _isLoadingLocations
                              ? 'Loading locations...'
                              : (_locations.isEmpty
                                    ? 'No locations available'
                                    : 'Select stock location'),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF9CA3AF),
                            fontStyle:
                                _locations.isEmpty && !_isLoadingLocations
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                        items: [
                          if (_locations.isEmpty && !_isLoadingLocations) ...[
                            DropdownMenuItem<String?>(
                              value: null,
                              enabled: false,
                              child: Text(
                                'No locations available',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF9CA3AF),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          ..._locations.map((loc) {
                            return DropdownMenuItem<String?>(
                              value: loc.id,
                              child: Text(loc.name),
                            );
                          }),
                          DropdownMenuItem<String?>(
                            value: '__add_new_location__',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: Color(0xFFB45309),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+ Add location',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == '__add_new_location__') {
                            _showAddLocationModal();
                            return;
                          }
                          if (val == null) return;
                          final matched = _locations
                              .where((l) => l.id == val)
                              .firstOrNull;
                          if (matched != null) {
                            setState(() {
                              _selectedLocationId = matched.id;
                              _selectedLocationName = matched.name;
                              _locationError = null;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  if (_locationError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _locationError!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFFDC2626),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Opening Stock'),
                            const SizedBox(height: 2),
                            Text(
                              'Initial quantity available at this location',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildTextInput(
                              controller: _openingStockController,
                              hint: '0',
                              keyboardType: TextInputType.number,
                              enabled: _locations.isNotEmpty && _selectedLocationId != null,
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildFieldLabel('Low Stock Threshold'),
                            const SizedBox(height: 6),
                            _buildTextInput(
                              controller: _reorderPointController,
                              hint: 'e.g. 5',
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Common UI Helpers
  Widget _buildCardHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4EB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFFB45309)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Text(
      isRequired ? '$label *' : label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF374151),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    String? hint,
    String? prefixText,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? const Color(0xFFD1D5DB) : const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w500,
        ),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefixText,
          prefixStyle: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF9CA3AF),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildNullableDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            hint,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF6B7280),
          ),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w500,
          ),
          items: items.map((it) {
            return DropdownMenuItem<String>(value: it, child: Text(it));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildBrandDropdown() {
    final hasBrands = _brands.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _brandError != null
              ? const Color(0xFFDC2626)
              : const Color(0xFFD1D5DB),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedBrandId,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _isLoadingBrands ? 'Loading brands...' : 'Select brand',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
          isExpanded: true,
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF6B7280),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w500,
          ),
          items: [
            if (!hasBrands && !_isLoadingBrands) ...[
              DropdownMenuItem<String?>(
                value: null,
                enabled: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'No brands yet',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF9CA3AF),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
            ..._brands.map((b) {
              return DropdownMenuItem<String?>(
                value: b.id,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(b.name),
                ),
              );
            }),
            DropdownMenuItem<String?>(
              value: '__add_new_brand__',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add new brand',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (val) {
            if (val == '__add_new_brand__') {
              _showAddBrandModal();
              return;
            }
            if (val == null) return;
            final matched = _brands.firstWhere((b) => b.id == val);
            setState(() {
              _selectedBrandId = matched.id;
              _selectedBrand = matched.name;
              _brandError = null;
            });
          },
        ),
      ),
    );
  }

  void _showAddBrandModal() {
    final brandController = TextEditingController();
    String? modalError;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF4EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.branding_watermark_outlined,
                      size: 18,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add New Brand',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create a brand for your business catalog.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 18),
                    RichText(
                      text: TextSpan(
                        text: 'Brand Name',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                        children: const [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: brandController,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF111827),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter brand name',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF9CA3AF),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: modalError != null
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: modalError != null
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: modalError != null
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFB45309),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (modalError != null) {
                          setModalState(() => modalError = null);
                        }
                      },
                      onSubmitted: (_) async {
                        if (isSaving) return;
                        final name = brandController.text.trim();
                        if (name.isEmpty) {
                          setModalState(
                            () => modalError = 'Enter a brand name.',
                          );
                          return;
                        }
                        setModalState(() => isSaving = true);
                        try {
                          final newBrand = await _brandProvider.createBrand(
                            name: name,
                            businessId: widget.businessId,
                          );
                          if (!mounted) return;
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          setState(() {
                            _selectedBrandId = newBrand.id;
                            _selectedBrand = newBrand.name;
                            _brandError = null;
                          });
                        } catch (e) {
                          setModalState(() {
                            isSaving = false;
                            if (e is StateError) {
                              modalError = e.message;
                            } else if (e is ArgumentError) {
                              modalError =
                                  e.message?.toString() ?? e.toString();
                            } else {
                              modalError =
                                  "We couldn't save this brand. Please try again.";
                            }
                          });
                        }
                      },
                    ),
                    if (modalError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        modalError!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = brandController.text.trim();
                          if (name.isEmpty) {
                            setModalState(
                              () => modalError = 'Enter a brand name.',
                            );
                            return;
                          }
                          setModalState(() => isSaving = true);
                          try {
                            final newBrand = await _brandProvider.createBrand(
                              name: name,
                              businessId: widget.businessId,
                            );
                            if (!mounted) return;
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            setState(() {
                              _selectedBrandId = newBrand.id;
                              _selectedBrand = newBrand.name;
                              _brandError = null;
                            });
                          } catch (e) {
                            setModalState(() {
                              isSaving = false;
                              if (e is StateError) {
                                modalError = e.message;
                              } else if (e is ArgumentError) {
                                modalError =
                                    e.message?.toString() ?? e.toString();
                              } else {
                                modalError =
                                    "We couldn't save this brand. Please try again.";
                              }
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF181513),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Brand'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryDropdown() {
    final hasCategories = _categories.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _categoryError != null
              ? const Color(0xFFDC2626)
              : const Color(0xFFD1D5DB),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedCategoryId,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _isLoadingCategories
                  ? 'Loading categories...'
                  : 'Select category',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
          isExpanded: true,
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF6B7280),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w500,
          ),
          items: [
            if (!hasCategories && !_isLoadingCategories) ...[
              DropdownMenuItem<String?>(
                value: null,
                enabled: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'No categories yet',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF9CA3AF),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
            ..._categories.map((c) {
              return DropdownMenuItem<String?>(
                value: c.id,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(c.name),
                ),
              );
            }),
            DropdownMenuItem<String?>(
              value: '__add_new_category__',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Add new category',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (val) {
            if (val == '__add_new_category__') {
              _showAddCategoryModal();
              return;
            }
            if (val == null) return;
            final matched = _categories.firstWhere((c) => c.id == val);
            setState(() {
              _selectedCategoryId = matched.id;
              _selectedCategory = matched.name;
              _categoryError = null;
            });
          },
        ),
      ),
    );
  }

  void _showAddCategoryModal() {
    final categoryController = TextEditingController();
    String? modalError;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF4EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      size: 18,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add New Category',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create a category for your product catalog.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 18),
                    RichText(
                      text: TextSpan(
                        text: 'CATEGORY NAME',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                        children: const [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: categoryController,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF111827),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter category name',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF9CA3AF),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: modalError != null
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: modalError != null
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: modalError != null
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFB45309),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (modalError != null) {
                          setModalState(() => modalError = null);
                        }
                      },
                      onSubmitted: (_) async {
                        if (isSaving) return;
                        final name = categoryController.text.trim();
                        if (name.isEmpty) {
                          setModalState(
                            () => modalError = 'Enter a category name.',
                          );
                          return;
                        }
                        setModalState(() => isSaving = true);
                        try {
                          final newCategory = await _categoryProvider
                              .createCategory(
                                name: name,
                                businessId: widget.businessId,
                              );
                          if (!mounted) return;
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          await _loadCategories();
                          setState(() {
                            _selectedCategoryId = newCategory.id;
                            _selectedCategory = newCategory.name;
                            _categoryError = null;
                          });
                        } catch (e) {
                          setModalState(() {
                            isSaving = false;
                            if (e is StateError) {
                              modalError = e.message;
                            } else if (e is ArgumentError) {
                              modalError =
                                  e.message?.toString() ?? e.toString();
                            } else {
                              modalError = e
                                  .toString()
                                  .replaceAll('Exception: ', '')
                                  .replaceAll('Bad state: ', '');
                            }
                          });
                        }
                      },
                    ),
                    if (modalError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        modalError!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = categoryController.text.trim();
                          if (name.isEmpty) {
                            setModalState(
                              () => modalError = 'Enter a category name.',
                            );
                            return;
                          }
                          setModalState(() => isSaving = true);
                          try {
                            final newCategory = await _categoryProvider
                                .createCategory(
                                  name: name,
                                  businessId: widget.businessId,
                                );
                            if (!mounted) return;
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            await _loadCategories();
                            setState(() {
                              _selectedCategoryId = newCategory.id;
                              _selectedCategory = newCategory.name;
                              _categoryError = null;
                            });
                          } catch (e) {
                            setModalState(() {
                              isSaving = false;
                              if (e is StateError) {
                                modalError = e.message;
                              } else if (e is ArgumentError) {
                                modalError =
                                    e.message?.toString() ?? e.toString();
                              } else {
                                modalError = e
                                    .toString()
                                    .replaceAll('Exception: ', '')
                                    .replaceAll('Bad state: ', '');
                              }
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF181513),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add Category'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSupplierDropdown() {
    final hasSuppliers = _suppliers.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _supplierError != null
              ? const Color(0xFFDC2626)
              : const Color(0xFFD1D5DB),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedSupplierId,
          hint: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _isLoadingSuppliers ? 'Loading suppliers...' : 'Select supplier',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ),
          isExpanded: true,
          icon: const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Color(0xFF6B7280),
            ),
          ),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w500,
          ),
          items: [
            if (!hasSuppliers && !_isLoadingSuppliers) ...[
              DropdownMenuItem<String?>(
                value: '__no_suppliers__',
                enabled: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'No suppliers yet',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF9CA3AF),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
            ],
            ..._suppliers.map((s) {
              return DropdownMenuItem<String?>(
                value: s.id,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(s.name),
                ),
              );
            }),
            DropdownMenuItem<String?>(
              value: '__add_new_supplier__',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+ Add new supplier',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          onChanged: (val) {
            if (val == '__add_new_supplier__') {
              _showAddSupplierModal();
              return;
            }
            if (val == null || val == '__no_suppliers__') return;
            final matched = _suppliers.where((s) => s.id == val).firstOrNull;
            if (matched != null) {
              setState(() {
                _selectedSupplierId = matched.id;
                _selectedSupplier = matched.name;
                _supplierError = null;
              });
            }
          },
        ),
      ),
    );
  }

  void _showAddSupplierModal() {
    final supplierController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    String? modalError;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF4EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.business_outlined,
                      size: 18,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add New Supplier',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add a supplier or mill partner to your business catalog.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 18),
                    RichText(
                      text: TextSpan(
                        text: 'Supplier Name',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                        children: const [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(color: Color(0xFFDC2626)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: supplierController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Enter supplier name',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF9CA3AF),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFB45309),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onSubmitted: (_) async {
                        if (isSaving) return;
                        final name = supplierController.text.trim();
                        if (name.isEmpty) {
                          setModalState(
                            () => modalError = 'Enter a supplier name.',
                          );
                          return;
                        }
                        setModalState(() {
                          isSaving = true;
                          modalError = null;
                        });
                        try {
                          final newSupplier = await _supplierRepository
                              .createSupplier(
                                name: name,
                                contactEmail:
                                    emailController.text.trim().isNotEmpty
                                    ? emailController.text.trim()
                                    : null,
                                contactPhone:
                                    phoneController.text.trim().isNotEmpty
                                    ? phoneController.text.trim()
                                    : null,
                                businessId: widget.businessId,
                              );
                          if (!mounted) return;
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          await _loadSuppliers();
                          setState(() {
                            _selectedSupplierId = newSupplier.id;
                            _selectedSupplier = newSupplier.name;
                            _supplierError = null;
                          });
                        } catch (e) {
                          setModalState(() {
                            isSaving = false;
                            if (e is StateError) {
                              modalError = e.message;
                            } else if (e is ArgumentError) {
                              modalError =
                                  e.message?.toString() ?? e.toString();
                            } else {
                              modalError = e
                                  .toString()
                                  .replaceAll('Exception: ', '')
                                  .replaceAll('Bad state: ', '');
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Contact Email (Optional)',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'e.g. orders@supplier.com',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF9CA3AF),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                      ),
                    ),
                    if (modalError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        modalError!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = supplierController.text.trim();
                          if (name.isEmpty) {
                            setModalState(
                              () => modalError = 'Enter a supplier name.',
                            );
                            return;
                          }
                          setModalState(() {
                            isSaving = true;
                            modalError = null;
                          });
                          try {
                            final newSupplier = await _supplierRepository
                                .createSupplier(
                                  name: name,
                                  contactEmail:
                                      emailController.text.trim().isNotEmpty
                                      ? emailController.text.trim()
                                      : null,
                                  contactPhone:
                                      phoneController.text.trim().isNotEmpty
                                      ? phoneController.text.trim()
                                      : null,
                                  businessId: widget.businessId,
                                );
                            if (!mounted) return;
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            await _loadSuppliers();
                            setState(() {
                              _selectedSupplierId = newSupplier.id;
                              _selectedSupplier = newSupplier.name;
                              _supplierError = null;
                            });
                          } catch (e) {
                            setModalState(() {
                              isSaving = false;
                              if (e is StateError) {
                                modalError = e.message;
                              } else if (e is ArgumentError) {
                                modalError =
                                    e.message?.toString() ?? e.toString();
                              } else {
                                modalError = e
                                    .toString()
                                    .replaceAll('Exception: ', '')
                                    .replaceAll('Bad state: ', '');
                              }
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF181513),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add Supplier'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddLocationModal() {
    final locationController = TextEditingController();
    String? modalError;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBF4EB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Add Stock Location',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add a storage facility, warehouse, or retail location.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 18),
                    RichText(
                      text: TextSpan(
                        text: 'LOCATION NAME',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                        children: const [
                          TextSpan(
                            text: ' *',
                            style: TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: locationController,
                      autofocus: true,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF111827),
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Main Facility, Backroom A',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF9CA3AF),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: modalError != null
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: modalError != null
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: modalError != null
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFB45309),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) {
                        if (modalError != null) {
                          setModalState(() => modalError = null);
                        }
                      },
                      onSubmitted: (_) async {
                        if (isSaving) return;
                        final name = locationController.text.trim();
                        if (name.isEmpty) {
                          setModalState(
                            () => modalError = 'Enter a location name.',
                          );
                          return;
                        }
                        setModalState(() => isSaving = true);
                        try {
                          final newLocation = await _locationRepository
                              .createLocation(
                                name: name,
                                businessId: widget.businessId,
                              );
                          if (!mounted) return;
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                          await _loadLocations();
                          setState(() {
                            _selectedLocationId = newLocation.id;
                            _selectedLocationName = newLocation.name;
                            _locationError = null;
                          });
                          if (CurrentBusinessService.instance.currentLocationId ==
                              null) {
                            CurrentBusinessService.instance
                                .setCurrentLocationId(newLocation.id);
                          }
                        } catch (e) {
                          setModalState(() {
                            isSaving = false;
                            if (e is StateError) {
                              modalError = e.message;
                            } else if (e is ArgumentError) {
                              modalError =
                                  e.message?.toString() ?? e.toString();
                            } else {
                              modalError = e
                                  .toString()
                                  .replaceAll('Exception: ', '')
                                  .replaceAll('Bad state: ', '');
                            }
                          });
                        }
                      },
                    ),
                    if (modalError != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        modalError!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = locationController.text.trim();
                          if (name.isEmpty) {
                            setModalState(
                              () => modalError = 'Enter a location name.',
                            );
                            return;
                          }
                          setModalState(() => isSaving = true);
                          try {
                            final newLocation = await _locationRepository
                                .createLocation(
                                  name: name,
                                  businessId: widget.businessId,
                                );
                            if (!mounted) return;
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                            await _loadLocations();
                            setState(() {
                              _selectedLocationId = newLocation.id;
                              _selectedLocationName = newLocation.name;
                              _locationError = null;
                            });
                          } catch (e) {
                            setModalState(() {
                              isSaving = false;
                              if (e is StateError) {
                                modalError = e.message;
                              } else if (e is ArgumentError) {
                                modalError =
                                    e.message?.toString() ?? e.toString();
                              } else {
                                modalError = e
                                    .toString()
                                    .replaceAll('Exception: ', '')
                                    .replaceAll('Bad state: ', '');
                              }
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF181513),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add Location'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddTagDialog() {
    final tagCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add Workspace Tag',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: tagCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Summer Capsule',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTag = tagCtrl.text.trim();
              if (newTag.isNotEmpty && !_tags.contains(newTag)) {
                setState(() => _tags.add(newTag));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
            ),
            child: const Text('Add Tag'),
          ),
        ],
      ),
    );
  }
}
