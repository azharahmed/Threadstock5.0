// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/approval_center_view.dart';
import '../../../../core/responsive/desktop_layout.dart';

enum OverviewPageMode {
  approvalCenter,
  operationalOverview,
}

class OverviewPage extends StatefulWidget {
  const OverviewPage({
    super.key,
    this.initialMode = OverviewPageMode.operationalOverview,
    this.autoShowSessionExpired = false,
    this.autoShowSwitchBusiness = false,
    this.onNavigateToIndex,
    this.onTitleChanged,
  });

  final OverviewPageMode initialMode;
  final bool autoShowSessionExpired;
  final bool autoShowSwitchBusiness;
  final ValueChanged<int>? onNavigateToIndex;
  final ValueChanged<String>? onTitleChanged;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late OverviewPageMode _mode;
  String _selectedChartTab = '7D';

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (_mode == OverviewPageMode.approvalCenter) {
      widget.onTitleChanged?.call('Approval Center');
    } else {
      widget.onTitleChanged?.call('Overview');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == OverviewPageMode.approvalCenter) {
      return ApprovalCenterView(
        onViewOperationalOverview: () {
          setState(() {
            _mode = OverviewPageMode.operationalOverview;
            widget.onTitleChanged?.call('Overview');
          });
        },
      );
    }

    return SingleChildScrollView(
      child: DesktopContentConstraint(
        verticalPadding: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Greeting Section
            _buildGreetingRow(),
            const SizedBox(height: 20),

            // 2. 4 KPI Metrics Cards
            _buildKpiRow(),
            const SizedBox(height: 20),

            // 3. Middle Section: Recent Activity & Sales Trend Chart
            LayoutBuilder(
              builder: (context, constraints) {
                final isStacked = constraints.maxWidth < 980;
                if (isStacked) {
                  return Column(
                    children: [
                      _buildRecentActivityCard(),
                      const SizedBox(height: 20),
                      _buildSalesTrendCard(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Recent Activity (~32%)
                    Expanded(
                      flex: 4,
                      child: _buildRecentActivityCard(),
                    ),
                    const SizedBox(width: 20),

                    // Right Column: Sales Trend Chart (~68%)
                    Expanded(
                      flex: 7,
                      child: _buildSalesTrendCard(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // 4. Bottom Row: Top Categories + Stock Health + AI Insight
            LayoutBuilder(
              builder: (context, constraints) {
                final isStacked = constraints.maxWidth < 1100;
                if (isStacked) {
                  return Column(
                    children: [
                      _buildTopCategoriesCard(),
                      const SizedBox(height: 20),
                      _buildStockHealthCard(),
                      const SizedBox(height: 20),
                      _buildAiInsightCard(),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildTopCategoriesCard()),
                    const SizedBox(width: 20),
                    Expanded(flex: 4, child: _buildStockHealthCard()),
                    const SizedBox(width: 20),
                    Expanded(flex: 3, child: _buildAiInsightCard()),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. GREETING ROW
  // ===========================================================================
  Widget _buildGreetingRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Good morning, Alex',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181513),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '👋',
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Here is your operational update for Zone A.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFF6B7280),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. 4 KPI METRICS ROW
  // ===========================================================================
  Widget _buildKpiRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        if (isCompact) {
          return Column(
            children: [
              _buildKpiCard(
                icon: Icons.verified_outlined,
                iconColor: const Color(0xFF059669),
                iconBgColor: const Color(0xFFD1FAE5),
                title: "Today's Sales",
                value: '₹1,48,200',
                badgeText: '↑ +12%',
                badgeColor: const Color(0xFFDCFCE7),
                badgeTextColor: const Color(0xFF16A34A),
              ),
              const SizedBox(height: 14),
              _buildKpiCard(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFDBEAFE),
                title: 'Total Stock',
                value: '2,842',
              ),
              const SizedBox(height: 14),
              _buildKpiCard(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBgColor: const Color(0xFFFEE2E2),
                title: 'Low-Stock SKUs',
                value: '23 styles',
              ),
              const SizedBox(height: 14),
              _buildKpiCard(
                icon: Icons.local_shipping_outlined,
                iconColor: const Color(0xFFD97706),
                iconBgColor: const Color(0xFFFEF3C7),
                title: 'Pending Transfers',
                value: '5',
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.verified_outlined,
                iconColor: const Color(0xFF059669),
                iconBgColor: const Color(0xFFD1FAE5),
                title: "Today's Sales",
                value: '₹1,48,200',
                badgeText: '↑ +12%',
                badgeColor: const Color(0xFFDCFCE7),
                badgeTextColor: const Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFDBEAFE),
                title: 'Total Stock',
                value: '2,842',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBgColor: const Color(0xFFFEE2E2),
                title: 'Low-Stock SKUs',
                value: '23 styles',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.local_shipping_outlined,
                iconColor: const Color(0xFFD97706),
                iconBgColor: const Color(0xFFFEF3C7),
                title: 'Pending Transfers',
                value: '5',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String value,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(icon, size: 20, color: iconColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const Icon(Icons.more_horiz, size: 18, color: Color(0xFF94A3B8)),
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
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor ?? const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeTextColor ?? const Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. RECENT ACTIVITY CARD (Left Column)
  // ===========================================================================
  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            icon: Icons.inventory_2_outlined,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFD1FAE5),
            title: 'New stock received',
            time: '2 hours ago',
          ),
          const SizedBox(height: 14),
          _buildActivityItem(
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF2563EB),
            iconBg: const Color(0xFFDBEAFE),
            title: 'Sale completed',
            time: '3 hours ago',
          ),
          const SizedBox(height: 14),
          _buildActivityItem(
            icon: Icons.local_shipping_outlined,
            iconColor: const Color(0xFF6366F1),
            iconBg: const Color(0xFFEEF2FF),
            title: 'Transfer shipped',
            time: '5 hours ago',
          ),
          const SizedBox(height: 14),
          _buildActivityItem(
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            title: 'Low stock alert',
            time: '6 hours ago',
          ),
          const SizedBox(height: 14),
          _buildActivityItem(
            icon: Icons.shopping_bag_outlined,
            iconColor: const Color(0xFF0284C7),
            iconBg: const Color(0xFFE0F2FE),
            title: 'New product added',
            time: '1 day ago',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String time,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Center(child: Icon(icon, size: 16, color: iconColor)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                time,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. SALES TREND CHART CARD (Right Column)
  // ===========================================================================
  Widget _buildSalesTrendCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
              Row(
                children: ['7D', '30D', '90D'].map((tab) {
                  final isSelected = tab == _selectedChartTab;
                  return InkWell(
                    onTap: () => setState(() => _selectedChartTab = tab),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(left: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tab,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chart Area with Callout Badge
          Stack(
            children: [
              SizedBox(
                height: 170,
                width: double.infinity,
                child: CustomPaint(
                  painter: _SalesChartPainter(),
                ),
              ),
              Positioned(
                right: 12,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹1,48,200',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Today',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Days of the week row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
              return Text(
                day,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w400,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. BOTTOM ROW CARDS
  // ===========================================================================
  Widget _buildTopCategoriesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Categories',
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 96,
                height: 96,
                child: CustomPaint(
                  painter: _CategoryDonutPainter(),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '2,842',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Total Styles',
                          style: GoogleFonts.inter(
                            fontSize: 8.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Categories Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCategoryLegendItem('Shirts', '32%', const Color(0xFFD97706)),
                    const SizedBox(height: 4),
                    _buildCategoryLegendItem('Knitwear', '24%', const Color(0xFFB45309)),
                    const SizedBox(height: 4),
                    _buildCategoryLegendItem('Denim', '18%', const Color(0xFF3B82F6)),
                    const SizedBox(height: 4),
                    _buildCategoryLegendItem('Outerwear', '12%', const Color(0xFF1E293B)),
                    const SizedBox(height: 4),
                    _buildCategoryLegendItem('Others', '14%', const Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLegendItem(String label, String percent, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
            ),
          ],
        ),
        Text(
          percent,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildStockHealthCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stock Health',
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          _buildHealthBar('In Stock', 1728, '61%', 0.61, const Color(0xFF047857)),
          const SizedBox(height: 10),
          _buildHealthBar('Low Stock', 312, '11%', 0.11, const Color(0xFFD97706)),
          const SizedBox(height: 10),
          _buildHealthBar('Out of Stock', 128, '4%', 0.04, const Color(0xFFDC2626)),
          const SizedBox(height: 10),
          _buildHealthBar('Overstock', 674, '24%', 0.24, const Color(0xFF065F46)),
        ],
      ),
    );
  }

  Widget _buildHealthBar(String label, int count, String percent, double ratio, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 36,
          child: Text(
            count.toString(),
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            percent,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiInsightCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Text(
                'AI Insight',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Denim category is moving 28% faster this month. Consider replenishing top 5 SKUs to avoid stockout.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.45,
              color: const Color(0xFF451A03),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () {
              widget.onNavigateToIndex?.call(6); // AI Studio / Insights
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View Recommendation',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFB45309)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CUSTOM PAINTERS
// =============================================================================

class _SalesChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    // Horizontal grid lines
    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = [
      Offset(0, size.height * 0.70),
      Offset(size.width * 0.20, size.height * 0.45),
      Offset(size.width * 0.40, size.height * 0.60),
      Offset(size.width * 0.60, size.height * 0.35),
      Offset(size.width * 0.80, size.height * 0.38),
      Offset(size.width, size.height * 0.18),
    ];

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final ctrl1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final ctrl2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, p1.dx, p1.dy);
    }

    // Line Paint
    final linePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Nodes on points
    final dotPaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final p in points) {
      canvas.drawCircle(p, 4.0, dotPaint);
      canvas.drawCircle(p, 4.0, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 14.0;

    final slices = [
      {'val': 0.32, 'color': const Color(0xFFD97706)},
      {'val': 0.24, 'color': const Color(0xFFB45309)},
      {'val': 0.18, 'color': const Color(0xFF3B82F6)},
      {'val': 0.12, 'color': const Color(0xFF1E293B)},
      {'val': 0.14, 'color': const Color(0xFF94A3B8)},
    ];

    double startAngle = -math.pi / 2;

    for (final slice in slices) {
      final sweepAngle = (slice['val'] as double) * 2 * math.pi;
      final paint = Paint()
        ..color = slice['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle - 0.04,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
