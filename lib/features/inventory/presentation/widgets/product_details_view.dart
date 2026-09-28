// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/auth/authorization_service.dart';
import '../../../../core/widgets/safe_image.dart';
import '../../data/product_media_repository.dart';
import '../../data/product_repository.dart';
import '../../domain/models/product.dart';
import '../../domain/models/product_image_item.dart';
import '../../domain/models/product_variant.dart';
import '../../data/location_repository.dart';
import 'add_product_variant_dialog.dart';
import 'stock_adjustment_view.dart';

class ProductDetailsView extends StatefulWidget {
  const ProductDetailsView({
    super.key,
    this.productId,
    this.businessId,
    this.productRepository,
    this.locationRepository,
    this.onBackToInventory,
    this.onEditProduct,
    this.onAdjustStock,
    this.onEnableTracking,
  });

  final String? productId;
  final String? businessId;
  final ProductRepository? productRepository;
  final LocationRepository? locationRepository;
  final VoidCallback? onBackToInventory;
  final VoidCallback? onEditProduct;
  final void Function(StockAdjustmentType? type)? onAdjustStock;
  final VoidCallback? onEnableTracking;

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView> {
  int _selectedTabIndex =
      0; // 0: Overview, 1: Variants, 2: Inventory, 3: Purchasing, 4: Sales, 5: Activity
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  Product? _product;
  List<ProductVariant> _variants = [];
  Map<String, int> _variantBalances = {};
  int _totalStock = 0;
  List<Map<String, dynamic>> _locationBalances = [];
  String? _primaryImageUrl;
  String? _categoryName;
  String? _brandName;
  String? _supplierName;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void didUpdateWidget(covariant ProductDetailsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);
    try {
      final repo = widget.productRepository ?? ProductRepository();
      String? targetId = widget.productId;
      if (targetId == null || targetId.isEmpty) {
        final prods = await repo.getProducts();
        if (prods.isNotEmpty) {
          targetId = prods.first.id;
        }
      }
      if (targetId != null && targetId.isNotEmpty) {
        final details = await repo.getProductDetails(targetId);
        if (details != null && mounted) {
          final mediaList = (details['media'] as List<ProductImageItem>?) ?? [];
          String? primaryImg;
          if (mediaList.isNotEmpty) {
            final primary = mediaList.firstWhere(
              (m) => m.isPrimary,
              orElse: () => mediaList.first,
            );
            primaryImg = primary.remoteUrl ?? primary.storagePath;
          }
          if (primaryImg == null || primaryImg.isEmpty) {
            final fallbackMedia =
                ProductMediaRepository.instance.getMediaForProduct(targetId);
            if (fallbackMedia.isNotEmpty) {
              final primary = fallbackMedia.firstWhere(
                (m) => m.isPrimary,
                orElse: () => fallbackMedia.first,
              );
              primaryImg = primary.remoteUrl ?? primary.storagePath;
            }
          }

          setState(() {
            _product = details['product'] as Product?;
            _variants = (details['variants'] as List<ProductVariant>?) ?? [];
            _variantBalances = (details['variantBalances'] as Map<String, int>?) ?? {};
            _totalStock = (details['totalStock'] as int?) ?? 0;
            _locationBalances =
                (details['locationBalances'] as List<Map<String, dynamic>>?) ??
                [];
            _primaryImageUrl = primaryImg;
            _categoryName = details['categoryName'] as String?;
            _brandName = details['brandName'] as String?;
            _supplierName = details['supplierName'] as String?;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading product details: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: CircularProgressIndicator(color: Color(0xFFD97706)),
        ),
      );
    }

    if (_product == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 16),
              Text(
                'No product selected',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select a product from inventory to inspect its details and inventory balances.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: widget.onBackToInventory,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Back to Inventory'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1E1C1A),
                  side: const BorderSide(color: Color(0xFFDECDB9)),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          if (widget.onBackToInventory != null) ...[
            InkWell(
              onTap: widget.onBackToInventory,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Back to Inventory',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 1. Top Product Header Card
          _buildProductHeaderCard(),
          const SizedBox(height: 20),

          // 2. Horizontal Navigation Tabs
          _buildNavigationTabs(),
          const SizedBox(height: 20),

          // 3. Tab Content
          _buildTabContent(),
          const SizedBox(height: 16),

          // 4. Bottom Legend & Real-time Info Bar
          _buildLegendBar(),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // 1. Top Product Header Card
  Widget _buildProductHeaderCard() {
    final prod = _product!;
    final skuDisplay = prod.id.length >= 8
        ? prod.id.substring(0, 8).toUpperCase()
        : prod.id.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SafeImage(
              source: _primaryImageUrl,
              width: 110,
              height: 110,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(10),
              fallback: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEADBCA)),
                ),
                child: const Icon(
                  Icons.checkroom_rounded,
                  size: 44,
                  color: Color(0xFF8D7B38),
                ),
              ),
            ),
          ),
          const SizedBox(width: 22),

          // Details & KPI Cards
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title, Active Badge, and Action Buttons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        prod.name,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: prod.isActive
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: prod.isActive
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF6B7280),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            prod.isActive
                                ? 'Active'
                                : (prod.isDraft ? 'Draft' : 'Archived'),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: prod.isActive
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: widget.onEditProduct,
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Edit Product'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  'SKU: $skuDisplay   •   Brand: ${_brandName ?? 'None'}   •   Category: ${_categoryName ?? 'Uncategorized'}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 14),

                // Summary Stat Cards
                Row(
                  children: [
                    // Card 1: Total Stock Available
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _totalStock > 0
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.all_inbox_rounded,
                              size: 20,
                              color: _totalStock > 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Stock Available',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _totalStock > 0
                                    ? '$_totalStock units'
                                    : 'No inventory recorded',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Card 2: Supplier
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
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
                              Icons.business_outlined,
                              size: 20,
                              color: Color(0xFFB45309),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Primary Supplier',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                _supplierName ?? 'None assigned',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  // 2. Horizontal Navigation Tabs
  Widget _buildNavigationTabs() {
    final tabs = [
      {'title': 'Overview', 'icon': Icons.description_outlined},
      {'title': 'Variants (${_variants.length})', 'icon': Icons.inventory_2_outlined},
      {'title': 'Inventory', 'icon': Icons.storefront_outlined},
      {'title': 'Purchasing', 'icon': Icons.shopping_cart_outlined},
      {'title': 'Sales', 'icon': Icons.bar_chart_rounded},
      {'title': 'Activity', 'icon': Icons.history_rounded},
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            _buildTabItem(
              title: tabs[i]['title'] as String,
              icon: tabs[i]['icon'] as IconData,
              index: i,
            ),
            if (i < tabs.length - 1) const SizedBox(width: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required IconData icon,
    required int index,
  }) {
    final isActive = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFFD97706) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive
                  ? const Color(0xFFB45309)
                  : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF111827)
                    : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Tab Content
  Widget _buildTabContent() {
    if (_selectedTabIndex == 0) {
      return _buildOverviewCard();
    } else if (_selectedTabIndex == 1) {
      return _buildVariantsCard();
    } else if (_selectedTabIndex == 2) {
      return _buildInventoryCard();
    } else if (_selectedTabIndex == 3) {
      return _buildEmptyTabCard(
        'Purchasing',
        'No purchase orders recorded for this product.',
      );
    } else if (_selectedTabIndex == 4) {
      return _buildEmptyTabCard(
        'Sales',
        'No sales transactions recorded for this product.',
      );
    } else {
      return _buildEmptyTabCard(
        'Activity',
        'No activity history recorded for this product.',
      );
    }
  }

  Widget _buildOverviewCard() {
    final prod = _product!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Specifications',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildSpecRow('Product Name', prod.name),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Brand', _brandName ?? 'Not Assigned'),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Category', _categoryName ?? 'Not Assigned'),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Supplier', _supplierName ?? 'Not Assigned'),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildSpecRow('Tax Category', prod.taxCategory ?? 'Standard'),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildSpecRow(
            'Track Stock Levels',
            prod.trackStockLevels ? 'Yes' : 'No',
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          _buildSpecRow(
            'Tags',
            prod.tags.isNotEmpty ? prod.tags.join(', ') : 'None',
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVariantsCard() {
    final canManage = AuthorizationService.instance.can('inventory.manage');
    final prod = _product;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Variants (${_variants.length})',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All configured SKU variations and inventory for this product.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: canManage && prod != null
                      ? () {
                          AddProductVariantDialog.show(
                            context,
                            productId: prod.id,
                            productName: prod.name,
                            businessId: widget.businessId ?? prod.businessId,
                            defaultCostPriceCents: _variants.isNotEmpty
                                ? _variants.first.costPriceCents
                                : 0,
                            defaultRetailPriceCents: _variants.isNotEmpty
                                ? _variants.first.retailPriceCents
                                : 0,
                            productRepository: widget.productRepository,
                            locationRepository: widget.locationRepository,
                            onVariantCreated: () {
                              _loadProduct();
                            },
                          );
                        }
                      : null,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('+ Add Variant'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB45309),
                    side: const BorderSide(color: Color(0xFFFDE68A)),
                    backgroundColor: const Color(0xFFFFFBEB),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          if (_variants.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.style_outlined,
                      size: 36,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No variants yet',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This product currently has no color or size variants configured.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Table Column Headers
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _variantColHeader('SKU', flex: 18),
                  _variantColHeader('Barcode', flex: 13),
                  _variantColHeader('Color', flex: 10),
                  _variantColHeader('Size', flex: 8),
                  _variantColHeader('Material', flex: 11),
                  _variantColHeader('Cost', flex: 10),
                  _variantColHeader('Selling Price', flex: 12),
                  _variantColHeader('Status', flex: 10),
                  _variantColHeader('Available Stock', flex: 14),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            for (final v in _variants) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // SKU
                    Expanded(
                      flex: 18,
                      child: Text(
                        v.sku,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    // Barcode
                    Expanded(
                      flex: 13,
                      child: Text(
                        v.barcode?.isNotEmpty == true ? v.barcode! : '—',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    // Color
                    Expanded(
                      flex: 10,
                      child: Text(
                        v.color?.isNotEmpty == true ? v.color! : '—',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                    // Size
                    Expanded(
                      flex: 8,
                      child: Text(
                        v.size?.isNotEmpty == true ? v.size! : '—',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                    // Material
                    Expanded(
                      flex: 11,
                      child: Text(
                        v.material?.isNotEmpty == true ? v.material! : '—',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    // Cost
                    Expanded(
                      flex: 10,
                      child: Text(
                        '₹${(v.costPriceCents / 100).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    // Selling Price
                    Expanded(
                      flex: 12,
                      child: Text(
                        '₹${(v.retailPriceCents / 100).toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                    // Status
                    Expanded(
                      flex: 10,
                      child: Text(
                        v.status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: v.status.toLowerCase() == 'active'
                              ? const Color(0xFF15803D)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                    // Available Stock
                    Expanded(
                      flex: 14,
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (_variantBalances[v.id] ?? 0) > 0
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_variantBalances[v.id] ?? 0} units',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _variantColHeader(String title, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF64748B),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  void _handleAdjustStock(StockAdjustmentType? type) {
    if (widget.onAdjustStock != null) {
      widget.onAdjustStock!(type);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100, maxHeight: 750),
            child: StockAdjustmentView(
              initialProductId: _product?.id,
              initialAdjustmentType: type,
              onAdjustStockCompleted: () {
                Navigator.of(ctx).pop();
                _loadProduct();
              },
            ),
          ),
        ),
      );
    }
  }

  Future<void> _handleEnableTracking() async {
    if (_product == null) return;
    if (widget.onEnableTracking != null) {
      widget.onEnableTracking!();
      return;
    }
    try {
      final updated = _product!.copyWith(trackStockLevels: true);
      final repo = widget.productRepository ?? ProductRepository();
      await repo.updateProduct(updated);
      if (mounted) {
        setState(() {
          _product = updated;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock tracking enabled for this product.'),
            backgroundColor: Color(0xFF15803D),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _product = _product!.copyWith(trackStockLevels: true);
        });
      }
    }
  }

  Widget _buildInventoryCard() {
    final canAdjust = AuthorizationService.instance.can('inventory.adjust');
    final trackStock = _product?.trackStockLevels ?? false;

    // State 1: Tracking Disabled
    if (!trackStock) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.sensors_off_outlined,
                  size: 28,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tracking Disabled',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Stock tracking is currently disabled for this product.\nEnable tracking to monitor available, committed, and damaged inventory across locations.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _handleEnableTracking,
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Enable Tracking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF181513),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // State 2: Tracking enabled but zero stock / no balance recorded
    if (_totalStock == 0 && _locationBalances.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 28,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No stock recorded',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No stock balances recorded for this product across active locations.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
              ),
              if (canAdjust) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _handleAdjustStock(StockAdjustmentType.add),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Stock'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF181513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // State 3: Stock Balances Table
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock Balances',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Available: $_totalStock units',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              if (canAdjust)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _handleAdjustStock(StockAdjustmentType.add),
                      icon: const Icon(Icons.add, size: 15),
                      label: const Text('+ Add Stock'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF15803D),
                        side: const BorderSide(color: Color(0xFF86EFAC)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () => _handleAdjustStock(null),
                      icon: const Icon(Icons.tune, size: 15),
                      label: const Text('Adjust Stock'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF181513),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Location Table Header: Location | Available | Committed | Damaged | Last Counted
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('Location', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('Available', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('Committed', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('Damaged', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
                Expanded(flex: 2, child: Text('Last Counted', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)))),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Location Table Rows
          if (_locationBalances.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                'No location breakdown available.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
              ),
            )
          else
            ..._locationBalances.map((loc) {
              final locName = loc['locationName'] as String? ?? 'Stock Location';
              final avail = loc['availableQty'] as int? ?? 0;
              final committed = loc['committedQty'] as int? ?? 0;
              final damaged = loc['damagedQty'] as int? ?? 0;
              final lastCountedRaw = loc['lastCountedAt'] as String?;
              String lastCountedStr = 'Never';
              if (lastCountedRaw != null && lastCountedRaw.isNotEmpty) {
                final parsed = DateTime.tryParse(lastCountedRaw);
                if (parsed != null) {
                  lastCountedStr = '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
                } else {
                  lastCountedStr = lastCountedRaw;
                }
              }
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(locName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)))),
                    Expanded(flex: 2, child: Text('$avail units', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF111827)))),
                    Expanded(flex: 2, child: Text('$committed units', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)))),
                    Expanded(flex: 2, child: Text('$damaged units', style: GoogleFonts.inter(fontSize: 13, color: damaged > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B)))),
                    Expanded(flex: 2, child: Text(lastCountedStr, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyTabCard(String title, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inbox_outlined,
              size: 36,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              'No $title records',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Bottom Legend & Real-time Info Bar
  Widget _buildLegendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildLegendItem(const Color(0xFF10B981), 'Healthy stock'),
              const SizedBox(width: 16),
              _buildLegendItem(const Color(0xFFF59E0B), 'Low stock'),
              const SizedBox(width: 16),
              _buildLegendItem(const Color(0xFFEF4444), 'Out of stock'),
            ],
          ),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                'Stock levels are updated in real-time.',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color dotColor, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: const Color(0xFF4B5563),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
