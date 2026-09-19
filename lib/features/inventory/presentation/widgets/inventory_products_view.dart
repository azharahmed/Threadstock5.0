// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InventoryProductRow {
  InventoryProductRow({
    required this.name,
    required this.sku,
    required this.imagePath,
    required this.variantsCount,
    required this.available,
    required this.committed,
    required this.incoming,
    required this.sales30d,
    required this.sellThroughPct,
    required this.status,
    required this.statusType,
    this.isSelected = false,
  });

  final String name;
  final String sku;
  final String imagePath;
  final int variantsCount;
  final int available;
  final int committed;
  final int incoming;
  final int sales30d;
  final int sellThroughPct;
  final String status;
  final InventoryProductStatusType statusType;
  bool isSelected;
}

enum InventoryProductStatusType {
  healthy,
  lowStock,
  outOfStock,
}

class InventoryProductsView extends StatefulWidget {
  const InventoryProductsView({
    super.key,
    this.onAddProduct,
    this.onImport,
    this.onStockCount,
    this.onAdjustStock,
    this.onViewProductDetails,
  });

  final VoidCallback? onAddProduct;
  final VoidCallback? onImport;
  final VoidCallback? onStockCount;
  final VoidCallback? onAdjustStock;
  final ValueChanged<String>? onViewProductDetails;

  @override
  State<InventoryProductsView> createState() => _InventoryProductsViewState();
}

class _InventoryProductsViewState extends State<InventoryProductsView> {
  String _selectedLocation = 'Central Warehouse (Zone A)';
  String _selectedCategory = 'All Categories';
  String _selectedSeason = 'All Seasons';
  String _selectedStatus = 'All Statuses';
  String _selectedSupplier = 'All Suppliers';

  int _selectedTabIndex = 0; // 0: Overview, 1: Variants (16), 2: Activity
  int _selectedProductIndex = 0; // Oxford Linen Shirt selected

  late final List<InventoryProductRow> _products;

  @override
  void initState() {
    super.initState();
    _products = [
      InventoryProductRow(
        name: 'Oxford Linen Shirt',
        sku: 'TS-10492',
        imagePath: 'assets/oxford_linen_shirt.jpg',
        variantsCount: 16,
        available: 245,
        committed: 42,
        incoming: 120,
        sales30d: 847,
        sellThroughPct: 74,
        status: 'Healthy',
        statusType: InventoryProductStatusType.healthy,
        isSelected: true,
      ),
      InventoryProductRow(
        name: 'Merino Wool Blazer',
        sku: 'MWB-20188',
        imagePath: 'assets/merino_wool_blazer.jpg',
        variantsCount: 12,
        available: 18,
        committed: 15,
        incoming: 50,
        sales30d: 124,
        sellThroughPct: 82,
        status: 'Low Stock',
        statusType: InventoryProductStatusType.lowStock,
        isSelected: false,
      ),
      InventoryProductRow(
        name: 'Silk Evening Dress',
        sku: 'SED-16166',
        imagePath: 'assets/silk_evening_dress.jpg',
        variantsCount: 20,
        available: 0,
        committed: 8,
        incoming: 80,
        sales30d: 98,
        sellThroughPct: 90,
        status: 'Out of Stock',
        statusType: InventoryProductStatusType.outOfStock,
        isSelected: false,
      ),
      InventoryProductRow(
        name: 'Cashmere Sweater',
        sku: 'CS-50155',
        imagePath: 'assets/cashmere_sweater.jpg',
        variantsCount: 18,
        available: 410,
        committed: 100,
        incoming: 0,
        sales30d: 310,
        sellThroughPct: 43,
        status: 'Healthy',
        statusType: InventoryProductStatusType.healthy,
        isSelected: false,
      ),
      InventoryProductRow(
        name: 'Raw Denim Jeans',
        sku: 'RDJ-22322',
        imagePath: 'assets/raw_denim_jeans.jpg',
        variantsCount: 10,
        available: 88,
        committed: 12,
        incoming: 100,
        sales30d: 240,
        sellThroughPct: 68,
        status: 'Healthy',
        statusType: InventoryProductStatusType.healthy,
        isSelected: false,
      ),
      InventoryProductRow(
        name: 'Gabardine Trench Coat',
        sku: 'GTC-27193',
        imagePath: 'assets/gabardine_trench.jpg',
        variantsCount: 6,
        available: 5,
        committed: 2,
        incoming: 20,
        sales30d: 45,
        sellThroughPct: 89,
        status: 'Low Stock',
        statusType: InventoryProductStatusType.lowStock,
        isSelected: false,
      ),
    ];
  }

  InventoryProductRow get _currentSelectedProduct =>
      _products[_selectedProductIndex];

  @override
  Widget build(BuildContext context) {
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
                    Expanded(
                      flex: 29,
                      child: _buildSelectedProductDrawer(),
                    ),
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
              '2,842 styles across all locations',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: widget.onImport,
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
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: widget.onStockCount,
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
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: widget.onAddProduct,
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
            items: const [
              'Central Warehouse (Zone A)',
              'East Coast Hub',
              'Milano Warehouse',
            ],
            onChanged: (val) => setState(() => _selectedLocation = val!),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            label: 'Category',
            value: _selectedCategory,
            items: const ['All Categories', 'Shirts', 'Outerwear', 'Dresses', 'Knitwear'],
            onChanged: (val) => setState(() => _selectedCategory = val!),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            label: 'Season',
            value: _selectedSeason,
            items: const ['All Seasons', 'Summer 2027', 'Autumn 2027', 'Winter 2026'],
            onChanged: (val) => setState(() => _selectedSeason = val!),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            label: 'Stock Status',
            value: _selectedStatus,
            items: const ['All Statuses', 'Healthy', 'Low Stock', 'Out of Stock'],
            onChanged: (val) => setState(() => _selectedStatus = val!),
          ),
          const SizedBox(width: 8),
          _buildFilterDropdown(
            label: 'Supplier',
            value: _selectedSupplier,
            items: const ['All Suppliers', 'Milano Tessuti', 'Fabrico S.p.A', 'Direct Mills'],
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                minimumSize: const Size(0, 32),
                textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
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
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280)),
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
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF6B7280)),
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1F2937), fontWeight: FontWeight.w500),
              items: items.map((it) {
                return DropdownMenuItem<String>(
                  value: it,
                  child: Text(it),
                );
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
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.inventory_2_outlined,
            iconBg: const Color(0xFFFBF4EB),
            iconColor: const Color(0xFFB45309),
            value: '2,842',
            label: 'Total Styles',
            badgeText: '+12%',
            badgeBg: const Color(0xFFDCFCE7),
            badgeColor: const Color(0xFF15803D),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.all_inbox_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            value: '1,728',
            label: 'In Stock',
            badgeText: '61%',
            badgeBg: const Color(0xFFEFF6FF),
            badgeColor: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.warning_amber_rounded,
            iconBg: const Color(0xFFFEF2F2),
            iconColor: const Color(0xFFEF4444),
            value: '312',
            label: 'Low Stock',
            badgeText: '11%',
            badgeBg: const Color(0xFFFEF3C7),
            badgeColor: const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.block_rounded,
            iconBg: const Color(0xFFFEF2F2),
            iconColor: const Color(0xFFEF4444),
            value: '128',
            label: 'Out of Stock',
            badgeText: '4%',
            badgeBg: const Color(0xFFFEE2E2),
            badgeColor: const Color(0xFFDC2626),
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
  }) {
    return Container(
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
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
              ],
            ),
          ),
        ],
      ),
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
                  child: Icon(Icons.check_box_outline_blank, size: 16, color: const Color(0xFFCBD5E1)),
                ),
                const SizedBox(width: 10),
                Expanded(flex: 30, child: Text('Product', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 14, child: Text('Variants', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 11, child: Text('Available', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 11, child: Text('Committed', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 11, child: Text('Incoming', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 11, child: Text('Sales 30D', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 12, child: Text('Sell-through %', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 14, child: Center(child: Text('Status', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
                const SizedBox(width: 24),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table Rows
          for (int i = 0; i < _products.length; i++) ...[
            _buildTableRow(i, _products[i]),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],

          // Table Pagination Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing 1–6 of 2,842 products',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
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
                      child: const Icon(Icons.chevron_left_rounded, size: 15, color: Color(0xFF94A3B8)),
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
                      child: Text('1', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFFB45309))),
                    ),
                    const SizedBox(width: 4),
                    _buildPageItem('2'),
                    const SizedBox(width: 4),
                    _buildPageItem('3'),
                    const SizedBox(width: 4),
                    _buildPageItem('4'),
                    const SizedBox(width: 4),
                    _buildPageItem('5'),
                    const SizedBox(width: 4),
                    Text('...', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8))),
                    const SizedBox(width: 4),
                    _buildPageItem('474'),
                    const SizedBox(width: 4),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.chevron_right_rounded, size: 15, color: Color(0xFF94A3B8)),
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
    final isSelected = _selectedProductIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedProductIndex = index;
          for (int j = 0; j < _products.length; j++) {
            _products[j].isSelected = (j == index);
          }
        });
      },
      child: Container(
        color: isSelected ? const Color(0xFFFBF4EB).withOpacity(0.35) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  item.isSelected = !item.isSelected;
                  if (item.isSelected) _selectedProductIndex = index;
                });
              },
              child: SizedBox(
                width: 20,
                child: Icon(
                  item.isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
                  size: 16,
                  color: item.isSelected ? const Color(0xFF181513) : const Color(0xFFCBD5E1),
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
                    child: Image.asset(
                      item.imagePath,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 34,
                        height: 34,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.checkroom_rounded, size: 16, color: Color(0xFF94A3B8)),
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
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          item.sku,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
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
                '${item.variantsCount} variants',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
              ),
            ),

            // Available
            Expanded(
              flex: 11,
              child: Text(
                '${item.available}',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
              ),
            ),

            // Committed
            Expanded(
              flex: 11,
              child: Text(
                '${item.committed}',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563)),
              ),
            ),

            // Incoming
            Expanded(
              flex: 11,
              child: Text(
                '${item.incoming}',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563)),
              ),
            ),

            // Sales 30D
            Expanded(
              flex: 11,
              child: Text(
                '${item.sales30d}',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563)),
              ),
            ),

            // Sell-through %
            Expanded(
              flex: 12,
              child: Text(
                '${item.sellThroughPct}%',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563)),
              ),
            ),

            // Status Badge
            Expanded(
              flex: 14,
              child: Center(
                child: _buildStatusBadge(item.status, item.statusType),
              ),
            ),

            // Actions
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFF9CA3AF)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String text, InventoryProductStatusType type) {
    Color bg;
    Color fg;
    if (type == InventoryProductStatusType.healthy) {
      bg = const Color(0xFFDCFCE7);
      fg = const Color(0xFF15803D);
    } else if (type == InventoryProductStatusType.lowStock) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildPageItem(String num) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: Text(num, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280))),
    );
  }

  // Selected Product Drawer (Right Card)
  Widget _buildSelectedProductDrawer() {
    final product = _currentSelectedProduct;

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
              const Icon(Icons.more_horiz_rounded, size: 18, color: Color(0xFF6B7280)),
            ],
          ),
          const SizedBox(height: 14),

          // Large Photo
          InkWell(
            onTap: () => widget.onViewProductDetails?.call(product.sku),
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                product.imagePath,
                width: double.infinity,
                height: 210,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 210,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.checkroom_rounded, size: 48, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Product Name and SKU Details
          InkWell(
            onTap: () => widget.onViewProductDetails?.call(product.sku),
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
            'SKU: ${product.sku}  •  Summer 2027  •  Shirts',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),

          // Navigation Tabs: Overview, Variants (16), Activity
          Row(
            children: [
              _buildDrawerTab('Overview', 0),
              const SizedBox(width: 16),
              _buildDrawerTab('Variants (${product.variantsCount})', 1),
              const SizedBox(width: 16),
              _buildDrawerTab('Activity', 2),
            ],
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Stock Stats List
          _buildStatRow(
            icon: Icons.inventory_2_outlined,
            label: 'Available Stock',
            value: '${product.available} units',
            valueColor: const Color(0xFF15803D),
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
            icon: Icons.calendar_today_outlined,
            label: 'Expected Lead Time',
            value: '12 Days',
            valueColor: const Color(0xFF111827),
          ),
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
                    const Icon(Icons.auto_awesome_rounded, size: 14, color: Color(0xFFB45309)),
                    const SizedBox(width: 6),
                    Text(
                      'AI SUGGESTION',
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
                  'Black/Medium is trending 34% higher than usual. Replenishment transfer advised within 48 hours to avoid stockout.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    height: 1.4,
                    color: const Color(0xFF451A03),
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB45309),
                      side: const BorderSide(color: Color(0xFFFDE68A)),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Run Replenishment →'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
        Row(
          children: [
            Icon(icon, size: 15, color: const Color(0xFF6B7280)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563)),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: valueColor),
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
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF4EB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart_rounded, size: 20, color: Color(0xFFB45309)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inventory Insights',
                    style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Outerwear category sales are up 24% this month. Consider\nincreasing stock for winter collection.',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF4B5563), height: 1.35),
                  ),
                ],
              ),
            ],
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFD97706)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
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
              const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Text(
                'Quick Actions',
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onAdjustStock,
                  icon: const Icon(Icons.tune_rounded, size: 14),
                  label: const Text('Adjust Stock'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500),
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
