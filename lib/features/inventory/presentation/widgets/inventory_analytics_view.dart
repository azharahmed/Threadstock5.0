// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/responsive_values.dart';

class InventoryAnalyticsView extends StatefulWidget {
  final VoidCallback? onSwitchToStockList;
  final VoidCallback? onTriggerTransfer;
  final VoidCallback? onPlanMarkdown;
  final VoidCallback? onInvestigate;

  const InventoryAnalyticsView({
    super.key,
    this.onSwitchToStockList,
    this.onTriggerTransfer,
    this.onPlanMarkdown,
    this.onInvestigate,
  });

  @override
  State<InventoryAnalyticsView> createState() => _InventoryAnalyticsViewState();
}

class _InventoryAnalyticsViewState extends State<InventoryAnalyticsView> {
  String _selectedSeason = 'All Active Seasons';
  String _selectedCategory = 'All Categories';

  final List<String> _seasons = const [
    'All Active Seasons',
    'Spring 27',
    'Summer 27',
    'Autumn 27',
    'Winter 27',
  ];

  final List<String> _categories = const [
    'All Categories',
    'Shirts',
    'Knitwear',
    'Blazers',
    'Trousers',
    'Dresses',
  ];

  void _showAuditLogDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(
              Icons.history_edu_rounded,
              size: 20,
              color: Color(0xFF8C5E33),
            ),
            const SizedBox(width: 10),
            Text(
              'Inventory Audit Log',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181512),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recent physical stock count audits and adjustments across Primary Facility (Zone A):',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B6358),
                ),
              ),
              const SizedBox(height: 14),
              _buildAuditRow(
                'Today, 11:20 AM',
                'Physical Count verified for inventory lines',
                '+12 units adjusted',
              ),
              _buildAuditRow(
                'Yesterday, 04:45 PM',
                'Cycle Count: Verified stock',
                'Zero variance',
              ),
              _buildAuditRow(
                '16 Sep, 02:15 PM',
                'Transfer dispatch #TR-8829 to Regional Store',
                '-40 units dispatched',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8C5E33),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String date, String desc, String delta) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181512),
                  ),
                ),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF3ECE1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              delta,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF8C5E33),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRecommendationsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: Color(0xFFBA8A55),
            ),
            const SizedBox(width: 10),
            Text(
              'AI Stock Recommendations',
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
                'AI Optimization Plan for Primary Facility (Zone A):',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181512),
                ),
              ),
              const SizedBox(height: 12),
              _buildRecItem(
                '1. Inter-store Balancing',
                'Transfer 12% of seasonal surplus stock (48 units) to Regional Store to capture unmet regional peak demand.',
              ),
              _buildRecItem(
                '2. Markdown Campaign',
                'Initiate promotional markdown on slow-moving inventory to optimize carrying costs.',
              ),
              _buildRecItem(
                '3. Replenishment Alert',
                'Issue an expedited purchase order for low-stock SKUs before retail stock depletion in 48 hours.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Dismiss',
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
                    'AI recommendations queued for manager approval.',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  backgroundColor: const Color(0xFF181512),
                  duration: const Duration(seconds: 2),
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
              'Apply Plan',
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveHorizontalMargin,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Filter and Action Bar
          _buildFilterBar(),
          const SizedBox(height: 16),

          // 2. Metrics Row (Overall Health Donut + 4 KPI Cards)
          _buildMetricsSection(),
          const SizedBox(height: 16),

          // 3. Middle Section: Seasonality Matrix + Active Inventory Alerts
          _buildMiddleSection(),
          const SizedBox(height: 16),

          // 4. Bottom AI Insight Callout Banner
          _buildAiInsightBanner(),
        ],
      ),
    );
  }

  // 1. Filter & Action Bar
  Widget _buildFilterBar() {
    return Row(
      children: [
        // Seasons Dropdown
        PopupMenuButton<String>(
          tooltip: 'Select Season',
          offset: const Offset(0, 40),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE5DACD)),
          ),
          onSelected: (val) => setState(() => _selectedSeason = val),
          itemBuilder: (context) => _seasons.map((season) {
            return PopupMenuItem<String>(
              value: season,
              height: 36,
              child: Text(
                season,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: season == _selectedSeason
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: season == _selectedSeason
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
                  _selectedSeason,
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
        const SizedBox(width: 10),

        // Categories Dropdown
        PopupMenuButton<String>(
          tooltip: 'Select Category',
          offset: const Offset(0, 40),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE5DACD)),
          ),
          onSelected: (val) => setState(() => _selectedCategory = val),
          itemBuilder: (context) => _categories.map((cat) {
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

        const Spacer(),

        // Audit Log Button
        InkWell(
          onTap: _showAuditLogDialog,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5DACD)),
            ),
            child: Text(
              'Audit Log',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181512),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Stock Count Button
        InkWell(
          onTap: () {
            if (widget.onSwitchToStockList != null) {
              widget.onSwitchToStockList!();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Opening Stock Count & Inventory Ledger...',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  backgroundColor: const Color(0xFF181512),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF181512),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Stock Count',
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

  // 2. Metrics Section: Overall Health Hero + 4 KPI Cards
  Widget _buildMetricsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero Left Card: Overall Inventory Health (~38% flex)
        Expanded(flex: 38, child: _buildOverallHealthCard()),
        const SizedBox(width: 16),

        // 4 KPI Cards Grid (~62% flex)
        Expanded(
          flex: 62,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Total Active SKUs',
                      value: '4,247',
                      growth: '↑ 12%',
                      subtitleLeft: '2,842 styles listed',
                      subtitleRight: 'vs last month',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      icon: Icons.toll_outlined,
                      title: 'Stock Value',
                      value: '₹2.8Cr',
                      growth: '↑ 8%',
                      subtitleLeft: 'Cost basis valuation',
                      subtitleRight: 'vs last month',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      icon: Icons.sync_rounded,
                      title: 'Turnover Rate',
                      value: '4.2x',
                      growth: '↑ 0.6x',
                      subtitleLeft: 'Optimal target: 5.0x',
                      subtitleRight: 'vs last month',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard(
                      icon: Icons.percent_rounded,
                      title: 'Average Fill Rate',
                      value: '94%',
                      growth: '↑ 2%',
                      subtitleLeft: '98% on core basics',
                      subtitleRight: 'vs last month',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverallHealthCard() {
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
            'Overall Inventory Health',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181512),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Measures stock availability, aging, and risk across all categories.',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B6358),
            ),
          ),
          const SizedBox(height: 18),

          // Donut Progress Indicator
          Center(
            child: SizedBox(
              width: 136,
              height: 136,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 136,
                    height: 136,
                    child: CircularProgressIndicator(
                      value: 0.86,
                      strokeWidth: 12,
                      backgroundColor: const Color(0xFFF0EDE8),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFC89748),
                      ),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '86%',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181512),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'EXCELLENT',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF16A34A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Growth Badge Center
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_upward_rounded,
                    size: 12,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '6% vs last month',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Aging Warning Bottom Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF6B6358),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only 4% of total valuation falls into critical aging bucket (180+ days).',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B6358),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String title,
    required String value,
    required String growth,
    required String subtitleLeft,
    required String subtitleRight,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF5EE),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: const Color(0xFF8C5E33)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6358),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181512),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  growth,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                subtitleLeft,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6358),
                ),
              ),
              Text(
                subtitleRight,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Middle Section: Seasonality Stock Distribution Matrix + Active Inventory Alerts
  Widget _buildMiddleSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Table: Seasonality Stock Distribution Matrix (~60% flex)
        Expanded(flex: 60, child: _buildSeasonalityMatrixCard()),
        const SizedBox(width: 16),

        // Right Column: Active Inventory Alerts (~40% flex)
        Expanded(flex: 40, child: _buildActiveAlertsCard()),
      ],
    );
  }

  Widget _buildSeasonalityMatrixCard() {
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
            'Seasonality Stock Distribution Matrix',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181512),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Stock health by category and season.',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B6358),
            ),
          ),
          const SizedBox(height: 18),

          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 12,
                  child: Text(
                    'Category',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B6358),
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: Text(
                      'Spring 27',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B6358),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: Text(
                      'Summer 27',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B6358),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: Text(
                      'Autumn 27',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B6358),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: Text(
                      'Winter 27',
                      style: GoogleFonts.inter(
                        fontSize: 12,
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

          // 5 Rows
          _buildMatrixRow(
            category: 'Shirts',
            springStatus: _StockStatus.optimal,
            summerStatus: _StockStatus.optimal,
            autumnStatus: _StockStatus.highStock,
            winterStatus: _StockStatus.healthy,
          ),
          _buildMatrixRow(
            category: 'Knitwear',
            springStatus: _StockStatus.lowStock,
            summerStatus: _StockStatus.healthy,
            autumnStatus: _StockStatus.optimal,
            winterStatus: _StockStatus.optimal,
          ),
          _buildMatrixRow(
            category: 'Blazers',
            springStatus: _StockStatus.healthy,
            summerStatus: _StockStatus.healthy,
            autumnStatus: _StockStatus.lowStock,
            winterStatus: _StockStatus.lowStock,
          ),
          _buildMatrixRow(
            category: 'Trousers',
            springStatus: _StockStatus.optimal,
            summerStatus: _StockStatus.optimal,
            autumnStatus: _StockStatus.optimal,
            winterStatus: _StockStatus.optimal,
          ),
          _buildMatrixRow(
            category: 'Dresses',
            springStatus: _StockStatus.stockout,
            summerStatus: _StockStatus.lowStock,
            autumnStatus: _StockStatus.healthy,
            winterStatus: _StockStatus.healthy,
            isLast: true,
          ),

          const SizedBox(height: 18),

          // Status Legend
          Row(
            children: [
              _buildLegendItem(const Color(0xFF10B981), 'Optimal'),
              const SizedBox(width: 14),
              _buildLegendItem(const Color(0xFF86EFAC), 'Healthy'),
              const SizedBox(width: 14),
              _buildLegendItem(const Color(0xFFF59E0B), 'High Stock'),
              const SizedBox(width: 14),
              _buildLegendItem(const Color(0xFFF87171), 'Low Stock'),
              const SizedBox(width: 14),
              _buildLegendItem(const Color(0xFFDC2626), 'Stockout'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatrixRow({
    required String category,
    required _StockStatus springStatus,
    required _StockStatus summerStatus,
    required _StockStatus autumnStatus,
    required _StockStatus winterStatus,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF8F5F0))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 12,
            child: Text(
              category,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181512),
              ),
            ),
          ),
          Expanded(
            flex: 10,
            child: Center(child: _buildStatusPill(springStatus)),
          ),
          Expanded(
            flex: 10,
            child: Center(child: _buildStatusPill(summerStatus)),
          ),
          Expanded(
            flex: 10,
            child: Center(child: _buildStatusPill(autumnStatus)),
          ),
          Expanded(
            flex: 10,
            child: Center(child: _buildStatusPill(winterStatus)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(_StockStatus status) {
    Color bg;
    Color textColor;
    String label;

    switch (status) {
      case _StockStatus.optimal:
        bg = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
        label = 'Optimal';
        break;
      case _StockStatus.healthy:
        bg = const Color(0xFFE6F4EA);
        textColor = const Color(0xFF137333);
        label = 'Healthy';
        break;
      case _StockStatus.highStock:
        bg = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFB45309);
        label = 'High Stock';
        break;
      case _StockStatus.lowStock:
        bg = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        label = 'Low Stock';
        break;
      case _StockStatus.stockout:
        bg = const Color(0xFFFCE8E6);
        textColor = const Color(0xFFC5221F);
        label = 'Stockout';
        break;
    }

    return Container(
      width: 78,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color dotColor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B6358),
          ),
        ),
      ],
    );
  }

  // Active Inventory Alerts Card
  Widget _buildActiveAlertsCard() {
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
            children: [
              Text(
                'Active Inventory Alerts',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181512),
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Viewing all 14 inventory alerts across all zones.',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      backgroundColor: const Color(0xFF181512),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF946A36),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF946A36),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Alert 1: Stockout Risk
          _buildAlertItem(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFDC2626),
            title: 'STOCKOUT RISK',
            titleColor: const Color(0xFFDC2626),
            priorityLabel: 'High Priority',
            priorityBg: const Color(0xFFFEE2E2),
            priorityColor: const Color(0xFFDC2626),
            description:
                'Key apparel inventory is running critically low in retail node (3 units left).',
            actionText: 'Trigger Transfer →',
            onAction:
                widget.onTriggerTransfer ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Initiating urgent stock transfer #TR-9041 for replenishment to retail branch.',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      backgroundColor: const Color(0xFF181512),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
          ),
          const SizedBox(height: 10),

          // Alert 2: Overstock Warning
          _buildAlertItem(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFD97706),
            title: 'OVERSTOCK WARNING',
            titleColor: const Color(0xFFB45309),
            priorityLabel: 'Medium',
            priorityBg: const Color(0xFFFEF3C7),
            priorityColor: const Color(0xFFB45309),
            description:
                'Overstocked variants have stayed stagnant for 45 days.',
            actionText: 'Plan Markdown →',
            onAction:
                widget.onPlanMarkdown ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Opening Markdown Planning tool for slow-moving inventory.',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      backgroundColor: const Color(0xFF181512),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
          ),
          const SizedBox(height: 10),

          // Alert 3: Slow-Mover Detected
          _buildAlertItem(
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF475569),
            title: 'SLOW-MOVER DETECTED',
            titleColor: const Color(0xFF334155),
            priorityLabel: 'Low',
            priorityBg: const Color(0xFFF1F5F9),
            priorityColor: const Color(0xFF64748B),
            description:
                'Linen Blazer — Cream has a low turnover index of 0.8x this season.',
            actionText: 'Investigate →',
            onAction:
                widget.onInvestigate ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Opening SKU Diagnostics for Linen Blazer — Cream...',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      backgroundColor: const Color(0xFF181512),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Color titleColor,
    required String priorityLabel,
    required Color priorityBg,
    required Color priorityColor,
    required String description,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF9F6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3ECE1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priorityLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF4B5563),
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: onAction,
                  child: Text(
                    actionText,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181512),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Alert options',
                  offset: const Offset(0, 30),
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Color(0xFFE5DACD)),
                  ),
                  onSelected: (val) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$val alert: $title',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                        backgroundColor: const Color(0xFF181512),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'Acknowledge',
                      height: 32,
                      child: Text(
                        'Acknowledge',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'Snooze 24h',
                      height: 32,
                      child: Text(
                        'Snooze 24h',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'Assign to Team',
                      height: 32,
                      child: Text(
                        'Assign to Team',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                    ),
                  ],
                  child: const Icon(
                    Icons.more_vert_rounded,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Bottom AI Insight Callout Banner
  Widget _buildAiInsightBanner() {
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
            Icons.auto_awesome_outlined,
            size: 22,
            color: Color(0xFFBA8A55),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insight',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181512),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Rebalancing inventory across active locations and running a targeted promotion on slow-moving items could reduce excess stock by 18%.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6358),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: _showRecommendationsDialog,
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

  Widget _buildRecItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
            desc,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B6358),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

enum _StockStatus { optimal, healthy, highStock, lowStock, stockout }
