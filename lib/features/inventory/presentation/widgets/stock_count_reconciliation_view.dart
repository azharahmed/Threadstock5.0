// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscrepancyItem {
  DiscrepancyItem({
    required this.name,
    required this.category,
    required this.sku,
    required this.sysQty,
    required this.countedQty,
    required this.imageAsset,
    required this.reason,
    required this.status,
    this.isSelected = false,
  });

  final String name;
  final String category;
  final String sku;
  final int sysQty;
  final int countedQty;
  final String imageAsset;
  String reason;
  String status;
  bool isSelected;

  int get variance => countedQty - sysQty;
}

class StockCountReconciliationView extends StatefulWidget {
  const StockCountReconciliationView({
    super.key,
    this.onExportReport,
    this.onApplyAdjustments,
  });

  final VoidCallback? onExportReport;
  final VoidCallback? onApplyAdjustments;

  @override
  State<StockCountReconciliationView> createState() =>
      _StockCountReconciliationViewState();
}

class _StockCountReconciliationViewState
    extends State<StockCountReconciliationView> {
  int _selectedTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  late final List<DiscrepancyItem> _items;

  final List<String> _tabs = [
    'Discrepancies (23)',
    'Pending Review (12)',
    'Approved (8)',
    'All Items',
  ];

  final List<String> _reasonOptions = [
    'Theft',
    'Damage',
    'Unrecorded Inbound',
    'Transfer Error',
    'Miscount',
    'Data Entry Error',
  ];

  @override
  void initState() {
    super.initState();
    _items = [
      DiscrepancyItem(
        name: 'Oxford Linen Shirt (Black/M)',
        category: 'Shirts  •  Black / M',
        sku: 'TS-10492-BM',
        sysQty: 50,
        countedQty: 48,
        imageAsset: 'assets/oxford_linen_shirt.jpg',
        reason: 'Theft',
        status: 'Pending Action',
      ),
      DiscrepancyItem(
        name: 'Merino Wool Blazer (Navy/L)',
        category: 'Outerwear  •  Navy / L',
        sku: 'TS-20788-NL',
        sysQty: 18,
        countedQty: 15,
        imageAsset: 'assets/merino_wool_blazer.jpg',
        reason: 'Damage',
        status: 'Approved',
      ),
      DiscrepancyItem(
        name: 'Silk Evening Dress (Red/S)',
        category: 'Dresses  •  Red / S',
        sku: 'TS-16166-RS',
        sysQty: 8,
        countedQty: 12,
        imageAsset: 'assets/silk_evening_dress.jpg',
        reason: 'Unrecorded Inbound',
        status: 'Pending Action',
      ),
      DiscrepancyItem(
        name: 'Raw Denim Jeans (Indigo/32)',
        category: 'Denim  •  Indigo / 32',
        sku: 'TS-22322-IND',
        sysQty: 30,
        countedQty: 27,
        imageAsset: 'assets/raw_denim_jeans.jpg',
        reason: 'Transfer Error',
        status: 'Under Review',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _selectedCount => _items.where((i) => i.isSelected).length;

  List<DiscrepancyItem> get _filteredItems {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((i) {
      return i.name.toLowerCase().contains(q) ||
          i.sku.toLowerCase().contains(q) ||
          i.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row: Title, Subtitle, and Top-Right Action Buttons
          _buildHeader(),
          const SizedBox(height: 18),

          // 2. Top Metrics Row (4 Cards)
          _buildMetricsRow(),
          const SizedBox(height: 20),

          // 3. Main Card: Tabs, Search/Filters, Batch Actions Toolbar, Table, Pagination
          _buildMainTableCard(),
          const SizedBox(height: 20),

          // 4. Bottom 2-Card Row: AI Auditor Insights & Reconciliation Progress
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 940;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 58, child: _buildAiAuditorInsightsCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 42, child: _buildReconciliationProgressCard()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildAiAuditorInsightsCard(),
                  const SizedBox(height: 16),
                  _buildReconciliationProgressCard(),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Count Reconciliation',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reconcile counted units with current ledger across all locations.',
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
              onPressed: widget.onExportReport ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Exporting audit report as CSV / PDF...'),
                        backgroundColor: Color(0xFF181513),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Export Audit Report'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1F2937),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: widget.onApplyAdjustments ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reconciliation adjustments posted to inventory ledger.'),
                        backgroundColor: Color(0xFF181513),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              child: const Text('Apply Adjustments'),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Metrics Row (4 Cards)
  Widget _buildMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;
        final cardWidth = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            // Card 1: Total Discrepancies
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                icon: Icons.inventory_2_outlined,
                iconBg: const Color(0xFFFBF4EB),
                iconColor: const Color(0xFFB45309),
                title: 'Total Discrepancies',
                value: '23 SKUs',
                subWidget: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '↑ 12%',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Mini vertical bars
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildMiniBar(6, const Color(0xFFFCA5A5)),
                        const SizedBox(width: 3),
                        _buildMiniBar(10, const Color(0xFFFCA5A5)),
                        const SizedBox(width: 3),
                        _buildMiniBar(14, const Color(0xFFFCA5A5)),
                        const SizedBox(width: 3),
                        _buildMiniBar(8, const Color(0xFFFCA5A5)),
                        const SizedBox(width: 3),
                        _buildMiniBar(18, const Color(0xFFEF4444)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Card 2: Shrinkage Value
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                icon: Icons.south_east_rounded,
                iconBg: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFDC2626),
                title: 'Shrinkage Value',
                value: '-₹1.48L',
                subWidget: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        'Cost Impact',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626)),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 54,
                      height: 16,
                      child: CustomPaint(painter: _SparklinePainter(color: const Color(0xFFDC2626), isUp: false)),
                    ),
                  ],
                ),
              ),
            ),

            // Card 3: Overage Value
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                icon: Icons.north_east_rounded,
                iconBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF15803D),
                title: 'Overage Value',
                value: '+₹27,360',
                subWidget: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        'Surplus Found',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A)),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 54,
                      height: 16,
                      child: CustomPaint(painter: _SparklinePainter(color: const Color(0xFF16A34A), isUp: true)),
                    ),
                  ],
                ),
              ),
            ),

            // Card 4: Net Ledger Adjustment
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                icon: Icons.account_balance_wallet_outlined,
                iconBg: const Color(0xFFFEF3C7),
                iconColor: const Color(0xFFB45309),
                title: 'Net Ledger Adjustment',
                value: '-₹1.20L',
                subWidget: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Text(
                      'Post Adjustment',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFB45309)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required Widget subWidget,
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
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 17, color: iconColor),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          subWidget,
        ],
      ),
    );
  }

  Widget _buildMiniBar(double height, Color color) {
    return Container(
      width: 4,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }

  // 3. Main Table Card
  Widget _buildMainTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Tabs + Search & Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Tabs
                Row(
                  children: [
                    for (int i = 0; i < _tabs.length; i++) ...[
                      InkWell(
                        onTap: () => setState(() => _selectedTabIndex = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTabIndex == i ? const Color(0xFFB45309) : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: Text(
                            _tabs[i],
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: _selectedTabIndex == i ? FontWeight.w700 : FontWeight.w500,
                              color: _selectedTabIndex == i ? const Color(0xFFB45309) : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),

                // Search & Filter buttons
                Row(
                  children: [
                    Container(
                      width: 210,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 15, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.inter(fontSize: 12),
                              decoration: const InputDecoration(
                                hintText: 'Search items, SKU or variant...',
                                hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11.5),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.tune_rounded, size: 14),
                      label: const Text('Filters'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Batch Actions Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.flag_outlined, size: 14, color: Color(0xFF374151)),
                      label: const Text('Bulk Resolve as Damaged'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.person_add_alt_1_outlined, size: 14, color: Color(0xFF374151)),
                      label: const Text('Approve System Inventory Override'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_selectedCount items selected',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    final allSelected = _items.every((i) => i.isSelected);
                    setState(() {
                      for (final i in _items) {
                        i.isSelected = !allSelected;
                      }
                    });
                  },
                  child: SizedBox(
                    width: 20,
                    child: Icon(
                      _items.every((i) => i.isSelected)
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank,
                      size: 16,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(flex: 30, child: Text('Product Name', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 15, child: Text('SKU', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 10, child: Center(child: Text('Sys Qty', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
                Expanded(flex: 10, child: Center(child: Text('Counted', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
                Expanded(flex: 10, child: Center(child: Text('Variance', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
                Expanded(flex: 22, child: Text('Reason for Discrepancy', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 16, child: Center(child: Text('Audit Status', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
                Expanded(flex: 8, child: Center(child: Text('Actions', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table Rows
          for (final item in _filteredItems) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => setState(() => item.isSelected = !item.isSelected),
                    child: SizedBox(
                      width: 20,
                      child: Icon(
                        item.isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
                        size: 16,
                        color: item.isSelected ? const Color(0xFFB45309) : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Product Details with Thumbnail
                  Expanded(
                    flex: 30,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            item.imageAsset,
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
                                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                item.category,
                                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SKU
                  Expanded(
                    flex: 15,
                    child: Text(
                      item.sku,
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF4B5563)),
                    ),
                  ),

                  // Sys Qty
                  Expanded(
                    flex: 10,
                    child: Center(
                      child: Text(
                        '${item.sysQty}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                      ),
                    ),
                  ),

                  // Counted
                  Expanded(
                    flex: 10,
                    child: Center(
                      child: Text(
                        '${item.countedQty}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                      ),
                    ),
                  ),

                  // Variance
                  Expanded(
                    flex: 10,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.variance < 0 ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.variance > 0 ? '+${item.variance}' : '${item.variance}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: item.variance < 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Reason for Discrepancy Dropdown
                  Expanded(
                    flex: 22,
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: item.reason,
                          isDense: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF6B7280)),
                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF374151), fontWeight: FontWeight.w500),
                          items: _reasonOptions.map((r) {
                            return DropdownMenuItem<String>(
                              value: r,
                              child: Text(r),
                            );
                          }).toList(),
                          onChanged: (newReason) {
                            if (newReason != null) {
                              setState(() => item.reason = newReason);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Audit Status
                  Expanded(
                    flex: 16,
                    child: Center(
                      child: _buildStatusPill(item.status),
                    ),
                  ),

                  // Actions
                  Expanded(
                    flex: 8,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFF9CA3AF)),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
                Text('Showing 1–4 of 23 discrepancy items', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: const Icon(Icons.chevron_left_rounded, size: 16, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(color: const Color(0xFFFBF4EB), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFD97706))),
                      alignment: Alignment.center,
                      child: Text('1', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFB45309))),
                    ),
                    const SizedBox(width: 4),
                    _buildPageNum('2'),
                    const SizedBox(width: 4),
                    _buildPageNum('3'),
                    const SizedBox(width: 4),
                    _buildPageNum('4'),
                    const SizedBox(width: 4),
                    _buildPageNum('5'),
                    const SizedBox(width: 4),
                    Text('...', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                    const SizedBox(width: 4),
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

  Widget _buildPageNum(String num) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
      alignment: Alignment.center,
      child: Text(num, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFFFFFBEB);
    Color text = const Color(0xFFB45309);

    if (status == 'Approved') {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF15803D);
    } else if (status == 'Under Review') {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: text),
      ),
    );
  }

  // 4A. AI Auditor Insights Card
  Widget _buildAiAuditorInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF4EB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFB45309), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Auditor Insights',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Top discrepancies are linked to Denim and Outerwear categories. Consider verifying recent transfers and damaged items.',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280), height: 1.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFFDE68A)),
              backgroundColor: const Color(0xFFFFFBEB).withOpacity(0.5),
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

  // 4B. Reconciliation Progress Card
  Widget _buildReconciliationProgressCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reconciliation Progress',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
              ),
              Text(
                '64% Complete',
                style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.64,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB45309)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildProgressStat('23', 'Discrepancies', const Color(0xFF111827)),
              const SizedBox(width: 16),
              _buildProgressStat('12', 'Pending', const Color(0xFFDC2626)),
              const SizedBox(width: 16),
              _buildProgressStat('8', 'Approved', const Color(0xFF15803D)),
              const Spacer(),
              _buildProgressStat('847', 'Items Counted', const Color(0xFF111827)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String val, String label, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: valColor)),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280))),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.color, required this.isUp});
  final Color color;
  final bool isUp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isUp) {
      path.moveTo(0, size.height * 0.85);
      path.lineTo(size.width * 0.25, size.height * 0.7);
      path.lineTo(size.width * 0.5, size.height * 0.75);
      path.lineTo(size.width * 0.75, size.height * 0.35);
      path.lineTo(size.width, size.height * 0.15);
    } else {
      path.moveTo(0, size.height * 0.2);
      path.lineTo(size.width * 0.25, size.height * 0.35);
      path.lineTo(size.width * 0.5, size.height * 0.3);
      path.lineTo(size.width * 0.75, size.height * 0.7);
      path.lineTo(size.width, size.height * 0.85);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isUp != isUp;
}
