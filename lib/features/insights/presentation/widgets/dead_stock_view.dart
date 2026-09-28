// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/responsive_values.dart';

class DeadStockView extends StatefulWidget {
  final VoidCallback? onReviewGuidelines;
  final VoidCallback? onBulkActions;
  final VoidCallback? onExecuteOptimization;

  const DeadStockView({
    super.key,
    this.onReviewGuidelines,
    this.onBulkActions,
    this.onExecuteOptimization,
  });

  @override
  State<DeadStockView> createState() => _DeadStockViewState();
}

class _DeadStockViewState extends State<DeadStockView> {
  String _selectedPeriod = 'Past 90 Days (Stagnant)';
  String _selectedCategory = 'All Categories';

  final List<String> _periods = const [
    'Past 90 Days (Stagnant)',
    'Past 60 Days (Aging)',
    'Past 120 Days (Critical)',
    'Past 180+ Days (Severe)',
  ];

  final List<String> _categories = const [
    'All Categories',
    'Shirts',
    'Knitwear',
    'Dresses',
    'Outerwear',
    'Blazers',
    'Trousers',
  ];

  void _showGuidelinesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(
              Icons.rule_folder_outlined,
              size: 20,
              color: Color(0xFF8C5E33),
            ),
            const SizedBox(width: 10),
            Text(
              'Dead Stock Management Guidelines',
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
                'Standard Operating Thresholds for Stagnant Inventory:',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181512),
                ),
              ),
              const SizedBox(height: 12),
              _buildGuidelineItem(
                '1. 60–90 Days Static',
                'Flag as at-risk. Explore regional inter-store replenishment before any price cut.',
              ),
              _buildGuidelineItem(
                '2. 90–120 Days Static',
                'Trigger tiered markdown (10% to 15%) or bundling promotion in low-velocity nodes.',
              ),
              _buildGuidelineItem(
                '3. 120+ Days Static',
                'Liquidate via factory outlet channels, flash digital sales, or supplier buyback clauses.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Understood',
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

  Widget _buildGuidelineItem(String title, String desc) {
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

  void _showBulkActionsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: Color(0xFF181512),
            ),
            const SizedBox(width: 10),
            Text(
              'Bulk Stagnant Stock Actions',
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
                'Apply batch actions across all 4 stagnant product categories (2,450 total units):',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF6B6358),
                ),
              ),
              const SizedBox(height: 16),
              _buildBulkActionRow(
                icon: Icons.percent_rounded,
                title: 'Global 15% Clearance Markdown',
                subtitle: 'Applies to Outerwear & Dresses over 90 days',
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bulk 15% markdown scheduled across 124 styles.',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      backgroundColor: const Color(0xFF181512),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildBulkActionRow(
                icon: Icons.sync_alt_rounded,
                title: 'Consolidate to High-Demand Node',
                subtitle:
                    'Moves 180+ days shirts & knitwear to high-demand node',
                onTap: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Inter-store dispatch batch created.',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      backgroundColor: const Color(0xFF181512),
                    ),
                  );
                },
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
        ],
      ),
    );
  }

  Widget _buildBulkActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEADBCA)),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF3ECE1),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: const Color(0xFF8C5E33)),
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
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181512),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: const Color(0xFF6B6358),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
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

          // 2. Dead Stock Distribution Plot Card
          _buildDistributionPlotCard(),
          const SizedBox(height: 16),

          // 3. Recommendation Columns (Markdown + Inter-Store Transfer)
          _buildRecommendationsSection(),
          const SizedBox(height: 16),

          // 4. Bottom AI Optimization Action Callout
          _buildAiOptimizationBanner(),
        ],
      ),
    );
  }

  // 1. Filter & Action Bar
  Widget _buildFilterBar() {
    return Row(
      children: [
        // Period Dropdown
        PopupMenuButton<String>(
          tooltip: 'Select Timeframe',
          offset: const Offset(0, 40),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE5DACD)),
          ),
          onSelected: (val) => setState(() => _selectedPeriod = val),
          itemBuilder: (context) => _periods.map((period) {
            return PopupMenuItem<String>(
              value: period,
              height: 36,
              child: Text(
                period,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: period == _selectedPeriod
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: period == _selectedPeriod
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
                  _selectedPeriod,
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

        // Category Dropdown
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
                  Icons.shield_outlined,
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

        // Review All Guidelines Button
        InkWell(
          onTap: widget.onReviewGuidelines ?? _showGuidelinesDialog,
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
              'Review All Guidelines',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181512),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Bulk Actions Button
        InkWell(
          onTap: widget.onBulkActions ?? _showBulkActionsDialog,
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
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bulk Actions',
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
      ],
    );
  }

  // 2. Dead Stock Distribution Plot Card
  Widget _buildDistributionPlotCard() {
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
                    'Dead Stock Distribution Plot',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181512),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Product categories by days in stock and stagnant volume',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B6358),
                    ),
                  ),
                ],
              ),
              Text(
                'Size indicates absolute unit volume stagnant',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6358),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart Plot with Custom Painter and Bubble Labels
          SizedBox(
            height: 260,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Y-Axis Vertical Label
                RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'Stagnant Volume (Units)',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B6358),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Y-Axis Scale Values
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '2,000',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                      Text(
                        '1,500',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                      Text(
                        '1,000',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                      Text(
                        '500',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                      Text(
                        '0',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Main Chart Grid + Bubbles
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Background Grid Lines
                                CustomPaint(
                                  size: Size(
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                  ),
                                  painter: _ChartGridPainter(),
                                ),

                                // Bubble 1: Knitwear (X: 30 days, Y: 650 units)
                                _buildBubble(
                                  constraints: constraints,
                                  xRatio: 1.0 / 6.0,
                                  yRatio: 650.0 / 2000.0,
                                  radius: 24,
                                  fillColor: const Color(
                                    0xFFBFDBFE,
                                  ).withOpacity(0.85),
                                  borderColor: const Color(0xFF3B82F6),
                                  label: 'Knitwear',
                                  labelColor: const Color(0xFF1E3A8A),
                                  tooltip:
                                      'Knitwear: 650 units stagnant (30 days)',
                                ),

                                // Bubble 2: Dresses (X: 90 days, Y: 1150 units)
                                _buildBubble(
                                  constraints: constraints,
                                  xRatio: 3.0 / 6.0,
                                  yRatio: 1150.0 / 2000.0,
                                  radius: 28,
                                  fillColor: const Color(
                                    0xFFFDE68A,
                                  ).withOpacity(0.75),
                                  borderColor: const Color(0xFFD97706),
                                  label: 'Dresses',
                                  labelColor: const Color(0xFF78350F),
                                  tooltip:
                                      'Dresses: 1,150 units stagnant (90 days)',
                                ),

                                // Bubble 3: Outerwear (X: 120 days, Y: 1700 units)
                                _buildBubble(
                                  constraints: constraints,
                                  xRatio: 4.0 / 6.0,
                                  yRatio: 1700.0 / 2000.0,
                                  radius: 34,
                                  fillColor: const Color(
                                    0xFFFECACA,
                                  ).withOpacity(0.8),
                                  borderColor: const Color(0xFFEF4444),
                                  label: 'Outerwear',
                                  labelColor: const Color(0xFF991B1B),
                                  tooltip:
                                      'Outerwear: 1,700 units stagnant (120 days)',
                                ),

                                // Bubble 4: Shirts (X: 180+ days, Y: 400 units)
                                _buildBubble(
                                  constraints: constraints,
                                  xRatio: 5.9 / 6.0,
                                  yRatio: 400.0 / 2000.0,
                                  radius: 21,
                                  fillColor: const Color(
                                    0xFFA7F3D0,
                                  ).withOpacity(0.75),
                                  borderColor: const Color(0xFF10B981),
                                  label: 'Shirts',
                                  labelColor: const Color(0xFF065F46),
                                  tooltip:
                                      'Shirts: 400 units stagnant (180+ days)',
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // X-Axis Scale Ticks
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '0 Days',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF6B6358),
                            ),
                          ),
                          Text(
                            '30 Days',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF6B6358),
                            ),
                          ),
                          Text(
                            '60 Days',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF6B6358),
                            ),
                          ),
                          Text(
                            '90 Days',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF6B6358),
                            ),
                          ),
                          Text(
                            '120 Days',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF6B6358),
                            ),
                          ),
                          Text(
                            '150 Days',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF6B6358),
                            ),
                          ),
                          Text(
                            '180+ Days',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: const Color(0xFF6B6358),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Days in Stock (Stagnant)',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B6358),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),

                // Right Legend
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendDot(const Color(0xFF10B981), 'Shirts'),
                      const SizedBox(height: 10),
                      _buildLegendDot(const Color(0xFF3B82F6), 'Knitwear'),
                      const SizedBox(height: 10),
                      _buildLegendDot(const Color(0xFFD97706), 'Dresses'),
                      const SizedBox(height: 10),
                      _buildLegendDot(const Color(0xFFEF4444), 'Outerwear'),
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

  Widget _buildBubble({
    required BoxConstraints constraints,
    required double xRatio,
    required double yRatio,
    required double radius,
    required Color fillColor,
    required Color borderColor,
    required String label,
    required Color labelColor,
    required String tooltip,
  }) {
    final cx = constraints.maxWidth * xRatio;
    final cy = constraints.maxHeight * (1.0 - yRatio);

    return Positioned(
      left: cx - radius,
      top: cy - radius,
      child: Tooltip(
        message: tooltip,
        textStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white),
        decoration: BoxDecoration(
          color: const Color(0xFF181512),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            color: fillColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String name) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B6358),
          ),
        ),
      ],
    );
  }

  // 3. Middle Section: Markdown + Transfer Recommendations
  Widget _buildRecommendationsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Recommended for Markdown
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
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
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: Color(0xFF8C5E33),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recommended for Markdown',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181512),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Viewing all markdown candidate items...',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                            backgroundColor: const Color(0xFF181512),
                          ),
                        );
                      },
                      child: Row(
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

                // Item 1: Cashmere Cardigan
                _buildRecommendationCard(
                  imageAsset: '',
                  title: 'Cashmere Cardigan (Grey/S)',
                  subtitle: '120 Days Static · Qty: 45 · Val: ₹2.1L',
                  actionButton: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '15% Markdown initiated for Cashmere Cardigan.',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          backgroundColor: const Color(0xFF181512),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF181512),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Trigger 15% Markdown',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Item 2: Classic Trench Coat
                _buildRecommendationCard(
                  imageAsset: '',
                  title: 'Classic Trench Coat (Beige/M)',
                  subtitle: '95 Days Static · Qty: 32 · Val: ₹4.8L',
                  actionButton: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '10% Markdown initiated for Classic Trench Coat.',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          backgroundColor: const Color(0xFF181512),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF181512),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Trigger 10% Markdown',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Right Column: Recommended for Inter-Store Transfer
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
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
                    const Icon(
                      Icons.call_made_rounded,
                      size: 18,
                      color: Color(0xFF8C5E33),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recommended for Inter-Store Transfer',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181512),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Viewing all transfer candidates...',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                            backgroundColor: const Color(0xFF181512),
                          ),
                        );
                      },
                      child: Row(
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

                // Item 1: Classic Linen Shirt
                _buildRecommendationCard(
                  imageAsset: '',
                  title: 'Classic Linen Shirt (White/L)',
                  subtitle: '110 Days Static · Qty: 88 · Val: ₹1.2L',
                  actionButton: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Inter-store transfer order generated.',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          backgroundColor: const Color(0xFF181512),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5DACD)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Transfer Stock',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181512),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Item 2: Silk Slip Dress
                _buildRecommendationCard(
                  imageAsset: '',
                  title: 'Silk Slip Dress (Midnight/M)',
                  subtitle: '85 Days Static · Qty: 14 · Val: ₹2.2L',
                  actionButton: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Inter-store transfer order generated for secondary store.',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                          backgroundColor: const Color(0xFF181512),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE5DACD)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      'Transfer to Store',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181512),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard({
    required String imageAsset,
    required String title,
    required String subtitle,
    required Widget actionButton,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF0EAE1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              imageAsset,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => Container(
                width: 48,
                height: 48,
                color: const Color(0xFFF3ECE1),
                child: const Icon(
                  Icons.checkroom_rounded,
                  size: 20,
                  color: Color(0xFF8C5E33),
                ),
              ),
            ),
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
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181512),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6358),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          actionButton,
        ],
      ),
    );
  }

  // 4. Bottom AI Optimization Action Callout
  Widget _buildAiOptimizationBanner() {
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
                  'THREADSTOCK AI OPTIMIZATION ACTION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF946A36),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF4B5563),
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(
                        text:
                            'Reallocating 48 units of surplus stock to secondary facility',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181512),
                        ),
                      ),
                      const TextSpan(text: ' is estimated to recover '),
                      TextSpan(
                        text: '₹2.1L in valuation',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181512),
                        ),
                      ),
                      const TextSpan(
                        text: ' based on localized category velocity records.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed:
                widget.onExecuteOptimization ??
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Optimization executed! Transfer order created for 48 units of surplus stock to secondary facility.',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      backgroundColor: const Color(0xFF181512),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBA8A55),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Execute Action',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1.0;

    // 5 Horizontal Grid Lines (Y = 0, 500, 1000, 1500, 2000)
    for (int i = 0; i <= 4; i++) {
      final y = size.height * (i / 4.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // 7 Vertical Grid Lines (X = 0, 30, 60, 90, 120, 150, 180)
    for (int i = 0; i <= 6; i++) {
      final x = size.width * (i / 6.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
