// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

// ─── Data models ──────────────────────────────────────────────────────────────

enum CatalogTab { categories, collections, brands, attributes }

class _Category {
  final String id;
  final String name;
  final int products;
  final int variants;
  final bool isActive;
  final List<_Category> children;
  final String? description;
  final String? parent;
  final DateTime? createdOn;
  final DateTime? lastUpdated;

  const _Category({
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

// ─── Seeded demo catalog removed to keep the workspace empty until real catalog data exists. ─────────────────────────────────────

final List<_Category> _sampleCategories = const [];

// ─── Page ─────────────────────────────────────────────────────────────────────

class CatalogManagerPage extends StatefulWidget {
  final void Function(String title)? onTitleChanged;

  const CatalogManagerPage({super.key, this.onTitleChanged});

  @override
  State<CatalogManagerPage> createState() => _CatalogManagerPageState();
}

class _CatalogManagerPageState extends State<CatalogManagerPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CatalogTab _activeTab = CatalogTab.categories;
  _Category? _selectedCategory;
  final Set<String> _expandedIds = {'men', 'shirts'};
  final TextEditingController _searchController = TextEditingController();
  bool _gridView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedCategory = null;
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTab = CatalogTab.values[_tabController.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
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
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
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
            _buildInspectorPanel(_selectedCategory!),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Catalog Manager',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF111827), letterSpacing: -0.4),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('+ Add Category', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
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
              setState(() => _activeTab = CatalogTab.values[i]);
            },
            child: Container(
              padding: const EdgeInsets.only(bottom: 10, right: 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active ? const Color(0xFFD97706) : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                tabs[i],
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? const Color(0xFF111827) : const Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTab) {
      case CatalogTab.categories:
        return _buildCategoriesTab();
      case CatalogTab.collections:
        return _buildComingSoon('Collections', 'Group products into curated collections for your storefront.');
      case CatalogTab.brands:
        return _buildComingSoon('Brands', 'Manage brand associations for your product catalog.');
      case CatalogTab.attributes:
        return _buildComingSoon('Attributes', 'Define custom product attributes like color, size, material.');
    }
  }

  Widget _buildComingSoon(String title, String sub) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.folder_outlined, color: Color(0xFF9CA3AF), size: 28),
          ),
          const SizedBox(height: 14),
          Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(sub, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          _buildToolbar(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          _buildTableHeader(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _sampleCategories.map((c) => _buildCategoryRow(c)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text('Product Categories', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
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
                      decoration: InputDecoration(
                        hintText: 'Search categories...',
                        hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // List/Grid toggle
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _toggleBtn(Icons.format_list_bulleted_rounded, !_gridView, () => setState(() => _gridView = false)),
                _toggleBtn(Icons.grid_view_rounded, _gridView, () => setState(() => _gridView = true)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              setState(() {
                _expandedIds.addAll(_sampleCategories.map((c) => c.id));
                for (final c in _sampleCategories) {
                  _expandedIds.addAll(c.children.map((cc) => cc.id));
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text('Expand All', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF374151))),
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
          boxShadow: active ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)] : null,
        ),
        child: Icon(icon, size: 16, color: active ? const Color(0xFF374151) : const Color(0xFF9CA3AF)),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 24),
          const SizedBox(width: 8),
          const SizedBox(width: 18), // icon
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Text('Name', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF9CA3AF), letterSpacing: 0.3)),
          ),
          _hdr('Products'),
          _hdr('Variants'),
          _hdr('Status'),
          _hdr('Actions'),
        ],
      ),
    );
  }

  Widget _hdr(String label) {
    return SizedBox(
      width: 90,
      child: Text(label, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF9CA3AF), letterSpacing: 0.3)),
    );
  }

  Widget _buildCategoryRow(_Category cat, {int depth = 0}) {
    final isExpanded = _expandedIds.contains(cat.id);
    final isSelected = _selectedCategory?.id == cat.id;
    final hasChildren = cat.children.isNotEmpty;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _selectedCategory = cat),
          child: Container(
            padding: EdgeInsets.only(left: 16.0 + depth * 20, right: 16, top: 10, bottom: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFFF7ED) : Colors.transparent,
              border: const Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: hasChildren
                      ? GestureDetector(
                          onTap: () => setState(() {
                            if (isExpanded) {
                              _expandedIds.remove(cat.id);
                            } else {
                              _expandedIds.add(cat.id);
                            }
                          }),
                          child: Icon(
                            isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.chevron_right_rounded,
                            size: 18,
                            color: const Color(0xFF6B7280),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Icon(
                  depth == 0 ? Icons.folder_outlined : Icons.description_outlined,
                  size: 18,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Text(cat.name, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500, color: const Color(0xFF111827))),
                      if (hasChildren) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${cat.children.length} subcategor${cat.children.length == 1 ? 'y' : 'ies'} · ${_fmt(cat.products)} products)',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 90, child: Text(_fmt(cat.products), style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF374151)))),
                SizedBox(width: 90, child: Text(_fmt(cat.variants), style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF374151)))),
                SizedBox(
                  width: 90,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: cat.isActive ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cat.isActive ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      cat.isActive ? 'Active' : 'Inactive',
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: cat.isActive ? const Color(0xFF059669) : const Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz_rounded, size: 18, color: Color(0xFF6B7280)),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFE5E7EB))),
                    onSelected: (_) {},
                    itemBuilder: (_) => [
                      _popupItem('Edit', Icons.edit_outlined),
                      _popupItem('Add Subcategory', Icons.add_circle_outline),
                      _popupItem('Archive', Icons.archive_outlined),
                      _popupItem('Delete', Icons.delete_outline, destructive: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...cat.children.map((child) => _buildCategoryRow(child, depth: depth + 1)),
      ],
    );
  }

  PopupMenuItem<String> _popupItem(String label, IconData icon, {bool destructive = false}) {
    return PopupMenuItem(
      value: label,
      child: Row(
        children: [
          Icon(icon, size: 16, color: destructive ? const Color(0xFFEF4444) : const Color(0xFF6B7280)),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.inter(fontSize: 13, color: destructive ? const Color(0xFFEF4444) : const Color(0xFF111827))),
        ],
      ),
    );
  }

  Widget _buildInspectorPanel(_Category cat) {
    return Container(
      width: 268,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB)))),
            child: Row(
              children: [
                Text('Category Inspector', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _selectedCategory = null),
                  child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA3AF)),
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
                  // Title row
                  Row(
                    children: [
                      const Icon(Icons.folder_outlined, size: 22, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                            if (cat.parent != null)
                              Text('${cat.parent} › ${cat.name}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF9CA3AF))),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.edit_outlined, size: 13, color: Color(0xFF374151)),
                              const SizedBox(width: 4),
                              Text('Edit', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF374151))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Image placeholder (for subcategories)
                  if (cat.parent != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        height: 110,
                        color: const Color(0xFFF3F4F6),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.checkroom_outlined, size: 36, color: Color(0xFFD1D5DB)),
                              if (cat.description != null) ...[
                                const SizedBox(height: 6),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(cat.description!, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)), textAlign: TextAlign.center),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Metadata
                  if (cat.parent != null) _iRow('Parent Category', cat.parent!),
                  _iRow('TOTAL PRODUCTS', '${_fmt(cat.products)} products'),
                  _iRow('ACTIVE VARIANTS', '${_fmt(cat.variants)} variants'),
                  if (cat.createdOn != null) _iRow('CREATED ON', _fmtDate(cat.createdOn)),
                  if (cat.lastUpdated != null) _iRow('LAST UPDATED', _fmtDate(cat.lastUpdated)),
                  _iStatusRow('STATUS', cat.isActive),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 12),

                  // Actions
                  _iActionBtn(Icons.edit_outlined, 'Rename Category', const Color(0xFF111827), onTap: () {}),
                  const SizedBox(height: 8),
                  _iActionBtn(Icons.swap_vert_rounded, 'Move Node Hierarchy', const Color(0xFF111827), onTap: () {}),
                  const SizedBox(height: 8),
                  _iActionBtn(Icons.archive_outlined, 'Archive Category', const Color(0xFFD97706), onTap: () {}),
                  const SizedBox(height: 8),
                  _iActionBtn(Icons.delete_outline_rounded, 'Delete Category', const Color(0xFFEF4444),
                      background: const Color(0xFFFFF0F0), outlined: true, onTap: () {}),

                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 12),

                  Text('Quick Actions', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                  const SizedBox(height: 10),
                  _quickAction('View Products'),
                  _quickAction('Manage Subcategories'),
                  _quickAction('Set Display Order'),
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
            child: Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w500, color: const Color(0xFF9CA3AF), letterSpacing: 0.5)),
          ),
          Text(value, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF111827))),
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
            child: Text(label.toUpperCase(), style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w500, color: const Color(0xFF9CA3AF), letterSpacing: 0.5)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: active ? const Color(0xFFECFDF5) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: active ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB)),
            ),
            child: Text(active ? 'Active' : 'Inactive',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: active ? const Color(0xFF059669) : const Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }

  Widget _iActionBtn(IconData icon, String label, Color color, {Color? background, bool outlined = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: background ?? Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: outlined ? color.withOpacity(0.4) : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.menu_outlined, size: 15, color: Color(0xFF6B7280)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF374151)))),
            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

