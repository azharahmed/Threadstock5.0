// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/auth/authorization_service.dart';
import '../../../../core/business/current_business_service.dart';
import '../../../../core/widgets/safe_image.dart';
import '../../data/category_repository.dart';
import '../../data/inventory_repository.dart';
import '../../data/location_repository.dart';
import '../../data/product_media_repository.dart';
import '../../data/product_repository.dart';
import '../../data/supplier_repository.dart';
import '../../domain/models/product_variant.dart';
import '../../domain/models/stock_location.dart';
import '../../domain/inventory_change_notifier.dart';

import 'add_product_variant_dialog.dart';

class InventoryProductRow {
  InventoryProductRow({
    required this.id,
    required this.name,
    required this.sku,
    this.categoryName,
    this.supplierName,
    this.supplierId,
    required this.imagePath,
    required this.variantsCount,
    required this.available,
    required this.committed,
    required this.incoming,
    required this.sales30d,
    required this.sellThroughPct,
    required this.status,
    required this.statusType,
    this.variants = const [],
    this.lowStockThreshold,
    this.trackStockLevels = true,
    this.isSelected = false,
  });

  final String id;
  final String name;
  final String sku;
  final String? categoryName;
  final String? supplierName;
  final String? supplierId;
  final String imagePath;
  final int variantsCount;
  final int available;
  final int committed;
  final int incoming;
  final int sales30d;
  final int sellThroughPct;
  final String status;
  final InventoryProductStatusType statusType;
  final List<ProductVariant> variants;
  final int? lowStockThreshold;
  final bool trackStockLevels;
  bool isSelected;
}

enum InventoryProductStatusType { healthy, lowStock, outOfStock, trackingDisabled }

class InventoryProductsView extends StatefulWidget {
  const InventoryProductsView({
    super.key,
    this.onAddProduct,
    this.onImport,
    this.onStockCount,
    this.onAdjustStock,
    this.onStockHistory,
    this.onDamagedStock,
    this.onViewProductDetails,
    this.onEditProduct,
    this.onAdjustProductStock,
    this.onProductStockHistory,
    this.inventoryRepository,
    this.productRepository,
    this.locationRepository,
    this.categoryRepository,
    this.supplierRepository,
    this.businessId,
  });

  final VoidCallback? onAddProduct;
  final VoidCallback? onImport;
  final VoidCallback? onStockCount;
  final VoidCallback? onAdjustStock;
  final VoidCallback? onStockHistory;
  final VoidCallback? onDamagedStock;
  final ValueChanged<String>? onViewProductDetails;
  final ValueChanged<String>? onEditProduct;
  final ValueChanged<String>? onAdjustProductStock;
  final ValueChanged<String>? onProductStockHistory;
  final InventoryRepository? inventoryRepository;
  final ProductRepository? productRepository;
  final LocationRepository? locationRepository;
  final CategoryRepository? categoryRepository;
  final SupplierRepository? supplierRepository;
  final String? businessId;

  @override
  State<InventoryProductsView> createState() => _InventoryProductsViewState();
}

class _InventoryProductsViewState extends State<InventoryProductsView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<InventoryProductRow> _products = [];
  List<StockLocation> _availableLocations = [];
  List<String> _locations = ['All Locations'];
  List<String> _categories = ['All Categories'];
  List<String> _suppliers = ['All Suppliers'];

  String _selectedLocation = 'All Locations';
  String _selectedLocationId = 'all';
  String _selectedCategory = 'All Categories';
  String _selectedSeason = 'All Seasons';
  String _selectedStatus = 'All Statuses';
  String _selectedSupplier = 'All Suppliers';

  int _selectedTabIndex = 0; // 0: Overview, 1: Variants, 2: Activity
  String? _selectedProductId;
  String? _hoveredProductId;
  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    InventoryChangeNotifier.instance.addListener(_handleInventoryChanged);
    AuthorizationService.instance.addListener(_handleAuthorizationChanged);
    _setupRealtimeSubscription();
    _loadData();
    _ensureAuthorization();
  }

  void _handleAuthorizationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _ensureAuthorization() {
    final bizId = widget.businessId ?? CurrentBusinessService.instance.currentBusinessId;
    if (bizId != null &&
        bizId.isNotEmpty &&
        !bizId.startsWith('test') &&
        !bizId.startsWith('biz_test')) {
      AuthorizationService.instance.refreshAuthorization(businessId: bizId);
    }
  }

  void _handleInventoryChanged() {
    if (mounted) {
      _loadData();
    }
  }

  void _setupRealtimeSubscription() {
    try {
      final sb = Supabase.instance.client;
      final bizId = widget.businessId;
      if (bizId != null && bizId.isNotEmpty && !bizId.startsWith('biz_test')) {
        _realtimeChannel = sb
            .channel('realtime_inventory_$bizId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'inventory_balances',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'business_id',
                value: bizId,
              ),
              callback: (_) {
                if (mounted) {
                  _loadData();
                }
              },
            )
            .subscribe();
      }
    } catch (e) {
      debugPrint('[InventoryProductsView] Realtime subscription not active: $e');
    }
  }

  void _cleanupRealtimeSubscription() {
    if (_realtimeChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_realtimeChannel!);
      } catch (_) {}
      _realtimeChannel = null;
    }
  }

  @override
  void dispose() {
    InventoryChangeNotifier.instance.removeListener(_handleInventoryChanged);
    AuthorizationService.instance.removeListener(_handleAuthorizationChanged);
    _cleanupRealtimeSubscription();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final productRepo = widget.productRepository ?? ProductRepository();
      final inventoryRepo = widget.inventoryRepository ?? InventoryRepository();
      final categoryRepo = widget.categoryRepository ?? CategoryRepository();
      final supplierRepo = widget.supplierRepository ?? SupplierRepository();
      final locationRepo = widget.locationRepository ?? LocationRepository();

      final products = await productRepo.getProducts(
        businessId: widget.businessId,
      );
      final categories = await categoryRepo.getCategories(
        businessId: widget.businessId,
      );
      final suppliers = await supplierRepo.getSuppliers(
        businessId: widget.businessId,
      );
      final locations = await locationRepo.getLocations(
        businessId: widget.businessId,
      );

      final locId = _selectedLocationId == 'all' ? null : _selectedLocationId;
      final summaries = await inventoryRepo.getProductInventorySummaries(
        businessId: widget.businessId,
        locationId: locId,
        preloadedProducts: products,
      );

      final categoryMap = {for (var c in categories) c.id: c.name};
      final supplierMap = {for (var s in suppliers) s.id: s.name};

      final productImages = <String, String>{};
      try {
        final productIds = products.map((p) => p.id).toList();
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
        debugPrint('[InventoryProductsView] media lookup fallback: $e');
      }

      final rows = <InventoryProductRow>[];
      for (int i = 0; i < products.length; i++) {
        final p = products[i];
        final summary = summaries[p.id];
        final catName = p.categoryId != null ? categoryMap[p.categoryId] : null;
        final supName =
            p.supplierId != null ? supplierMap[p.supplierId] : null;

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

        final variantCount = summary?.variantCount ?? 0;
        final available = summary?.availableQty ?? 0;
        final committed = summary?.committedQty ?? 0;
        final trackStock = summary?.trackStockLevels ?? p.trackStockLevels;
        final threshold = summary?.lowStockThreshold ?? p.lowStockThreshold;

        InventoryProductStatusType statusType;
        if (!trackStock) {
          statusType = InventoryProductStatusType.trackingDisabled;
        } else if (available <= 0) {
          statusType = InventoryProductStatusType.outOfStock;
        } else if (threshold != null && available <= threshold) {
          statusType = InventoryProductStatusType.lowStock;
        } else {
          statusType = InventoryProductStatusType.healthy;
        }

        final statusLabel = summary?.stockStatusLabel ??
            (!trackStock
                ? 'Tracking Disabled'
                : (available <= 0
                    ? 'Out of Stock'
                    : (threshold != null && available <= threshold
                        ? 'Low Stock'
                        : 'In Stock')));

        rows.add(
          InventoryProductRow(
            id: p.id,
            name: p.name,
            sku:
                summary != null &&
                    summary.variants.isNotEmpty &&
                    summary.variants.first.sku.isNotEmpty
                ? summary.variants.first.sku
                : (p.id.length >= 8
                      ? p.id.substring(0, 8).toUpperCase()
                      : p.id.toUpperCase()),
            categoryName:
                catName ?? (p.tags.isNotEmpty ? p.tags.first : 'General'),
            supplierName: supName,
            supplierId: p.supplierId,
            imagePath: imgPath,
            variantsCount: variantCount,
            available: available,
            committed: committed,
            incoming: 0,
            sales30d: 0,
            sellThroughPct: 0,
            status: statusLabel,
            statusType: statusType,
            variants: summary?.variants ?? [],
            lowStockThreshold: threshold,
            trackStockLevels: trackStock,
            isSelected: false,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _products = rows;
          _availableLocations = locations;
          _locations = ['All Locations', ...locations.map((l) => l.name)];
          _categories = ['All Categories', ...categories.map((c) => c.name)];
          _suppliers = ['All Suppliers', ...suppliers.map((s) => s.name)];
          if (!_locations.contains(_selectedLocation)) {
            _selectedLocation = 'All Locations';
            _selectedLocationId = 'all';
          }
          if (!_categories.contains(_selectedCategory)) {
            _selectedCategory = 'All Categories';
          }
          if (!_suppliers.contains(_selectedSupplier)) {
            _selectedSupplier = 'All Suppliers';
          }
          if (_selectedProductId != null &&
              !rows.any((r) => r.id == _selectedProductId)) {
            _selectedProductId = null;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(
        '[InventoryProductsView] Error loading inventory products: $e',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  List<InventoryProductRow> get _filteredProducts {
    return _products.where((p) {
      if (_selectedCategory != 'All Categories' &&
          p.categoryName != _selectedCategory) {
        return false;
      }
      if (_selectedSupplier != 'All Suppliers' &&
          p.supplierName != _selectedSupplier) {
        return false;
      }
      if (_selectedStatus != 'All Statuses') {
        if (_selectedStatus == 'Healthy' &&
            p.statusType != InventoryProductStatusType.healthy)
          return false;
        if (_selectedStatus == 'Low Stock' &&
            p.statusType != InventoryProductStatusType.lowStock)
          return false;
        if (_selectedStatus == 'Out of Stock' &&
            p.statusType != InventoryProductStatusType.outOfStock)
          return false;
        if (_selectedStatus == 'Draft' && p.status != 'Draft') return false;
      }
      return true;
    }).toList();
  }

  InventoryProductRow? get _currentSelectedProduct {
    if (_selectedProductId == null) return null;
    return _products.where((p) => p.id == _selectedProductId).firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: CircularProgressIndicator(color: Color(0xFFB45309)),
        ),
      );
    }
    if (_errorMessage != null && _products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFFDC2626),
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load inventory data',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF181513),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Page Header: Title, Subtitle, and Top Action Buttons
          _buildPageHeader(),
          const SizedBox(height: 18),

          // 2. Main Content Layout: Table & Filters on Left (~71%), Selected Product Drawer on Right (~29%)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1040;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 71,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFilterRow(),
                          const SizedBox(height: 16),
                          _buildKpiMetricsGrid(),
                          const SizedBox(height: 16),
                          _buildProductsTableCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(flex: 29, child: _buildSelectedProductDrawer()),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilterRow(),
                  const SizedBox(height: 16),
                  _buildKpiMetricsGrid(),
                  const SizedBox(height: 16),
                  _buildProductsTableCard(),
                  const SizedBox(height: 18),
                  _buildSelectedProductDrawer(),
                ],
              );
            },
          ),
          const SizedBox(height: 18),

          // 3. Bottom Row: Inventory Insights (~58%) & Quick Actions (~42%)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 840;
              if (isWide) {
                return Row(
                  children: [
                    Expanded(flex: 58, child: _buildInventoryInsightsCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 42, child: _buildQuickActionsCard()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildInventoryInsightsCard(),
                  const SizedBox(height: 16),
                  _buildQuickActionsCard(),
                ],
              );
            },
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // 1. Page Header
  Widget _buildPageHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inventory',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${_products.length} style${_products.length == 1 ? '' : 's'} across active locations',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        Flexible(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: Row(
          children: [
            if (widget.onStockHistory != null) ...[
              OutlinedButton.icon(
                onPressed: AuthorizationService.instance.can('inventory.view') ? widget.onStockHistory : null,
                icon: const Icon(Icons.history_rounded, size: 15),
                label: const Text('Stock History'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (widget.onDamagedStock != null) ...[
              OutlinedButton.icon(
                onPressed: AuthorizationService.instance.can('inventory.adjust') ? widget.onDamagedStock : null,
                icon: const Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFDC2626)),
                label: const Text('Damaged Stock'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF991B1B),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (widget.onAdjustStock != null) ...[
              OutlinedButton.icon(
                onPressed: AuthorizationService.instance.can('inventory.adjust') ? widget.onAdjustStock : null,
                icon: const Icon(Icons.tune_rounded, size: 15),
                label: const Text('Adjust Stock'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
            ],
            OutlinedButton.icon(
              onPressed: AuthorizationService.instance.can('inventory.import') ? widget.onImport : null,
              icon: const Icon(Icons.file_upload_outlined, size: 15),
              label: const Text('Import'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: AuthorizationService.instance.can('inventory.adjust') ? widget.onStockCount : null,
              icon: const Icon(Icons.bar_chart_rounded, size: 15),
              label: const Text('Stock Count'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: AuthorizationService.instance.can('inventory.manage') ? widget.onAddProduct : null,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Product'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
          ),
        ),
      ],
    );
  }

  // Filter Row
  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterDropdown(
            label: 'Location',
            value: _selectedLocation,
            items: _locations,
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _selectedLocation = val;
                if (val == 'All Locations') {
                  _selectedLocationId = 'all';
                } else {
                  final matches = _availableLocations.where(
                    (l) => l.name == val,
                  );
                  if (matches.isNotEmpty) {
                    _selectedLocationId = matches.first.id;
                  }
                }
              });
              _loadData();
            },
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            label: 'Category',
            value: _selectedCategory,
            items: _categories,
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            label: 'Season',
            value: _selectedSeason,
            items: const ['All Seasons', 'Current Season'],
            onChanged: (val) => setState(() => _selectedSeason = val!),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            label: 'Stock Status',
            value: _selectedStatus,
            items: const [
              'All Statuses',
              'Healthy',
              'Draft',
              'Low Stock',
              'Out of Stock',
            ],
            onChanged: (val) => setState(() => _selectedStatus = val!),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            label: 'Supplier',
            value: _selectedSupplier,
            items: _suppliers,
            onChanged: (val) => setState(() => _selectedSupplier = val!),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list_rounded, size: 14),
              label: const Text('Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 32),
                textStyle: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
              ),
              items: items.map((it) {
                return DropdownMenuItem<String>(value: it, child: Text(it));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // 4 Summary KPI Metric Cards
  Widget _buildKpiMetricsGrid() {
    final total = _products.length;
    final trackedProducts =
        _products.where((p) => p.trackStockLevels).toList();
    final trackedDenominator = trackedProducts.length;

    final inStockProducts = trackedProducts
        .where((p) => p.statusType == InventoryProductStatusType.healthy)
        .toList();
    final lowStockProducts = trackedProducts
        .where((p) => p.statusType == InventoryProductStatusType.lowStock)
        .toList();
    final outOfStockProducts = trackedProducts
        .where((p) => p.statusType == InventoryProductStatusType.outOfStock)
        .toList();

    final inStock = inStockProducts.length;
    final lowStock = lowStockProducts.length;
    final outOfStock = outOfStockProducts.length;

    final inStockUnits =
        inStockProducts.fold<int>(0, (sum, p) => sum + p.available);
    final lowStockUnits =
        lowStockProducts.fold<int>(0, (sum, p) => sum + p.available);
    final totalUnits =
        _products.fold<int>(0, (sum, p) => sum + p.available);

    final inStockPct = trackedDenominator == 0
        ? '0%'
        : '${((inStock / trackedDenominator) * 100).round()}%';
    final lowStockPct = trackedDenominator == 0
        ? '0%'
        : '${((lowStock / trackedDenominator) * 100).round()}%';
    final outOfStockPct = trackedDenominator == 0
        ? '0%'
        : '${((outOfStock / trackedDenominator) * 100).round()}%';

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.inventory_2_outlined,
            iconBg: const Color(0xFFFBF4EB),
            iconColor: const Color(0xFFB45309),
            value: '$total',
            label: 'Total Styles',
            subtitle: '$totalUnits units total',
            badgeText: '100%',
            badgeBg: const Color(0xFFDCFCE7),
            badgeColor: const Color(0xFF15803D),
            tooltip:
                'Total Styles\nAll active products and styles in the current business.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.all_inbox_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            value: '$inStock',
            label: 'In Stock',
            subtitle: '$inStockUnits units available',
            badgeText: inStockPct,
            badgeBg: const Color(0xFFEFF6FF),
            badgeColor: const Color(0xFF2563EB),
            tooltip:
                'In Stock\nNumber of stock-tracked styles with one or more sellable units.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.warning_amber_rounded,
            iconBg: const Color(0xFFFEF2F2),
            iconColor: const Color(0xFFEF4444),
            value: '$lowStock',
            label: 'Low Stock',
            subtitle: '$lowStockUnits units available',
            badgeText: lowStockPct,
            badgeBg: const Color(0xFFFEF3C7),
            badgeColor: const Color(0xFFD97706),
            tooltip:
                'Low Stock\nNumber of stock-tracked styles at or below their configured low-stock threshold.',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.block_rounded,
            iconBg: const Color(0xFFFEF2F2),
            iconColor: const Color(0xFFEF4444),
            value: '$outOfStock',
            label: 'Out of Stock',
            subtitle: '0 units available',
            badgeText: outOfStockPct,
            badgeBg: const Color(0xFFFEE2E2),
            badgeColor: const Color(0xFFDC2626),
            tooltip:
                'Out of Stock\nNumber of stock-tracked styles with zero sellable units available.',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required String label,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    String? subtitle,
    String? tooltip,
  }) {
    final cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9CA3AF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        textStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w400,
          color: Colors.white,
        ),
        child: cardContent,
      );
    }
    return cardContent;
  }

  Widget _buildTableHeaderText({
    required String text,
    String? tooltip,
    bool isCenter = false,
  }) {
    final textWidget = Text(
      text,
      textAlign: isCenter ? TextAlign.center : TextAlign.start,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF6B7280),
      ),
    );

    if (tooltip == null || tooltip.isEmpty) {
      return textWidget;
    }

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      textStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: Colors.white,
      ),
      child: textWidget,
    );
  }

  // Product Table Card
  Widget _buildProductsTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Icon(
                    Icons.check_box_outline_blank,
                    size: 16,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 30,
                  child: _buildTableHeaderText(text: 'Product'),
                ),
                Expanded(
                  flex: 14,
                  child: _buildTableHeaderText(
                    text: 'Variants',
                    tooltip:
                        'Number of product variants such as size, color, or material.',
                  ),
                ),
                Expanded(
                  flex: 11,
                  child: _buildTableHeaderText(
                    text: 'Available',
                    tooltip:
                        'Sellable units currently available at the selected location(s).',
                  ),
                ),
                Expanded(
                  flex: 11,
                  child: _buildTableHeaderText(
                    text: 'Committed',
                    tooltip:
                        'Units reserved or allocated and not currently available for sale.',
                  ),
                ),
                Expanded(
                  flex: 11,
                  child: _buildTableHeaderText(
                    text: 'Incoming',
                    tooltip:
                        'Units expected from open purchase orders or inbound transfers.',
                  ),
                ),
                Expanded(
                  flex: 11,
                  child: _buildTableHeaderText(
                    text: 'Sales 30D',
                    tooltip: 'Units sold during the last 30 days.',
                  ),
                ),
                Expanded(
                  flex: 12,
                  child: _buildTableHeaderText(
                    text: 'Sell-through %',
                    tooltip:
                        'Percentage of available inventory sold during the measured period.',
                  ),
                ),
                Expanded(
                  flex: 14,
                  child: Center(
                    child: _buildTableHeaderText(
                      text: 'Status',
                      isCenter: true,
                      tooltip:
                          'Inventory status based on stock tracking, available quantity, and low-stock threshold.',
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table Rows
          if (_filteredProducts.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 36,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No products found',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Products added to your catalog will appear here.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            for (int i = 0; i < _filteredProducts.length; i++) ...[
              _buildTableRow(i, _filteredProducts[i]),
              const Divider(height: 1, color: Color(0xFFF7F5F0)),
            ],
          ],

          // Table Pagination Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing 1–${_filteredProducts.length} of ${_filteredProducts.length} products',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 15,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFD97706)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '1',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(int index, InventoryProductRow item) {
    final isSelected = _selectedProductId == item.id;
    final isHovered = _hoveredProductId == item.id;

    // Hover: very subtle warm ivory / champagne background tint (calm, minimal, premium)
    // Selected: slightly stronger than hover, clear and restrained highlight
    final Color rowBackground = isSelected
        ? const Color(0xFFF5EFE5)
        : (isHovered
            ? const Color(0xFFFAF7F2)
            : Colors.transparent);

    // Constant border thickness across all states (left: 2px, top: 1px, bottom: 1px) to guarantee zero layout shift
    final Border rowBorder = isSelected
        ? const Border(
            left: BorderSide(color: Color(0xFFD9935A), width: 2),
            top: BorderSide(color: Color(0xFFEFE7DB), width: 1),
            bottom: BorderSide(color: Color(0xFFEFE7DB), width: 1),
          )
        : (isHovered
            ? const Border(
                left: BorderSide(color: Color(0xFFEBE3D7), width: 2),
                top: BorderSide(color: Color(0xFFF7F3EC), width: 1),
                bottom: BorderSide(color: Color(0xFFF7F3EC), width: 1),
              )
            : const Border(
                left: BorderSide(color: Colors.transparent, width: 2),
                top: BorderSide(color: Colors.transparent, width: 1),
                bottom: BorderSide(color: Colors.transparent, width: 1),
              ));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        if (_hoveredProductId != item.id) {
          setState(() {
            _hoveredProductId = item.id;
          });
        }
      },
      onExit: (_) {
        if (_hoveredProductId == item.id) {
          setState(() {
            _hoveredProductId = null;
          });
        }
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedProductId = item.id;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: rowBackground,
            border: rowBorder,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    item.isSelected = !item.isSelected;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 20,
                  child: Icon(
                    item.isSelected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank,
                    size: 16,
                    color: item.isSelected
                        ? const Color(0xFF181513)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Product image + name + sku
              Expanded(
                flex: 30,
                child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SafeImage(
                          source: item.imagePath,
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(6),
                          fallback: Container(
                            width: 34,
                            height: 34,
                            color: const Color(0xFFF1F5F9),
                            child: const Icon(
                              Icons.checkroom_rounded,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: isHovered || isSelected
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              item.sku,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
              ),

              // Variants
              Expanded(
                flex: 14,
                child: Text(
                  '${item.variantsCount} variant${item.variantsCount == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),

              // Available
              Expanded(
                flex: 11,
                child: Text(
                  '${item.available}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),

              // Committed
              Expanded(
                flex: 11,
                child: Text(
                  '${item.committed}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),

              // Incoming
              Expanded(
                flex: 11,
                child: Text(
                  '${item.incoming}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),

              // Sales 30D
              Expanded(
                flex: 11,
                child: Text(
                  '${item.sales30d}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),

              // Sell-through %
              Expanded(
                flex: 12,
                child: Text(
                  '${item.sellThroughPct}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF4B5563),
                  ),
                ),
              ),

              // Status Badge
              Expanded(
                flex: 14,
                child: Center(
                  child: _buildStatusBadge(item.status, item.statusType),
                ),
              ),

              // Actions Three-Dot Menu — smoothly highlights and becomes more visible on hover/select
              AnimatedOpacity(
                duration: const Duration(milliseconds: 140),
                opacity: isHovered || isSelected ? 1.0 : 0.6,
                child: PopupMenuButton<String>(
                  tooltip: 'Product actions',
                  splashRadius: 16,
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: isHovered || isSelected
                        ? const Color(0xFF64748B)
                        : const Color(0xFFCBD5E1),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                onSelected: (value) async {
                  switch (value) {
                    case 'view_details':
                      widget.onViewProductDetails?.call(item.id);
                      break;
                    case 'edit_product':
                      if (widget.onEditProduct != null) {
                        widget.onEditProduct!(item.id);
                      } else {
                        widget.onViewProductDetails?.call(item.id);
                      }
                      break;
                    case 'add_variant':
                      await _openAddVariantDialog(item);
                      break;
                    case 'adjust_stock':
                      if (widget.onAdjustProductStock != null) {
                        widget.onAdjustProductStock!(item.id);
                      } else if (widget.onAdjustStock != null) {
                        widget.onAdjustStock!();
                      }
                      break;
                    case 'toggle_tracking':
                      await _toggleProductTracking(item);
                      break;
                    case 'stock_history':
                      if (widget.onProductStockHistory != null) {
                        widget.onProductStockHistory!(item.id);
                      } else if (widget.onStockHistory != null) {
                        widget.onStockHistory!();
                      }
                      break;
                    case 'archive_product':
                      await _confirmArchiveProduct(item);
                      break;
                  }
                },
                itemBuilder: (context) {
                  // If authorization is currently loading, show a loading item rather than a disabled menu
                  if (AuthorizationService.instance.isLoading) {
                    return <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFB45309),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Checking permissions...',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  }

                  final canView = AuthorizationService.instance.can('inventory.view');
                  final canManage = AuthorizationService.instance.can('inventory.manage');
                  final canAdjust = AuthorizationService.instance.can('inventory.adjust');
                  final isTrackingDisabled =
                      item.statusType == InventoryProductStatusType.trackingDisabled;

                  return <PopupMenuEntry<String>>[
                    PopupMenuItem(
                      value: 'view_details',
                      enabled: canView,
                      child: _buildMenuItem(
                        Icons.visibility_outlined,
                        'View Details',
                        canView,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'edit_product',
                      enabled: canManage,
                      child: _buildMenuItem(
                        Icons.edit_outlined,
                        'Edit Product',
                        canManage,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'add_variant',
                      enabled: canManage,
                      child: _buildMenuItem(
                        Icons.add_circle_outline_rounded,
                        'Add Variant',
                        canManage,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'adjust_stock',
                      enabled: canAdjust,
                      child: _buildMenuItem(
                        Icons.tune_rounded,
                        'Adjust Stock',
                        canAdjust,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_tracking',
                      enabled: canManage,
                      child: _buildMenuItem(
                        isTrackingDisabled
                            ? Icons.sensors_outlined
                            : Icons.sensors_off_outlined,
                        isTrackingDisabled
                            ? 'Enable Tracking'
                            : 'Disable Tracking',
                        canManage,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'stock_history',
                      enabled: canView,
                      child: _buildMenuItem(
                        Icons.history_rounded,
                        'Stock History',
                        canView,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'archive_product',
                      enabled: canManage,
                      child: _buildMenuItem(
                        Icons.archive_outlined,
                        'Archive Product',
                        canManage,
                        isDestructive: true,
                      ),
                    ),
                  ];
                },
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String label,
    bool isEnabled, {
    bool isDestructive = false,
  }) {
    final color = !isEnabled
        ? const Color(0xFF9CA3AF)
        : (isDestructive
            ? const Color(0xFFDC2626)
            : const Color(0xFF374151));

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _openAddVariantDialog(InventoryProductRow product) async {
    final created = await showDialog<ProductVariant>(
      context: context,
      builder: (ctx) => AddProductVariantDialog(
        productId: product.id,
        productName: product.name,
        businessId: widget.businessId,
        productRepository: widget.productRepository,
        locationRepository: widget.locationRepository,
      ),
    );
    if (created != null) {
      await _loadData();
      if (mounted) {
        setState(() {
          _selectedProductId = product.id;
        });
      }
    }
  }

  Future<void> _toggleProductTracking(InventoryProductRow product) async {
    final isCurrentlyDisabled =
        product.statusType == InventoryProductStatusType.trackingDisabled;
    final enable = isCurrentlyDisabled;
    try {
      final repo = widget.productRepository ?? ProductRepository();
      await repo.toggleTracking(
        product.id,
        trackStockLevels: enable,
        businessId: widget.businessId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enable
                  ? 'Stock tracking enabled for ${product.name}'
                  : 'Stock tracking disabled for ${product.name}',
            ),
            backgroundColor: const Color(0xFF181513),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update tracking: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmArchiveProduct(InventoryProductRow product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Archive Product',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to archive "${product.name}"? It will be hidden from the active catalog. Existing stock and order history will be preserved.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4B5563)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: Text(
              'Archive',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final repo = widget.productRepository ?? ProductRepository();
        await repo.archiveProduct(product.id, businessId: widget.businessId);
        if (_selectedProductId == product.id) {
          _selectedProductId = null;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product "${product.name}" archived.'),
              backgroundColor: const Color(0xFF181513),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        await _loadData();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to archive product: $e'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildStatusBadge(String text, InventoryProductStatusType type) {
    Color bg;
    Color fg;
    String label = text;
    if (type == InventoryProductStatusType.trackingDisabled) {
      label = 'Tracking Disabled';
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
    } else if (type == InventoryProductStatusType.healthy) {
      label = text == 'Draft' ? 'Draft' : 'In Stock';
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
    } else if (type == InventoryProductStatusType.lowStock) {
      label = 'Low Stock';
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else if (type == InventoryProductStatusType.outOfStock) {
      label = 'Out of Stock';
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    } else {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  // Selected Product Drawer (Right Card)
  Widget _buildSelectedProductDrawer() {
    final product = _currentSelectedProduct;

    if (product == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFEFE9DE)),
                ),
                child: const Icon(
                  Icons.touch_app_outlined,
                  size: 24,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Select a product',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a product to view inventory, variants and activity.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drawer Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Product',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              const Icon(
                Icons.more_horiz_rounded,
                size: 18,
                color: Color(0xFF6B7280),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Large Photo
          InkWell(
            onTap: () => widget.onViewProductDetails?.call(product.id),
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SafeImage(
                source: product.imagePath,
                width: double.infinity,
                height: 210,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(8),
                fallback: Container(
                  width: double.infinity,
                  height: 210,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(
                    Icons.checkroom_rounded,
                    size: 48,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Product Name and SKU Details
          InkWell(
            onTap: () => widget.onViewProductDetails?.call(product.id),
            child: Text(
              product.name,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            product.supplierName != null && product.supplierName!.isNotEmpty
                ? 'SKU: ${product.sku}  •  ${product.categoryName ?? 'General'}  •  ${product.supplierName}'
                : 'SKU: ${product.sku}  •  ${product.categoryName ?? 'General'}',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),

          // Navigation Tabs: Overview, Variants, Activity
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildDrawerTab('Overview', 0),
                const SizedBox(width: 16),
                _buildDrawerTab('Variants (${product.variantsCount})', 1),
                const SizedBox(width: 16),
                _buildDrawerTab('Activity', 2),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Drawer Tab Content
          if (_selectedTabIndex == 1)
            _buildDrawerVariantsList(product)
          else if (_selectedTabIndex == 2)
            _buildDrawerActivity(product)
          else
            _buildDrawerOverview(product),
        ],
      ),
    );
  }

  Future<void> _handleEnableTracking(InventoryProductRow product) async {
    try {
      final repo = widget.productRepository ?? ProductRepository();
      final fullProd = await repo.getProduct(product.id);
      if (fullProd != null) {
        await repo.updateProduct(fullProd.copyWith(trackStockLevels: true));
        _loadData();
      }
    } catch (_) {}
  }

  Widget _buildDrawerOverview(InventoryProductRow product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (product.statusType == InventoryProductStatusType.trackingDisabled) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.sensors_off_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      'Tracking Disabled',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Stock tracking is disabled for this product.',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () => _handleEnableTracking(product),
                  icon: const Icon(Icons.tune, size: 14),
                  label: const Text('Enable Tracking'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF181513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ] else if (product.available == 0) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Text(
                      'No stock recorded',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tracking is active but no balance exists across locations.',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF78350F)),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onAdjustStock != null) {
                      widget.onAdjustStock!();
                    }
                  },
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Add Stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF181513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Stock Stats List
        _buildStatRow(
          icon: Icons.inventory_2_outlined,
          label: 'Available Stock',
          value: '${product.available} units',
          valueColor: product.available > 0
              ? const Color(0xFF15803D)
              : const Color(0xFFDC2626),
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          icon: Icons.access_time_rounded,
          label: 'Committed',
          value: '${product.committed} units',
          valueColor: const Color(0xFF111827),
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          icon: Icons.file_upload_outlined,
          label: 'Incoming',
          value: '${product.incoming} units',
          valueColor: const Color(0xFF111827),
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          icon: Icons.warning_amber_rounded,
          label: 'Low Stock Threshold',
          value: product.lowStockThreshold != null
              ? '${product.lowStockThreshold} units'
              : 'Not configured',
          valueColor: const Color(0xFF111827),
        ),
        const SizedBox(height: 12),
        _buildStatRow(
          icon: Icons.calendar_today_outlined,
          label: 'Expected Lead Time',
          value: 'N/A',
          valueColor: const Color(0xFF111827),
        ),
        if (product.supplierName != null &&
            product.supplierName!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildStatRow(
            icon: Icons.local_shipping_outlined,
            label: 'Supplier',
            value: product.supplierName!,
            valueColor: const Color(0xFF111827),
          ),
        ],
        const SizedBox(height: 16),

        // AI Suggestion Box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB).withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: Color(0xFFB45309),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'AI INSIGHT',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFB45309),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'ThreadStock AI will generate replenishment recommendations after sufficient sales and inventory history is available.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  height: 1.4,
                  color: const Color(0xFF451A03),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerVariantsList(InventoryProductRow product) {
    final canManage = AuthorizationService.instance.can('inventory.manage');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Variants (${product.variants.length})',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            OutlinedButton.icon(
              onPressed: canManage ? () => _openAddVariantDialog(product) : null,
              icon: const Icon(Icons.add_rounded, size: 14),
              label: const Text('Add Variant'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB45309),
                side: const BorderSide(color: Color(0xFFD97706)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (product.variants.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.style_outlined,
                    size: 28,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No variants configured',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This product does not have any variants saved yet.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
        for (final v in product.variants) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.sku,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (v.barcode != null && v.barcode!.isNotEmpty)
                      Text(
                        'Barcode: ${v.barcode}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${(v.retailPriceCents / 100).toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      v.status,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: v.status.toLowerCase() == 'active'
                            ? const Color(0xFF15803D)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDrawerActivity(InventoryProductRow product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_rounded,
              size: 28,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 8),
            Text(
              'No recent activity',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Activity history will appear here once inventory adjustments or sales occur.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTab(String label, int index) {
    final isActive = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFFD97706) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF111827) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFF6B7280)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF4B5563),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  // Bottom Card 1: Inventory Insights
  Widget _buildInventoryInsightsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4EB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    size: 20,
                    color: Color(0xFFB45309),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventory Insights',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Inventory analytics will generate automatically as sales and stock movements are recorded.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF4B5563),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFD97706)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('View Insights →'),
          ),
        ],
      ),
    );
  }

  // Bottom Card 2: Quick Actions
  Widget _buildQuickActionsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                size: 16,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 6),
              Text(
                'Quick Actions',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.description_outlined, size: 14),
                  label: const Text('Generate Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.file_upload_outlined, size: 14),
                  label: const Text('Bulk Update'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: AuthorizationService.instance.can('inventory.adjust') ? widget.onAdjustStock : null,
                  icon: const Icon(Icons.tune_rounded, size: 14),
                  label: const Text('Adjust Stock'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
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
}
