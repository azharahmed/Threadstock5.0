// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SalesAnalyticsView extends StatefulWidget {
  final VoidCallback? onNavigateToOverview;
  final VoidCallback? onNavigateToNewSale;
  final ValueChanged<String>? onNavigateToSaleDetail;

  const SalesAnalyticsView({
    super.key,
    this.onNavigateToOverview,
    this.onNavigateToNewSale,
    this.onNavigateToSaleDetail,
  });

  @override
  State<SalesAnalyticsView> createState() => _SalesAnalyticsViewState();
}

class _SalesAnalyticsViewState extends State<SalesAnalyticsView> {
  String _selectedDateRange = 'Last 30 Days: Oct 1 - Oct 31';
  String _selectedCategory = 'All Categories';
  String _selectedTrendFrequency = 'Daily';

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFFBA8A55), size: 18),
            const SizedBox(width: 10),
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showScheduleReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF6EE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.schedule_rounded,
                            color: Color(0xFFC89748), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Schedule Sales Report',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181512),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF7E766B), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Configure automated email delivery of your sales performance summary.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6E665A),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEADBCA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Frequency',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181512),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Weekly on Monday at 9:00 AM IST • All India Operations',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF4A443B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4A443B),
                      side: const BorderSide(color: Color(0xFFDCCFBD)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showFeedback(
                          'Automated report scheduled successfully for All India Operations.');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF181512),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text('Confirm Schedule',
                        style: GoogleFonts.inter(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Action Filter Bar (Date Selector + Category Selector + Export CSV + Schedule Report)
        _buildActionFilterBar(),
        const SizedBox(height: 20),

        // 2. Hero Card: Total Sales Revenue with 30-Day Trend Sparkline
        _buildHeroRevenueCard(),
        const SizedBox(height: 18),

        // 3. 4 KPI Metric Cards (Transactions, Average Order, Units Sold, Returns)
        _buildKpiMetricsRow(),
        const SizedBox(height: 18),

        // 4. Middle Section: Revenue Trend Analysis Chart
        _buildRevenueTrendAnalysisCard(),
        const SizedBox(height: 18),

        // 5. Bottom Section: Top Products by Revenue & Sales by Category Share
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1020;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 58,
                    child: _buildTopProductsCard(),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    flex: 42,
                    child: _buildCategoryShareCard(),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _buildTopProductsCard(),
                const SizedBox(height: 18),
                _buildCategoryShareCard(),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ===========================================================================
  // 1. Action Filter Bar
  // ===========================================================================
  Widget _buildActionFilterBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Filters
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            // Date Filter Pill
            PopupMenuButton<String>(
              tooltip: 'Time Range',
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFEADBCA)),
              ),
              color: Colors.white,
              onSelected: (val) {
                setState(() => _selectedDateRange = val);
                _showFeedback('Filtered to $val');
              },
              itemBuilder: (context) => [
                _buildFilterMenuItem('Last 7 Days: Oct 25 - Oct 31'),
                _buildFilterMenuItem('Last 30 Days: Oct 1 - Oct 31'),
                _buildFilterMenuItem('Last 90 Days: Aug 1 - Oct 31'),
                _buildFilterMenuItem('Year to Date: Jan 1 - Oct 31'),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8DFD3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 15, color: Color(0xFF4A443B)),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDateRange,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2A2520),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: Color(0xFF7A7267)),
                  ],
                ),
              ),
            ),

            // Category Filter Pill
            PopupMenuButton<String>(
              tooltip: 'Category Filter',
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFEADBCA)),
              ),
              color: Colors.white,
              onSelected: (val) {
                setState(() => _selectedCategory = val);
                _showFeedback('Filtered to $val');
              },
              itemBuilder: (context) => [
                _buildFilterMenuItem('All Categories'),
                _buildFilterMenuItem('Shirts'),
                _buildFilterMenuItem('Knitwear'),
                _buildFilterMenuItem('Blazers'),
                _buildFilterMenuItem('Trousers'),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE8DFD3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer_outlined,
                        size: 15, color: Color(0xFF4A443B)),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategory,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2A2520),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: Color(0xFF7A7267)),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Right Actions (Export CSV + Schedule Report)
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            // Export CSV Button
            OutlinedButton(
              onPressed: () {
                _showFeedback('Exporting sales dataset (CSV)...');
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2A2520),
                side: const BorderSide(color: Color(0xFFE5DACD)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.file_download_outlined,
                      size: 16, color: Color(0xFF4A443B)),
                  const SizedBox(width: 6),
                  Text(
                    'Export CSV',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2A2520),
                    ),
                  ),
                ],
              ),
            ),

            // Schedule Report Button
            ElevatedButton(
              onPressed: _showScheduleReportDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181512),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Schedule Report',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String value) {
    return PopupMenuItem<String>(
      value: value,
      height: 38,
      child: Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF1E1C1A),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. Hero Card: Total Sales Revenue with 30-Day Trend Sparkline
  // ===========================================================================
  Widget _buildHeroRevenueCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Coins Icon in Rounded Square
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF6EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF2E6D5)),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.monetization_on_outlined,
              size: 28,
              color: Color(0xFFBA8A55),
            ),
          ),
          const SizedBox(width: 18),

          // Total Sales Revenue Info
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Total Sales Revenue',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7E766B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹12,48,200',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF181512),
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF8F2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_upward_rounded,
                              size: 12, color: Color(0xFF16A34A)),
                          const SizedBox(width: 3),
                          Text(
                            '14.2%',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'vs ₹10,92,800 in previous period',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7E766B),
                  ),
                ),
              ],
            ),
          ),

          // Right Sparkline (30-DAY TREND)
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '30-DAY TREND',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: const Color(0xFF9E958A),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _RevenueSparklinePainter(
                      color: const Color(0xFFC89748),
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

  // ===========================================================================
  // 3. 4 KPI Metric Cards
  // ===========================================================================
  Widget _buildKpiMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1050;
        final isMedium = constraints.maxWidth >= 640;

        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.description_outlined,
                  label: 'Transactions',
                  value: '847',
                  deltaText: '8.2% vs prev',
                  isPositiveDelta: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Average Order',
                  value: '₹1,464',
                  deltaText: '5.3% vs prev',
                  isPositiveDelta: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Units Sold',
                  value: '2,341',
                  deltaText: '9.1% vs prev',
                  isPositiveDelta: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildKpiCard(
                  icon: Icons.replay_rounded,
                  label: 'Returns',
                  value: '₹84,200',
                  deltaText: '6.7% rate',
                  isPositiveDelta: false,
                ),
              ),
            ],
          );
        }

        if (isMedium) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      icon: Icons.description_outlined,
                      label: 'Transactions',
                      value: '847',
                      deltaText: '8.2% vs prev',
                      isPositiveDelta: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildKpiCard(
                      icon: Icons.shopping_cart_outlined,
                      label: 'Average Order',
                      value: '₹1,464',
                      deltaText: '5.3% vs prev',
                      isPositiveDelta: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Units Sold',
                      value: '2,341',
                      deltaText: '9.1% vs prev',
                      isPositiveDelta: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildKpiCard(
                      icon: Icons.replay_rounded,
                      label: 'Returns',
                      value: '₹84,200',
                      deltaText: '6.7% rate',
                      isPositiveDelta: false,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildKpiCard(
              icon: Icons.description_outlined,
              label: 'Transactions',
              value: '847',
              deltaText: '8.2% vs prev',
              isPositiveDelta: true,
            ),
            const SizedBox(height: 14),
            _buildKpiCard(
              icon: Icons.shopping_cart_outlined,
              label: 'Average Order',
              value: '₹1,464',
              deltaText: '5.3% vs prev',
              isPositiveDelta: true,
            ),
            const SizedBox(height: 14),
            _buildKpiCard(
              icon: Icons.inventory_2_outlined,
              label: 'Units Sold',
              value: '2,341',
              deltaText: '9.1% vs prev',
              isPositiveDelta: true,
            ),
            const SizedBox(height: 14),
            _buildKpiCard(
              icon: Icons.replay_rounded,
              label: 'Returns',
              value: '₹84,200',
              deltaText: '6.7% rate',
              isPositiveDelta: false,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required String deltaText,
    required bool isPositiveDelta,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF6EE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF2E6D5)),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: const Color(0xFFBA8A55)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7E766B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF181512),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isPositiveDelta
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_upward_rounded, // in screenshot, returns has red arrow up
                      size: 12,
                      color: isPositiveDelta
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      deltaText,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isPositiveDelta
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
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

  // ===========================================================================
  // 4. Middle Section: Revenue Trend Analysis Chart
  // ===========================================================================
  Widget _buildRevenueTrendAnalysisCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row (Title + Legend + Daily Dropdown)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Trend Analysis',
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181512),
                ),
              ),
              Row(
                children: [
                  // Legend 1: Actual Revenue
                  Row(
                    children: [
                      Container(
                        width: 14,
                        height: 2.5,
                        color: const Color(0xFFC89748),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Actual Revenue',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF4A443B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),

                  // Legend 2: Comparison Period
                  Row(
                    children: [
                      CustomPaint(
                        size: const Size(14, 2),
                        painter: _DashedLinePainter(
                          color: const Color(0xFFB5ABA0),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Comparison Period',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 18),

                  // Frequency Selector
                  PopupMenuButton<String>(
                    tooltip: 'Frequency',
                    offset: const Offset(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFEADBCA)),
                    ),
                    color: Colors.white,
                    onSelected: (val) {
                      setState(() => _selectedTrendFrequency = val);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                          value: 'Daily',
                          child: Text('Daily',
                              style: GoogleFonts.inter(fontSize: 13))),
                      PopupMenuItem(
                          value: 'Weekly',
                          child: Text('Weekly',
                              style: GoogleFonts.inter(fontSize: 13))),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE5DACD)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedTrendFrequency,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF2A2520),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded,
                              size: 15, color: Color(0xFF7A7267)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart canvas
          SizedBox(
            height: 185,
            child: _RevenueDualTrendLineChart(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. Bottom Section: Top Products & Sales by Category Share
  // ===========================================================================

  // Left Card: Top Products by Revenue
  Widget _buildTopProductsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Products by Revenue',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181512),
                ),
              ),
              InkWell(
                onTap: () {
                  _showFeedback('Viewing complete product sales breakdown...');
                },
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8C5E33),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded,
                        size: 13, color: Color(0xFF8C5E33)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Subheader row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8C8478),
                ),
              ),
              Text(
                'Revenue',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8C8478),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 Product Rows
          _buildProductRevenueRow(
            name: 'Oxford Linen Shirt',
            revenue: '₹4.2L',
            barFraction: 0.82,
            imageAsset: 'Assets/oxford_linen_shirt_blue.jpg',
          ),
          const SizedBox(height: 14),

          _buildProductRevenueRow(
            name: 'Merino Wool Blazer',
            revenue: '₹3.1L',
            barFraction: 0.60,
            imageAsset: 'Assets/merino_wool_blazer.jpg',
          ),
          const SizedBox(height: 14),

          _buildProductRevenueRow(
            name: 'Cashmere Sweater',
            revenue: '₹2.4L',
            barFraction: 0.45,
            imageAsset: 'Assets/cashmere_sweater.jpg',
          ),
          const SizedBox(height: 14),

          _buildProductRevenueRow(
            name: 'Raw Denim Jeans',
            revenue: '₹1.8L',
            barFraction: 0.32,
            imageAsset: 'Assets/raw_denim_jeans.jpg',
          ),
        ],
      ),
    );
  }

  Widget _buildProductRevenueRow({
    required String name,
    required String revenue,
    required double barFraction,
    required String imageAsset,
  }) {
    return Row(
      children: [
        // Thumbnail Image
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF7EFE4),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFEADBCA)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            imageAsset,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.checkroom_rounded,
                    size: 20, color: Color(0xFF9E8462)),
          ),
        ),
        const SizedBox(width: 14),

        // Product Name
        SizedBox(
          width: 150,
          child: Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181512),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 14),

        // Progress Bar
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 8,
                    width: constraints.maxWidth,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4ECE2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    height: 8,
                    width: constraints.maxWidth * barFraction,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC89748),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: 16),

        // Revenue Value
        SizedBox(
          width: 60,
          child: Text(
            revenue,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181512),
            ),
          ),
        ),
      ],
    );
  }

  // Right Card: Sales by Category Share
  Widget _buildCategoryShareCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales by Category Share',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181512),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              // Donut Chart with center value
              SizedBox(
                width: 146,
                height: 146,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(146, 146),
                      painter: _CategoryShareDonutPainter(),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '₹12.5L',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF181512),
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          'Total Sales',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF7E766B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Legend items on right
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Shirts', '40%', const Color(0xFFC89748)),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                        'Knitwear', '25%', const Color(0xFF2F69A8)),
                    const SizedBox(height: 12),
                    _buildLegendItem('Blazers', '20%', const Color(0xFF525B62)),
                    const SizedBox(height: 12),
                    _buildLegendItem(
                        'Trousers', '15%', const Color(0xFFA8AFB5)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String category, String percentage, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              category,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4A443B),
              ),
            ),
          ],
        ),
        Text(
          percentage,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181512),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// Custom Painters: Sparkline, Dual Line Chart, Donut & Dashed Line
// ===========================================================================

// 1. Hero Sparkline Painter
class _RevenueSparklinePainter extends CustomPainter {
  final Color color;
  _RevenueSparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Relative points matching upward wave curve in screenshot
    final points = [
      Offset(0, size.height * 0.85),
      Offset(size.width * 0.15, size.height * 0.72),
      Offset(size.width * 0.30, size.height * 0.78),
      Offset(size.width * 0.45, size.height * 0.58),
      Offset(size.width * 0.60, size.height * 0.50),
      Offset(size.width * 0.75, size.height * 0.32),
      Offset(size.width * 0.90, size.height * 0.16),
      Offset(size.width, size.height * 0.08),
    ];

    final path = Path();
    final areaPath = Path();

    path.moveTo(points[0].dx, points[0].dy);
    areaPath.moveTo(points[0].dx, size.height);
    areaPath.lineTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
          controlPoint2.dy, p1.dx, p1.dy);
      areaPath.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx,
          controlPoint2.dy, p1.dx, p1.dy);
    }

    areaPath.lineTo(size.width, size.height);
    areaPath.close();

    // Area Fill
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.24),
          color.withOpacity(0.01),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(areaPath, areaPaint);

    // Stroke
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 2. Dashed Line Painter for Legend
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(0, 1), const Offset(4, 1), paint);
    canvas.drawLine(const Offset(6, 1), const Offset(10, 1), paint);
    canvas.drawLine(const Offset(12, 1), const Offset(14, 1), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 3. Revenue Dual Trend Line Chart (Solid Actual vs Dashed Comparison)
class _RevenueDualTrendLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;
        const leftPadding = 42.0;
        const bottomPadding = 24.0;

        final chartWidth = totalWidth - leftPadding;
        final chartHeight = totalHeight - bottomPadding;

        return Stack(
          children: [
            // Horizontal grid lines & Y-axis labels
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: bottomPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGridRow('₹20L', leftPadding),
                  _buildGridRow('₹15L', leftPadding),
                  _buildGridRow('₹10L', leftPadding),
                  _buildGridRow('₹5L', leftPadding),
                  _buildGridRow('0', leftPadding),
                ],
              ),
            ),

            // Lines painter
            Positioned(
              left: leftPadding,
              top: 0,
              width: chartWidth,
              height: chartHeight,
              child: CustomPaint(
                painter: _DualTrendLinePainter(),
              ),
            ),

            // X-Axis Date Labels
            Positioned(
              left: leftPadding,
              bottom: 0,
              width: chartWidth,
              height: bottomPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildXLabel('Oct 1'),
                  _buildXLabel('Oct 5'),
                  _buildXLabel('Oct 10'),
                  _buildXLabel('Oct 15'),
                  _buildXLabel('Oct 20'),
                  _buildXLabel('Oct 25'),
                  _buildXLabel('Oct 30'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGridRow(String label, double leftPadding) {
    return Row(
      children: [
        SizedBox(
          width: leftPadding - 10,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: const Color(0xFF9E958A),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFF2ECE4),
          ),
        ),
      ],
    );
  }

  Widget _buildXLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10.5,
        color: const Color(0xFF9E958A),
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _DualTrendLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 0 to 20L scale
    // Actual Revenue Points (Oct 1: ~4L, Oct 5: ~5L, Oct 10: ~9L, Oct 15: ~12.5L, Oct 20: ~11.5L, Oct 25: ~15.5L, Oct 30: ~17.5L)
    final actualPoints = [
      Offset(0, getY(4.0, size.height)),
      Offset(size.width * 0.166, getY(4.8, size.height)),
      Offset(size.width * 0.333, getY(9.0, size.height)),
      Offset(size.width * 0.500, getY(12.5, size.height)),
      Offset(size.width * 0.666, getY(11.5, size.height)),
      Offset(size.width * 0.833, getY(15.5, size.height)),
      Offset(size.width, getY(17.5, size.height)),
    ];

    // Comparison Period Points (gentle dashed curve from 3.5L to ~15.0L)
    final compPoints = [
      Offset(0, getY(3.5, size.height)),
      Offset(size.width * 0.166, getY(5.0, size.height)),
      Offset(size.width * 0.333, getY(7.2, size.height)),
      Offset(size.width * 0.500, getY(9.8, size.height)),
      Offset(size.width * 0.666, getY(11.8, size.height)),
      Offset(size.width * 0.833, getY(13.6, size.height)),
      Offset(size.width, getY(15.0, size.height)),
    ];

    // 1. Draw Comparison Period Dashed Line
    final compPaint = Paint()
      ..color = const Color(0xFFB5ABA0)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    _drawDashedPath(canvas, compPoints, compPaint);

    // 2. Draw Actual Revenue Line
    final actualLinePaint = Paint()
      ..color = const Color(0xFFC89748)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotFillPaint = Paint()
      ..color = const Color(0xFFC89748)
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final actualPath = Path();
    actualPath.moveTo(actualPoints[0].dx, actualPoints[0].dy);
    for (int i = 1; i < actualPoints.length; i++) {
      actualPath.lineTo(actualPoints[i].dx, actualPoints[i].dy);
    }
    canvas.drawPath(actualPath, actualLinePaint);

    // Draw circular dots at each actual point
    for (final pt in actualPoints) {
      canvas.drawCircle(pt, 4.0, dotFillPaint);
      canvas.drawCircle(pt, 4.0, dotBorderPaint);
    }
  }

  double getY(double lakhValue, double height) {
    // 0 to 20L
    final fraction = lakhValue.clamp(0.0, 20.0) / 20.0;
    return height - (fraction * height);
  }

  void _drawDashedPath(Canvas canvas, List<Offset> points, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final dx = p2.dx - p1.dx;
      final dy = p2.dy - p1.dy;
      final distance = math.sqrt(dx * dx + dy * dy);

      double currentDist = 0.0;
      while (currentDist < distance) {
        final startFraction = currentDist / distance;
        final endDist = math.min(currentDist + dashWidth, distance);
        final endFraction = endDist / distance;

        canvas.drawLine(
          Offset(p1.dx + dx * startFraction, p1.dy + dy * startFraction),
          Offset(p1.dx + dx * endFraction, p1.dy + dy * endFraction),
          paint,
        );
        currentDist += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 4. Donut Painter for Sales by Category Share
class _CategoryShareDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final strokeWidth = 20.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Percentages:
    // Shirts: 40% (0.40) -> 0.40 * 2pi
    // Knitwear: 25% (0.25) -> 0.25 * 2pi
    // Blazers: 20% (0.20) -> 0.20 * 2pi
    // Trousers: 15% (0.15) -> 0.15 * 2pi

    const gapRadian = 0.04;
    double currentAngle = -math.pi / 2;

    final slices = [
      _Slice(0.40, const Color(0xFFC89748)), // Shirts
      _Slice(0.25, const Color(0xFF2F69A8)), // Knitwear
      _Slice(0.20, const Color(0xFF525B62)), // Blazers
      _Slice(0.15, const Color(0xFFA8AFB5)), // Trousers
    ];

    for (final slice in slices) {
      final sweepAngle = (slice.percentage * 2 * math.pi) - gapRadian;
      paint.color = slice.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle + gapRadian / 2,
        sweepAngle,
        false,
        paint,
      );

      currentAngle += slice.percentage * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Slice {
  final double percentage;
  final Color color;
  _Slice(this.percentage, this.color);
}
