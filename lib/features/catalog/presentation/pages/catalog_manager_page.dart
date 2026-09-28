// ignore_for_file: deprecated_member_use, unused_element_parameter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';
import '../../../../core/business/current_business_service.dart';
import '../../../inventory/data/product_repository.dart';
import '../../../inventory/domain/models/brand.dart';
import '../../../inventory/domain/models/product.dart';
import '../../../inventory/presentation/providers/brand_provider.dart';
import '../../../inventory/presentation/providers/category_provider.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

enum CatalogTab { categories, collections, brands, attributes }

class _CategoryItem {
  final String id;
  final String name;
  final int products;
  final int variants;
  final bool isActive;
  final List<_CategoryItem> children;
  final String? description;
  final String? parent;
  final DateTime? createdOn;
  final DateTime? lastUpdated;

  const _CategoryItem({
    required this.id,
    required this.name,
    required this.products,
    required this.variants,
    this.isActive = true,
    this.children = const [],
    this.description,
    this.parent,
    this.createdOn,
    this.lastUpdated,
  });
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class CatalogManagerPage extends StatefulWidget {
  final CatalogTab initialTab;
  final ValueChanged<CatalogTab>? onTabChanged;
  final void Function(String title)? onTitleChanged;

  const CatalogManagerPage({
    super.key,
    this.initialTab = CatalogTab.categories,
    this.onTabChanged,
    this.onTitleChanged,
  });

  @override
  State<CatalogManagerPage> createState() => _CatalogManagerPageState();
}

class _CatalogManagerPageState extends State<CatalogManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CatalogTab _activeTab;
  _CategoryItem? _selectedCategory;
  Brand? _selectedBrand;
  final TextEditingController _searchController = TextEditingController();
  bool _gridView = false;

  late final CategoryProvider _categoryProvider;
  late final BrandProvider _brandProvider;
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    _tabController.addListener(_handleTabChanged);

    _categoryProvider = CategoryProvider.shared;
    _brandProvider = BrandProvider.shared;

    _categoryProvider.addListener(_onDataChanged);
    _brandProvider.addListener(_onDataChanged);

    _loadData();
  }

  @override
  void didUpdateWidget(covariant CatalogManagerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab &&
        _tabController.index != widget.initialTab.index) {
      _activeTab = widget.initialTab;
      _tabController.index = widget.initialTab.index;
      _selectedCategory = null;
      _selectedBrand = null;
    }
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging) {
      final newTab = CatalogTab.values[_tabController.index];
      if (_activeTab != newTab) {
        setState(() {
          _activeTab = newTab;
          _selectedCategory = null;
          _selectedBrand = null;
        });
        widget.onTabChanged?.call(newTab);
      }
    }
  }

  void _onDataChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final bizId = CurrentBusinessService.instance.currentBusinessId;
      await Future.wait([
        _categoryProvider.loadCategories(businessId: bizId, forceRefresh: true),
        _brandProvider.loadBrands(businessId: bizId, forceRefresh: true),
      ]);
      final productsList = await ProductRepository().getProducts(
        businessId: bizId,
      );
      if (mounted) {
        setState(() {
          _products = productsList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _categoryProvider.removeListener(_onDataChanged);
    _brandProvider.removeListener(_onDataChanged);
    super.dispose();
  }

  String _fmt(int n) {
    if (n >= 1000) {
      final s = n.toString();
      return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return n.toString();
  }

  String _fmtDate(DateTime? d) {
    if (d == null) return '—';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  List<_CategoryItem> get _categoryItems {
    final query = _searchController.text.trim().toLowerCase();
    final rawCats = _categoryProvider.categories;

    final items = rawCats.map((cat) {
      final productCount = _products
          .where((p) => p.categoryId == cat.id)
          .length;
      return _CategoryItem(
        id: cat.id,
        name: cat.name,
        products: productCount,
        variants: 0,
        isActive: true,
        createdOn: cat.createdAt,
        lastUpdated: cat.createdAt,
      );
    }).toList();

    if (query.isEmpty) return items;
    return items.where((c) => c.name.toLowerCase().contains(query)).toList();
  }

  List<Brand> get _brandItems {
    final query = _searchController.text.trim().toLowerCase();
    final rawBrands = _brandProvider.brands;
    if (query.isEmpty) return rawBrands;
    return rawBrands
        .where((b) => b.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopContentConstraint(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 4),
                Text(
                  'Organize your product catalog with categories, collections, brands and attributes.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 20),
                _buildTabBar(),
                const SizedBox(height: 16),
                Expanded(child: _buildTabContent()),
              ],
            ),
          ),
          if (_selectedCategory != null) ...[
            const SizedBox(width: 20),
            _buildCategoryInspectorPanel(_selectedCategory!),
          ],
          if (_selectedBrand != null && _activeTab == CatalogTab.brands) ...[
            const SizedBox(width: 20),
            _buildBrandInspectorPanel(_selectedBrand!),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    String actionLabel = '+ Add Category';
    VoidCallback? onAction = _showAddCategoryDialog;
    if (_activeTab == CatalogTab.brands) {
      actionLabel = '+ Add Brand';
      onAction = _showAddBrandDialog;
    } else if (_activeTab == CatalogTab.collections) {
      actionLabel = '+ Add Collection';
      onAction = null;
    } else if (_activeTab == CatalogTab.attributes) {
      actionLabel = '+ Add Attribute';
      onAction = null;
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            'Catalog Manager',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              letterSpacing: -0.4,
            ),
          ),
        ),
        if (onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTabBar() {
    final tabs = ['Categories', 'Collections', 'Brands', 'Attributes'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = _tabController.index == i;
          return GestureDetector(
            onTap: () {
              _tabController.animateTo(i);
              setState(() {
                _activeTab = CatalogTab.values[i];
                _selectedCategory = null;
                _selectedBrand = null;
              });
              widget.onTabChanged?.call(CatalogTab.values[i]);
            },
            child: Container(
              padding: const EdgeInsets.only(bottom: 10, right: 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active
                        ? const Color(0xFFD97706)
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[i],
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active
                      ? const Color(0xFF111827)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFBA8A55),
          strokeWidth: 2.5,
        ),
      );
    }

    switch (_activeTab) {
      case CatalogTab.categories:
        return _buildCategoriesTab();
      case CatalogTab.collections:
        return _buildEmptyCatalogState(
          title: 'No collections created yet',
          subtitle:
              'Collections allow you to group products into curated themes or seasonal lines.',
          icon: Icons.auto_awesome_motion_outlined,
        );
      case CatalogTab.brands:
        return _buildBrandsTab();
      case CatalogTab.attributes:
        return _buildEmptyCatalogState(
          title: 'No custom attributes configured yet',
          subtitle:
              'Define custom product attributes like fabric weight, weave, sleeve length, or care codes.',
          icon: Icons.tune_rounded,
        );
    }
  }

  Widget _buildEmptyCatalogState({
    required String title,
    required String subtitle,
    required IconData icon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF8F4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEADBCA)),
              ),
              child: Icon(icon, color: const Color(0xFFBA8A55), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  height: 1.4,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF181513),
                  side: const BorderSide(color: Color(0xFFDECDB9)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesTab() {
    final items = _categoryItems;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildToolbar('Product Categories', 'Search categories...'),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildTableHeader(
            columns: ['Products', 'Variants', 'Status', 'Actions'],
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: items.isEmpty
                ? _buildEmptyCatalogState(
                    title: 'No categories found',
                    subtitle:
                        'Create your first category to start organizing your product catalog.',
                    icon: Icons.category_outlined,
                    actionLabel: '+ Add Category',
                    onAction: _showAddCategoryDialog,
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: items.map((c) => _buildCategoryRow(c)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandsTab() {
    final items = _brandItems;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildToolbar('Brand Directory', 'Search brands...'),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildTableHeader(
            columns: ['Products', 'Created', 'Status', 'Actions'],
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: items.isEmpty
                ? _buildEmptyCatalogState(
                    title: 'No brands found',
                    subtitle:
                        'Add a brand to associate with your products and purchase orders.',
                    icon: Icons.branding_watermark_outlined,
                    actionLabel: '+ Add Brand',
                    onAction: _showAddBrandDialog,
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: items.map((b) => _buildBrandRow(b)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(String title, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Icon(Icons.search, size: 16, color: Color(0xFF9CA3AF)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF9CA3AF),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _toggleBtn(
                  Icons.format_list_bulleted_rounded,
                  !_gridView,
                  () => setState(() => _gridView = false),
                ),
                _toggleBtn(
                  Icons.grid_view_rounded,
                  _gridView,
                  () => setState(() => _gridView = true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  Widget _buildTableHeader({required List<String> columns}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const SizedBox(width: 8),
          const SizedBox(width: 18),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text(
              'Name',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.3,
              ),
            ),
          ),
          for (final col in columns) _hdr(col),
        ],
      ),
    );
  }

  Widget _hdr(String label) {
    return SizedBox(
      width: 90,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF9CA3AF),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildCategoryRow(_CategoryItem cat, {int depth = 0}) {
    final isSelected = _selectedCategory?.id == cat.id;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _selectedCategory = cat),
          child: Container(
            padding: EdgeInsets.only(
              left: 16.0 + depth * 20,
              right: 16,
              top: 10,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF7ED) : Colors.transparent,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFF3F4F6)),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 24),
                const SizedBox(width: 8),
                const Icon(
                  Icons.folder_outlined,
                  size: 18,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: Text(
                    cat.name,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    _fmt(cat.products),
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    _fmt(cat.variants),
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: cat.isActive
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cat.isActive
                            ? const Color(0xFFBBF7D0)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      cat.isActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: cat.isActive
                            ? const Color(0xFF059669)
                            : const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    onSelected: (_) {},
                    itemBuilder: (_) => [
                      _popupItem('View Products', Icons.inventory_2_outlined),
                      _popupItem('Edit', Icons.edit_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandRow(Brand brand) {
    final isSelected = _selectedBrand?.id == brand.id;
    final productCount = _products.where((p) => p.brandId == brand.id).length;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _selectedBrand = brand),
          child: Container(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16,
              top: 10,
              bottom: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF7ED) : Colors.transparent,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFF3F4F6)),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 24),
                const SizedBox(width: 8),
                const Icon(
                  Icons.branding_watermark_outlined,
                  size: 18,
                  color: Color(0xFFBA8A55),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: Text(
                    brand.name,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    _fmt(productCount),
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: const Color(0xFF374151),
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    _fmtDate(brand.createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      'Active',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF059669),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    onSelected: (_) {},
                    itemBuilder: (_) => [
                      _popupItem('View Products', Icons.inventory_2_outlined),
                      _popupItem('Edit', Icons.edit_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _popupItem(
    String label,
    IconData icon, {
    bool destructive = false,
  }) {
    return PopupMenuItem(
      value: label,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: destructive
                ? const Color(0xFFEF4444)
                : const Color(0xFF6B7280),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: destructive
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryInspectorPanel(_CategoryItem cat) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Text(
                  'Category Inspector',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _selectedCategory = null),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 22,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cat.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _iRow('TOTAL PRODUCTS', '${_fmt(cat.products)} products'),
                  if (cat.createdOn != null)
                    _iRow('CREATED ON', _fmtDate(cat.createdOn)),
                  _iStatusRow('STATUS', cat.isActive),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandInspectorPanel(Brand brand) {
    final productCount = _products.where((p) => p.brandId == brand.id).length;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                Text(
                  'Brand Inspector',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _selectedBrand = null),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.branding_watermark_outlined,
                        size: 22,
                        color: Color(0xFFBA8A55),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          brand.name,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _iRow('TOTAL PRODUCTS', '${_fmt(productCount)} products'),
                  if (brand.createdAt != null)
                    _iRow('CREATED ON', _fmtDate(brand.createdAt)),
                  _iStatusRow('STATUS', true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iStatusRow(String label, bool active) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? const Color(0xFFBBF7D0)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              active ? 'Active' : 'Inactive',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: active
                    ? const Color(0xFF059669)
                    : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    String? error;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Add Category',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category Name',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Shirts, Outerwear, Knitwear',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        setDialogState(() => error = 'Enter a category name.');
                        return;
                      }
                      setDialogState(() {
                        isSaving = true;
                        error = null;
                      });
                      try {
                        await _categoryProvider.createCategory(name: name);
                        if (mounted && ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSaving = false;
                          error = e
                              .toString()
                              .replaceAll('Exception: ', '')
                              .replaceAll('StateError: ', '');
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Category'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBrandDialog() {
    final controller = TextEditingController();
    String? error;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Add Brand',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Brand Name',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Studio Collection, ThreadStock Raw',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  errorText: error,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: const Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) {
                        setDialogState(() => error = 'Enter a brand name.');
                        return;
                      }
                      setDialogState(() {
                        isSaving = true;
                        error = null;
                      });
                      try {
                        await _brandProvider.createBrand(name: name);
                        if (mounted && ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                      } catch (e) {
                        setDialogState(() {
                          isSaving = false;
                          error = e
                              .toString()
                              .replaceAll('Exception: ', '')
                              .replaceAll('StateError: ', '');
                        });
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Save Brand'),
            ),
          ],
        ),
      ),
    );
  }
}
