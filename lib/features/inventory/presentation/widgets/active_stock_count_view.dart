// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StockCountItem {
  StockCountItem({
    required this.name,
    required this.variant,
    required this.sku,
    required this.systemQty,
    required this.countedQty,
    required this.imageAsset,
  });

  final String name;
  final String variant;
  final String sku;
  final int systemQty;
  int countedQty;
  final String imageAsset;

  int get variance => countedQty - systemQty;
  bool get isMatched => variance == 0;
}

class ActiveStockCountView extends StatefulWidget {
  const ActiveStockCountView({
    super.key,
    this.onViewFullReport,
    this.onPauseSession,
    this.onSubmitAudit,
    this.onScanBarcode,
  });

  final VoidCallback? onViewFullReport;
  final VoidCallback? onPauseSession;
  final VoidCallback? onSubmitAudit;
  final VoidCallback? onScanBarcode;

  @override
  State<ActiveStockCountView> createState() => _ActiveStockCountViewState();
}

class _ActiveStockCountViewState extends State<ActiveStockCountView> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  late final List<StockCountItem> _items;

  final List<String> _categories = [
    'Denim (145/200)',
    'Knitwear (89/120)',
    'Outerwear (20/150)',
    'Accessories (593/854)',
  ];

  @override
  void initState() {
    super.initState();
    _items = [
      StockCountItem(
        name: 'Oxford Linen Shirt',
        variant: 'Black / M',
        sku: 'TS-10492-BM',
        systemQty: 50,
        countedQty: 48,
        imageAsset: 'assets/oxford_linen_shirt.jpg',
      ),
      StockCountItem(
        name: 'Raw Denim Jeans',
        variant: 'Indigo / 32',
        sku: 'TS-22322-IND32',
        systemQty: 30,
        countedQty: 30,
        imageAsset: 'assets/oxford_linen_shirt_blue.jpg',
      ),
      StockCountItem(
        name: 'Cashmere Sweater',
        variant: 'Camel / L',
        sku: 'TS-50155-CL',
        systemQty: 12,
        countedQty: 15,
        imageAsset: 'assets/cashmere_sweater.jpg',
      ),
      StockCountItem(
        name: 'Silk Evening Dress',
        variant: 'Red / S',
        sku: 'TS-16166-RS',
        systemQty: 8,
        countedQty: 8,
        imageAsset: 'assets/silk_evening_dress.jpg',
      ),
      StockCountItem(
        name: 'Gabardine Trench Coat',
        variant: 'Beige / M',
        sku: 'TS-27193-BM',
        systemQty: 24,
        countedQty: 23,
        imageAsset: 'assets/gabardine_trench.jpg',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StockCountItem> get _filteredItems {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _items;
    return _items.where((i) {
      return i.name.toLowerCase().contains(q) ||
          i.variant.toLowerCase().contains(q) ||
          i.sku.toLowerCase().contains(q);
    }).toList();
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
          const SizedBox(height: 18),

          // 2. Hero Progress Card: Q3 Full Inventory Count
          _buildHeroProgressCard(),
          const SizedBox(height: 20),

          // 3. Main 2-Column Layout (Items Table & Live Analytics)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1060;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Items Table (~70%)
                    Expanded(
                      flex: 70,
                      child: _buildItemsTableColumn(),
                    ),
                    const SizedBox(width: 18),

                    // Right Column: Analytics & Team (~30%)
                    Expanded(
                      flex: 30,
                      child: _buildAnalyticsColumn(),
                    ),
                  ],
                );
              }

              // Stacked for smaller screens
              return Column(
                children: [
                  _buildItemsTableColumn(),
                  const SizedBox(height: 20),
                  _buildAnalyticsColumn(),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 4. Bottom 2-Card Row: AI Auditor Insights & Quick Actions
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 58, child: _buildAiAuditorInsightsCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 42, child: _buildQuickActionsCard()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildAiAuditorInsightsCard(),
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

  // 1. Header
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Active Stock Count',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF15803D),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'In Progress',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Real-time inventory counting and variance tracking.',
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Started by Alex Mercer (08:30 AM)',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
                Text(
                  'Q3 Full Inventory Count — Zone A',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF374151)),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Hero Progress Card
  Widget _buildHeroProgressCard() {
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
          // Top Row: Title + 64% Complete pill
          Row(
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
                    child: const Icon(Icons.inventory_rounded, size: 18, color: Color(0xFFB45309)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Q3 Full Inventory Count',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Zone A  •  Started Aug 27, 2026  •  08:30 AM',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  '64% Complete',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar (64% filled)
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: 0.64,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB45309)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _buildStatMetric('847', 'Counted Items'),
              const SizedBox(width: 32),
              _buildStatMetric('477', 'Remaining'),
              const SizedBox(width: 32),
              _buildStatMetric('1,324', 'Total SKUs'),
              const SizedBox(width: 32),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF6B7280)),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Est. Time Remaining', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280))),
                      Text('2h 15m', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                    ],
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                  backgroundColor: const Color(0xFFFFFBEB).withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text('View Details'),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String val, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(val, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280))),
      ],
    );
  }

  // 3A. Left Column: Items Table Column
  Widget _buildItemsTableColumn() {
    return Column(
      children: [
        // Category Pills & Search Toolbar Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Category Pills
            Row(
              children: [
                for (int i = 0; i < _categories.length; i++) ...[
                  InkWell(
                    onTap: () => setState(() => _selectedCategoryIndex = i),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedCategoryIndex == i ? const Color(0xFF181513) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedCategoryIndex == i ? const Color(0xFF181513) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        _categories[i],
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: _selectedCategoryIndex == i ? FontWeight.w600 : FontWeight.w500,
                          color: _selectedCategoryIndex == i ? Colors.white : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFF6B7280)),
                ),
              ],
            ),

            // Search input & Filter
            Row(
              children: [
                Container(
                  width: 170,
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
                            hintText: 'Search items...',
                            hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
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
        const SizedBox(height: 12),

        // Items Table Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    const SizedBox(width: 20, child: Icon(Icons.check_box_outline_blank, size: 16, color: Color(0xFFCBD5E1))),
                    const SizedBox(width: 10),
                    Expanded(flex: 34, child: Text('Item Details', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                    Expanded(flex: 22, child: Text('SKU', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                    Expanded(flex: 12, child: Center(child: Text('System Qty', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
                    Expanded(flex: 14, child: Center(child: Text('Counted Qty', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
                    Expanded(flex: 10, child: Center(child: Text('Variance', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
                    Expanded(flex: 12, child: Center(child: Text('Status', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Item Rows
              for (final item in _filteredItems) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const SizedBox(width: 20, child: Icon(Icons.check_box_outline_blank, size: 16, color: Color(0xFFCBD5E1))),
                      const SizedBox(width: 10),

                      // Thumbnail & Item Details
                      Expanded(
                        flex: 34,
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
                                    item.variant,
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
                        flex: 22,
                        child: Text(
                          item.sku,
                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF4B5563)),
                        ),
                      ),

                      // System Qty
                      Expanded(
                        flex: 12,
                        child: Center(
                          child: Text(
                            '${item.systemQty}',
                            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                          ),
                        ),
                      ),

                      // Counted Qty (editable box)
                      Expanded(
                        flex: 14,
                        child: Center(
                          child: Container(
                            width: 50,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFD1D5DB)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.countedQty}',
                              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                            ),
                          ),
                        ),
                      ),

                      // Variance
                      Expanded(
                        flex: 10,
                        child: Center(
                          child: Text(
                            item.variance == 0
                                ? '0'
                                : (item.variance > 0 ? '+${item.variance}' : '${item.variance}'),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: item.variance == 0
                                  ? const Color(0xFF6B7280)
                                  : (item.variance > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
                            ),
                          ),
                        ),
                      ),

                      // Status Pill
                      Expanded(
                        flex: 12,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.isMatched ? const Color(0xFFDCFCE7) : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.isMatched ? 'Matched' : 'Variance',
                              style: GoogleFonts.inter(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: item.isMatched ? const Color(0xFF15803D) : const Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Actions
                      const SizedBox(
                        width: 24,
                        child: Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFF9CA3AF)),
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
                    Text('Showing 1–5 of 145 items', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
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
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
                          alignment: Alignment.center,
                          child: Text('2', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
                          alignment: Alignment.center,
                          child: Text('3', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                        ),
                        const SizedBox(width: 4),
                        Text('...', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF94A3B8))),
                        const SizedBox(width: 4),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFE2E8F0))),
                          alignment: Alignment.center,
                          child: Text('29', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                        ),
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
        ),
      ],
    );
  }

  // 3B. Right Column: Analytics & Team Column
  Widget _buildAnalyticsColumn() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Live Counting Analytics + View Full Report
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.insights_rounded, size: 17, color: Color(0xFF111827)),
                  const SizedBox(width: 8),
                  Text('Live Counting Analytics', style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                ],
              ),
              InkWell(
                onTap: widget.onViewFullReport,
                child: Row(
                  children: [
                    Text('View Full Report', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFB45309))),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFB45309)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats with Circular Progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total SKUs Handled', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280))),
                        Text('847 / 1,324', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Discrepancies Flagged', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280))),
                        Text('23 items', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Categories Done', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280))),
                        Text('4 / 8 complete', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF15803D))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Circular Gauge showing 64%
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 0.64,
                      strokeWidth: 5.5,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB45309)),
                    ),
                    Center(
                      child: Text(
                        '64%',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Team Assignments
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Team Assignments', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
              InkWell(
                onTap: () {},
                child: Row(
                  children: [
                    Text('Manage Team', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFB45309))),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFB45309)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Team Member 1: Sarah K.
          _buildTeamMemberRow('assets/emma_carter.jpg', 'Sarah K.', 'Denim Section', '847 / 1,324'),
          const SizedBox(height: 8),

          // Team Member 2: Mike R.
          _buildTeamMemberRow('assets/vikram_singh.jpg', 'Mike R.', 'Outerwear Section', '612 / 854'),
          const SizedBox(height: 18),

          // Action 1: Pause & Save Session
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onPauseSession ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Stock count session paused and saved.'),
                        backgroundColor: Color(0xFF181513),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
              icon: const Icon(Icons.pause_rounded, size: 16),
              label: const Text('Pause & Save Session'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Action 2: Submit Count for Audit
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onSubmitAudit ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Stock count submitted for inventory manager audit.'),
                        backgroundColor: Color(0xFF181513),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
              icon: const Icon(Icons.check_rounded, size: 16, color: Color(0xFF111827)),
              label: const Text('Submit Count for Audit'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF111827),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberRow(String asset, String name, String section, String count) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundImage: AssetImage(asset),
          backgroundColor: const Color(0xFFF1F5F9),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
              Text(section, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF6B7280))),
            ],
          ),
        ),
        Text(count, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
      ],
    );
  }

  // 4A. Bottom Left: AI Auditor Insights Card
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
                  'Delhi flagship has completed Denim. Recommend merging counts automatically to speed up variance resolution.',
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

  // 4B. Bottom Right: Quick Actions Card
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
              const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF111827)),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(Icons.qr_code_scanner_rounded, 'Scan Barcode', widget.onScanBarcode),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(Icons.file_upload_outlined, 'Bulk Update', () {}),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildActionButton(Icons.description_outlined, 'Export Report', () {}),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String title, VoidCallback? onTap) {
    return OutlinedButton(
      onPressed: onTap ?? () {},
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        minimumSize: Size.zero,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF4B5563)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              title,
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
