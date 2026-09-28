// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SupplierPerformanceView extends StatefulWidget {
  final VoidCallback? onNavigateToPurchasing;
  final VoidCallback? onNavigateToSuppliers;

  const SupplierPerformanceView({
    super.key,
    this.onNavigateToPurchasing,
    this.onNavigateToSuppliers,
  });

  @override
  State<SupplierPerformanceView> createState() =>
      _SupplierPerformanceViewState();
}

class _SupplierPerformanceViewState extends State<SupplierPerformanceView> {
  String _selectedPeriod = 'Past 90 Days: Aug 1 - Oct 31';

  void _showFeedback(String message) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header (Title + Subtitle on Left, Date Selector on Right)
        _buildHeader(),
        const SizedBox(height: 20),

        // 2. 4 Supplier Performance Cards
        _buildSupplierCardsRow(),
        const SizedBox(height: 20),

        // 3. Middle Section: Delivery Performance Timeline (Recent POs)
        _buildDeliveryPerformanceTimelineCard(),
        const SizedBox(height: 20),

        // 4. Bottom Section: Supplier Defect Rate (%) & Supplier Alerts
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1020;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 58, child: _buildDefectRateCard()),
                  const SizedBox(width: 20),
                  Expanded(flex: 42, child: _buildSupplierAlertsCard()),
                ],
              );
            }
            return Column(
              children: [
                _buildDefectRateCard(),
                const SizedBox(height: 20),
                _buildSupplierAlertsCard(),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // 5. AI Insight Callout Card
        _buildAiInsightCalloutBanner(),
        const SizedBox(height: 24),
      ],
    );
  }

  // ===========================================================================
  // 1. HEADER
  // ===========================================================================
  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 750;

        final leftContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supplier Performance',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181512),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track supplier reliability, quality, and delivery performance to build a stronger supply chain.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B6358),
              ),
            ),
          ],
        );

        final rightContent = PopupMenuButton<String>(
          tooltip: 'Select time range',
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFEADBCA)),
          ),
          onSelected: (val) {
            setState(() => _selectedPeriod = val);
            _showFeedback('Period updated: $val');
          },
          itemBuilder: (context) =>
              [
                    'Past 90 Days: Aug 1 - Oct 31',
                    'Past 30 Days: Oct 1 - Oct 31',
                    'Past 6 Months',
                    'Year to Date (2024)',
                  ]
                  .map(
                    (p) => PopupMenuItem(
                      value: p,
                      height: 38,
                      child: Text(
                        p,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: p == _selectedPeriod
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: p == _selectedPeriod
                              ? const Color(0xFF8D6433)
                              : const Color(0xFF1E1C1A),
                        ),
                      ),
                    ),
                  )
                  .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5DACB)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A231A).withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF8B6B46),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedPeriod,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF8B6B46),
                ),
              ],
            ),
          ),
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [leftContent, const SizedBox(height: 12), rightContent],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: leftContent),
            const SizedBox(width: 20),
            rightContent,
          ],
        );
      },
    );
  }

  // ===========================================================================
  // 2. 4 SUPPLIER PERFORMANCE CARDS
  // ===========================================================================
  Widget _buildSupplierCardsRow() {
    final suppliers = const <_SupplierCardData>[];
    if (suppliers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 36,
                color: Color(0xFFBA8A55),
              ),
              const SizedBox(height: 10),
              Text(
                'No supplier performance history yet',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181512),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Performance analytics will appear after purchase orders and receipts are recorded.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF7E7569),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ===========================================================================
  // 3. DELIVERY PERFORMANCE TIMELINE (RECENT POS)
  // ===========================================================================
  Widget _buildDeliveryPerformanceTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Performance Timeline (Recent POs)',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181512),
                ),
              ),
              InkWell(
                onTap: () => _showFeedback('Viewing all purchase orders...'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All POs',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7C4E1F),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF7C4E1F),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Timeline Empty State
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No active purchase order shipments to display.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF7E7569),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4A. SUPPLIER DEFECT RATE (%) BAR CHART
  // ===========================================================================
  Widget _buildDefectRateCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
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
            'Supplier Defect Rate (%)',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181512),
            ),
          ),
          const SizedBox(height: 16),

          // Bar Chart with Y Axis, Gridlines, and Top Value Labels
          SizedBox(height: 200, child: _DefectRateBarChart()),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4B. SUPPLIER ALERTS CARD
  // ===========================================================================
  Widget _buildSupplierAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Supplier Alerts',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181512),
                ),
              ),
              InkWell(
                onTap: () =>
                    _showFeedback('Viewing all active supplier alerts...'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All Alerts',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7C4E1F),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF7C4E1F),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Alerts Empty State
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Center(
              child: Text(
                'No supplier alerts at this time.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF7E7569),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. AI INSIGHT CALLOUT BANNER
  // ===========================================================================
  Widget _buildAiInsightCalloutBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(10),
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
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF2E6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: Color(0xFF9B6E39),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insight',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181512),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Suppliers with defect rates above 5% are costing ~12% more in rework and returns. Consider consolidating low-performing suppliers.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5A5348),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          InkWell(
            onTap: () => _showFeedback(
              'Viewing supplier consolidation & quality recommendations...',
            ),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFDECBB8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Recommendations',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C4E1F),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFF7C4E1F),
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

// Data models
class _SupplierCardData {
  final String name;
  final String scoreBadge;
  final Color scoreColor;
  final Color scoreBg;
  final String statusBadge;
  final Color statusColor;
  final Color statusBg;
  final IconData icon;
  final String onTimePct;
  final String onTimeGrowth;
  final bool isOnTimePositive;
  final String qualityScore;
  final String qualityGrowth;
  final bool isQualityPositive;
  final String avgLeadTime;
  final String activePos;

  const _SupplierCardData({
    required this.name,
    required this.scoreBadge,
    required this.scoreColor,
    required this.scoreBg,
    required this.statusBadge,
    required this.statusColor,
    required this.statusBg,
    required this.icon,
    required this.onTimePct,
    required this.onTimeGrowth,
    required this.isOnTimePositive,
    required this.qualityScore,
    required this.qualityGrowth,
    required this.isQualityPositive,
    required this.avgLeadTime,
    required this.activePos,
  });
}

// =============================================================================
// DEFECT RATE BAR CHART
// =============================================================================
class _DefectRateBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bars = const <_DefectBarItem>[];
    if (bars.isEmpty) {
      return Center(
        child: Text(
          'No defect rate data recorded.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF7E7569),
          ),
        ),
      );
    }

    const yTicks = ['10%', '8%', '5%', '3%', '0%'];
    const leftGutter = 32.0;
    const bottomGutter = 24.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final plotWidth = width - leftGutter;
        final plotHeight = height - bottomGutter;

        return Stack(
          children: [
            // Y Axis Ticks
            Positioned(
              left: 0,
              top: 0,
              width: leftGutter - 6,
              height: plotHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: yTicks
                    .map(
                      (t) => Text(
                        t,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E958A),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            // Horizontal Gridlines
            Positioned(
              left: leftGutter,
              top: 0,
              width: plotWidth,
              height: plotHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (_) => Container(height: 1, color: const Color(0xFFF1EAE0)),
                ),
              ),
            ),

            // Bars and Top Value Labels
            Positioned(
              left: leftGutter,
              top: 0,
              width: plotWidth,
              height: plotHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: bars.map((b) {
                  // Max rate is 10.0%
                  final barHeight = (b.rate / 10.0) * (plotHeight - 24);
                  final barColor = b.isOk
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444);

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${b.rate.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181512),
                        ),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                        child: Container(
                          width: 48,
                          height: barHeight,
                          color: barColor,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

            // X Axis Category Labels
            Positioned(
              left: leftGutter,
              bottom: 0,
              width: plotWidth,
              height: bottomGutter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: bars
                    .map(
                      (b) => SizedBox(
                        width: 90,
                        child: Text(
                          b.label,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5A5348),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DefectBarItem {
  final String label;
  final double rate;
  final bool isOk;

  const _DefectBarItem({
    required this.label,
    required this.rate,
    required this.isOk,
  });
}
