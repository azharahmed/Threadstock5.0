// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WeeklySalesSummaryView extends StatefulWidget {
  final VoidCallback? onBackToReports;
  final VoidCallback? onNavigateToInventory;

  const WeeklySalesSummaryView({
    super.key,
    this.onBackToReports,
    this.onNavigateToInventory,
  });

  @override
  State<WeeklySalesSummaryView> createState() => _WeeklySalesSummaryViewState();
}

class _WeeklySalesSummaryViewState extends State<WeeklySalesSummaryView> {
  int _activeOutlineIndex = 0;

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFFBA8A55),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1050;

        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDocumentCanvas(),
              const SizedBox(height: 24),
              _buildSidebarPanel(),
              const SizedBox(height: 24),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Document Canvas (73% flex)
            Expanded(flex: 73, child: _buildDocumentCanvas()),
            const SizedBox(width: 24),

            // Right Sidebar Controls & Outline (27% flex)
            Expanded(flex: 27, child: _buildSidebarPanel()),
          ],
        );
      },
    );
  }

  // ========================================================
  // 1. MAIN DOCUMENT CANVAS
  // ========================================================
  Widget _buildDocumentCanvas() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 16,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Document Header
          _buildDocHeader(),
          const SizedBox(height: 24),

          // 1. EXECUTIVE SUMMARY
          _buildExecutiveSummarySection(),
          const SizedBox(height: 26),

          // 2. REVENUE & VELOCITY OVERVIEW
          _buildRevenueVelocitySection(),
          const SizedBox(height: 26),

          // 3. TOP PERFORMING STYLES
          _buildTopPerformingStylesSection(),
          const SizedBox(height: 26),

          // 4. AI INSIGHTS & FLAGGED ITEMS
          _buildAiInsightsSection(),
          const SizedBox(height: 28),

          // Document Footer
          _buildDocFooter(),
        ],
      ),
    );
  }

  // ==========================================
  // DOCUMENT HEADER
  // ==========================================
  Widget _buildDocHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Title Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF4E7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFF2DCBE),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  'THREADSTOCK AUTOMATED INTELLIGENCE',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFFA86718),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                'Weekly Sales Summary',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),

              // Period & Location Subtitle
              Text(
                'Period: Sep 8 - Sep 14, 2024 • All Active Channels & Fulfillment Centers',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6357),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Right Generated Timestamp Box
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF4EC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF0E5D4), width: 1.0),
              ),
              child: const Center(
                child: Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Color(0xFF8D6433),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generated on',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8C8377),
                  ),
                ),
                Text(
                  'Sep 14, 2024, 08:00 AM',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 1. EXECUTIVE SUMMARY SECTION
  // ==========================================
  Widget _buildExecutiveSummarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          '1. EXECUTIVE SUMMARY',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: const Color(0xFFA86718),
          ),
        ),
        const SizedBox(height: 10),

        // Text Narrative
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF2B231D),
              height: 1.5,
            ),
            children: const [
              TextSpan(text: 'Revenue during this cycle has tracked '),
              TextSpan(
                text: '8.4% above',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text:
                    ' target, driven primarily by a Sunday demand spike at primary retail locations. General stock health is robust at ',
              ),
              TextSpan(
                text: '82%',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text:
                    ' overall optimization, though velocity spikes in raw linen styles have triggered warnings on active inventory thresholds.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4 KPI Metric Mini-Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 36) / 4;
            return Row(
              children: [
                _buildKpiCard(
                  width: cardWidth,
                  icon: Icons.bar_chart_rounded,
                  label: 'Total Revenue',
                  value: '₹42.8L',
                  trendText: '↑ 8.4%',
                  trendSub: 'vs target',
                  isPositive: true,
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  width: cardWidth,
                  icon: Icons.shopping_bag_outlined,
                  label: 'Units Sold',
                  value: '1,211',
                  trendText: '↑ 12%',
                  trendSub: 'vs last week',
                  isPositive: true,
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  width: cardWidth,
                  icon: Icons.layers_outlined,
                  label: 'Avg. Order Value',
                  value: '₹3,535',
                  trendText: '↑ 6%',
                  trendSub: 'vs last week',
                  isPositive: true,
                ),
                const SizedBox(width: 12),
                _buildKpiCard(
                  width: cardWidth,
                  icon: Icons.favorite_border_rounded,
                  label: 'Stock Health',
                  value: '82%',
                  badgeText: 'Healthy',
                  isPositive: true,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required double width,
    required IconData icon,
    required String label,
    required String value,
    String? trendText,
    String? trendSub,
    String? badgeText,
    required bool isPositive,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF4EC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFF0E5D4), width: 1.0),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF8D6433)),
          ),
          const SizedBox(width: 10),

          // Metric Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6357),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 3),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F5EA),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: const Color(0xFFC6E7CE),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF257B39),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Text(
                        trendText ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isPositive
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trendSub ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF8C8377),
                          ),
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

  // ==========================================
  // 2. REVENUE & VELOCITY OVERVIEW
  // ==========================================
  Widget _buildRevenueVelocitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          '2. REVENUE & VELOCITY OVERVIEW',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: const Color(0xFFA86718),
          ),
        ),
        const SizedBox(height: 12),

        // Row: Bar Chart (flex 62) + Sunday Surge Callout (flex 38)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: Bar Chart Container
            Expanded(
              flex: 62,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEADBCA),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chart Area with Y-axis and bars
                    SizedBox(
                      height: 110,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Y-Axis Labels
                          SizedBox(
                            width: 28,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '30L',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF8C8377),
                                  ),
                                ),
                                Text(
                                  '20L',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF8C8377),
                                  ),
                                ),
                                Text(
                                  '10L',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF8C8377),
                                  ),
                                ),
                                Text(
                                  '0',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    color: const Color(0xFF8C8377),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // 7 Days Bars
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildBar(
                                  day: 'Mon',
                                  fraction: 0.25,
                                  isHighlighted: false,
                                ),
                                _buildBar(
                                  day: 'Tue',
                                  fraction: 0.45,
                                  isHighlighted: false,
                                ),
                                _buildBar(
                                  day: 'Wed',
                                  fraction: 0.50,
                                  isHighlighted: false,
                                ),
                                _buildBar(
                                  day: 'Thu',
                                  fraction: 0.72,
                                  isHighlighted: false,
                                ),
                                _buildBar(
                                  day: 'Fri',
                                  fraction: 0.60,
                                  isHighlighted: false,
                                ),
                                _buildBar(
                                  day: 'Sat',
                                  fraction: 0.70,
                                  isHighlighted: false,
                                ),
                                _buildBar(
                                  day: 'Sun',
                                  fraction: 0.88,
                                  isHighlighted: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Right: Sunday Surge Activity Card
            Expanded(
              flex: 38,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFEADBCA),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF4EC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFF0E5D4)),
                          ),
                          child: const Icon(
                            Icons.trending_up_rounded,
                            size: 15,
                            color: Color(0xFF8D6433),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sunday Surge Activity',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "The peak cycle recorded on D7 (Sunday) contributed 42% of regional flagship's total weekly volume. Sourcing streams remain consistent but demand represents an emerging regional trend.",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B6357),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBar({
    required String day,
    required double fraction,
    required bool isHighlighted,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 80 * fraction,
          decoration: BoxDecoration(
            color: isHighlighted
                ? const Color(0xFFBA8A55)
                : const Color(0xFFEADBCA),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
            color: isHighlighted
                ? const Color(0xFF181513)
                : const Color(0xFF8C8377),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 3. TOP PERFORMING STYLES SECTION
  // ==========================================
  Widget _buildTopPerformingStylesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          '3. TOP PERFORMING STYLES',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: const Color(0xFFA86718),
          ),
        ),
        const SizedBox(height: 12),

        // Table Container
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAF8F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
          ),
          child: Column(
            children: [
              // Header Row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEADBCA), width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      child: Text(
                        '#',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8C8377),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 6,
                      child: Text(
                        'Style Description',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8C8377),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Units Sold',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8C8377),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Gross Revenue',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8C8377),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Health',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8C8377),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        'Trend',
                        textAlign: TextAlign.end,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8C8377),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Row 1: Classic Linen Shirt (Black)
              _buildStyleRow(
                rank: '1',
                name: 'Classic Linen Shirt (Black)',
                units: '847 pcs',
                revenue: '₹21,17,500',
                health: '92%',
                isHealthy: true,
                isTrendUp: true,
                isLast: false,
              ),

              // Row 2: Wool Tailored Blazer (Navy)
              _buildStyleRow(
                rank: '2',
                name: 'Wool Tailored Blazer (Navy)',
                units: '124 pcs',
                revenue: '₹9,92,000',
                health: '85%',
                isHealthy: true,
                isTrendUp: true,
                isLast: false,
              ),

              // Row 3: Classic Indigo Denim (Dark Wash)
              _buildStyleRow(
                rank: '3',
                name: 'Classic Indigo Denim (Dark Wash)',
                units: '240 pcs',
                revenue: '₹8,40,000',
                health: '79%',
                isHealthy: false,
                isTrendUp: false,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyleRow({
    required String rank,
    required String name,
    required String units,
    required String revenue,
    required String health,
    required bool isHealthy,
    required bool isTrendUp,
    required bool isLast,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF0E5D4), width: 1.0),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              rank,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5E574E),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              units,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF5E574E),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              revenue,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isHealthy
                      ? const Color(0xFFE6F5EA)
                      : const Color(0xFFFDF4E7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isHealthy
                        ? const Color(0xFFC6E7CE)
                        : const Color(0xFFF2DCBE),
                    width: 1.0,
                  ),
                ),
                child: Text(
                  health,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isHealthy
                        ? const Color(0xFF257B39)
                        : const Color(0xFFA86718),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                isTrendUp
                    ? Icons.trending_up_rounded
                    : Icons.trending_flat_rounded,
                size: 16,
                color: isTrendUp
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFA86718),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. AI INSIGHTS & FLAGGED ITEMS
  // ==========================================
  Widget _buildAiInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          '4. AI INSIGHTS & FLAGGED ITEMS',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: const Color(0xFFA86718),
          ),
        ),
        const SizedBox(height: 12),

        // Warning Alert Banner Container
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF7E1C5), width: 1.0),
          ),
          child: Row(
            children: [
              // Warning Icon
              const Icon(
                Icons.warning_amber_rounded,
                size: 20,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 12),

              // Alert Text
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF543210),
                    ),
                    children: const [
                      TextSpan(
                        text: 'Stock Monitor: ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text:
                            'Inventory levels tracked against current buffer thresholds.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Action Link
              InkWell(
                onTap:
                    widget.onNavigateToInventory ??
                    () => _showNotification('Opening inventory view...'),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View in Inventory',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFA86718),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFFA86718),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DOCUMENT FOOTER
  // ==========================================
  Widget _buildDocFooter() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 1,
          color: const Color(0xFFEADBCA),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Report Reference: TS-REP-2024-00914',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8C8377),
              ),
            ),
            Text(
              'Generated using TS-Intelligence-v4 Engine',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF8C8377),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================
  // 2. RIGHT SIDEBAR PANEL (ACTIONS, OUTLINE, SCHEDULE)
  // ========================================================
  Widget _buildSidebarPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Actions
        _buildActionsCard(),
        const SizedBox(height: 24),

        // Card 2: Document Outline
        _buildDocumentOutlineCard(),
        const SizedBox(height: 24),

        // Card 3: Automated Schedule
        _buildAutomatedScheduleCard(),
        const SizedBox(height: 32),

        // Bottom Brand Quote Banner
        _buildRightBrandQuote(),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181513),
          ),
        ),
        const SizedBox(height: 12),

        // Download PDF Button (Solid Caramel Bronze)
        InkWell(
          onTap: () => _showNotification(
            'Downloading Weekly Sales Summary PDF document...',
          ),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFBA8A55),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.download_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Download PDF Document',
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
        const SizedBox(height: 10),

        // Share with Stakeholders Button (Outlined)
        InkWell(
          onTap: () => _showNotification(
            'Share link generated and copied to clipboard.',
          ),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD5C6), width: 1.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.ios_share_rounded,
                  size: 15,
                  color: Color(0xFF181513),
                ),
                const SizedBox(width: 8),
                Text(
                  'Share with Stakeholders',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181513),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Regenerate with Live Data Button (Tinted Outlined)
        InkWell(
          onTap: () => _showNotification(
            'Regenerating Weekly Sales Summary with live database metrics...',
          ),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF4EC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFECDCC8), width: 1.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  size: 15,
                  color: Color(0xFFA86718),
                ),
                const SizedBox(width: 8),
                Text(
                  'Regenerate with Live Data',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFA86718),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentOutlineCard() {
    final outlineItems = [
      '1. Executive Summary',
      '2. Revenue & Velocity Overview',
      '3. Top Performing Styles',
      '4. AI Insights & Flags',
      '5. Sourcing Recommendations',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Outline',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181513),
          ),
        ),
        const SizedBox(height: 12),

        ...outlineItems.asMap().entries.map((entry) {
          final index = entry.key;
          final title = entry.value;
          final isSelected = index == _activeOutlineIndex;

          return InkWell(
            onTap: () => setState(() => _activeOutlineIndex = index),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFFA86718)
                      : const Color(0xFF5E574E),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAutomatedScheduleCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Automated Schedule',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181513),
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF4EC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF0E5D4)),
                ),
                child: const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Color(0xFF8D6433),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivered Weekly',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mondays at 8:00 AM IST',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B6357),
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

  Widget _buildRightBrandQuote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gold vertical bar
        Container(width: 2.5, height: 36, color: const Color(0xFFBA8A55)),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data today.\nBetter decisions\ntomorrow.',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 17.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7E5B37),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '— THREADSTOCK',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7E766B),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
