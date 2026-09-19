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
                  Expanded(
                    flex: 58,
                    child: _buildDefectRateCard(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 42,
                    child: _buildSupplierAlertsCard(),
                  ),
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
          itemBuilder: (context) => [
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
            children: [
              leftContent,
              const SizedBox(height: 12),
              rightContent,
            ],
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
    final suppliers = const [
      _SupplierCardData(
        name: 'Biella Fabric Mills',
        scoreBadge: '94 pts',
        scoreColor: Color(0xFF1E7E34),
        scoreBg: Color(0xFFE7F7ED),
        statusBadge: 'Top Performer',
        statusColor: Color(0xFF1E7E34),
        statusBg: Color(0xFFE7F7ED),
        icon: Icons.eco_outlined,
        onTimePct: '98%',
        onTimeGrowth: '↑ 2%',
        isOnTimePositive: true,
        qualityScore: '99.2%',
        qualityGrowth: '↑ 1%',
        isQualityPositive: true,
        avgLeadTime: '12d',
        activePos: '4',
      ),
      _SupplierCardData(
        name: 'Milano Silk Co.',
        scoreBadge: '88 pts',
        scoreColor: Color(0xFF92400E),
        scoreBg: Color(0xFFFEF3C7),
        statusBadge: 'Reliable',
        statusColor: Color(0xFF92400E),
        statusBg: Color(0xFFFEF3C7),
        icon: Icons.grid_4x4_rounded,
        onTimePct: '92%',
        onTimeGrowth: '↑ 4%',
        isOnTimePositive: true,
        qualityScore: '97.5%',
        qualityGrowth: '↑ 2%',
        isQualityPositive: true,
        avgLeadTime: '14d',
        activePos: '2',
      ),
      _SupplierCardData(
        name: 'Indo Weaver',
        scoreBadge: '82 pts',
        scoreColor: Color(0xFF92400E),
        scoreBg: Color(0xFFFEF3C7),
        statusBadge: 'Watch',
        statusColor: Color(0xFF92400E),
        statusBg: Color(0xFFFEF3C7),
        icon: Icons.texture_rounded,
        onTimePct: '85%',
        onTimeGrowth: '↓ 3%',
        isOnTimePositive: false,
        qualityScore: '96.0%',
        qualityGrowth: '↑ 1%',
        isQualityPositive: true,
        avgLeadTime: '18d',
        activePos: '5',
      ),
      _SupplierCardData(
        name: 'Delta Trim & Co.',
        scoreBadge: '71 pts',
        scoreColor: Color(0xFFDC2626),
        scoreBg: Color(0xFFFEE2E2),
        statusBadge: 'Needs Attention',
        statusColor: Color(0xFFDC2626),
        statusBg: Color(0xFFFEE2E2),
        icon: Icons.change_history_rounded,
        onTimePct: '78%',
        onTimeGrowth: '↓ 6%',
        isOnTimePositive: false,
        qualityScore: '94.2%',
        qualityGrowth: '↓ 2%',
        isQualityPositive: false,
        avgLeadTime: '10d',
        activePos: '1',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 950;
        final cardSpacing = 14.0;

        if (isCompact) {
          return Wrap(
            spacing: cardSpacing,
            runSpacing: cardSpacing,
            children: suppliers
                .map((s) => SizedBox(
                      width: (constraints.maxWidth - cardSpacing) / 2,
                      child: _buildSupplierCard(s),
                    ))
                .toList(),
          );
        }

        return Row(
          children: suppliers
              .asMap()
              .entries
              .map(
                (entry) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: entry.key == 0 ? 0 : cardSpacing / 2,
                      right: entry.key == suppliers.length - 1
                          ? 0
                          : cardSpacing / 2,
                    ),
                    child: _buildSupplierCard(entry.value),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildSupplierCard(_SupplierCardData data) {
    return Container(
      padding: const EdgeInsets.all(14),
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
          // Header Row: Icon Badge + Supplier Name + Score Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF4EB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEADBCA)),
                ),
                child: Icon(data.icon, size: 16, color: const Color(0xFF9B6E39)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            data.name,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181512),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: data.scoreBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            data.scoreBadge,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: data.scoreColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: data.statusBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        data.statusBadge,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: data.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Metrics Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: On-Time % & Avg Lead Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'On-Time %',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7E7569),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          data.onTimePct,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181512),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: data.isOnTimePositive
                                ? const Color(0xFFE7F7ED)
                                : const Color(0xFFFDECEB),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            data.onTimeGrowth,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: data.isOnTimePositive
                                  ? const Color(0xFF1E7E34)
                                  : const Color(0xFFD9534F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Avg Lead Time',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7E7569),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.avgLeadTime,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181512),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Right: Quality Score & Active POs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quality Score',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7E7569),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          data.qualityScore,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181512),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: data.isQualityPositive
                                ? const Color(0xFFE7F7ED)
                                : const Color(0xFFFDECEB),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            data.qualityGrowth,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: data.isQualityPositive
                                  ? const Color(0xFF1E7E34)
                                  : const Color(0xFFD9534F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Active POs',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7E7569),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.activePos,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181512),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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

          // Timeline Rows + Legend Column
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // PO Progress Bars (flex 75)
              Expanded(
                flex: 75,
                child: Column(
                  children: [
                    // Row 1: PO #10492 — Biella (Blue transit + Red delayed segment)
                    _buildPoTimelineRow(
                      poTitle: 'PO #10492 — Biella',
                      segments: const [
                        _TimelineSegment(factor: 0.62, color: Color(0xFF3B82F6)),
                        _TimelineSegment(factor: 0.08, color: Color(0xFFEF4444)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Row 2: PO #10493 — Milano Silk (Green On Time)
                    _buildPoTimelineRow(
                      poTitle: 'PO #10493 — Milano Silk',
                      segments: const [
                        _TimelineSegment(factor: 0.70, color: Color(0xFF10B981)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Row 3: PO #10494 — Indo Weaver (Blue In Transit)
                    _buildPoTimelineRow(
                      poTitle: 'PO #10494 — Indo Weaver',
                      segments: const [
                        _TimelineSegment(factor: 0.45, color: Color(0xFF3B82F6)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Legend (flex 25)
              Expanded(
                flex: 25,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    _TimelineLegendItem(
                      label: 'Delayed > 3 Days',
                      color: Color(0xFFEF4444),
                    ),
                    SizedBox(height: 8),
                    _TimelineLegendItem(
                      label: 'On Time',
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(height: 8),
                    _TimelineLegendItem(
                      label: 'In Transit',
                      color: Color(0xFF3B82F6),
                    ),
                    SizedBox(height: 8),
                    _TimelineLegendItem(
                      label: 'Not Started',
                      color: Color(0xFFCBD5E1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPoTimelineRow({
    required String poTitle,
    required List<_TimelineSegment> segments,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 170,
          child: Text(
            poTitle,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2E2A24),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 12,
              color: const Color(0xFFF3ECE4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  return Row(
                    children: segments
                        .map((seg) => Container(
                              width: totalWidth * seg.factor,
                              height: 12,
                              color: seg.color,
                            ))
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ],
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
          SizedBox(
            height: 200,
            child: _DefectRateBarChart(),
          ),
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
                onTap: () => _showFeedback('Viewing all active supplier alerts...'),
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

          // Alert 1: Delay Alert
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delay Alert',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181512),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Biella Fabric Mills PO #10492 delayed by 3 days.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5A5348),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '2 hours ago',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E958A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Alert 2: Quality Risk
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quality Risk',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181512),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Milano Silk batch #SFD-16 has 4.2% defect rate.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF5A5348),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '5 hours ago',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E958A),
                        ),
                      ),
                    ],
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
                'Viewing supplier consolidation & quality recommendations...'),
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

class _TimelineSegment {
  final double factor;
  final Color color;

  const _TimelineSegment({required this.factor, required this.color});
}

class _TimelineLegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _TimelineLegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5A5348),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// DEFECT RATE BAR CHART
// =============================================================================
class _DefectRateBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bars = const [
      _DefectBarItem(label: 'Biella Fabric Mills', rate: 1.2, isOk: true),
      _DefectBarItem(label: 'Milano Silk Co.', rate: 2.8, isOk: true),
      _DefectBarItem(label: 'Indo Weaver', rate: 6.4, isOk: false),
      _DefectBarItem(label: 'Delta Trim & Co.', rate: 8.9, isOk: false),
    ];

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
                    .map((t) => Text(
                          t,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF9E958A),
                          ),
                        ))
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
                  (_) => Container(
                    height: 1,
                    color: const Color(0xFFF1EAE0),
                  ),
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
                  final barColor =
                      b.isOk ? const Color(0xFF10B981) : const Color(0xFFEF4444);

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
                    .map((b) => SizedBox(
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
                        ))
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
