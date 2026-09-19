// ignore_for_file: deprecated_member_use
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductDemandForecastView extends StatefulWidget {
  const ProductDemandForecastView({
    super.key,
    this.onDraftReplenishmentPo,
    this.onNavigateToPurchasing,
    this.onSwitchToWorkspace,
  });

  final VoidCallback? onDraftReplenishmentPo;
  final VoidCallback? onNavigateToPurchasing;
  final VoidCallback? onSwitchToWorkspace;

  @override
  State<ProductDemandForecastView> createState() => _ProductDemandForecastViewState();
}

class _ProductDemandForecastViewState extends State<ProductDemandForecastView> {
  String _selectedTimeframe = '90 days';

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF181513),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Product Header Card (Image, Title, SKU, Tags, Timeframe Buttons)
          _buildProductHeaderCard(),
          const SizedBox(height: 16),

          // 2. 4 Metric Cards Row (Current Stock, 30-Day Forecast, Coverage, Reorder Point)
          _buildMetricsRow(),
          const SizedBox(height: 16),

          // 3. Sales & Demand Projection Trend (Interactive Custom Chart)
          _buildTrendChartCard(),
          const SizedBox(height: 16),

          // 4. Bottom Section: Identified Demand Drivers & AI Recommended Safety Action
          _buildBottomSection(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. TOP PRODUCT HEADER CARD
  // ===========================================================================
  Widget _buildProductHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 800;

          final productInfo = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 86,
                  height: 86,
                  color: const Color(0xFFF8FAFC),
                  child: Image.asset(
                    'Assets/oxford_linen_shirt.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.checkroom_rounded,
                        size: 38,
                        color: const Color(0xFFBA8A55).withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),

              // Title, SKU, Supplier, Tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Classic White Oxford — M',
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'SKU: TS-OXF-WHT-M  |  Primary Supplier: Milan Textile Hub',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tags Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildTagPill('Shirts'),
                        _buildTagPill('Formal Wear'),
                        _buildTagPill('Core Collection'),
                        _buildTagPill('Active', isGreen: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final timeframeSelector = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimeframeButton('30 days'),
              const SizedBox(width: 6),
              _buildTimeframeButton('60 days'),
              const SizedBox(width: 6),
              _buildTimeframeButton('90 days'),
              const SizedBox(width: 6),
              _buildTimeframeButton('180 days'),
            ],
          );

          if (isStacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                productInfo,
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: timeframeSelector,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: productInfo),
              const SizedBox(width: 16),
              timeframeSelector,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTagPill(String label, {bool isGreen = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isGreen ? const Color(0xFFEAF7EE) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isGreen ? FontWeight.w600 : FontWeight.w500,
          color: isGreen ? const Color(0xFF15803D) : const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildTimeframeButton(String label) {
    final isSelected = _selectedTimeframe == label;
    return InkWell(
      onTap: () {
        setState(() => _selectedTimeframe = label);
        _showNotification('Switched forecast projection to $label.');
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF181513) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF181513) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. 4 METRIC CARDS ROW
  // ===========================================================================
  Widget _buildMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 980;

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.inventory_2_outlined,
                      iconBg: const Color(0xFFFFF9EE),
                      iconColor: const Color(0xFFD97706),
                      title: 'Current Stock',
                      value: '124 units',
                      badgeLabel: 'Healthy',
                      badgeColor: const Color(0xFFEAF7EE),
                      badgeTextColor: const Color(0xFF15803D),
                      subtext: 'On hand at Central Warehouse',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.trending_up_rounded,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      title: '30-Day Forecast',
                      value: '89 units',
                      badgeLabel: 'Moderate Velocity',
                      badgeColor: const Color(0xFFFEF3C7),
                      badgeTextColor: const Color(0xFFB45309),
                      subtext: 'AI predicted demand',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.shield_outlined,
                      iconBg: const Color(0xFFFFFBEB),
                      iconColor: const Color(0xFFD97706),
                      title: 'Coverage',
                      value: '41 days',
                      badgeLabel: 'Secure',
                      badgeColor: const Color(0xFFEAF7EE),
                      badgeTextColor: const Color(0xFF15803D),
                      subtext: 'Based on current stock',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.shopping_cart_outlined,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Reorder Point',
                      value: '45 units',
                      badgeLabel: 'Safe Zone',
                      badgeColor: const Color(0xFFEFF6FF),
                      badgeTextColor: const Color(0xFF2563EB),
                      subtext: 'Recommended level',
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.inventory_2_outlined,
                iconBg: const Color(0xFFFFF9EE),
                iconColor: const Color(0xFFD97706),
                title: 'Current Stock',
                value: '124 units',
                badgeLabel: 'Healthy',
                badgeColor: const Color(0xFFEAF7EE),
                badgeTextColor: const Color(0xFF15803D),
                subtext: 'On hand at Central Warehouse',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.trending_up_rounded,
                iconBg: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFEA580C),
                title: '30-Day Forecast',
                value: '89 units',
                badgeLabel: 'Moderate Velocity',
                badgeColor: const Color(0xFFFEF3C7),
                badgeTextColor: const Color(0xFFB45309),
                subtext: 'AI predicted demand',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.shield_outlined,
                iconBg: const Color(0xFFFFFBEB),
                iconColor: const Color(0xFFD97706),
                title: 'Coverage',
                value: '41 days',
                badgeLabel: 'Secure',
                badgeColor: const Color(0xFFEAF7EE),
                badgeTextColor: const Color(0xFF15803D),
                subtext: 'Based on current stock',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.shopping_cart_outlined,
                iconBg: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFEA580C),
                title: 'Reorder Point',
                value: '45 units',
                badgeLabel: 'Safe Zone',
                badgeColor: const Color(0xFFEFF6FF),
                badgeTextColor: const Color(0xFF2563EB),
                subtext: 'Recommended level',
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
    required String badgeLabel,
    required Color badgeColor,
    required Color badgeTextColor,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ),
          const SizedBox(width: 12),

          // Details Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badgeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtext,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
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
  // 3. SALES & DEMAND PROJECTION TREND (CHART)
  // ===========================================================================
  Widget _buildTrendChartCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart Header: Title & Legends
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sales & Demand Projection Trend',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),

              // Legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Actual Sales
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 18,
                        height: 2,
                        color: const Color(0xFF181513),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Actual Sales',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // AI Forecast
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          3,
                          (index) => Container(
                            width: 4,
                            height: 2,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            color: const Color(0xFFB45309),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI Forecast',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // 95% Confidence Interval
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F3EA),
                          border: Border.all(color: const Color(0xFFEADBCA)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '95% Confidence Interval',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Custom Painted Chart
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: _DemandTrendChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. BOTTOM SECTION: DEMAND DRIVERS & SAFETY ACTION
  // ===========================================================================
  Widget _buildBottomSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 960;

        final driversCard = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title & View All
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Identified Demand Drivers',
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  InkWell(
                    onTap: () => _showNotification('Viewing all demand drivers.'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Color(0xFFB45309),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3 Driver Cards Row
              LayoutBuilder(
                builder: (context, c) {
                  final isNarrowDrivers = c.maxWidth < 620;

                  final driver1 = _buildDriverItem(
                    icon: Icons.trending_up_rounded,
                    percentage: '+18%',
                    percentageColor: const Color(0xFFD97706),
                    title: 'Seasonal Demand Surge',
                    description: 'Corresponds with peak regional wedding & festive clothing cycles.',
                    impactLabel: 'High Impact',
                    impactBg: const Color(0xFFFEF3C7),
                    impactTextColor: const Color(0xFFB45309),
                  );

                  final driver2 = _buildDriverItem(
                    icon: Icons.card_giftcard_outlined,
                    percentage: '+12%',
                    percentageColor: const Color(0xFFD97706),
                    title: 'Store Promotion Event',
                    description: 'Flagship store loyalty points exclusive starting next week.',
                    impactLabel: 'Medium Impact',
                    impactBg: const Color(0xFFFEF3C7),
                    impactTextColor: const Color(0xFFB45309),
                  );

                  final driver3 = _buildDriverItem(
                    icon: Icons.grain_rounded,
                    percentage: '-4%',
                    percentageColor: const Color(0xFF64748B),
                    title: 'Adverse Weather Impact',
                    description: 'Early heavy monsoon forecast reduces typical footfall volume.',
                    impactLabel: 'Low Impact',
                    impactBg: const Color(0xFFEAF7EE),
                    impactTextColor: const Color(0xFF15803D),
                  );

                  if (isNarrowDrivers) {
                    return Column(
                      children: [
                        driver1,
                        const SizedBox(height: 12),
                        driver2,
                        const SizedBox(height: 12),
                        driver3,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: driver1),
                      const SizedBox(width: 12),
                      Expanded(child: driver2),
                      const SizedBox(width: 12),
                      Expanded(child: driver3),
                    ],
                  );
                },
              ),
            ],
          ),
        );

        final safetyActionCard = Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB45309).withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 15,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI RECOMMENDED SAFETY ACTION',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB45309),
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Replenish safety stock early',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current stockout date projected in 41 days.\nTo secure lead time buffer, create a replenishment PO now.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Button
              InkWell(
                onTap: () {
                  widget.onDraftReplenishmentPo?.call();
                  _showNotification('Drafting Replenishment PO with Milan Textile Hub...');
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181513),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Draft Replenishment PO',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        if (isStacked) {
          return Column(
            children: [
              driversCard,
              const SizedBox(height: 16),
              safetyActionCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 66, child: driversCard),
            const SizedBox(width: 16),
            SizedBox(width: 320, child: safetyActionCard),
          ],
        );
      },
    );
  }

  Widget _buildDriverItem({
    required IconData icon,
    required String percentage,
    required Color percentageColor,
    required String title,
    required String description,
    required String impactLabel,
    required Color impactBg,
    required Color impactTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: const Color(0xFFD97706)),
              Text(
                percentage,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: percentageColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: impactBg,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              impactLabel,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: impactTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DEMAND TREND CHART PAINTER
// =============================================================================
class _DemandTrendChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 36.0;
    const bottomMargin = 26.0;
    const topMargin = 10.0;
    const rightMargin = 20.0;

    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;

    // Y Axis: 0 to 200 (step 50)
    final yValues = [200, 150, 100, 50, 0];
    final textStyle = GoogleFonts.inter(
      fontSize: 11.5,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF94A3B8),
    );

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (int i = 0; i < yValues.length; i++) {
      final y = topMargin + (chartHeight * (i / (yValues.length - 1)));

      // Draw horizontal grid line
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(leftMargin + chartWidth, y),
        gridPaint,
      );

      // Draw Y label
      final textPainter = TextPainter(
        text: TextSpan(text: '${yValues[i]}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(leftMargin - textPainter.width - 8, y - textPainter.height / 2),
      );
    }

    // X Axis Dates: Jun 01, Jun 15, Jun 30, Jul 15, Jul 30, Aug 14, Aug 29
    final xLabels = ['Jun 01', 'Jun 15', 'Jun 30', 'Jul 15', 'Jul 30', 'Aug 14', 'Aug 29'];
    for (int i = 0; i < xLabels.length; i++) {
      final x = leftMargin + (chartWidth * (i / (xLabels.length - 1)));
      final textPainter = TextPainter(
        text: TextSpan(text: xLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - textPainter.height),
      );
    }

    // Coordinates mapping
    double getX(double indexFraction) => leftMargin + (chartWidth * (indexFraction / 6.0));
    double getY(double val) => topMargin + chartHeight * (1.0 - (val / 200.0));

    // Data Points
    // Actuals:
    // Jun 01 (0.0): 68
    // Jun 15 (1.0): 106
    // Jun 30 (2.0): 78
    // Jul 15 (3.0): 136 (transition)
    final actualPoints = [
      Offset(getX(0.0), getY(68)),
      Offset(getX(1.0), getY(106)),
      Offset(getX(2.0), getY(78)),
      Offset(getX(3.0), getY(136)),
    ];

    // Forecast Points:
    // Jul 15 (3.0): 136
    // Jul 30 (4.0): 112
    // Aug 14 (5.0): 132
    // Aug 29 (6.0): 164
    final forecastUpper = [
      Offset(getX(3.0), getY(144)),
      Offset(getX(4.0), getY(152)),
      Offset(getX(5.0), getY(162)),
      Offset(getX(6.0), getY(184)),
    ];

    final forecastLower = [
      Offset(getX(3.0), getY(128)),
      Offset(getX(4.0), getY(86)),
      Offset(getX(5.0), getY(106)),
      Offset(getX(6.0), getY(142)),
    ];

    // 1. Draw Confidence Interval Ribbon
    final ribbonPath = Path();
    ribbonPath.moveTo(forecastUpper[0].dx, forecastUpper[0].dy);
    for (int i = 1; i < forecastUpper.length; i++) {
      final pPrev = forecastUpper[i - 1];
      final pCurr = forecastUpper[i];
      final cx = (pPrev.dx + pCurr.dx) / 2;
      ribbonPath.cubicTo(cx, pPrev.dy, cx, pCurr.dy, pCurr.dx, pCurr.dy);
    }
    ribbonPath.lineTo(forecastLower.last.dx, forecastLower.last.dy);
    for (int i = forecastLower.length - 2; i >= 0; i--) {
      final pPrev = forecastLower[i + 1];
      final pCurr = forecastLower[i];
      final cx = (pPrev.dx + pCurr.dx) / 2;
      ribbonPath.cubicTo(cx, pPrev.dy, cx, pCurr.dy, pCurr.dx, pCurr.dy);
    }
    ribbonPath.close();

    final ribbonPaint = Paint()
      ..color = const Color(0xFFF9F3EA).withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawPath(ribbonPath, ribbonPaint);

    // 2. Draw AI Forecast Dashed Line
    final forecastPoints = [
      Offset(getX(3.0), getY(136)),
      Offset(getX(4.0), getY(112)),
      Offset(getX(5.0), getY(132)),
      Offset(getX(6.0), getY(164)),
    ];

    final forecastPath = Path();
    forecastPath.moveTo(forecastPoints[0].dx, forecastPoints[0].dy);
    for (int i = 1; i < forecastPoints.length; i++) {
      final pPrev = forecastPoints[i - 1];
      final pCurr = forecastPoints[i];
      final cx = (pPrev.dx + pCurr.dx) / 2;
      forecastPath.cubicTo(cx, pPrev.dy, cx, pCurr.dy, pCurr.dx, pCurr.dy);
    }

    _drawDashedPath(
      canvas: canvas,
      path: forecastPath,
      paint: Paint()
        ..color = const Color(0xFFB45309)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
      dashWidth: 5.0,
      dashSpace: 4.0,
    );

    // 3. Draw Actual Sales Solid Line
    final actualPath = Path();
    actualPath.moveTo(actualPoints[0].dx, actualPoints[0].dy);
    for (int i = 1; i < actualPoints.length; i++) {
      actualPath.lineTo(actualPoints[i].dx, actualPoints[i].dy);
    }

    final actualPaint = Paint()
      ..color = const Color(0xFF181513)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(actualPath, actualPaint);

    // 4. Draw Actual Points Circular Dots
    final dotFillPaint = Paint()..color = const Color(0xFF181513);
    for (final pt in actualPoints) {
      canvas.drawCircle(pt, 3.5, dotFillPaint);
    }
  }

  void _drawDashedPath({
    required Canvas canvas,
    required Path path,
    required Paint paint,
    required double dashWidth,
    required double dashSpace,
  }) {
    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final len = math.min(dashWidth, metric.length - distance);
        final extractPath = metric.extractPath(distance, distance + len);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
