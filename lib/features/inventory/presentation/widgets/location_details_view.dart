// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationStockItem {
  const LocationStockItem({
    required this.name,
    required this.spec,
    required this.sku,
    required this.category,
    required this.categoryBg,
    required this.categoryColor,
    required this.onHand,
    required this.reserved,
    required this.available,
    required this.lastRestocked,
    required this.lastRestockedDate,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.imageAsset,
  });

  final String name;
  final String spec;
  final String sku;
  final String category;
  final Color categoryBg;
  final Color categoryColor;
  final int onHand;
  final int reserved;
  final int available;
  final String lastRestocked;
  final String? lastRestockedDate;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final String imageAsset;
}

class LocationDetailsView extends StatefulWidget {
  const LocationDetailsView({
    super.key,
    this.locationName = 'SoHo Flagship Store',
    this.locationAddress = '112 Greene St, New York, NY 10012',
    this.locationType = 'Retail Store',
    this.onBackToLocations,
    this.onCreateTransfer,
    this.onStockAdjustment,
    this.onGenerateReport,
    this.onViewAiInsights,
  });

  final String locationName;
  final String locationAddress;
  final String locationType;
  final VoidCallback? onBackToLocations;
  final VoidCallback? onCreateTransfer;
  final VoidCallback? onStockAdjustment;
  final VoidCallback? onGenerateReport;
  final VoidCallback? onViewAiInsights;

  @override
  State<LocationDetailsView> createState() => _LocationDetailsViewState();
}

class _LocationDetailsViewState extends State<LocationDetailsView> {
  int _selectedTab = 0; // 0: Inventory Matrix, 1: Transfers, 2: Staffing Access, 3: Terminal Settings
  String _selectedCategoryFilter = 'All Items';
  final TextEditingController _searchController = TextEditingController();

  final List<LocationStockItem> _items = const [
    LocationStockItem(
      name: 'Oxford Linen Shirt (Black/M)',
      spec: 'Black / M',
      sku: 'TS-OLS-BM',
      category: 'Shirts',
      categoryBg: Color(0xFFEFF6FF),
      categoryColor: Color(0xFF2563EB),
      onHand: 18,
      reserved: 2,
      available: 16,
      lastRestocked: '3 days ago',
      lastRestockedDate: 'Nov 11, 2027',
      status: 'Low Stock',
      statusBg: Color(0xFFFEF3C7),
      statusColor: Color(0xFFD97706),
      imageAsset: 'assets/oxford_linen_shirt.jpg',
    ),
    LocationStockItem(
      name: 'Merino Wool Crewneck (Navy / L)',
      spec: 'Navy / L',
      sku: 'TS-MWC-NL',
      category: 'Knitwear',
      categoryBg: Color(0xFFF1F5F9),
      categoryColor: Color(0xFF6366F1),
      onHand: 120,
      reserved: 14,
      available: 106,
      lastRestocked: '1 week ago',
      lastRestockedDate: 'Nov 7, 2027',
      status: 'Healthy',
      statusBg: Color(0xFFDCFCE7),
      statusColor: Color(0xFF15803D),
      imageAsset: 'assets/merino_wool_blazer.jpg',
    ),
    LocationStockItem(
      name: 'Silk Evening Dress (Crimson / S)',
      spec: 'Crimson / S',
      sku: 'TS-SED-CS',
      category: 'Dresses',
      categoryBg: Color(0xFFFEE2E2),
      categoryColor: Color(0xFFDC2626),
      onHand: 0,
      reserved: 0,
      available: 0,
      lastRestocked: 'Never',
      lastRestockedDate: null,
      status: 'Out of Stock',
      statusBg: Color(0xFFFEE2E2),
      statusColor: Color(0xFFDC2626),
      imageAsset: 'assets/silk_evening_dress.jpg',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LocationStockItem> get _filteredItems {
    final q = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      if (_selectedCategoryFilter != 'All Items' && item.category != _selectedCategoryFilter) {
        return false;
      }
      if (q.isNotEmpty) {
        final matches = item.name.toLowerCase().contains(q) ||
            item.sku.toLowerCase().contains(q) ||
            item.category.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  void _showEditLocationModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Edit Store Profile', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: widget.locationName,
                decoration: InputDecoration(
                  labelText: 'Location Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: widget.locationAddress,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Store details saved.'),
                  backgroundColor: Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Profile Card (Header)
          _buildProfileHeaderCard(),
          const SizedBox(height: 20),

          // 2. Top 4 Metric KPI Cards
          _buildKpiCardsRow(),
          const SizedBox(height: 20),

          // 3. Tab Navigation Row
          _buildTabBar(),
          const SizedBox(height: 16),

          // 4. Filter Pills & Search Toolbar
          _buildToolbarRow(),
          const SizedBox(height: 16),

          // 5. Inventory Items Table
          _buildInventoryTable(),
          const SizedBox(height: 24),

          // 6. Bottom Row (2 Columns: Inventory Insights + Quick Actions)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1060;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 58, child: _buildInventoryInsightsCard()),
                    const SizedBox(width: 20),
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
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 1. Profile Header Card
  Widget _buildProfileHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Store Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/central_store.jpg',
              width: 120,
              height: 78,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 120,
                height: 78,
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.storefront_outlined, color: Color(0xFF94A3B8), size: 36),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Middle: Title, Badge, Address
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.locationName,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.locationType,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 4),
                    Text(
                      widget.locationAddress,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right Actions: [Edit Location] and [⋮]
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _showEditLocationModal,
                icon: const Icon(Icons.edit_outlined, size: 15),
                label: const Text('Edit Location'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF6B7280)),
                  onSelected: (val) {
                    if (val == 'back') widget.onBackToLocations?.call();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'back', child: Text('Back to Locations', style: GoogleFonts.inter(fontSize: 12.5))),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Top 4 Metric KPI Cards
  Widget _buildKpiCardsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.inventory_2_outlined,
            title: 'SKUs Stocked Here',
            value: '847 units',
            trend: '↑ 12%',
            trendColor: const Color(0xFF16A34A),
            sparklineColor: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.warning_amber_rounded,
            title: 'Low Stock Alerts',
            value: '12 alerts',
            valueColor: const Color(0xFFDC2626),
            trend: '↑ 3 new',
            trendColor: const Color(0xFFDC2626),
            sparklineColor: const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.payments_outlined,
            title: 'Estimated Valuation',
            value: '₹ 1,42,500',
            trend: '↑ 8%',
            trendColor: const Color(0xFF16A34A),
            sparklineColor: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.all_inbox_outlined,
            title: 'Total Items',
            value: '3 categories',
            subtitle: 'Shirts • Jackets • Dresses',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
    String? trend,
    Color? trendColor,
    String? subtitle,
    Color? sparklineColor,
  }) {
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBF4EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF92400E)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (trend != null)
                    Text(
                      trend,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: trendColor ?? const Color(0xFF16A34A),
                      ),
                    )
                  else if (subtitle != null)
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)),
                    ),
                ],
              ),
              if (sparklineColor != null)
                SizedBox(
                  width: 54,
                  height: 22,
                  child: CustomPaint(
                    painter: _MiniTrendPainter(color: sparklineColor),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Tab Navigation Row
  Widget _buildTabBar() {
    final tabs = ['Inventory Matrix', 'Transfers (2 Active)', 'Staffing Access', 'Terminal Settings'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            InkWell(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == i ? const Color(0xFFB45309) : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: _selectedTab == i ? FontWeight.w700 : FontWeight.w500,
                    color: _selectedTab == i ? const Color(0xFF92400E) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  // 4. Filter Pills & Search Toolbar
  Widget _buildToolbarRow() {
    return Row(
      children: [
        // Search Input
        Container(
          width: 260,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 17, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.inter(fontSize: 12.5),
                  decoration: const InputDecoration(
                    hintText: "Search this store's stock...",
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // Filter Pills
        _buildPill('All Items', '847', isAll: true),
        const SizedBox(width: 8),
        _buildPill('Shirts', '312'),
        const SizedBox(width: 8),
        _buildPill('Jackets', '286'),
        const SizedBox(width: 8),
        _buildPill('Dresses', '249'),

        const Spacer(),

        // Filters Action Button
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.tune_rounded, size: 15),
          label: const Text('Filters'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF374151),
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String label, String count, {bool isAll = false}) {
    final isSelected = _selectedCategoryFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedCategoryFilter = label),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF181513) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isSelected ? const Color(0xFF181513) : const Color(0xFFD1D5DB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF374151) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Inventory Table
  Widget _buildInventoryTable() {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SizedBox(width: 20, child: Icon(Icons.check_box_outline_blank, size: 16, color: Color(0xFFCBD5E1))),
                const SizedBox(width: 12),
                Expanded(
                  flex: 30,
                  child: Row(
                    children: [
                      Text('Item Name', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                      const SizedBox(width: 4),
                      const Icon(Icons.unfold_more_rounded, size: 14, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                ),
                Expanded(
                  flex: 14,
                  child: Row(
                    children: [
                      Text('SKU', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                      const SizedBox(width: 4),
                      const Icon(Icons.unfold_more_rounded, size: 14, color: Color(0xFF9CA3AF)),
                    ],
                  ),
                ),
                Expanded(flex: 12, child: Text('Category', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 10, child: Text('On Hand', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 10, child: Text('Reserved', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 10, child: Text('Available', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 16, child: Text('Last Restocked', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 14, child: Text('Status', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                const SizedBox(width: 32, child: Text('Actions', textAlign: TextAlign.end, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Rows
          for (final item in _filteredItems) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const SizedBox(width: 20, child: Icon(Icons.check_box_outline_blank, size: 16, color: Color(0xFFCBD5E1))),
                  const SizedBox(width: 12),

                  // Item Name & Spec
                  Expanded(
                    flex: 30,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            item.imageAsset,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 36,
                              height: 36,
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.checkroom_rounded, size: 18, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
                              const SizedBox(height: 1),
                              Text(item.spec, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SKU
                  Expanded(
                    flex: 14,
                    child: Text(item.sku, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563))),
                  ),

                  // Category Pill
                  Expanded(
                    flex: 12,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: item.categoryBg, borderRadius: BorderRadius.circular(4)),
                        child: Text(item.category, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: item.categoryColor)),
                      ),
                    ),
                  ),

                  // On Hand
                  Expanded(
                    flex: 10,
                    child: Text('${item.onHand}', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                  ),

                  // Reserved
                  Expanded(
                    flex: 10,
                    child: Text('${item.reserved}', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF4B5563))),
                  ),

                  // Available
                  Expanded(
                    flex: 10,
                    child: Text('${item.available}', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF4B5563))),
                  ),

                  // Last Restocked
                  Expanded(
                    flex: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.lastRestocked, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151))),
                        if (item.lastRestockedDate != null) ...[
                          const SizedBox(height: 1),
                          Text(item.lastRestockedDate!, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF9CA3AF))),
                        ],
                      ],
                    ),
                  ),

                  // Status Pill
                  Expanded(
                    flex: 14,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(color: item.statusBg, borderRadius: BorderRadius.circular(4)),
                        child: Text(item.status, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: item.statusColor)),
                      ),
                    ),
                  ),

                  // Actions
                  SizedBox(
                    width: 32,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFF6B7280)),
                        onSelected: (val) {
                          if (val == 'adjust') widget.onStockAdjustment?.call();
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'adjust', child: Text('Adjust Stock', style: GoogleFonts.inter(fontSize: 12.5))),
                          PopupMenuItem(value: 'transfer', child: Text('Transfer SKU', style: GoogleFonts.inter(fontSize: 12.5))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],

          // Footer Pagination
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Showing 1–3 of 3 items', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: const Icon(Icons.chevron_left_rounded, size: 16, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: const Color(0xFFFBF4EB), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFD97706))),
                      alignment: Alignment.center,
                      child: Text('1', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFB45309))),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
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

  // 6. Left: Inventory Insights Card
  Widget _buildInventoryInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFBF4EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventory Insights',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                ),
                const SizedBox(height: 2),
                Text(
                  'This location has 12 low stock items. Consider replenishment to avoid stockouts.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: widget.onViewAiInsights,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFF59E0B)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('View AI Insights'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 13),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. Right: Quick Actions Card
  Widget _buildQuickActionsCard() {
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
                  onPressed: widget.onCreateTransfer ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening Transfer Request for SoHo Flagship Store...'),
                            backgroundColor: Color(0xFF181513),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                  icon: const Icon(Icons.sync_alt_rounded, size: 14),
                  label: const Text('Create Transfer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onStockAdjustment,
                  icon: const Icon(Icons.description_outlined, size: 14),
                  label: const Text('Stock Adjustment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onGenerateReport ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Generating SoHo Store inventory valuation audit report...'),
                            backgroundColor: Color(0xFF181513),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                  icon: const Icon(Icons.bar_chart_rounded, size: 14),
                  label: const Text('Generate Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
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

class _MiniTrendPainter extends CustomPainter {
  const _MiniTrendPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..cubicTo(size.width * 0.35, size.height * 0.8, size.width * 0.6, size.height * 0.25, size.width, size.height * 0.1);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
