// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RestockRecommendationView extends StatefulWidget {
  const RestockRecommendationView({
    super.key,
    this.onCreatePo,
    this.onDismiss,
    this.onRefresh,
    this.onViewAllWarnings,
  });

  final VoidCallback? onCreatePo;
  final VoidCallback? onDismiss;
  final VoidCallback? onRefresh;
  final VoidCallback? onViewAllWarnings;

  @override
  State<RestockRecommendationView> createState() => _RestockRecommendationViewState();
}

class _RestockRecommendationViewState extends State<RestockRecommendationView> {
  bool _isDismissed = false;

  void _showSimilarProductsModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 20),
            ),
            const SizedBox(width: 12),
            Text('Alternative Knitwear Recommendations', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAlternativeProductItem('Merino Wool Crewneck (Charcoal / L)', 'MWC-CHR-L', 'Available: 84 units', 'North Hub'),
              const SizedBox(height: 10),
              _buildAlternativeProductItem('Cashmere Blend V-Neck (Navy / M)', 'CBV-NVY-M', 'Available: 62 units', 'Mumbai Central'),
              const SizedBox(height: 10),
              _buildAlternativeProductItem('Fine Gauge Knit Polo (Navy / M)', 'FGK-NVY-M', 'Available: 110 units', 'Central Store'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeProductItem(String title, String sku, String stock, String loc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
              const SizedBox(height: 2),
              Text('$sku  •  $loc', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280))),
            ],
          ),
          Text(stock, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF15803D))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Title, Subtitle, Last updated & Refresh button
          _buildHeader(),
          const SizedBox(height: 20),

          // 2. Main Body 2-Column Section
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1060;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Main Column (~68%)
                    Expanded(
                      flex: 68,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTopRecommendationCard(),
                          const SizedBox(height: 20),
                          _buildChartsAndDynamicsRow(),
                          const SizedBox(height: 20),
                          _buildSuggestedReplenishmentPoCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Right Sidebar Column (~32%)
                    Expanded(
                      flex: 32,
                      child: Column(
                        children: [
                          _buildModelInsightsCard(),
                          const SizedBox(height: 20),
                          _buildRelatedWarningsCard(),
                          const SizedBox(height: 20),
                          _buildAiRecommendationCard(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Stacked for narrow viewports
              return Column(
                children: [
                  _buildTopRecommendationCard(),
                  const SizedBox(height: 20),
                  _buildChartsAndDynamicsRow(),
                  const SizedBox(height: 20),
                  _buildSuggestedReplenishmentPoCard(),
                  const SizedBox(height: 24),
                  _buildModelInsightsCard(),
                  const SizedBox(height: 20),
                  _buildRelatedWarningsCard(),
                  const SizedBox(height: 20),
                  _buildAiRecommendationCard(),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Restock Recommendation',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AI-powered insights to keep your inventory in the right place, at the right time.',
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
            const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(
              'Last updated\nNov 14, 2027, 10:24 AM',
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280), height: 1.2),
            ),
            const SizedBox(width: 14),
            OutlinedButton.icon(
              onPressed: widget.onRefresh ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Re-running neural demand forecast models...'),
                        backgroundColor: Color(0xFF181513),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh Insights'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Top Main Recommendation Card
  Widget _buildTopRecommendationCard() {
    if (_isDismissed) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Recommendation dismissed.', style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B))),
            TextButton(
              onPressed: () => setState(() => _isDismissed = false),
              child: const Text('Undo'),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Image (Sweater)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 86,
              height: 86,
              color: const Color(0xFF0F172A),
              child: Image.asset(
                'assets/merino_wool_blazer.jpg',
                width: 86,
                height: 86,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.checkroom_rounded, color: Colors.white54, size: 36),
              ),
            ),
          ),
          const SizedBox(width: 18),

          // Middle: Badges, Title, Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '92% Confidence',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFB45309)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'High Priority',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Restock Merino Wool Crewneck (Navy / M)',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF111827), letterSpacing: -0.3),
                ),
                const SizedBox(height: 4),
                Text(
                  'Our predictive model shows high sales velocity in Mumbai Phoenix and Delhi Flagship stores. Based on historic pre-holiday spikes, this SKU is highly likely to face stockout in exactly 14 days.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Right: Stockout Risk Badge + Meta Table
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Stockout Risk',
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _buildMetaKeyValue('SKU', 'MWC-NVY-M'),
              const SizedBox(height: 4),
              _buildMetaKeyValue('Category', 'Knitwear'),
              const SizedBox(height: 4),
              _buildMetaKeyValue('Current Stock', '18 units', valueColor: const Color(0xFFDC2626), isBold: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaKeyValue(String key, String val, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$key: ', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF))),
        Text(
          val,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? const Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  // 3. Middle Charts & Dynamics Row
  Widget _buildChartsAndDynamicsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Demand & Stock Projection Chart (~58%)
        Expanded(
          flex: 58,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header + Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Demand & Stock Projection',
                          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SOHO Store Daily Velocity Projections',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildLegendItem('Projected Demand', const Color(0xFFD97706)),
                        const SizedBox(width: 14),
                        _buildLegendItem('Current Stock', const Color(0xFF2563EB)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Chart Area
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _ProjectionChartPainter(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),

        // Right: Stockout Dynamics (~42%)
        Expanded(
          flex: 42,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stockout Dynamics',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                ),
                const SizedBox(height: 18),

                // Metric 1: Current Velocity
                _buildDynamicsMetricItem(
                  icon: Icons.assignment_outlined,
                  label: 'Current Velocity',
                  value: '18 units / day',
                  subText: '↑ 34% increase vs. last week',
                  subTextColor: const Color(0xFF16A34A),
                ),
                const SizedBox(height: 16),

                // Metric 2: Estimated Stockout Window
                _buildDynamicsMetricItem(
                  icon: Icons.access_time_rounded,
                  label: 'Estimated Stockout Window',
                  value: '14 Days',
                  valueColor: const Color(0xFFDC2626),
                  subText: 'Projected Date: Nov 28, 2027',
                ),
                const SizedBox(height: 16),

                // Metric 3: Recommended Order Quantity
                _buildDynamicsMetricItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Recommended Order Quantity',
                  value: '450 Units',
                  subText: 'Covers 30 days of demand',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildDynamicsMetricItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required String subText,
    Color? subTextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFFBF4EB),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF92400E)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subText,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: subTextColor != null ? FontWeight.w600 : FontWeight.w400,
                  color: subTextColor ?? const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Bottom Suggested Replenishment PO Details Card
  Widget _buildSuggestedReplenishmentPoCard() {
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
          Row(
            children: [
              const Icon(Icons.shopping_cart_outlined, color: Color(0xFF92400E), size: 19),
              const SizedBox(width: 10),
              Text(
                'Suggested Replenishment PO Details',
                style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 4 Parameter Tiles
          Row(
            children: [
              Expanded(
                child: _buildPoTile(
                  icon: Icons.person_outline_rounded,
                  label: 'Preferred Supplier',
                  value: 'Biella Woolen Mills',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildPoTile(
                  icon: Icons.inventory_2_outlined,
                  label: 'Optimal Quantity',
                  value: '450 Units',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildPoTile(
                  icon: Icons.payments_outlined,
                  label: 'Est. Value',
                  value: '₹6,42,000',
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildPoTile(
                  icon: Icons.local_shipping_outlined,
                  label: 'Lead Time',
                  value: '12 Days (Air Transit)',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: widget.onCreatePo ??
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Generating Draft PO for Biella Woolen Mills (450 Units)...'),
                          backgroundColor: Color(0xFF181513),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('Create Purchase Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF181513),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  textStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() => _isDismissed = true);
                },
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Dismiss Recommendation'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Footer Disclaimer
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(
                'This is an AI-generated recommendation. Please review before creating a purchase order.',
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFFFBF4EB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF92400E)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280))),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Right Sidebar: Model Insights Card
  Widget _buildModelInsightsCard() {
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
          // Header
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 18),
              const SizedBox(width: 8),
              Text(
                'Model Insights',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Model Accuracy Sub-heading
          Row(
            children: [
              const Icon(Icons.access_time_rounded, color: Color(0xFFB45309), size: 14),
              const SizedBox(width: 6),
              Text(
                'MODEL ACCURACY',
                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFFB45309), letterSpacing: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pre-Eid Predictive Model v2.4',
            style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          Text(
            'This insight uses our verified cluster learning algorithms with historical holiday purchase variables, showing a 94.2% accuracy rate in the past 12 months.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Key Drivers
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                'Key Drivers',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildDriverRow(Icons.shopping_bag_outlined, 'Historical holiday demand', '+62%'),
          const SizedBox(height: 10),
          _buildDriverRow(Icons.storefront_outlined, 'Mumbai Phoenix store velocity', '+48%'),
          const SizedBox(height: 10),
          _buildDriverRow(Icons.inventory_2_outlined, 'Low current stock', '-', isNeutral: true),
          const SizedBox(height: 10),
          _buildDriverRow(Icons.ac_unit_rounded, 'Seasonal trend (Eid)', '+55%'),
        ],
      ),
    );
  }

  Widget _buildDriverRow(IconData icon, String label, String value, {bool isNeutral = false}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFFB45309)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563))),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isNeutral ? const Color(0xFF9CA3AF) : const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  // 6. Right Sidebar: Related Warnings Card
  Widget _buildRelatedWarningsCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Related Warnings',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  ),
                ],
              ),
              InkWell(
                onTap: widget.onViewAllWarnings,
                child: Row(
                  children: [
                    Text('View All', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFB45309))),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFB45309)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Warning 1
          _buildWarningItem(
            imagePath: 'assets/black_linen_shirt.jpg',
            fallbackIcon: Icons.checkroom_rounded,
            title: 'Linen Blend Jackets (Black / L)',
            subtitle: 'Stockout risk in Soho',
            pillText: '12 Days',
            pillBg: const Color(0xFFFEE2E2),
            pillColor: const Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),

          // Warning 2
          _buildWarningItem(
            imagePath: 'assets/cashmere_sweater.jpg',
            fallbackIcon: Icons.dry_cleaning_rounded,
            title: 'Cashmere Sweater (Emerald / S)',
            subtitle: 'Stockout risk in Lucknow',
            pillText: '18 Days',
            pillBg: const Color(0xFFFEF3C7),
            pillColor: const Color(0xFFD97706),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem({
    required String imagePath,
    required IconData fallbackIcon,
    required String title,
    required String subtitle,
    required String pillText,
    required Color pillBg,
    required Color pillColor,
  }) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 38,
            height: 38,
            color: const Color(0xFF0F172A),
            child: Image.asset(
              imagePath,
              width: 38,
              height: 38,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(fallbackIcon, color: Colors.white54, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(4)),
          child: Text(
            pillText,
            style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: pillColor),
          ),
        ),
      ],
    );
  }

  // 7. Right Sidebar: AI Recommendation Card
  Widget _buildAiRecommendationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 16),
              const SizedBox(width: 8),
              Text(
                'AI Recommendation',
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Consider creating a purchase order with the recommended quantity or review similar SKUs.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280), height: 1.35),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _showSimilarProductsModal,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB45309),
                side: const BorderSide(color: Color(0xFFF59E0B)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text('View Similar Products'),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for the Projection Chart
class _ProjectionChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const leftMargin = 32.0;
    const bottomMargin = 26.0;
    const topMargin = 12.0;
    const rightMargin = 20.0;

    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomMargin;

    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final textStyle = GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF94A3B8));

    // Y Axis labels & grid lines: 0, 20, 40, 60, 80
    final yLabels = [80, 60, 40, 20, 0];
    for (int i = 0; i < yLabels.length; i++) {
      final y = topMargin + (chartHeight / (yLabels.length - 1)) * i;
      canvas.drawLine(Offset(leftMargin, y), Offset(size.width - rightMargin, y), gridPaint);

      final tp = TextPainter(
        text: TextSpan(text: '${yLabels[i]}', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftMargin - tp.width - 8, y - tp.height / 2));
    }

    // X Axis points: Today (0), In 7 Days (1), In 14 Days (2), In 21 Days (3), In 28 Days (4)
    final xLabels = ['Today', 'In 7 Days', 'In 14 Days', 'In 21 Days', 'In 28 Days'];
    final xPositions = List.generate(5, (i) => leftMargin + (chartWidth / 4) * i);

    for (int i = 0; i < xLabels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(text: xLabels[i], style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(xPositions[i] - tp.width / 2, size.height - bottomMargin + 8));
    }

    // Coordinates mapper
    double getY(double val) => topMargin + chartHeight * (1 - (val / 80.0));

    // Blue Line: Current Stock (24 -> 18 -> 2 -> 0 -> 0)
    final stockValues = [25.0, 18.0, 2.0, 0.0, 0.0];
    final stockPoints = List.generate(5, (i) => Offset(xPositions[i], getY(stockValues[i])));

    final blueAreaPath = Path()..moveTo(stockPoints[0].dx, size.height - bottomMargin);
    for (final pt in stockPoints) {
      blueAreaPath.lineTo(pt.dx, pt.dy);
    }
    blueAreaPath.lineTo(stockPoints.last.dx, size.height - bottomMargin);
    blueAreaPath.close();

    final blueAreaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF3B82F6).withOpacity(0.18), const Color(0xFF3B82F6).withOpacity(0.01)],
      ).createShader(Rect.fromLTWH(leftMargin, topMargin, chartWidth, chartHeight));
    canvas.drawPath(blueAreaPath, blueAreaPaint);

    final blueLinePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final bluePath = Path()..moveTo(stockPoints[0].dx, stockPoints[0].dy);
    for (int i = 1; i < stockPoints.length; i++) {
      bluePath.lineTo(stockPoints[i].dx, stockPoints[i].dy);
    }
    canvas.drawPath(bluePath, blueLinePaint);

    // Amber Line: Projected Demand (16 -> 20 -> 30 -> 56 -> 76)
    final demandValues = [16.0, 20.0, 30.0, 56.0, 76.0];
    final demandPoints = List.generate(5, (i) => Offset(xPositions[i], getY(demandValues[i])));

    final amberLinePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final amberPath = Path()..moveTo(demandPoints[0].dx, demandPoints[0].dy);
    for (int i = 1; i < demandPoints.length; i++) {
      amberPath.lineTo(demandPoints[i].dx, demandPoints[i].dy);
    }
    canvas.drawPath(amberPath, amberLinePaint);

    // Draw dots
    final amberDotPaint = Paint()..color = const Color(0xFFD97706);
    final blueDotPaint = Paint()..color = const Color(0xFF2563EB);
    for (final pt in demandPoints) {
      canvas.drawCircle(pt, 3.5, amberDotPaint);
    }
    for (final pt in stockPoints.take(3)) {
      canvas.drawCircle(pt, 3.5, blueDotPaint);
    }

    // Callout badge at In 14 Days intersection: "Stockout in 14 Days"
    final calloutX = xPositions[2];
    final calloutY = getY(demandValues[2]) - 28;

    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(calloutX, calloutY), width: 78, height: 32),
      const Radius.circular(6),
    );

    final badgeBgPaint = Paint()..color = const Color(0xFFFEE2E2);
    canvas.drawRRect(badgeRect, badgeBgPaint);

    final redDotPaint = Paint()..color = const Color(0xFFDC2626);
    canvas.drawCircle(Offset(calloutX, getY(demandValues[2])), 4.5, redDotPaint);

    final tpStockout = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: 'Stockout in\n', style: GoogleFonts.inter(fontSize: 8.5, color: const Color(0xFFDC2626))),
          TextSpan(text: '14 Days', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626))),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    tpStockout.paint(canvas, Offset(calloutX - tpStockout.width / 2, calloutY - tpStockout.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
