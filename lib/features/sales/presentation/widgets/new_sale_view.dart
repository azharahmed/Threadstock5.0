// ignore_for_file: deprecated_member_use, unused_field
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/business/current_business_service.dart';
import '../../../../core/config/app_preferences_service.dart';
import '../../../../core/responsive/desktop_layout.dart';
import '../../../../core/widgets/safe_image.dart';
import '../../../inventory/data/inventory_repository.dart';
import '../../../inventory/data/location_repository.dart';
import '../../../inventory/data/product_media_repository.dart';
import '../../../inventory/data/product_repository.dart';
import '../../../inventory/domain/inventory_change_notifier.dart';
import '../../../inventory/domain/models/product_inventory_summary.dart';
import '../../../inventory/domain/models/stock_location.dart';
import '../../data/sales_repository.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/sale.dart';
import '../../domain/services/customer_input_classifier.dart';
import '../active_sale_session.dart';
import 'sale_complete_modal.dart';

class PosProduct {
  final String id;
  final String title;
  final String variantSubtitle;
  final String imageAsset;
  final int price;
  final int stockCount;
  final List<String> normalTags;
  final String highlightTag;
  final String? variantId;
  final String? sku;
  final int? costPrice;
  final String? taxCategory;

  const PosProduct({
    required this.id,
    required this.title,
    required this.variantSubtitle,
    required this.imageAsset,
    required this.price,
    required this.stockCount,
    required this.normalTags,
    required this.highlightTag,
    this.variantId,
    this.sku,
    this.costPrice,
    this.taxCategory,
  });

  PosProduct copyWith({
    String? id,
    String? title,
    String? variantSubtitle,
    String? imageAsset,
    int? price,
    int? stockCount,
    List<String>? normalTags,
    String? highlightTag,
    String? variantId,
    String? sku,
    int? costPrice,
    String? taxCategory,
  }) {
    return PosProduct(
      id: id ?? this.id,
      title: title ?? this.title,
      variantSubtitle: variantSubtitle ?? this.variantSubtitle,
      imageAsset: imageAsset ?? this.imageAsset,
      price: price ?? this.price,
      stockCount: stockCount ?? this.stockCount,
      normalTags: normalTags ?? this.normalTags,
      highlightTag: highlightTag ?? this.highlightTag,
      variantId: variantId ?? this.variantId,
      sku: sku ?? this.sku,
      costPrice: costPrice ?? this.costPrice,
      taxCategory: taxCategory ?? this.taxCategory,
    );
  }
}

enum SalesDiscountType {
  percentage,
  flat,
}

class SalesDiscountCalculator {
  /// Calculates the discount in rupees using safe minor currency units (paise).
  static double calculateDiscountAmount({
    required double subtotal,
    required SalesDiscountType type,
    required double inputValue,
  }) {
    if (inputValue <= 0 || subtotal <= 0) return 0.0;
    final subtotalPaise = (subtotal * 100).round();
    if (type == SalesDiscountType.percentage) {
      final paise = ((subtotalPaise * inputValue) / 100).round();
      final calculated = paise / 100.0;
      return calculated > subtotal ? subtotal : calculated;
    } else {
      final inputPaise = (inputValue * 100).round();
      final calculated = inputPaise / 100.0;
      return calculated > subtotal ? subtotal : calculated;
    }
  }

  /// Validates the input discount value. Returns null if valid, or an error message.
  static String? validateDiscount({
    required double subtotal,
    required SalesDiscountType type,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return 'Please enter a discount value';
    }
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return 'Enter a valid number';
    }
    if (parsed < 0) {
      return 'Discount cannot be negative';
    }
    if (parsed == 0) {
      return null;
    }
    if (subtotal <= 0) {
      return 'Discount cannot exceed the order subtotal.';
    }
    if (type == SalesDiscountType.percentage) {
      if (parsed > 100) {
        return 'Discount cannot exceed 100%';
      }
    } else {
      if (parsed > subtotal) {
        return 'Discount cannot exceed the order subtotal.';
      }
    }
    return null;
  }
}

class PosCartItem {
  final PosProduct product;
  int quantity;

  PosCartItem({required this.product, this.quantity = 1});

  int get totalItemPrice => product.price * quantity;
}

class NewSaleView extends StatefulWidget {
  const NewSaleView({super.key, this.onBackToOverview});

  final VoidCallback? onBackToOverview;

  @override
  State<NewSaleView> createState() => _NewSaleViewState();
}

class _NewSaleViewState extends State<NewSaleView> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _selectedCollection = 'All';
  String _selectedColor = 'All';
  String _selectedSize = 'All';
  String _selectedSort = 'Popular';
  bool _isGridView = false;

  String? _selectedCustomer;
  String? _selectedCustomerId;
  String? _customerPhone; // E.164 phone of attached customer
  String? _resumedSaleId;
  String? _locationId;
  List<StockLocation> _businessLocations = [];
  bool _isProcessingSale = false;
  bool _isHoldingSale = false;
  bool _skipSessionPersist = false;
  SalesDiscountType _discountType = SalesDiscountType.percentage;
  double _discountInputValue = 0.0;
  String? _saleNote;
  CartPaymentState _paymentState = const CartPaymentState();

  List<PosProduct> _catalog = [];
  bool _isLoadingProducts = true;
  String? _productsError;

  List<PosCartItem> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _restoreActiveSession();
    ActiveSaleSession.instance.addListener(_onActiveSessionChanged);
    CurrentBusinessService.instance.addListener(_onBusinessOrLocationChanged);
    InventoryChangeNotifier.instance.addListener(_onInventoryOrLocationChanged);
    _searchController.addListener(() {
      setState(() {});
    });
    _loadProducts();
  }

  void _onBusinessOrLocationChanged() {
    if (!mounted) return;
    final serviceLoc = CurrentBusinessService.instance.currentLocationId;
    if (serviceLoc != null &&
        serviceLoc != _locationId &&
        _businessLocations.any((l) => l.id == serviceLoc)) {
      _selectLocation(serviceLoc);
    } else {
      _loadProducts();
    }
  }

  void _onInventoryOrLocationChanged() {
    if (!mounted) return;
    _loadProducts();
  }

  Future<void> _selectLocation(String newLocId) async {
    if (_locationId == newLocId &&
        CurrentBusinessService.instance.currentLocationId == newLocId) {
      return;
    }
    final loc = _businessLocations.where((l) => l.id == newLocId).firstOrNull ??
        (_businessLocations.isNotEmpty ? _businessLocations.first : null);
    if (loc == null) return;

    setState(() {
      _locationId = loc.id;
    });

    CurrentBusinessService.instance.setCurrentLocationId(loc.id);
    ActiveSaleSession.instance.locationId = loc.id;
    ActiveSaleSession.instance.locationName = loc.name;
    final businessId = CurrentBusinessService.instance.currentBusinessId;
    if (businessId != null && businessId.isNotEmpty) {
      AppPreferencesService.instance.setCurrentLocationId(businessId, loc.id);
    }
    _persistActiveSession();

    // Invalidate and reload inventory availability for new location
    if (businessId != null && businessId.isNotEmpty) {
      try {
        final inventoryRepo = InventoryRepository();
        final productRepo = ProductRepository();
        final rawProducts = await productRepo.getProducts(businessId: businessId);
        final activeProducts =
            rawProducts.where((p) => p.status == 'active').toList();
        final summaries = await inventoryRepo.getProductInventorySummaries(
          businessId: businessId,
          locationId: loc.id,
          preloadedProducts: activeProducts,
        );
        if (mounted) {
          setState(() {
            _catalog = _catalog.map((p) {
              final s = summaries[p.id];
              return p.copyWith(
                stockCount: s?.availableQty ?? 0,
                highlightTag: s?.stockStatusLabel ?? 'Normal',
              );
            }).toList();
          });
        }
      } catch (e) {
        debugPrint('[NewSaleView] Error reloading summaries for location: $e');
      }
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });
    try {
      var businessId = CurrentBusinessService.instance.currentBusinessId;
      if (businessId == null || businessId.isEmpty) {
        businessId =
            await CurrentBusinessService.instance.resolveCurrentBusinessId();
      }
      if (businessId == null || businessId.isEmpty) {
        try {
          businessId = await LocationRepository().resolveCurrentBusinessId();
        } catch (_) {}
      }

      if (businessId == null || businessId.isEmpty) {
        if (mounted) {
          setState(() {
            _catalog = [];
            _businessLocations = [];
            _locationId = null;
            _isLoadingProducts = false;
          });
        }
        return;
      }

      final locRepo = LocationRepository();
      List<StockLocation> locs = [];
      try {
        locs = await locRepo.getLocations(
          businessId: businessId,
          onlyActive: true,
        );
      } catch (e) {
        debugPrint('[NewSaleView] Error loading locations: $e');
      }

      // Authoritative location selection
      // 1. If only 1 active location exists: auto-select it.
      // 2. Otherwise prefer saved session location if valid among active locs.
      // 3. Otherwise prefer CurrentBusinessService or saved preference location if valid among active locs.
      // 4. Otherwise default to first active location if any.
      String? activeLocId;
      if (locs.length == 1) {
        activeLocId = locs.first.id;
      } else if (locs.isNotEmpty) {
        final sessionLoc = _locationId ?? ActiveSaleSession.instance.locationId;
        final serviceLoc = CurrentBusinessService.instance.currentLocationId ??
            AppPreferencesService.instance.getCurrentLocationId(businessId);
        if (sessionLoc != null && locs.any((l) => l.id == sessionLoc)) {
          activeLocId = sessionLoc;
        } else if (serviceLoc != null && locs.any((l) => l.id == serviceLoc)) {
          activeLocId = serviceLoc;
        } else {
          activeLocId = locs.first.id;
        }
      } else {
        activeLocId = null;
      }

      final activeLoc = locs.where((l) => l.id == activeLocId).firstOrNull;

      // Synchronize single authoritative location across services
      CurrentBusinessService.instance.setCurrentLocationId(activeLocId);
      ActiveSaleSession.instance.locationId = activeLocId;
      ActiveSaleSession.instance.locationName = activeLoc?.name;
      if (activeLocId != null) {
        AppPreferencesService.instance
            .setCurrentLocationId(businessId, activeLocId);
      }
      _locationId = activeLocId;
      _businessLocations = locs;

      final productRepo = ProductRepository();
      final inventoryRepo = InventoryRepository();
      final rawProducts = await productRepo.getProducts(businessId: businessId);
      final activeProducts =
          rawProducts.where((p) => p.status == 'active').toList();

      Map<String, ProductInventorySummary> summariesMap = {};
      if (activeLocId != null) {
        summariesMap = await inventoryRepo.getProductInventorySummaries(
          businessId: businessId,
          locationId: activeLocId,
          preloadedProducts: activeProducts,
        );
      }

      final productImages = <String, String>{};
      try {
        final productIds = activeProducts.map((p) => p.id).toList();
        if (productIds.isNotEmpty) {
          SupabaseClient? sb;
          try {
            sb = Supabase.instance.client;
          } catch (_) {}
          if (sb != null) {
            final mediaRows = await sb
                .from('product_media')
                .select('product_id, storage_path, is_primary')
                .inFilter('product_id', productIds)
                .order('is_primary', ascending: false);
            for (final row in mediaRows as List) {
              final pid = row['product_id'] as String?;
              final sp = row['storage_path'] as String?;
              if (pid != null && sp != null && !productImages.containsKey(pid)) {
                productImages[pid] =
                    sb.storage.from('product-media').getPublicUrl(sp);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[NewSaleView] media lookup fallback: $e');
      }

      final products = <PosProduct>[];
      for (final p in activeProducts) {
        final summary = summariesMap[p.id];
        final primaryVariant = summary != null && summary.variants.isNotEmpty
            ? summary.variants.first
            : null;
        if (primaryVariant == null) continue;
        final priceCents = primaryVariant.retailPriceCents > 0
            ? primaryVariant.retailPriceCents
            : primaryVariant.costPriceCents;
        if (priceCents <= 0) continue;

        final priceRupees = (priceCents / 100).round();
        final sku =
            primaryVariant.sku.isNotEmpty ? primaryVariant.sku : 'SKU: —';
        final vCount = summary?.variantCount ?? 0;

        String imgPath = productImages[p.id] ?? '';
        if (imgPath.isEmpty) {
          final fallbackMedia =
              ProductMediaRepository.instance.getMediaForProduct(p.id);
          if (fallbackMedia.isNotEmpty) {
            imgPath = fallbackMedia.first.remoteUrl ??
                fallbackMedia.first.storagePath ??
                '';
          }
        }

        products.add(
          PosProduct(
            id: p.id,
            title: p.name,
            variantSubtitle: '$sku • $vCount variant${vCount == 1 ? '' : 's'}',
            imageAsset: imgPath,
            price: priceRupees > 0 ? priceRupees : 0,
            stockCount: summary?.availableQty ?? 0,
            normalTags: p.tags,
            highlightTag: summary?.stockStatusLabel ?? 'Normal',
            variantId: primaryVariant.id,
            sku: primaryVariant.sku,
            costPrice: primaryVariant.costPriceCents > 0
                ? (primaryVariant.costPriceCents / 100).round()
                : 0,
            taxCategory: p.taxCategory,
          ),
        );
      }
      if (mounted) {
        setState(() {
          _catalog = products;
          _isLoadingProducts = false;
          for (var i = 0; i < _cartItems.length; i++) {
            final matches = products.where((product) => product.id == _cartItems[i].product.id);
            if (matches.isEmpty) continue;
            final catalogProduct = matches.first;
            _cartItems[i] = PosCartItem(
              product: catalogProduct.copyWith(
                price: _cartItems[i].product.price,
                stockCount: _resumedSaleId != null
                    ? _cartItems[i].product.stockCount
                    : catalogProduct.stockCount,
                variantId: _cartItems[i].product.variantId ?? catalogProduct.variantId,
                sku: _cartItems[i].product.sku ?? catalogProduct.sku,
              ),
              quantity: _cartItems[i].quantity,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProducts = false;
          _productsError = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    ActiveSaleSession.instance.removeListener(_onActiveSessionChanged);
    CurrentBusinessService.instance.removeListener(_onBusinessOrLocationChanged);
    InventoryChangeNotifier.instance.removeListener(_onInventoryOrLocationChanged);
    _persistActiveSession();
    _searchController.dispose();
    super.dispose();
  }

  void _onActiveSessionChanged() {
    if (!mounted || _skipSessionPersist) return;
    setState(() {
      _restoreActiveSession();
    });
  }

  void _restoreActiveSession() {
    final session = ActiveSaleSession.instance;
    _cartItems = session.lines
        .map(
          (line) => PosCartItem(
            product: PosProduct(
              id: line.productId,
              title: line.title,
              variantSubtitle: line.variantSubtitle,
              imageAsset: line.imageAsset,
              price: (line.unitPriceMinor / 100).round(),
              stockCount: line.availableQty ?? line.stockCount,
              normalTags: const [],
              highlightTag: '',
              variantId: line.variantId,
              sku: line.sku,
              costPrice: (line.costPriceMinor / 100).round(),
              taxCategory: line.taxCategory,
            ),
            quantity: line.quantity,
          ),
        )
        .toList();
    _discountType = lineDiscountType(session.discountType);
    _discountInputValue = session.discountInput;
    _saleNote = session.note;
    _selectedCustomer = session.customerName;
    _selectedCustomerId = session.customerId;
    _customerPhone = session.customerPhone;
    _resumedSaleId = session.heldSaleId;
    _paymentState = session.paymentState;
    if (session.locationId != null && session.locationId!.isNotEmpty) {
      _locationId = session.locationId;
    }
  }

  SalesDiscountType lineDiscountType(String value) {
    return value == 'flat' ? SalesDiscountType.flat : SalesDiscountType.percentage;
  }

  void _persistActiveSession() {
    if (_skipSessionPersist) return;
    final activeLocName = _businessLocations
            .where((l) => l.id == _locationId)
            .firstOrNull
            ?.name ??
        ActiveSaleSession.instance.locationName;
    ActiveSaleSession.instance.save(
      lines: _cartItems
          .map(
            (item) => ActiveCartLine(
              productId: item.product.id,
              variantId: item.product.variantId,
              title: item.product.title,
              sku: item.product.sku ?? '',
              variantSubtitle: item.product.variantSubtitle,
              unitPriceMinor: (item.product.price * 100).round(),
              quantity: item.quantity,
              stockCount: item.product.stockCount,
              availableQty: item.product.stockCount,
              costPriceMinor: (item.product.costPrice ?? 0) * 100,
              taxCategory: item.product.taxCategory,
              imageAsset: item.product.imageAsset,
            ),
          )
          .toList(),
      discountType: _discountType == SalesDiscountType.percentage ? 'percentage' : 'flat',
      discountInput: _discountInputValue,
      note: _saleNote,
      customerId: _selectedCustomerId,
      customerName: _selectedCustomer,
      customerPhone: _customerPhone,
      heldSaleId: _resumedSaleId,
      paymentState: _paymentState,
      locationId: _locationId,
      locationName: activeLocName,
      stockWarnings: ActiveSaleSession.instance.stockWarnings,
    );
  }

  void _clearActiveSaleState({bool preserveLocation = true}) {
    _cartItems.clear();
    _discountInputValue = 0.0;
    _discountType = SalesDiscountType.percentage;
    _saleNote = null;
    _selectedCustomer = null;
    _selectedCustomerId = null;
    _customerPhone = null;
    _resumedSaleId = null;
    _paymentState = const CartPaymentState();
    if (!preserveLocation) {
      _locationId = null;
    }
    _skipSessionPersist = true;
    ActiveSaleSession.instance.clear(preserveLocation: preserveLocation);
    _skipSessionPersist = false;
  }

  List<PosProduct> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _catalog.where((product) {
      if (query.isNotEmpty) {
        final match =
            product.title.toLowerCase().contains(query) ||
            product.variantSubtitle.toLowerCase().contains(query) ||
            product.id.toLowerCase().contains(query);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  double get _subtotal {
    double sum = 0.0;
    for (final item in _cartItems) {
      sum += item.totalItemPrice;
    }
    return sum;
  }

  double get _calculatedDiscountAmount {
    return SalesDiscountCalculator.calculateDiscountAmount(
      subtotal: _subtotal,
      type: _discountType,
      inputValue: _discountInputValue,
    );
  }

  bool get _cartHasDecimals {
    return (_calculatedDiscountAmount % 1 != 0) ||
        (_subtotal % 1 != 0) ||
        (_totalAmount % 1 != 0);
  }

  double get _taxableSubtotal {
    final taxable = _subtotal - _calculatedDiscountAmount;
    return taxable > 0 ? taxable : 0.0;
  }

  String get _taxLabel {
    final country = CurrentBusinessService.instance.currentBusiness?.countryCode ?? 'IN';
    switch (country.toUpperCase()) {
      case 'IN':
        return 'Tax (GST)';
      case 'US':
        return 'Tax (Sales Tax)';
      case 'GB':
      case 'AE':
      case 'FR':
      case 'IT':
        return 'Tax (VAT)';
      case 'AU':
      case 'SG':
        return 'Tax (GST)';
      default:
        return 'Tax';
    }
  }

  double get _taxAmount => 0.0;

  double get _totalAmount {
    final raw = _taxableSubtotal + _taxAmount;
    return raw > 0 ? raw : 0.0;
  }

  List<PosCartItem> get _stockShortages => _cartItems
      .where((item) => item.quantity > item.product.stockCount)
      .toList();

  Widget _buildStockChangedNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF5D0A9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock changed since this sale was held.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF9A3412),
            ),
          ),
          const SizedBox(height: 6),
          for (final item in _stockShortages)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '${item.product.title}\nRequested: ${item.quantity}\nAvailable: ${item.product.stockCount}',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.35,
                  color: const Color(0xFF7C2D12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildItemsPayload() {
    return _cartItems.map((item) {
      final unitPriceMinor = (item.product.price * 100).round();
      final lineSubtotalMinor = unitPriceMinor * item.quantity;
      final lineDiscountMinor = _subtotal > 0
          ? ((lineSubtotalMinor / (_subtotal * 100)) * (_calculatedDiscountAmount * 100)).round()
          : 0;
      final taxableMinor = lineSubtotalMinor - lineDiscountMinor;
      return {
        'product_id': item.product.id,
        'variant_id': item.product.variantId,
        'sku_snapshot': item.product.sku ?? 'TS-SKU',
        'product_name_snapshot': item.product.title,
        'variant_title_snapshot': _getVariantTagline(item.product),
        'quantity': item.quantity,
        'unit_price_minor': unitPriceMinor,
        'unit_cost_minor': (item.product.costPrice ?? 0) * 100,
        'discount_minor': lineDiscountMinor,
        'taxable_amount_minor': taxableMinor,
        'tax_minor': 0,
        'line_total_minor': taxableMinor,
        'tax_category_snapshot': item.product.taxCategory ?? 'standard',
      };
    }).toList();
  }

  @visibleForTesting
  void applyDiscountForTesting({
    required SalesDiscountType type,
    required double inputValue,
  }) {
    setState(() {
      _discountType = type;
      _discountInputValue = inputValue;
    });
  }

  @visibleForTesting
  void removeDiscountForTesting() {
    setState(() {
      _discountInputValue = 0.0;
    });
  }

  @visibleForTesting
  void setCartItemsForTesting(List<PosCartItem> items) {
    setState(() {
      _cartItems = List.from(items);
    });
  }

  @visibleForTesting
  double get subtotalForTesting => _subtotal;

  @visibleForTesting
  double get calculatedDiscountAmountForTesting => _calculatedDiscountAmount;

  @visibleForTesting
  double get taxableSubtotalForTesting => _taxableSubtotal;

  @visibleForTesting
  double get taxAmountForTesting => _taxAmount;

  @visibleForTesting
  double get totalAmountForTesting => _totalAmount;

  @visibleForTesting
  SalesDiscountType get discountTypeForTesting => _discountType;

  @visibleForTesting
  double get discountInputValueForTesting => _discountInputValue;

  @visibleForTesting
  bool get isProcessingSaleForTesting => _isProcessingSale;

  @visibleForTesting
  Future<CompleteSaleResult> completeSaleForTesting({
    String paymentMethod = 'cash',
  }) async {
    final businessId = CurrentBusinessService.instance.currentBusinessId ?? 'default_business';
    final itemsPayload = _cartItems.map((item) {
      final unitPriceMinor = (item.product.price * 100).round();
      final lineSubtotalMinor = unitPriceMinor * item.quantity;
      final lineDiscountMinor = _subtotal > 0
          ? ((lineSubtotalMinor / (_subtotal * 100)) * (_calculatedDiscountAmount * 100)).round()
          : 0;
      final taxableMinor = lineSubtotalMinor - lineDiscountMinor;
      return {
        'product_id': item.product.id,
        'variant_id': item.product.variantId,
        'sku_snapshot': item.product.sku ?? 'TS-SKU',
        'product_name_snapshot': item.product.title,
        'variant_title_snapshot': _getVariantTagline(item.product),
        'quantity': item.quantity,
        'unit_price_minor': unitPriceMinor,
        'unit_cost_minor': (item.product.costPrice ?? 0) * 100,
        'discount_minor': lineDiscountMinor,
        'taxable_amount_minor': taxableMinor,
        'tax_minor': 0,
        'line_total_minor': taxableMinor,
        'tax_category_snapshot': item.product.taxCategory ?? 'standard',
      };
    }).toList();

    return await SalesRepository.instance.completeSale(
      businessId: businessId,
      customerId: _selectedCustomerId,
      customerName: _selectedCustomer,
      subtotal: _subtotal,
      discount: _calculatedDiscountAmount,
      discountType: _discountType == SalesDiscountType.percentage ? 'percentage' : 'flat',
      discountRate: _discountInputValue,
      tax: _taxAmount,
      total: _totalAmount,
      currencyCode: CurrentBusinessService.instance.currentBusiness?.currencyCode ?? 'INR',
      idempotencyKey: 'test_${DateTime.now().millisecondsSinceEpoch}',
      items: itemsPayload,
      payments: [
        {
          'payment_method': paymentMethod,
          'amount_minor': (_totalAmount * 100).round(),
          'processing_type': 'recorded',
          'currency_code': CurrentBusinessService.instance.currentBusiness?.currencyCode ?? 'INR',
        }
      ],
    );
  }

  void _addToCart(PosProduct product) {
    if (_locationId == null) {
      _showToast(
        'Cannot add items: No location configured for this business.',
        isError: true,
      );
      return;
    }
    setState(() {
      final index = _cartItems.indexWhere(
        (item) => item.product.id == product.id,
      );
      if (index >= 0) {
        if (_cartItems[index].quantity >= product.stockCount) {
          _showToast('${product.title} only has ${product.stockCount} units available.');
          return;
        }
        _cartItems[index].quantity += 1;
      } else {
        if (product.stockCount <= 0) {
          _showToast('${product.title} is out of stock.');
          return;
        }
        _cartItems.add(PosCartItem(product: product, quantity: 1));
      }
    });

    _showToast('Added ${product.title} to cart');
  }

  void _incrementCartItem(int index) {
    final item = _cartItems[index];
    if (item.quantity >= item.product.stockCount) {
      _showToast('${item.product.title} only has ${item.product.stockCount} units available.');
      return;
    }
    setState(() {
      _cartItems[index].quantity += 1;
    });
  }

  void _decrementCartItem(int index) {
    setState(() {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity -= 1;
      } else {
        final removedTitle = _cartItems[index].product.title;
        _cartItems.removeAt(index);
        _showToast('Removed $removedTitle from cart');
      }
    });
  }

  void _clearCart() {
    if (_cartItems.isEmpty) return;
    setState(_clearActiveSaleState);
    _showToast('Cart cleared');
  }

  void _showToast(String message, {String? detail, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: isError ? const Color(0xFFFCA5A5) : const Color(0xFFBA8A55),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFFE7E5E4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 20,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1050;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Section: Catalog, Search & Quick Actions
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCatalogHeader(),
                          if (_locationId == null && !_isLoadingProducts) ...[
                            const SizedBox(height: 12),
                            _buildNoLocationBanner(),
                          ],
                          const SizedBox(height: 16),
                          _buildSearchAndBarcodeBar(),
                          const SizedBox(height: 14),
                          _buildFilterToolbar(),
                          const SizedBox(height: 16),
                          _buildProductList(),
                          const SizedBox(height: 24),
                          _buildQuickActionsSection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Section: Active Cart Card (fixed width 380-420px)
                  SizedBox(width: 390, child: _buildActiveCartCard()),
                ],
              );
            }

            // Stacked Layout for compact window
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCatalogHeader(),
                  if (_locationId == null && !_isLoadingProducts) ...[
                    const SizedBox(height: 12),
                    _buildNoLocationBanner(),
                  ],
                  const SizedBox(height: 16),
                  _buildSearchAndBarcodeBar(),
                  const SizedBox(height: 14),
                  _buildFilterToolbar(),
                  const SizedBox(height: 16),
                  _buildProductList(),
                  const SizedBox(height: 24),
                  _buildActiveCartCard(),
                  const SizedBox(height: 24),
                  _buildQuickActionsSection(),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoLocationBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Color(0xFFB45309),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No Location Configured',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This business has no active inventory locations. Sales and stock tracking require at least one location.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 1. CATALOG HEADER: "Add Items to Sale" & Location Selector
  // ========================================================
  Widget _buildCatalogHeader() {
    final activeLoc =
        _businessLocations.where((l) => l.id == _locationId).firstOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.onBackToOverview != null) ...[
              InkWell(
                onTap: widget.onBackToOverview,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFDFD6C9)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_back_rounded,
                        size: 14,
                        color: Color(0xFF5A5248),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Overview',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5A5248),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 14,
                runSpacing: 4,
                children: [
                  Text(
                    'Add Items to Sale',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    'Search, scan or browse products',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6E665B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildLocationSelector(activeLoc),
          ],
        );
      },
    );
  }

  Widget _buildLocationSelector(StockLocation? activeLoc) {
    if (_businessLocations.isEmpty) {
      return Container(
        key: const Key('sales_location_selector'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 14,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 6),
            Text(
              'No Location',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      );
    }

    if (_businessLocations.length == 1) {
      final loc = _businessLocations.first;
      return Container(
        key: const Key('sales_location_selector'),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E0D8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.storefront_outlined,
              size: 15,
              color: Color(0xFF8C7355),
            ),
            const SizedBox(width: 6),
            Text(
              loc.name,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Active',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final selectedId = _locationId ?? _businessLocations.first.id;
    return Container(
      key: const Key('sales_location_selector'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E0D8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _businessLocations.any((l) => l.id == selectedId)
              ? selectedId
              : _businessLocations.first.id,
          icon: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Color(0xFF8C7355),
            ),
          ),
          isDense: true,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181513),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          items: _businessLocations.map((loc) {
            return DropdownMenuItem<String>(
              value: loc.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.storefront_outlined,
                    size: 14,
                    color: Color(0xFF8C7355),
                  ),
                  const SizedBox(width: 6),
                  Text(loc.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (newLocId) {
            if (newLocId != null) {
              _selectLocation(newLocId);
            }
          },
        ),
      ),
    );
  }

  // ========================================================
  // 2. SEARCH BAR & SCANNER BARCODE BUTTON
  // ========================================================
  Widget _buildSearchAndBarcodeBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDFD7CC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: Color(0xFF8C8478)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1E1C1A),
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: 'Search product, SKU or scan barcode...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: const Color(0xFFA1978A),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            InkWell(
              onTap: () => _searchController.clear(),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Color(0xFF8C8478),
                ),
              ),
            ),
          const SizedBox(width: 12),

          // Scan Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _simulateBarcodeScan,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDFD4C5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.view_week_outlined,
                      size: 17,
                      color: Color(0xFF332D26),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scan',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF332D26),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Barcode Ready Indicator Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EE),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFC3E6CB)),
            ),
            child: Text(
              'Barcode Ready',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E7E34),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _simulateBarcodeScan() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2D6C5)),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.qr_code_scanner_rounded,
              color: Color(0xFFBA8A55),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Hardware Barcode Scanner',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hardware USB/Bluetooth scanner is active and listening for barcode signals.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF5F574E),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE3DACD)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF1E7E34),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _catalog.isNotEmpty
                        ? 'Simulate scan: ${_catalog.first.title}'
                        : 'Simulate barcode scan (no products)',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF7A7268)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1C1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _catalog.isEmpty
                ? null
                : () {
                    Navigator.pop(ctx);
                    _addToCart(_catalog[0]);
                  },
            child: Text(
              'Simulate Scan Event',
              style: GoogleFonts.inter(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 3. FILTER TOOLBAR: Category, Collection, Color, Size, Sort, Grid/List
  // ========================================================
  Widget _buildFilterToolbar() {
    return Row(
      children: [
        _buildFilterDropdown(
          label: 'Category',
          value: _selectedCategory,
          options: const [
            'All',
            'Shirts',
            'Blazers',
            'Sweaters',
            'Jeans',
            'Dresses',
          ],
          onSelected: (val) => setState(() => _selectedCategory = val),
        ),
        const SizedBox(width: 8),
        _buildFilterDropdown(
          label: 'Collection',
          value: _selectedCollection,
          options: const [
            'All',
            "Summer '27",
            "Autumn '27",
            'Classics',
            'Formal',
          ],
          onSelected: (val) => setState(() => _selectedCollection = val),
        ),
        const SizedBox(width: 8),
        _buildFilterDropdown(
          label: 'Color',
          value: _selectedColor,
          options: const [
            'All',
            'Black',
            'Navy',
            'Heather Grey',
            'Indigo',
            'Beige',
            'Red',
          ],
          onSelected: (val) => setState(() => _selectedColor = val),
        ),
        const SizedBox(width: 8),
        _buildFilterDropdown(
          label: 'Size',
          value: _selectedSize,
          options: const ['All', 'XS', 'S', 'M', 'L', 'XL'],
          onSelected: (val) => setState(() => _selectedSize = val),
        ),
        const Spacer(),

        // Sort By
        _buildFilterDropdown(
          label: 'Sort: $_selectedSort',
          value: _selectedSort,
          options: const [
            'Popular',
            'Price: Low to High',
            'Price: High to Low',
            'Stock Level',
          ],
          onSelected: (val) => setState(() => _selectedSort = val),
          isSort: true,
        ),
        const SizedBox(width: 10),

        // Grid / List Toggle
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFDFD6C9)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _isGridView = true),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(5),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  color: _isGridView
                      ? const Color(0xFFEFE8DD)
                      : Colors.transparent,
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 16,
                    color: _isGridView
                        ? const Color(0xFF1E1C1A)
                        : const Color(0xFF8A8276),
                  ),
                ),
              ),
              Container(width: 1, height: 16, color: const Color(0xFFDFD6C9)),
              InkWell(
                onTap: () => setState(() => _isGridView = false),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(5),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  color: !_isGridView
                      ? const Color(0xFFEFE8DD)
                      : Colors.transparent,
                  child: Icon(
                    Icons.format_list_bulleted_rounded,
                    size: 16,
                    color: !_isGridView
                        ? const Color(0xFF1E1C1A)
                        : const Color(0xFF8A8276),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onSelected,
    bool isSort = false,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: const Color(0xFFFAF7F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDFD4C5)),
      ),
      itemBuilder: (ctx) => options.map((opt) {
        final isSelected = (opt == value) || (isSort && label.contains(opt));
        return PopupMenuItem<String>(
          value: opt,
          height: 36,
          child: Row(
            children: [
              Text(
                opt,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF1E1C1A)
                      : const Color(0xFF4A4237),
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: Color(0xFFBA8A55),
                ),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDFD6C9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF474035),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Color(0xFF6B6358),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // 4. PRODUCT LIST / GRID CARDS
  // ========================================================
  Widget _buildProductList() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 42,
              color: Color(0xFFA1978A),
            ),
            const SizedBox(height: 12),
            Text(
              'No matching products found',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF332D26),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching with a different keyword or barcode.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF7A7268),
              ),
            ),
          ],
        ),
      );
    }

    if (_isGridView) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => _buildProductGridCard(products[index]),
      );
    }

    return Column(
      children: List.generate(products.length, (index) {
        final product = products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildProductListCard(product),
        );
      }),
    );
  }

  Widget _buildProductListCard(PosProduct product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9E0D3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Product Image Thumbnail (72x72)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 68,
              height: 68,
              color: const Color(0xFFF7F4EF),
              child: SafeImage(
                source: product.imageAsset,
                width: 68,
                height: 68,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
                fallback: const Center(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF8A8275),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title, Subtitle, Tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.variantSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF756D62),
                  ),
                ),
                const SizedBox(height: 8),

                // Tags Row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...product.normalTags.map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EFE9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFE5DDD0)),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5A5247),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF5E6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFF0DEC0)),
                      ),
                      child: Text(
                        product.highlightTag,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94672D),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Stock count (green if available, red/grey if out of stock)
          Text(
            product.stockCount <= 0
                ? 'Out of stock'
                : '${product.stockCount} available',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: product.stockCount <= 0
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF1E7E34),
            ),
          ),
          const SizedBox(width: 24),

          // Price
          Text(
            '₹${_formatCurrency(product.price)}',
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(width: 20),

          // Add Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: product.stockCount <= 0 || _locationId == null
                  ? null
                  : () => _addToCart(product),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: product.stockCount <= 0 || _locationId == null
                      ? const Color(0xFFD6D0C7)
                      : const Color(0xFF1E1C1A),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: product.stockCount <= 0 || _locationId == null
                      ? null
                      : [
                          BoxShadow(
                            color: const Color(0xFF1E1C1A).withOpacity(0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Text(
                  product.stockCount <= 0 ? 'Out of stock' : 'Add',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: product.stockCount <= 0 || _locationId == null
                        ? const Color(0xFF756D62)
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGridCard(PosProduct product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9E0D3)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF7F4EF),
                child: SafeImage(
                  source: product.imageAsset,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(6),
                  fallback: const Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Color(0xFF8A8275),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            product.stockCount <= 0
                ? 'Out of stock'
                : '${product.stockCount} available',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: product.stockCount <= 0
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF1E7E34),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${_formatCurrency(product.price)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                onTap: product.stockCount <= 0 || _locationId == null
                    ? null
                    : () => _addToCart(product),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: product.stockCount <= 0 || _locationId == null
                        ? const Color(0xFFD6D0C7)
                        : const Color(0xFF1E1C1A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.stockCount <= 0 ? 'Out of stock' : 'Add',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: product.stockCount <= 0 || _locationId == null
                          ? const Color(0xFF756D62)
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 5. QUICK ACTIONS SECTION: Custom Item, Discount, Note, Split Payment
  // ========================================================
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E1C1A),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.add_rounded,
                label: 'Create Custom Item',
                onTap: _showCreateCustomItemDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.percent_rounded,
                label: _calculatedDiscountAmount > 0 ? 'Edit Discount' : 'Apply Discount',
                isActive: _calculatedDiscountAmount > 0,
                onTap: _showApplyDiscountDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.note_alt_outlined,
                label: (_saleNote != null && _saleNote!.isNotEmpty) ? 'Edit Note' : 'Add Note',
                isActive: _saleNote != null && _saleNote!.isNotEmpty,
                onTap: _showAddNoteDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: (_paymentState.mode == PaymentMode.split && _paymentState.isConfirmed)
                  ? _buildConfirmedSplitQuickAction()
                  : _buildQuickActionButton(
                      icon: Icons.call_split_rounded,
                      label: 'Split Payment',
                      onTap: () => _showSplitPaymentDialog(),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmedSplitQuickAction() {
    final currentTotalMinor = (_totalAmount * 100).round();
    final isStale = _paymentState.isStale(currentTotalMinor);
    final remainingMinor = currentTotalMinor - _paymentState.totalAllocatedMinor;
    final remainingFormatted = (remainingMinor.abs() / 100).toStringAsFixed(_cartHasDecimals ? 2 : 0);

    return InkWell(
      onTap: () => _showSplitPaymentDialog(),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isStale ? const Color(0xFFFFF4E5) : const Color(0xFFF3ECE1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isStale ? const Color(0xFFE07A5F) : const Color(0xFFBA8A55),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isStale ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                  size: 14,
                  color: isStale ? const Color(0xFFC84C0C) : const Color(0xFF1E7E34),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    isStale ? 'Split (Needs Update)' : 'Split Payment ✓',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isStale ? const Color(0xFFC84C0C) : const Color(0xFF181513),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Edit Split',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFBA8A55),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: _paymentState.allocations.map((a) {
                return Text(
                  '${a.displayName} ₹${_formatCurrency(a.amount, showDecimals: _cartHasDecimals)}',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B6358),
                  ),
                );
              }).toList(),
            ),
            if (isStale) ...[
              const SizedBox(height: 2),
              Text(
                'Remaining: ₹$remainingFormatted',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC84C0C),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFF5F0E8)
                : Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? const Color(0xFFBA8A55) : const Color(0xFFE4DAD0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A231A).withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isActive
                        ? const Color(0xFF8A6030)
                        : const Color(0xFFBA8A55),
                  ),
                  if (isActive)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1E7E34),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF8A6030)
                        : const Color(0xFF332D26),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // 6. RIGHT COLUMN: ACTIVE CART CARD
  // ========================================================
  Widget _buildActiveCartCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4DAD0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Active Cart (X items) + Cle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Active Cart (${_cartItems.length} items)',
                  style: GoogleFonts.inter(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: _clearCart,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8C281F),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Customer Tag Pill
          if (_selectedCustomer != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2D6C5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: Color(0xFF5A5248),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      key: const Key('customer_pill_open_dialog'),
                      onTap: _showSelectCustomerDialog,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCustomer!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2C2720),
                            ),
                          ),
                          if (_customerPhone != null && _customerPhone!.isNotEmpty)
                            Text(
                              _customerPhone!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF7A7268),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    key: const Key('change_customer_button'),
                    onPressed: _showSelectCustomerDialog,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Change',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFBA8A55),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    key: const Key('remove_customer_button'),
                    onTap: () {
                      setState(() {
                        _selectedCustomer = null;
                        _selectedCustomerId = null;
                        _customerPhone = null;
                      });
                      _showToast('Customer unlinked from sale');
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: Color(0xFF7A7268),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            InkWell(
              key: const Key('attach_customer_button'),
              onTap: _showSelectCustomerDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFFE2D6C5),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_add_alt_1_outlined,
                      size: 16,
                      color: Color(0xFFBA8A55),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Attach Customer...',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF7A7268),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          if (_stockShortages.isNotEmpty) ...[
            _buildStockChangedNotice(),
            const SizedBox(height: 12),
          ],

          // Cart Items List
          if (_cartItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 36,
                      color: Color(0xFFA1978A),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your cart is empty',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF332D26),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click "Add" on any product to begin sale',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF8A8276),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cartItems.length,
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFEFE8DE)),
              ),
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return Row(
                  children: [
                    // Item thumbnail (46x46)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFFF7F4EF),
                        child: item.product.imageAsset.isNotEmpty
                            ? Image.asset(
                                item.product.imageAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 20,
                                      color: Color(0xFF8A8275),
                                    ),
                              )
                            : const Icon(
                                Icons.inventory_2_outlined,
                                size: 20,
                                color: Color(0xFF8A8275),
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getVariantTagline(item.product),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF756D62),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_formatCurrency(item.product.price)}',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Stepper: [ - ]  qty  [ + ]
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFDFD6C9)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _decrementCartItem(index),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(4),
                            ),
                            child: const SizedBox(
                              width: 26,
                              height: 26,
                              child: Icon(
                                Icons.remove_rounded,
                                size: 14,
                                color: Color(0xFF474035),
                              ),
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 24),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181513),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _incrementCartItem(index),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                            child: const SizedBox(
                              width: 26,
                              height: 26,
                              child: Icon(
                                Icons.add_rounded,
                                size: 14,
                                color: Color(0xFF474035),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE8DFD3)),
          const SizedBox(height: 14),

          // Pricing Breakdown
          _buildSummaryRow(
            label: 'Subtotal',
            value: '₹${_formatCurrency(_subtotal, showDecimals: _cartHasDecimals)}',
          ),
          const SizedBox(height: 8),
          // ── Discount row ─────────────────────────────────────────
          _calculatedDiscountAmount > 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _discountType == SalesDiscountType.percentage
                              ? 'Discount (${_formatInputValue(_discountInputValue)}%)'
                              : 'Discount',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF635A4F),
                          ),
                        ),
                      ),
                      Text(
                        '-₹${_formatCurrency(_calculatedDiscountAmount, showDecimals: _cartHasDecimals)}',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E7E34),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Edit button
                      GestureDetector(
                        onTap: _showApplyDiscountDialog,
                        child: Text(
                          'Edit',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFBA8A55),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Remove button
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _discountType = SalesDiscountType.percentage;
                            _discountInputValue = 0.0;
                          });
                          _showToast('Discount removed');
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Color(0xFF8C281F),
                        ),
                      ),
                    ],
                  ),
                )
              : _buildSummaryRow(
                  label: 'Discount',
                  value: '₹0',
                  valueColor: const Color(0xFF1E7E34),
                  onTap: _showApplyDiscountDialog,
                ),
          const SizedBox(height: 8),

          // ── Note row (visible only when a note has been set) ──────
          if (_saleNote != null && _saleNote!.isNotEmpty) ...
            [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  children: [
                    const Icon(
                      Icons.note_alt_outlined,
                      size: 13,
                      color: Color(0xFF8A8276),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _saleNote!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF635A4F),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _showAddNoteDialog,
                      child: Text(
                        'Edit',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFBA8A55),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() => _saleNote = null);
                        _showToast('Note removed');
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Color(0xFF8C281F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

          _buildSummaryRow(
            label: _taxLabel,
            value: '₹${_formatCurrency(_taxAmount, showDecimals: _cartHasDecimals)}',
          ),
          const SizedBox(height: 14),

          // Total Amount (Big font)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Total Amount',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
              ),
              Text(
                '₹${_formatCurrency(_totalAmount, showDecimals: _cartHasDecimals)}',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Complete Sale CTA
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _cartItems.isEmpty || _isProcessingSale || _locationId == null
                  ? null
                  : _completeSale,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: _cartItems.isEmpty || _isProcessingSale || _locationId == null
                      ? const Color(0xFF7A7065)
                      : const Color(0xFF382718),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E1C1A).withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isProcessingSale) ...[
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                    ] else ...[
                      const Icon(
                        Icons.lock_outline_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _isProcessingSale ? 'Processing Sale...' : 'Complete Sale',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Hold Sale CTA
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _cartItems.isEmpty || _isHoldingSale || _isProcessingSale || _locationId == null
                  ? null
                  : _holdSale,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD8CFBF)),
                ),
                alignment: Alignment.center,
                child: _isHoldingSale
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2E2720),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Holding Sale...',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E2720),
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Hold Sale',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E2720),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF635A4F),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF181513),
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: row,
        ),
      );
    }
    return row;
  }

  String _getVariantTagline(PosProduct product) {
    // Extracts clean variant text, e.g. "Black • M"
    final parts = product.variantSubtitle.split(' • SKU:');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return product.variantSubtitle;
  }

  String _formatInputValue(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    final str = val.toStringAsFixed(2);
    return str.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }

  String _formatCurrency(num amount, {bool showDecimals = false}) {
    // Safe minor currency representation (paise)
    final paise = (amount * 100).round();
    final isNegative = paise < 0;
    final absPaise = paise.abs();
    final intPart = absPaise ~/ 100;
    final decPart = absPaise % 100;

    final str = intPart.toString();
    String formattedInt;
    if (str.length <= 3) {
      formattedInt = str;
    } else {
      final lastThree = str.substring(str.length - 3);
      final rest = str.substring(0, str.length - 3);

      final buffer = StringBuffer();
      for (int i = 0; i < rest.length; i++) {
        if (i > 0 && (rest.length - i) % 2 == 0) {
          buffer.write(',');
        }
        buffer.write(rest[i]);
      }
      formattedInt = '${buffer.toString()},$lastThree';
    }

    final sign = isNegative ? '-' : '';
    if (decPart > 0 || showDecimals) {
      return '$sign$formattedInt.${decPart.toString().padLeft(2, '0')}';
    }
    return '$sign$formattedInt';
  }

  // ========================================================
  // 7. POS CHECKOUT & MODALS
  // ========================================================
  void _completeSale() {
    if (_locationId == null) {
      _showToast(
        'Cannot complete sale: No location configured for this business.',
        isError: true,
      );
      return;
    }
    if (_cartItems.isEmpty) {
      _showToast('Cart is empty. Add products before completing a sale.');
      return;
    }
    if (_isProcessingSale) return;

    // Check stock upfront before opening payment
    for (final item in _cartItems) {
      if (item.quantity > item.product.stockCount) {
        _showToast('${item.product.title} only has ${item.product.stockCount} units available. Reduce the quantity before completing this sale.');
        return;
      }
    }

    _showPaymentSelectionDialog();
  }

  void _showPaymentSelectionDialog() {
    String selectedMethod = 'cash'; // 'cash', 'card', 'upi', 'split'
    final refCtrl = TextEditingController();
    String? paymentError;

    showDialog(
      context: context,
      barrierDismissible: !_isProcessingSale,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isSplitConfigured = _paymentState.mode == PaymentMode.split && _paymentState.isConfirmed;
          final currentTotalMinor = (_totalAmount * 100).round();
          final isStale = isSplitConfigured && _paymentState.isStale(currentTotalMinor);
          final allocatedMinor = isSplitConfigured ? _paymentState.totalAllocatedMinor : currentTotalMinor;
          final remainingMinor = currentTotalMinor - allocatedMinor;
          final remainingAmount = (remainingMinor.abs()) / 100;

          return AlertDialog(
            backgroundColor: const Color(0xFFFAF7F2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFDFD4C5)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF0E4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: Color(0xFFBA8A55),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Complete Sale — Payment',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3ECE1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFDFD4C5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Items (${_cartItems.length}):',
                                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B6358)),
                              ),
                              Text(
                                '₹${_formatCurrency(_subtotal, showDecimals: _cartHasDecimals)}',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          if (_calculatedDiscountAmount > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _discountType == SalesDiscountType.percentage
                                      ? 'Discount (${_formatInputValue(_discountInputValue)}%):'
                                      : 'Discount:',
                                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E7E34)),
                                ),
                                Text(
                                  '-₹${_formatCurrency(_calculatedDiscountAmount, showDecimals: _cartHasDecimals)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E7E34),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Color(0xFFDFD4C5)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Payable',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF181513),
                                ),
                              ),
                              Text(
                                '₹${_formatCurrency(_totalAmount, showDecimals: _cartHasDecimals)}',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF181513),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedCustomer != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.person_outline, size: 14, color: Color(0xFF8C8275)),
                                const SizedBox(width: 4),
                                Text(
                                  _selectedCustomer!,
                                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B6358)),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (isSplitConfigured) ...[
                      // Confirmed Split Breakdown (Reused directly, no need to click Split again)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isStale ? const Color(0xFFE07A5F) : const Color(0xFFDFD4C5),
                            width: isStale ? 1.5 : 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isStale ? Icons.warning_amber_rounded : Icons.call_split_rounded,
                                      size: 16,
                                      color: isStale ? const Color(0xFFC84C0C) : const Color(0xFFBA8A55),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Split Payment',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isStale ? const Color(0xFFC84C0C) : const Color(0xFF181513),
                                      ),
                                    ),
                                  ],
                                ),
                                if (isStale)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF4E5),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFE07A5F)),
                                    ),
                                    child: Text(
                                      'Needs Update',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFC84C0C),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1, color: Color(0xFFDFD4C5)),
                            const SizedBox(height: 8),

                            // Allocations breakdown
                            ..._paymentState.allocations.map((alloc) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      alloc.displayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF181513),
                                      ),
                                    ),
                                    Text(
                                      '₹${_formatCurrency(alloc.amount, showDecimals: _cartHasDecimals)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF181513),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            const SizedBox(height: 8),
                            const Divider(height: 1, color: Color(0xFFDFD4C5)),
                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  isStale ? 'Previous Allocation' : 'Total Allocated',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B6358),
                                  ),
                                ),
                                Text(
                                  '₹${_formatCurrency(_paymentState.totalAllocated, showDecimals: _cartHasDecimals)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF181513),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Remaining',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isStale ? const Color(0xFFC84C0C) : const Color(0xFF6B6358),
                                  ),
                                ),
                                Text(
                                  '₹${_formatCurrency(remainingAmount, showDecimals: _cartHasDecimals)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isStale ? const Color(0xFFC84C0C) : const Color(0xFF1E7E34),
                                  ),
                                ),
                              ],
                            ),

                            if (isStale) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Total Payable changed. Please update payment allocations before completing.',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFC84C0C),
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFBA8A55),
                                    side: const BorderSide(color: Color(0xFFBA8A55)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  icon: const Icon(Icons.edit_outlined, size: 14),
                                  label: const Text('Edit Split'),
                                  onPressed: () {
                                    _showSplitPaymentDialog(
                                      onConfirmed: () {
                                        setModalState(() {});
                                      },
                                    );
                                  },
                                ),
                                TextButton(
                                  onPressed: () {
                                    setModalState(() {
                                      _paymentState = const CartPaymentState();
                                      selectedMethod = 'cash';
                                      _persistActiveSession();
                                    });
                                  },
                                  child: Text(
                                    'Switch to Single Payment',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: const Color(0xFF8C8275),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Normal Payment-Method Selection: Cash, Card, UPI, Split
                      Text(
                        'Select Payment Method',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          _buildPaymentMethodOption(
                            label: 'Cash',
                            icon: Icons.payments_outlined,
                            isSelected: selectedMethod == 'cash',
                            onTap: () => setModalState(() {
                              selectedMethod = 'cash';
                              paymentError = null;
                            }),
                          ),
                          const SizedBox(width: 8),
                          _buildPaymentMethodOption(
                            label: 'Card',
                            icon: Icons.credit_card_rounded,
                            isSelected: selectedMethod == 'card',
                            onTap: () => setModalState(() {
                              selectedMethod = 'card';
                              paymentError = null;
                            }),
                          ),
                          const SizedBox(width: 8),
                          _buildPaymentMethodOption(
                            label: 'UPI',
                            icon: Icons.qr_code_rounded,
                            isSelected: selectedMethod == 'upi',
                            onTap: () => setModalState(() {
                              selectedMethod = 'upi';
                              paymentError = null;
                            }),
                          ),
                          const SizedBox(width: 8),
                          _buildPaymentMethodOption(
                            label: 'Split',
                            icon: Icons.call_split_rounded,
                            isSelected: false,
                            onTap: () {
                              _showSplitPaymentDialog(
                                onConfirmed: () {
                                  setModalState(() {});
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      if (selectedMethod == 'card') ...[
                        TextField(
                          controller: refCtrl,
                          decoration: InputDecoration(
                            labelText: 'Card Reference / Last 4 Digits (Optional)',
                            hintText: 'e.g. 4242 or AUTH123',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ] else if (selectedMethod == 'upi') ...[
                        TextField(
                          controller: refCtrl,
                          decoration: InputDecoration(
                            labelText: 'UPI Transaction Reference (Optional)',
                            hintText: 'e.g. UPI Ref / GooglePay / PhonePe ID',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ],
                    ],

                    if (paymentError != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        paymentError!,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB3261E),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isProcessingSale ? null : () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF6B6358))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1C1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  disabledBackgroundColor: const Color(0xFF7A7065),
                ),
                onPressed: (_isProcessingSale || (isSplitConfigured && isStale))
                    ? null
                    : () async {
                        await _processConfirmedSale(
                          dialogContext: ctx,
                          selectedMethod: isSplitConfigured ? 'split' : selectedMethod,
                          referenceNumber: refCtrl.text.trim(),
                          setModalError: (err) => setModalState(() => paymentError = err),
                        );
                      },
                child: _isProcessingSale
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Confirm & Complete ₹${_formatCurrency(_totalAmount, showDecimals: _cartHasDecimals)}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E1C1A) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF1E1C1A) : const Color(0xFFDFD4C5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFFFAF0E4) : const Color(0xFF6B6358),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF181513),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processConfirmedSale({
    required BuildContext dialogContext,
    required String selectedMethod,
    String? referenceNumber,
    required void Function(String?) setModalError,
  }) async {
    // 1. Double check quantities against live stock
    for (final item in _cartItems) {
      if (item.quantity > item.product.stockCount) {
        setModalError('${item.product.title} only has ${item.product.stockCount} units available. Reduce the quantity before completing this sale.');
        return;
      }
    }

    // 2. Prepare payments payload
    final List<Map<String, dynamic>> paymentsPayload = [];
    final currentTotalMinor = (_totalAmount * 100).round();

    if (selectedMethod == 'split') {
      if (!_paymentState.isConfirmed || _paymentState.allocations.isEmpty) {
        setModalError('Please configure and confirm split payment allocations.');
        return;
      }
      if (_paymentState.isStale(currentTotalMinor)) {
        setModalError('Payment allocations do not match the current cart total. Please edit split.');
        return;
      }
      if (_paymentState.totalAllocatedMinor != currentTotalMinor) {
        setModalError('Allocated amount does not match total payable.');
        return;
      }

      for (final alloc in _paymentState.allocations) {
        paymentsPayload.add({
          'payment_method': alloc.method,
          'amount_minor': alloc.amountMinor,
          'processing_type': 'recorded',
          if (alloc.reference != null && alloc.reference!.isNotEmpty)
            'reference_number': alloc.reference,
          'currency_code': CurrentBusinessService.instance.currentBusiness?.currencyCode ?? 'INR',
        });
      }
    } else {
      paymentsPayload.add({
        'payment_method': selectedMethod,
        'amount_minor': currentTotalMinor,
        'processing_type': 'recorded',
        if (referenceNumber != null && referenceNumber.isNotEmpty)
          'reference_number': referenceNumber,
        'currency_code': CurrentBusinessService.instance.currentBusiness?.currencyCode ?? 'INR',
      });
    }

    setState(() {
      _isProcessingSale = true;
    });

    final businessId = CurrentBusinessService.instance.currentBusinessId ?? 'default_business';
    final itemsPayload = _buildItemsPayload();

    try {
      final result = await SalesRepository.instance.completeSale(
        businessId: businessId,
        locationId: _locationId ?? CurrentBusinessService.instance.currentLocationId,
        saleId: _resumedSaleId,
        customerId: _selectedCustomerId,
        customerName: _selectedCustomer,
        subtotal: _subtotal,
        discount: _calculatedDiscountAmount,
        discountType: _discountType == SalesDiscountType.percentage ? 'percentage' : 'flat',
        discountRate: _discountInputValue,
        tax: _taxAmount,
        total: _totalAmount,
        currencyCode: CurrentBusinessService.instance.currentBusiness?.currencyCode ?? 'INR',
        note: _saleNote,
        idempotencyKey: 'pos_${DateTime.now().millisecondsSinceEpoch}',
        items: itemsPayload,
        payments: paymentsPayload,
      );

      if (!mounted) return;

      if (result.success && result.sale != null) {
        final completedSale = result.sale!;

        // 1. Authoritative invoice loading from persisted completed sale
        final invoiceData = await SalesRepository.instance.loadInvoiceData(
          businessId: businessId,
          saleId: completedSale.id,
          preloadedSale: completedSale,
        );

        // 2. Decrement local catalog count immediately so UI reflects stock update
        for (final item in _cartItems) {
          final catIdx = _catalog.indexWhere((p) => p.id == item.product.id);
          if (catIdx >= 0) {
            final old = _catalog[catIdx];
            final newCount = (old.stockCount - item.quantity).clamp(0, 999999);
            _catalog[catIdx] = old.copyWith(stockCount: newCount);
          }
        }

        if (dialogContext.mounted) {
          Navigator.pop(dialogContext); // Close payment dialog
        }

        // 3. Clear active sale state AFTER persisted sale data is loaded
        setState(() {
          _clearActiveSaleState(preserveLocation: true);
          _isProcessingSale = false;
        });

        // Trigger background refresh of products/inventory
        _loadProducts();

        // 4. Show polished Sale Complete modal
        if (invoiceData != null && mounted) {
          SaleCompleteModal.show(
            context: context,
            invoice: invoiceData,
            onStartNewSale: () {
              setState(() {
                _clearActiveSaleState(preserveLocation: true);
              });
            },
          );
        } else if (mounted) {
          _showSaleReceiptDialog(completedSale);
        }
      } else {
        setState(() {
          _isProcessingSale = false;
        });
        setModalError(result.errorMessage ?? 'Failed to complete sale');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessingSale = false;
        });
        setModalError(e.toString());
      }
    }
  }

  void _showSaleReceiptDialog(Sale sale) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFDFD4C5)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sale Completed',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  Text(
                    'Receipt #${sale.saleNumber}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B6358),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2D6C5)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Sale Number', sale.saleNumber),
                    const SizedBox(height: 6),
                    _buildReceiptRow(
                      'Customer',
                      sale.customerName ?? (sale.customerId == null ? 'Walk-in Customer' : 'Attached Customer'),
                    ),
                    const SizedBox(height: 6),
                    _buildReceiptRow(
                      'Payment',
                      sale.payments.isNotEmpty
                          ? '${sale.payments.first.paymentMethod.toUpperCase()} • ₹${_formatCurrency(sale.total, showDecimals: sale.total % 1 != 0)}'
                          : 'Recorded',
                    ),
                    const SizedBox(height: 6),
                    _buildReceiptRow(
                      'Date & Time',
                      '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                    ),
                    const Divider(height: 18, color: Color(0xFFDFD4C5)),
                    _buildReceiptRow(
                      'Subtotal',
                      '₹${_formatCurrency(sale.subtotal, showDecimals: sale.subtotal % 1 != 0 || sale.discount % 1 != 0)}',
                    ),
                    if (sale.discount > 0) ...[
                      const SizedBox(height: 6),
                      _buildReceiptRow(
                        'Discount',
                        '-₹${_formatCurrency(sale.discount, showDecimals: sale.discount % 1 != 0)}',
                        color: const Color(0xFF1E7E34),
                      ),
                    ],
                    const SizedBox(height: 6),
                    _buildReceiptRow(
                      'Tax',
                      '₹${_formatCurrency(sale.tax, showDecimals: sale.tax % 1 != 0)}',
                    ),
                    const Divider(height: 18, color: Color(0xFFDFD4C5)),
                    _buildReceiptRow(
                      'Total Paid',
                      '₹${_formatCurrency(sale.total, showDecimals: sale.total % 1 != 0)}',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFDFD4C5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              _showToast('Receipt sent to POS printer');
            },
            child: Text(
              'Print Receipt',
              style: GoogleFonts.inter(color: const Color(0xFF2E2720), fontSize: 13),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1C1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: Text(
              'New Sale',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? color, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isBold ? 14 : 12.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? const Color(0xFF181513) : const Color(0xFF6B6358),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isBold ? 16 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? (isBold ? const Color(0xFF181513) : const Color(0xFF2E2720)),
          ),
        ),
      ],
    );
  }

  Future<void> _holdSale() async {
    if (_locationId == null) {
      _showToast(
        'Cannot hold sale: No location configured for this business.',
        isError: true,
      );
      return;
    }
    if (_cartItems.isEmpty || _isHoldingSale || _isProcessingSale) return;
    setState(() => _isHoldingSale = true);

    final businessId = CurrentBusinessService.instance.currentBusinessId;
    if (businessId == null || businessId.isEmpty || businessId.startsWith('biz_')) {
      if (mounted) setState(() => _isHoldingSale = false);
      _showToast('Select a business before holding this sale.', isError: true);
      return;
    }

    final result = await SalesRepository.instance.holdSale(
      businessId: businessId,
      locationId: _locationId ?? CurrentBusinessService.instance.currentLocationId,
      customerId: _selectedCustomerId,
      customerName: _selectedCustomer,
      customerPhone: _customerPhone,
      saleId: _resumedSaleId,
      subtotal: _subtotal,
      discount: _calculatedDiscountAmount,
      discountType: _discountType == SalesDiscountType.percentage ? 'percentage' : 'flat',
      discountRate: _discountInputValue,
      tax: _taxAmount,
      total: _totalAmount,
      currencyCode: CurrentBusinessService.instance.currentBusiness?.currencyCode ?? 'INR',
      note: _saleNote,
      items: _buildItemsPayload(),
    );

    if (!mounted) return;
    if (!result.success) {
      setState(() => _isHoldingSale = false);
      _showToast(result.errorMessage ?? 'Could not hold this sale.', isError: true);
      return;
    }

    setState(() {
      _clearActiveSaleState();
      _isHoldingSale = false;
    });
    _showToast(
      'Sale held successfully',
      detail: 'Resume it anytime from Sales → Held Sales.',
    );
  }

  void _showSelectCustomerDialog() {
    final searchCtrl = TextEditingController();
    final newNameCtrl = TextEditingController();
    final newPhoneCtrl = TextEditingController();
    final newEmailCtrl = TextEditingController();

    // Default country/ISD from current business settings
    final bizCountryCode = CurrentBusinessService.instance.currentBusiness?.countryCode ?? 'IN';
    final defaultIsd = CustomerInputClassifier.defaultIsdForCountryCode(bizCountryCode);
    String selectedIsd = defaultIsd;

    List<Customer> recentCustomers = [];
    bool isLoadingRecent = true;
    List<Customer> searchResults = [];
    bool isSearching = false;
    bool showCreateForm = false;
    String? formError;
    Customer? duplicateCustomer;
    bool isCreating = false;

    // Track user manual edits to ensure we NEVER overwrite manual user input
    bool isNameManuallyEdited = false;
    bool isPhoneManuallyEdited = false;
    bool isEmailManuallyEdited = false;

    Timer? debounceTimer;
    bool hasLoadedInitial = false;

    final businessId = CurrentBusinessService.instance.currentBusinessId ?? '';

    void Function()? listenerCleanup;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> loadRecentCustomers() async {
            if (!ctx.mounted) return;
            setModalState(() => isLoadingRecent = true);
            try {
              String resolvedBizId = businessId;
              if (resolvedBizId.isEmpty || resolvedBizId.startsWith('biz_')) {
                final res = await SalesRepository.instance.resolveCurrentBusinessId();
                if (res != null && res.isNotEmpty) resolvedBizId = res;
              }
              final list = await SalesRepository.instance.getRecentCustomers(
                businessId: resolvedBizId,
                limit: 10,
              );
              if (ctx.mounted) {
                setModalState(() {
                  recentCustomers = list;
                  isLoadingRecent = false;
                });
              }
            } catch (e) {
              if (ctx.mounted) {
                setModalState(() {
                  isLoadingRecent = false;
                });
              }
            }
          }

          if (!hasLoadedInitial) {
            hasLoadedInitial = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              loadRecentCustomers();
            });

            void onCustomerChanged() {
              if (ctx.mounted) {
                loadRecentCustomers();
              }
            }
            CustomerChangeNotifier.instance.addListener(onCustomerChanged);
            listenerCleanup = () {
              CustomerChangeNotifier.instance.removeListener(onCustomerChanged);
            };
          }

          void autoFillFromSearch(String rawQuery) {
            final classification = CustomerInputClassifier.classify(
              rawQuery,
              defaultIsd: defaultIsd,
            );

            switch (classification.type) {
              case CustomerInputType.phone:
                if (!isPhoneManuallyEdited) {
                  newPhoneCtrl.text = classification.detectedPhone ?? '';
                  if (classification.detectedIsd != null) {
                    selectedIsd = classification.detectedIsd!;
                  }
                }
                if (!isNameManuallyEdited) {
                  newNameCtrl.text = '';
                }
                if (!isEmailManuallyEdited) {
                  newEmailCtrl.text = '';
                }
                break;

              case CustomerInputType.email:
                if (!isEmailManuallyEdited) {
                  newEmailCtrl.text = classification.detectedEmail ?? '';
                }
                if (!isNameManuallyEdited) {
                  newNameCtrl.text = '';
                }
                if (!isPhoneManuallyEdited) {
                  newPhoneCtrl.text = '';
                }
                break;

              case CustomerInputType.name:
                if (!isNameManuallyEdited) {
                  newNameCtrl.text = classification.detectedName ?? '';
                }
                if (!isPhoneManuallyEdited) {
                  newPhoneCtrl.text = '';
                }
                if (!isEmailManuallyEdited) {
                  newEmailCtrl.text = '';
                }
                break;

              case CustomerInputType.empty:
                if (!isNameManuallyEdited) newNameCtrl.text = '';
                if (!isPhoneManuallyEdited) newPhoneCtrl.text = '';
                if (!isEmailManuallyEdited) newEmailCtrl.text = '';
                break;
            }
          }

          Future<void> doSearch(String query) async {
            if (query.isEmpty) {
              setModalState(() {
                searchResults = [];
                isSearching = false;
              });
              return;
            }
            setModalState(() => isSearching = true);
            String resolvedBizId = businessId;
            if (resolvedBizId.isEmpty || resolvedBizId.startsWith('biz_')) {
              final res = await SalesRepository.instance.resolveCurrentBusinessId();
              if (res != null && res.isNotEmpty) resolvedBizId = res;
            }
            final results = await SalesRepository.instance.searchCustomers(
              businessId: resolvedBizId,
              query: query,
              defaultIsd: defaultIsd,
            );
            if (ctx.mounted) {
              setModalState(() {
                searchResults = results;
                isSearching = false;
              });
            }
          }

          Future<void> doCreate() async {
            final name = newNameCtrl.text.trim();
            final localPhone = newPhoneCtrl.text.trim();
            final email = newEmailCtrl.text.trim();

            if (name.isEmpty) {
              setModalState(() => formError = 'Full Name is required');
              return;
            }

            String resolvedBizId = businessId;
            if (resolvedBizId.isEmpty || resolvedBizId.startsWith('biz_')) {
              final res = await SalesRepository.instance.resolveCurrentBusinessId();
              if (res != null && res.isNotEmpty) resolvedBizId = res;
            }

            String? phoneE164;
            if (localPhone.isNotEmpty) {
              phoneE164 = CustomerInputClassifier.normalizeToE164(localPhone, defaultIsd: selectedIsd);
            }

            // Real-time duplicate check
            final duplicate = await SalesRepository.instance.findDuplicateCustomer(
              businessId: resolvedBizId,
              phoneE164: phoneE164,
              email: email.isNotEmpty ? email : null,
            );

            if (duplicate != null) {
              if (ctx.mounted) {
                final isPhoneMatch = phoneE164 != null &&
                    duplicate.phone != null &&
                    (duplicate.phone == phoneE164 ||
                        CustomerInputClassifier.cleanDigits(duplicate.phone!) ==
                            CustomerInputClassifier.cleanDigits(phoneE164));
                setModalState(() {
                  duplicateCustomer = duplicate;
                  formError = 'A customer with this ${isPhoneMatch ? "phone number" : "email"} already exists.';
                });
              }
              return;
            }

            setModalState(() {
              isCreating = true;
              formError = null;
              duplicateCustomer = null;
            });

            final created = await SalesRepository.instance.createCustomer(
              businessId: resolvedBizId,
              name: name,
              phone: phoneE164,
              email: email.isNotEmpty ? email : null,
            );

            if (!ctx.mounted) return;

            if (created != null) {
              setState(() {
                _selectedCustomer = created.name;
                _selectedCustomerId = created.id;
                _customerPhone = created.phone;
              });
              Navigator.pop(ctx);
              _showToast('Customer "${created.name}" attached to sale');
            } else {
              setModalState(() {
                isCreating = false;
                formError = 'Failed to create customer. Check your connection.';
              });
            }
          }

          final hasExactMatch = searchResults.any((c) {
            final cleanSearch = CustomerInputClassifier.cleanDigits(searchCtrl.text);
            final isEmail = searchCtrl.text.contains('@');
            if (isEmail && c.email != null) {
              return c.email!.toLowerCase() == searchCtrl.text.trim().toLowerCase();
            }
            if (cleanSearch.length >= 7 && c.phone != null) {
              return CustomerInputClassifier.cleanDigits(c.phone!) == cleanSearch;
            }
            return false;
          });

          return Dialog(
            backgroundColor: const Color(0xFFFAF7F2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFDFD4C5)),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460, maxHeight: 680),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Attach Customer',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Search field
                    TextField(
                      key: const Key('customer_search_field'),
                      controller: searchCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by name, phone or email...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 1.5),
                                ),
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                        ),
                      ),
                      onChanged: (v) {
                        if (showCreateForm) {
                          autoFillFromSearch(v);
                        }
                        debounceTimer?.cancel();
                        debounceTimer = Timer(const Duration(milliseconds: 200), () {
                          doSearch(v.trim());
                        });
                        setModalState(() {});
                      },
                    ),
                    const SizedBox(height: 10),

                    // Results list
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          // Walk-in option (always visible)
                          _buildCustomerSearchTile(
                            key: const Key('walk_in_customer_tile'),
                            name: 'Walk-in Customer',
                            subtitle: 'No account attached',
                            isAttached: _selectedCustomerId == null &&
                                (_selectedCustomer == null || _selectedCustomer == 'Walk-in Customer'),
                            onTap: () {
                              setState(() {
                                _selectedCustomer = 'Walk-in Customer';
                                _selectedCustomerId = null;
                                _customerPhone = null;
                              });
                              Navigator.pop(ctx);
                              _showToast('Walk-in sale');
                            },
                          ),

                          // Search is empty: display Recent Customers
                          if (searchCtrl.text.trim().isEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 12, bottom: 6),
                              child: Text(
                                'Recent Customers',
                                key: const Key('recent_customers_header'),
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7A7268),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if (isLoadingRecent)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              )
                            else if (recentCustomers.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text(
                                  'No saved customers found.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF8A8276),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            else
                              for (final c in recentCustomers)
                                _buildCustomerSearchTile(
                                  key: Key('customer_tile_${c.id}'),
                                  name: c.name,
                                  subtitle: c.phone != null && c.phone!.isNotEmpty
                                      ? (c.email != null && c.email!.isNotEmpty
                                          ? '${c.phone} • ${c.email}'
                                          : c.phone!)
                                      : (c.email ?? ''),
                                  isAttached: c.id == _selectedCustomerId,
                                  onTap: () {
                                    setState(() {
                                      _selectedCustomer = c.name;
                                      _selectedCustomerId = c.id;
                                      _customerPhone = c.phone;
                                    });
                                    Navigator.pop(ctx);
                                    _showToast('${c.name} attached to sale');
                                  },
                                ),

                            // Option to create new customer even when search is empty
                            InkWell(
                              key: const Key('create_new_customer_tile'),
                              onTap: () {
                                setModalState(() {
                                  showCreateForm = !showCreateForm;
                                  if (showCreateForm) {
                                    autoFillFromSearch(searchCtrl.text);
                                  }
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.person_add_alt_1_outlined,
                                      size: 16,
                                      color: Color(0xFFBA8A55),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Create new customer',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFBA8A55),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      showCreateForm
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: const Color(0xFFBA8A55),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            // Search is active
                            if (isSearching)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              )
                            else if (searchResults.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Text(
                                  'No customers matching "${searchCtrl.text.trim()}".',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: const Color(0xFF8A8276),
                                  ),
                                ),
                              )
                            else
                              for (final c in searchResults)
                                _buildCustomerSearchTile(
                                  key: Key('customer_tile_${c.id}'),
                                  name: c.name,
                                  subtitle: c.phone != null && c.phone!.isNotEmpty
                                      ? (c.email != null && c.email!.isNotEmpty
                                          ? '${c.phone} • ${c.email}'
                                          : c.phone!)
                                      : (c.email ?? ''),
                                  isAttached: c.id == _selectedCustomerId,
                                  onTap: () {
                                    setState(() {
                                      _selectedCustomer = c.name;
                                      _selectedCustomerId = c.id;
                                      _customerPhone = c.phone;
                                    });
                                    Navigator.pop(ctx);
                                    _showToast('${c.name} attached to sale');
                                  },
                                ),

                            // "Create new customer" option when not exact match
                            if (!isSearching && !hasExactMatch)
                              InkWell(
                                key: const Key('create_new_customer_tile'),
                                onTap: () {
                                  setModalState(() {
                                    showCreateForm = !showCreateForm;
                                    if (showCreateForm) {
                                      autoFillFromSearch(searchCtrl.text);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.person_add_alt_1_outlined,
                                        size: 16,
                                        color: Color(0xFFBA8A55),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Create new customer'
                                          '${searchCtrl.text.trim().isNotEmpty ? ' "${searchCtrl.text.trim()}"' : ''}',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFBA8A55),
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        showCreateForm
                                            ? Icons.keyboard_arrow_up_rounded
                                            : Icons.keyboard_arrow_down_rounded,
                                        size: 16,
                                        color: const Color(0xFFBA8A55),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],

                          // Inline create form
                          if (showCreateForm) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE2D6C5)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    key: const Key('customer_name_field'),
                                    controller: newNameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Full Name *',
                                      isDense: true,
                                    ),
                                    onChanged: (_) {
                                      isNameManuallyEdited = true;
                                      setModalState(() => formError = null);
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  // ISD + phone
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // ISD selector
                                      Container(
                                        height: 48,
                                        decoration: BoxDecoration(
                                          border:
                                              Border.all(color: const Color(0xFFCCC5BB)),
                                          borderRadius: BorderRadius.circular(6),
                                          color: const Color(0xFFFAF7F2),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: selectedIsd,
                                            isDense: true,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            items: CustomerInputClassifier.isdCodes
                                                .map((m) => DropdownMenuItem(
                                                      value: m['isd'],
                                                      child: Text(
                                                        '${m['isd']} ${m['code']}',
                                                        style: GoogleFonts.inter(
                                                            fontSize: 12.5),
                                                      ),
                                                    ))
                                                .toList(),
                                            onChanged: (v) {
                                              if (v != null) {
                                                setModalState(() {
                                                  selectedIsd = v;
                                                  formError = null;
                                                  duplicateCustomer = null;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          key: const Key('customer_phone_field'),
                                          controller: newPhoneCtrl,
                                          keyboardType: TextInputType.phone,
                                          decoration: const InputDecoration(
                                            labelText: 'Phone',
                                            isDense: true,
                                          ),
                                          onChanged: (_) {
                                            isPhoneManuallyEdited = true;
                                            setModalState(() {
                                              formError = null;
                                              duplicateCustomer = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    key: const Key('customer_email_field'),
                                    controller: newEmailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'Email',
                                      isDense: true,
                                    ),
                                    onChanged: (_) {
                                      isEmailManuallyEdited = true;
                                      setModalState(() {
                                        formError = null;
                                        duplicateCustomer = null;
                                      });
                                    },
                                  ),
                                  if (duplicateCustomer != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      key: const Key('customer_duplicate_alert'),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFF59E0B)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFB45309)),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  formError ?? 'Customer already exists',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(0xFF92400E),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${duplicateCustomer!.name} (${duplicateCustomer!.phone ?? duplicateCustomer!.email ?? ""})',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF1E1C1A),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              key: const Key('attach_duplicate_customer_button'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFFB45309),
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedCustomer = duplicateCustomer!.name;
                                                  _selectedCustomerId = duplicateCustomer!.id;
                                                  _customerPhone = duplicateCustomer!.phone;
                                                });
                                                Navigator.pop(ctx);
                                                _showToast('${duplicateCustomer!.name} attached to sale');
                                              },
                                              child: Text(
                                                'Attach ${duplicateCustomer!.name}',
                                                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ] else if (formError != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      formError!,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFFDC2626),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  // Create & Attach button — disabled until a valid name is entered
                                  Builder(
                                    builder: (context) {
                                      final canCreate = !isCreating && newNameCtrl.text.trim().isNotEmpty;
                                      return SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          key: const Key('create_and_attach_customer_button'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1E1C1A),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          onPressed: canCreate ? doCreate : null,
                                          child: isCreating
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                              : Text(
                                                  'Create & Attach',
                                                  style: GoogleFonts.inter(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF635A4F),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).then((_) {
      listenerCleanup?.call();
    });
  }

  Widget _buildCustomerSearchTile({
    Key? key,
    required String name,
    required String subtitle,
    required VoidCallback onTap,
    bool isAttached = false,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: isAttached
            ? BoxDecoration(
                color: const Color(0xFFF2EDE5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBA8A55)),
              )
            : null,
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isAttached ? const Color(0xFFBA8A55) : const Color(0xFFF2EDE5),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isAttached ? Colors.white : const Color(0xFFBA8A55),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2C2720),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isAttached) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF81C784)),
                          ),
                          child: Text(
                            'Attached',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF8A8276),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (isAttached)
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: Color(0xFF2E7D32),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateCustomItemDialog() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFDFD4C5)),
        ),
        title: Text(
          'Create Custom Item',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Item Name / Description',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1C1A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final title = titleCtrl.text.trim();
              final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
              if (title.isNotEmpty && price > 0) {
                Navigator.pop(ctx);
                setState(() {
                  _cartItems.add(
                    PosCartItem(
                      product: PosProduct(
                        id: 'CUSTOM-${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        variantSubtitle: 'Custom ThreadStock Line',
                        imageAsset: '',
                        price: price,
                        stockCount: 1,
                        normalTags: ['Custom'],
                        highlightTag: 'Special',
                      ),
                      quantity: 1,
                    ),
                  );
                });
                _showToast('Custom item added to cart');
              }
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  void _showApplyDiscountDialog() {
    var selectedType = _discountType;
    final initialText = _discountInputValue > 0
        ? _formatInputValue(_discountInputValue)
        : '';
    final discountCtrl = TextEditingController(text: initialText);
    String? errorText;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          void setLocalError(String? message) {
            setDialogState(() {
              errorText = message;
            });
          }

          final currentInput = discountCtrl.text.trim();
          final parsed = double.tryParse(currentInput);
          double? previewDiscount;
          double? previewTotal;
          if (parsed != null && parsed >= 0) {
            final calc = SalesDiscountCalculator.calculateDiscountAmount(
              subtotal: _subtotal,
              type: selectedType,
              inputValue: parsed,
            );
            if (calc <= _subtotal &&
                (selectedType != SalesDiscountType.percentage || parsed <= 100)) {
              previewDiscount = calc;
              previewTotal = (_subtotal - calc).clamp(0.0, double.infinity);
            }
          }

          return AlertDialog(
            backgroundColor: const Color(0xFFFAF7F2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFDFD4C5)),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF0E4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.percent_rounded,
                    color: Color(0xFFBA8A55),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Apply Discount',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discount Type',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF756C60),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Segmented Type Selector: [ Percentage % ] [ Flat Amount ]
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE4D8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedType = SalesDiscountType.percentage;
                                errorText = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedType == SalesDiscountType.percentage
                                    ? const Color(0xFF1E1C1A)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Percentage %',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: selectedType == SalesDiscountType.percentage
                                      ? Colors.white
                                      : const Color(0xFF5E5448),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setDialogState(() {
                                selectedType = SalesDiscountType.flat;
                                errorText = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: selectedType == SalesDiscountType.flat
                                    ? const Color(0xFF1E1C1A)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'Flat Amount',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: selectedType == SalesDiscountType.flat
                                      ? Colors.white
                                      : const Color(0xFF5E5448),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    selectedType == SalesDiscountType.percentage
                        ? 'Enter percentage to discount from subtotal:'
                        : 'Enter flat amount in rupees to discount:',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF6B6358),
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: discountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: selectedType == SalesDiscountType.percentage
                          ? 'Discount (%)'
                          : 'Discount (₹)',
                      prefixText: selectedType == SalesDiscountType.flat ? '₹ ' : null,
                      hintText: selectedType == SalesDiscountType.percentage
                          ? 'e.g. 0.1, 10'
                          : 'e.g. 0.50, 50',
                      errorText: errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                        borderSide: BorderSide(color: Color(0xFFBA8A55), width: 1.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) {
                      if (errorText != null) {
                        setLocalError(null);
                      } else {
                        setDialogState(() {});
                      }
                    },
                    onSubmitted: (_) {
                      _handleApplyDiscount(
                        ctx: ctx,
                        selectedType: selectedType,
                        rawText: discountCtrl.text,
                        setError: setLocalError,
                      );
                    },
                  ),

                  if (previewDiscount != null && previewTotal != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3ECE1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2D6C5)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Preview Total:',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B6358),
                            ),
                          ),
                          Text(
                            '₹${_formatCurrency(previewTotal, showDecimals: previewDiscount % 1 != 0 || previewTotal % 1 != 0)}  (-₹${_formatCurrency(previewDiscount, showDecimals: previewDiscount % 1 != 0)})',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E7E34),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (_discountInputValue > 0)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFB3261E),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _discountInputValue = 0.0;
                    });
                    _showToast('Discount removed');
                  },
                  child: Text(
                    'Remove Discount',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B6358)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1C1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  _handleApplyDiscount(
                    ctx: ctx,
                    selectedType: selectedType,
                    rawText: discountCtrl.text,
                    setError: setLocalError,
                  );
                },
                child: Text(
                  'Apply',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleApplyDiscount({
    required BuildContext ctx,
    required SalesDiscountType selectedType,
    required String rawText,
    required void Function(String?) setError,
  }) {
    final validationError = SalesDiscountCalculator.validateDiscount(
      subtotal: _subtotal,
      type: selectedType,
      text: rawText,
    );

    if (validationError != null) {
      setError(validationError);
      return;
    }

    final parsed = double.tryParse(rawText.trim()) ?? 0.0;
    if (parsed == 0.0) {
      Navigator.pop(ctx);
      setState(() {
        _discountInputValue = 0.0;
      });
      _showToast('Discount removed');
      return;
    }

    if (selectedType == SalesDiscountType.percentage) {
      Navigator.pop(ctx);
      setState(() {
        _discountType = SalesDiscountType.percentage;
        _discountInputValue = parsed;
      });
      _showToast('${_formatInputValue(parsed)}% discount applied');
    } else {
      final calculated = SalesDiscountCalculator.calculateDiscountAmount(
        subtotal: _subtotal,
        type: selectedType,
        inputValue: parsed,
      );
      Navigator.pop(ctx);
      setState(() {
        _discountType = SalesDiscountType.flat;
        _discountInputValue = calculated;
      });
      _showToast('₹${_formatCurrency(calculated)} discount applied');
    }
  }

  void _showAddNoteDialog() {
    final noteCtrl = TextEditingController(text: _saleNote ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFDFD4C5)),
        ),
        title: Text(
          'Order Note',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g. Gift wrapping requested, delivery by evening',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1C1A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _saleNote = noteCtrl.text.trim();
              });
              _showToast('Note attached to sale');
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _showSplitPaymentDialog({VoidCallback? onConfirmed}) {
    if (_cartItems.isEmpty) {
      _showToast('Add items to cart before configuring split payment.');
      return;
    }

    final totalPayableMinor = (_totalAmount * 100).round();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _SplitPaymentDialog(
        totalPayableMinor: totalPayableMinor,
        existingAllocations: _paymentState.allocations,
        cartHasDecimals: _cartHasDecimals,
        onConfirmed: (allocations) {
          setState(() {
            _paymentState = CartPaymentState(
              mode: PaymentMode.split,
              allocations: allocations,
              isConfirmed: true,
              confirmedTotalMinor: totalPayableMinor,
            );
            _persistActiveSession();
          });
          onConfirmed?.call();
          _showToast('Split payment configured');
        },
      ),
    );
  }
}

class _SplitPaymentDialog extends StatefulWidget {
  final int totalPayableMinor;
  final List<PaymentAllocation> existingAllocations;
  final bool cartHasDecimals;
  final ValueChanged<List<PaymentAllocation>> onConfirmed;

  const _SplitPaymentDialog({
    required this.totalPayableMinor,
    required this.existingAllocations,
    required this.cartHasDecimals,
    required this.onConfirmed,
  });

  @override
  State<_SplitPaymentDialog> createState() => _SplitPaymentDialogState();
}

class _SplitRowItem {
  String group; // 'Cash' or 'Online'
  String method; // 'cash', 'upi', 'card', 'bank_transfer', 'other'
  final TextEditingController controller;

  _SplitRowItem({
    required this.group,
    required this.method,
    required String initialValue,
  }) : controller = TextEditingController(text: initialValue);

  void dispose() {
    controller.dispose();
  }
}

class _SplitPaymentDialogState extends State<_SplitPaymentDialog> {
  final List<_SplitRowItem> _rows = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingAllocations.isNotEmpty) {
      for (final alloc in widget.existingAllocations) {
        final isCash = alloc.method.toLowerCase() == 'cash';
        final initial = (alloc.amountMinor / 100).toStringAsFixed(widget.cartHasDecimals ? 2 : 0);
        final row = _SplitRowItem(
          group: isCash ? 'Cash' : 'Online',
          method: isCash ? 'cash' : alloc.method,
          initialValue: initial,
        );
        row.controller.addListener(_onAmountChanged);
        _rows.add(row);
      }
    } else {
      // Default initial split: roughly half Cash, other half Online (UPI)
      final halfMinor = (widget.totalPayableMinor / 2).floor();
      final otherHalfMinor = widget.totalPayableMinor - halfMinor;
      final halfStr = (halfMinor / 100).toStringAsFixed(widget.cartHasDecimals ? 2 : 0);
      final otherHalfStr = (otherHalfMinor / 100).toStringAsFixed(widget.cartHasDecimals ? 2 : 0);

      final row1 = _SplitRowItem(
        group: 'Cash',
        method: 'cash',
        initialValue: halfStr,
      );
      row1.controller.addListener(_onAmountChanged);
      _rows.add(row1);

      final row2 = _SplitRowItem(
        group: 'Online',
        method: 'upi',
        initialValue: otherHalfStr,
      );
      row2.controller.addListener(_onAmountChanged);
      _rows.add(row2);
    }
  }

  void _onAmountChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.controller.removeListener(_onAmountChanged);
      row.dispose();
    }
    super.dispose();
  }

  int get _allocatedMinor {
    int sum = 0;
    for (final row in _rows) {
      final clean = row.controller.text.replaceAll(',', '').replaceAll(' ', '').trim();
      final val = double.tryParse(clean);
      if (val != null && val > 0) {
        sum += (val * 100).round();
      }
    }
    return sum;
  }

  int get _remainingMinor => widget.totalPayableMinor - _allocatedMinor;

  bool get _canConfirm => _allocatedMinor == widget.totalPayableMinor && widget.totalPayableMinor > 0;

  String _formatAmount(num amount) {
    if (widget.cartHasDecimals) {
      return amount.toStringAsFixed(2);
    }
    return amount.round().toString();
  }

  void _addRow() {
    setState(() {
      final hasCash = _rows.any((r) => r.group == 'Cash');
      final remainingAmount = _remainingMinor > 0
          ? (_remainingMinor / 100).toStringAsFixed(widget.cartHasDecimals ? 2 : 0)
          : '0';

      if (!hasCash) {
        final row = _SplitRowItem(
          group: 'Cash',
          method: 'cash',
          initialValue: remainingAmount,
        );
        row.controller.addListener(_onAmountChanged);
        _rows.add(row);
      } else {
        final usedOnlineMethods = _rows
            .where((r) => r.group == 'Online')
            .map((r) => r.method)
            .toSet();
        String nextMethod = 'card';
        if (usedOnlineMethods.contains('card')) {
          if (!usedOnlineMethods.contains('bank_transfer')) {
            nextMethod = 'bank_transfer';
          } else if (!usedOnlineMethods.contains('upi')) {
            nextMethod = 'upi';
          } else {
            nextMethod = 'other';
          }
        }
        final row = _SplitRowItem(
          group: 'Online',
          method: nextMethod,
          initialValue: remainingAmount,
        );
        row.controller.addListener(_onAmountChanged);
        _rows.add(row);
      }
    });
  }

  void _confirm() {
    if (!_canConfirm) return;
    final List<PaymentAllocation> allocations = [];
    for (final row in _rows) {
      final clean = row.controller.text.replaceAll(',', '').replaceAll(' ', '').trim();
      final val = double.tryParse(clean);
      final minor = (val != null && val > 0) ? (val * 100).round() : 0;
      if (minor > 0) {
        allocations.add(
          PaymentAllocation(
            method: row.group == 'Cash' ? 'cash' : row.method,
            amountMinor: minor,
          ),
        );
      }
    }
    Navigator.of(context).pop();
    widget.onConfirmed(allocations);
  }

  @override
  Widget build(BuildContext context) {
    final totalPayable = widget.totalPayableMinor / 100;
    final allocated = _allocatedMinor / 100;
    final remaining = (_remainingMinor.abs()) / 100;
    final isExact = _remainingMinor == 0;

    return AlertDialog(
      backgroundColor: const Color(0xFFFAF7F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFDFD4C5)),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF0E4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.call_split_rounded,
              color: Color(0xFFBA8A55),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Split Payment',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181513),
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Payable Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3ECE1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDFD4C5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Payable',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B6358),
                      ),
                    ),
                    Text(
                      '₹${_formatAmount(totalPayable)}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Rows
              ..._rows.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                final isCash = row.group == 'Cash';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isCash ? Icons.payments_outlined : Icons.phonelink_ring_outlined,
                                size: 15,
                                color: isCash ? const Color(0xFF1E7E34) : const Color(0xFFBA8A55),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                row.group,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B6358),
                                ),
                              ),
                            ],
                          ),
                          if (_rows.length > 2)
                            InkWell(
                              onTap: () {
                                setState(() {
                                  final removed = _rows.removeAt(index);
                                  removed.controller.removeListener(_onAmountChanged);
                                  removed.dispose();
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Text(
                                  'Remove',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFB3261E),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (!isCash) ...[
                            Container(
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFDFD4C5)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: row.method,
                                  isDense: true,
                                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6B6358)),
                                  items: const [
                                    DropdownMenuItem(value: 'upi', child: Text('UPI')),
                                    DropdownMenuItem(value: 'card', child: Text('Card')),
                                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                                    DropdownMenuItem(value: 'other', child: Text('Other')),
                                  ],
                                  onChanged: (newMethod) {
                                    if (newMethod != null) {
                                      setState(() {
                                        row.method = newMethod;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: TextField(
                              controller: row.controller,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181513),
                              ),
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                prefixStyle: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF6B6358),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFFBA8A55), width: 1.5),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              // + Add Payment Method
              TextButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16, color: Color(0xFFBA8A55)),
                label: Text(
                  '+ Add Payment Method',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFBA8A55),
                  ),
                ),
                onPressed: _addRow,
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFDFD4C5)),
              const SizedBox(height: 12),

              // Live Summary: Allocated & Remaining
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Allocated',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B6358),
                    ),
                  ),
                  Text(
                    '₹${_formatAmount(allocated)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Remaining',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isExact ? const Color(0xFF1E7E34) : const Color(0xFFB3261E),
                    ),
                  ),
                  Text(
                    '₹${_formatAmount(remaining)}',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isExact ? const Color(0xFF1E7E34) : const Color(0xFFB3261E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(color: const Color(0xFF6B6358)),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1C1A),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF7A7065),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          onPressed: _canConfirm ? _confirm : null,
          child: Text(
            'Confirm Split',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
