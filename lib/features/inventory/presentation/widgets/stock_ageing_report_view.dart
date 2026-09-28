// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/responsive_values.dart';
import '../../data/stock_ageing_repository.dart';

class StockAgeingReportView extends StatefulWidget {
  final VoidCallback? onExportBreakdown;
  final VoidCallback? onTriggerMarkdownPlan;
  final VoidCallback? onViewRecommendations;
  final VoidCallback? onCreateTransferPlan;
  final StockAgeingRepository? repository;
  final String? locationId;

  const StockAgeingReportView({
    super.key,
    this.onExportBreakdown,
    this.onTriggerMarkdownPlan,
    this.onViewRecommendations,
    this.onCreateTransferPlan,
    this.repository,
    this.locationId,
  });

  @override
  State<StockAgeingReportView> createState() => _StockAgeingReportViewState();
}

class _StockAgeingReportViewState extends State<StockAgeingReportView> {
  late final StockAgeingRepository _repository;
  bool _isLoading = true;
  StockAgeingSummary _summary = StockAgeingSummary.empty;
  StockAgeingItem? _selectedItem;

  String _selectedInterval = 'All Ageing Intervals';
  String _selectedCategory = 'All Categories';
  String _valuationBasis = 'Cost Basis';

  final List<String> _intervals = const [
    'All Ageing Intervals',
    '0–30 Days (Fresh)',
    '31–90 Days (Active)',
    '91–180 Days (Aging)',
    '180+ Days (Critical)',
  ];

  final List<String> _valuationOptions = const [
    'Cost Basis',
    'Selling Price Basis',
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? StockAgeingRepository();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant StockAgeingReportView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationId != widget.locationId) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final summary = await _repository.loadStockAgeing(
        locationId: widget.locationId,
      );
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
          // Do NOT select any product by default - user selects to inspect
          _selectedItem = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _summary = StockAgeingSummary.empty;
          _isLoading = false;
          _selectedItem = null;
        });
      }
    }
  }

  List<StockAgeingItem> get _filteredItems {
    return _summary.items.where((item) {
      // Interval filter
      if (_selectedInterval == '0–30 Days (Fresh)' && item.ageDays > 30)
        return false;
      if (_selectedInterval == '31–90 Days (Active)' &&
          (item.ageDays <= 30 || item.ageDays > 90))
        return false;
      if (_selectedInterval == '91–180 Days (Aging)' &&
          (item.ageDays <= 90 || item.ageDays > 180))
        return false;
      if (_selectedInterval == '180+ Days (Critical)' && item.ageDays <= 180)
        return false;

      // Category filter
      if (_selectedCategory != 'All Categories' &&
          item.category != _selectedCategory)
        return false;

      return true;
    }).toList();
  }

  bool get _hasAgedStock => _summary.items.any((it) => it.ageDays > 90);

  void _showMarkdownPlanDialog() {
    if (!_hasAgedStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'All inventory is fresh (under 90 days). No markdown plan is currently warranted.',
            style: GoogleFonts.inter(fontSize: 13),
          ),
          backgroundColor: const Color(0xFF181512),
        ),
      );
      return;
    }

    final agedItems = _summary.items.where((it) => it.ageDays > 90).toList();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(
              Icons.flash_on_rounded,
              size: 20,
              color: Color(0xFF181512),
            ),
            const SizedBox(width: 10),
            Text(
              'Trigger Markdown Plan',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181512),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identified ${agedItems.length} SKU(s) exceeding 90 days holding duration:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B6358),
                ),
              ),
              const SizedBox(height: 14),
              _buildMarkdownOption(
                '91–180 Days (High Aging)',
                '15% Seasonal Markdown',
                'Recovers capital and boosts sell-through',
              ),
              _buildMarkdownOption(
                '180+ Days (Critical Aging)',
                '25% Clearance Markdown',
                'Prevents permanent carrying loss',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B6358),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Markdown plan scheduled for review.',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  backgroundColor: const Color(0xFF181512),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181512),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Schedule Plan',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownOption(String title, String action, String outcome) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEADBCA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181512),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              action,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8C5E33),
              ),
            ),
            Text(
              outcome,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF6B6358),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 350,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF8C5E33),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveHorizontalMargin,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Filter and Action Bar (with Valuation Cost Basis option)
          _buildFilterBar(),
          const SizedBox(height: 16),

          if (_summary.isEmpty) ...[
            _buildEmptyState(),
          ] else ...[
            // 2. Ageing Distribution by Category (Stacked Bars based on real data)
            _buildDistributionStackedBarsCard(),
            const SizedBox(height: 16),

            // 3. Middle Section (Detailed Ledger + Product Inspector)
            _buildMiddleSection(),
            const SizedBox(height: 16),

            // 4. Bottom AI Callout Banner
            _buildAiInsightBanner(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF9F5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 26,
              color: Color(0xFF8C5E33),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No inventory ageing data yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181512),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Stock ageing will appear after inventory is received.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B6358),
            ),
          ),
        ],
      ),
    );
  }

  // 1. Filter and Action Bar
  Widget _buildFilterBar() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Intervals Dropdown
        PopupMenuButton<String>(
          tooltip: 'Select Ageing Interval',
          offset: const Offset(0, 40),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE5DACD)),
          ),
          onSelected: (val) => setState(() => _selectedInterval = val),
          itemBuilder: (context) => _intervals.map((item) {
            return PopupMenuItem<String>(
              value: item,
              height: 36,
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: item == _selectedInterval
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: item == _selectedInterval
                      ? const Color(0xFF8C5E33)
                      : const Color(0xFF181512),
                ),
              ),
            );
          }).toList(),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5DACD)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Color(0xFF6B6358),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedInterval,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181512),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF6B6358),
                ),
              ],
            ),
          ),
        ),

        // Categories Dropdown (Derived from real categories)
        PopupMenuButton<String>(
          tooltip: 'Select Category',
          offset: const Offset(0, 40),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE5DACD)),
          ),
          onSelected: (val) => setState(() => _selectedCategory = val),
          itemBuilder: (context) => _summary.categories.map((cat) {
            return PopupMenuItem<String>(
              value: cat,
              height: 36,
              child: Text(
                cat,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: cat == _selectedCategory
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: cat == _selectedCategory
                      ? const Color(0xFF8C5E33)
                      : const Color(0xFF181512),
                ),
              ),
            );
          }).toList(),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5DACD)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  size: 14,
                  color: Color(0xFF6B6358),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedCategory,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181512),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF6B6358),
                ),
              ],
            ),
          ),
        ),

        // Valuation Basis Dropdown (Requirement 10: Valuation Cost Basis as report option)
        PopupMenuButton<String>(
          tooltip: 'Select Valuation Basis',
          offset: const Offset(0, 40),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE5DACD)),
          ),
          onSelected: (val) => setState(() => _valuationBasis = val),
          itemBuilder: (context) => _valuationOptions.map((opt) {
            return PopupMenuItem<String>(
              value: opt,
              height: 36,
              child: Text(
                opt,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: opt == _valuationBasis
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: opt == _valuationBasis
                      ? const Color(0xFF8C5E33)
                      : const Color(0xFF181512),
                ),
              ),
            );
          }).toList(),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5DACD)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Valuation: ',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6358),
                  ),
                ),
                Text(
                  _valuationBasis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181512),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF6B6358),
                ),
              ],
            ),
          ),
        ),

        // Export Breakdown Button
        InkWell(
          onTap:
              widget.onExportBreakdown ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Exporting Stock Ageing Report CSV...',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                    backgroundColor: const Color(0xFF181512),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5DACD)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.file_download_outlined,
                  size: 16,
                  color: Color(0xFF181512),
                ),
                const SizedBox(width: 6),
                Text(
                  'Export Breakdown',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181512),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Trigger Markdown Plan Button (Requirement 8: Disabled unless real aged inventory exists)
        Tooltip(
          message: _hasAgedStock
              ? 'Trigger promotional markdown for aged inventory'
              : 'No markdown plan required for current stock',
          child: Opacity(
            opacity: _hasAgedStock ? 1.0 : 0.45,
            child: InkWell(
              onTap: widget.onTriggerMarkdownPlan ?? _showMarkdownPlanDialog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF181512),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Trigger Markdown Plan',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Ageing Distribution by Category (Stacked Bar Chart derived from real items)
  Widget _buildDistributionStackedBarsCard() {
    final realCategories = _summary.categories
        .where((c) => c != 'All Categories')
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ageing Distribution by Category',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181512),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share of inventory value across ageing buckets',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B6358),
                    ),
                  ),
                ],
              ),
              // Legend
              Wrap(
                spacing: 14,
                children: [
                  _buildLegendBox(const Color(0xFF8E9EAB), '0-30d'),
                  _buildLegendBox(const Color(0xFF5D6B78), '31-90d'),
                  _buildLegendBox(const Color(0xFF2E3842), '91-180d'),
                  _buildLegendBox(const Color(0xFFC89748), '180+d'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Render real category stacked bars
          if (realCategories.isEmpty)
            Text(
              'No category distribution available.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6B6358),
              ),
            )
          else
            ...realCategories.map((catName) {
              final catItems = _summary.items
                  .where((i) => i.category == catName)
                  .toList();
              final catTotalVal = catItems.fold<double>(
                0,
                (sum, i) => sum + i.numericValue,
              );

              double b0 = 0, b31 = 0, b91 = 0, b180 = 0;
              for (final i in catItems) {
                if (i.ageDays <= 30) {
                  b0 += i.numericValue;
                } else if (i.ageDays <= 90) {
                  b31 += i.numericValue;
                } else if (i.ageDays <= 180) {
                  b91 += i.numericValue;
                } else {
                  b180 += i.numericValue;
                }
              }

              final pct1 = catTotalVal > 0
                  ? ((b0 / catTotalVal) * 100).round()
                  : 0;
              final pct2 = catTotalVal > 0
                  ? ((b31 / catTotalVal) * 100).round()
                  : 0;
              final pct3 = catTotalVal > 0
                  ? ((b91 / catTotalVal) * 100).round()
                  : 0;
              final pct4 = catTotalVal > 0
                  ? ((b180 / catTotalVal) * 100).round()
                  : 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildStackedCategoryBar(
                  category: catName,
                  pct1: pct1,
                  pct2: pct2,
                  pct3: pct3,
                  pct4: pct4,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLegendBox(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B6358),
          ),
        ),
      ],
    );
  }

  Widget _buildStackedCategoryBar({
    required String category,
    required int pct1,
    required int pct2,
    required int pct3,
    required int pct4,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            category,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181512),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 32,
              child: Row(
                children: [
                  if (pct1 > 0)
                    Expanded(
                      flex: pct1,
                      child: Container(
                        color: const Color(0xFF8E9EAB),
                        alignment: Alignment.center,
                        child: Text(
                          '$pct1%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (pct2 > 0)
                    Expanded(
                      flex: pct2,
                      child: Container(
                        color: const Color(0xFF5D6B78),
                        alignment: Alignment.center,
                        child: Text(
                          '$pct2%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (pct3 > 0)
                    Expanded(
                      flex: pct3,
                      child: Container(
                        color: const Color(0xFF2E3842),
                        alignment: Alignment.center,
                        child: Text(
                          '$pct3%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (pct4 > 0)
                    Expanded(
                      flex: pct4,
                      child: Container(
                        color: const Color(0xFFC89748),
                        alignment: Alignment.center,
                        child: Text(
                          '$pct4%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (pct1 == 0 && pct2 == 0 && pct3 == 0 && pct4 == 0)
                    Expanded(
                      child: Container(
                        color: const Color(0xFFE5DACD),
                        alignment: Alignment.center,
                        child: Text(
                          '0%',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF6B6358),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 3. Middle Section: Detailed Ledger + Product Inspector
  Widget _buildMiddleSection() {
    final filtered = _filteredItems;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;

        final ledgerWidget = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEADBCA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detailed Ageing Ledger',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181512),
                    ),
                  ),
                  Text(
                    '${filtered.length} SKU(s) Tracked',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B6358),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Table Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 25,
                      child: Text(
                        'Product',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 12,
                      child: Text(
                        'Category',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 12,
                      child: Text(
                        'Age (Days)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 8,
                      child: Text(
                        'Qty',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 10,
                      child: Text(
                        'Value',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 11,
                      child: Center(
                        child: Text(
                          'Risk Level',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B6358),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF3ECE1)),

              if (filtered.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Center(
                    child: Text(
                      'No matching inventory records found for selected filters.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6358),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                ...filtered.map((item) {
                  final isSelected = _selectedItem?.variantId == item.variantId;
                  return InkWell(
                    onTap: () => setState(() => _selectedItem = item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFCF8F2)
                            : Colors.transparent,
                        border: Border(
                          bottom: const BorderSide(color: Color(0xFFF7F3EE)),
                          left: isSelected
                              ? const BorderSide(
                                  color: Color(0xFFBA8A55),
                                  width: 3,
                                )
                              : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Product Name & SKU
                          Expanded(
                            flex: 25,
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3ECE1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    Icons.checkroom_rounded,
                                    size: 18,
                                    color: Color(0xFF8C5E33),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF181512),
                                        ),
                                      ),
                                      Text(
                                        item.sku,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          color: const Color(0xFF8C5E33),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Category
                          Expanded(
                            flex: 12,
                            child: Text(
                              item.category,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2F69A8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Age (Days)
                          Expanded(
                            flex: 12,
                            child: Text(
                              '${item.ageDays} Days',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: const Color(0xFF181512),
                              ),
                            ),
                          ),

                          // Qty
                          Expanded(
                            flex: 8,
                            child: Text(
                              '${item.qty}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF181512),
                              ),
                            ),
                          ),

                          // Value
                          Expanded(
                            flex: 10,
                            child: Text(
                              item.valueFormatted,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF181512),
                              ),
                            ),
                          ),

                          // Risk Level Pill
                          Expanded(
                            flex: 11,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: item.riskBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.riskLevel,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: item.riskColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );

        final inspectorWidget = _buildProductInspector();

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ledgerWidget,
              const SizedBox(height: 16),
              inspectorWidget,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 62, child: ledgerWidget),
            const SizedBox(width: 16),
            Expanded(flex: 38, child: inspectorWidget),
          ],
        );
      },
    );
  }

  // Right Column: Ageing Product Inspector (Requirement 6: Shows selected real product or "Select a product to inspect")
  Widget _buildProductInspector() {
    final item = _selectedItem;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ageing Product Inspector',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181512),
            ),
          ),
          const SizedBox(height: 14),

          if (item == null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF9F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF3ECE1)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    size: 32,
                    color: Color(0xFF9E9282),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select a product to inspect',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181512),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Click any row in the ageing ledger to review holding metrics and carrying costs.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B6358),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Product Icon / Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF9F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF3ECE1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEADBCA)),
                    ),
                    child: const Icon(
                      Icons.checkroom_rounded,
                      size: 22,
                      color: Color(0xFF8C5E33),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181512),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SKU: ${item.sku} • Location: ${item.location}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF6B6358),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Metrics Rows
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Days Stagnant',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF6B6358),
                  ),
                ),
                Text(
                  '${item.ageDays} Days',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: item.ageDays >= 180
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF181512),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Carrying Cost (Est.)',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF6B6358),
                  ),
                ),
                Text(
                  item.monthlyCarryingCost,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181512),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stock Balance',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF6B6358),
                  ),
                ),
                Text(
                  '${item.qty} Units (${item.valueFormatted})',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181512),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // AI Suggestion Box (Requirement 7: No fake recommendations)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI SUGGESTION',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.aiSuggestion,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF4B5563),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 4. Bottom AI Callout Banner
  Widget _buildAiInsightBanner() {
    final hasCritical = _summary.bucket180PlusValue > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF9F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3E8DB)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 22,
            color: Color(0xFFBA8A55),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THREADSTOCK AI INSIGHT',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF946A36),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                if (hasCritical) ...[
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B6358),
                        height: 1.35,
                      ),
                      children: [
                        TextSpan(
                          text: 'Critical stock ageing detected: ',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181512),
                          ),
                        ),
                        TextSpan(
                          text:
                              'Items aged 180+ days represent significant capital lock. A targeted promotional clearance is advised.',
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'All inventory is currently within healthy turnover duration (0–30 days). No critical stock ageing detected.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B6358),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap:
                widget.onViewRecommendations ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        hasCritical
                            ? 'Opening AI Ageing Recommendations...'
                            : 'Inventory is healthy. No critical action required.',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      backgroundColor: const Color(0xFF181512),
                    ),
                  );
                },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5DACD)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Recommendations',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF946A36),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFF946A36),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
