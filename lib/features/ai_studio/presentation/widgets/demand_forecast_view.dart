// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DemandForecastProductRow {
  const DemandForecastProductRow({
    required this.name,
    required this.sku,
    required this.currentStock,
    required this.forecastDemand,
    required this.incoming,
    required this.coverage,
    required this.riskLevel,
    required this.riskBg,
    required this.riskColor,
    required this.suggestedAction,
    required this.imageAsset,
  });

  final String name;
  final String sku;
  final String currentStock;
  final String forecastDemand;
  final String incoming;
  final String coverage;
  final String riskLevel;
  final Color riskBg;
  final Color riskColor;
  final String suggestedAction;
  final String imageAsset;
}

class DemandForecastView extends StatefulWidget {
  const DemandForecastView({
    super.key,
    this.onPreparePo,
    this.onViewFullForecast,
    this.onCreatePoForRow,
    this.onViewAllProducts,
  });

  final ValueChanged<String>? onPreparePo;
  final VoidCallback? onViewFullForecast;
  final ValueChanged<DemandForecastProductRow>? onCreatePoForRow;
  final VoidCallback? onViewAllProducts;

  @override
  State<DemandForecastView> createState() => _DemandForecastViewState();
}

class _DemandForecastViewState extends State<DemandForecastView> {
  int _selectedDateFilterIndex = 1; // 0: 7 Days, 1: 30 Days, 2: 60 Days, 3: 90 Days

  final List<DemandForecastProductRow> _products = const [
    DemandForecastProductRow(
      name: 'Oxford Linen Shirt',
      sku: 'TS-10432-W / M',
      currentStock: '18 units',
      forecastDemand: '120 units',
      incoming: '+150',
      coverage: '11.4 Days',
      riskLevel: 'Reorder Required',
      riskBg: Color(0xFFFEF3C7),
      riskColor: Color(0xFFB45309),
      suggestedAction: 'Create PO',
      imageAsset: 'Assets/oxford_linen_shirt.jpg',
    ),
    DemandForecastProductRow(
      name: 'Silk Evening Dress',
      sku: 'SED-16166-S',
      currentStock: '0 units',
      forecastDemand: '30 units',
      incoming: '+80',
      coverage: '0.0 Days',
      riskLevel: 'High Out-of-Stock',
      riskBg: Color(0xFFFEE2E2),
      riskColor: Color(0xFFDC2626),
      suggestedAction: 'Create PO',
      imageAsset: 'Assets/silk_evening_dress.jpg',
    ),
    DemandForecastProductRow(
      name: 'Raw Denim Jeans',
      sku: 'RDJ-22011-L',
      currentStock: '88 units',
      forecastDemand: '45 units',
      incoming: '--',
      coverage: '58.0 Days',
      riskLevel: 'Healthy Cover',
      riskBg: Color(0xFFECFDF5),
      riskColor: Color(0xFF059669),
      suggestedAction: 'Monitor',
      imageAsset: 'Assets/raw_denim_jeans.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1060;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Header, KPIs, Velocity Chart, Attention Table
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),
                      _buildKpiCards(),
                      const SizedBox(height: 18),
                      _buildVelocityChartCard(),
                      const SizedBox(height: 22),
                      _buildProductsTableCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Column: Forecast Inspector Panel
                SizedBox(
                  width: 350,
                  child: _buildForecastInspector(),
                ),
              ],
            );
          }

          // Stacked Layout for compact screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildKpiCards(),
              const SizedBox(height: 18),
              _buildVelocityChartCard(),
              const SizedBox(height: 22),
              _buildProductsTableCard(),
              const SizedBox(height: 24),
              _buildForecastInspector(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // 1. Header with Title & Date Pills
  Widget _buildHeader() {
    final dateFilters = ['7 Days', '30 Days', '60 Days', '90 Days'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Demand Forecast',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Understand future stock requirements and seasonal velocity trends.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(dateFilters.length, (idx) {
              final isSelected = _selectedDateFilterIndex == idx;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDateFilterIndex = idx;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF181513) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    dateFilters[idx],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  // 2. 3 KPI Metric Cards
  Widget _buildKpiCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 640;
        if (isSmall) {
          return Column(
            children: [
              _buildKpiCard(
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                label: 'FORECASTED SALES',
                value: '₹6,84,000',
                subtitle: 'Based on 30-day velocity',
              ),
              const SizedBox(height: 12),
              _buildKpiCard(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                label: 'RECOMMENDED ORDERS',
                value: '1,420 units',
                subtitle: 'Optimized shipping',
              ),
              const SizedBox(height: 12),
              _buildKpiCard(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEE2E2),
                label: 'HIGH RISK SKUS',
                value: '3 styles',
                subtitle: 'Urgent focus required',
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                label: 'FORECASTED SALES',
                value: '₹6,84,000',
                subtitle: 'Based on 30-day velocity',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFFD97706),
                iconBg: const Color(0xFFFEF3C7),
                label: 'RECOMMENDED ORDERS',
                value: '1,420 units',
                subtitle: 'Optimized shipping',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEE2E2),
                label: 'HIGH RISK SKUS',
                value: '3 styles',
                subtitle: 'Urgent focus required',
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
    required Color iconBg,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Velocity Tracking Chart Card
  Widget _buildVelocityChartCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Velocity Tracking — Actual vs Forecast',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              Row(
                children: [
                  _buildLegendItem(
                    shape: BoxShape.circle,
                    color: const Color(0xFF181513),
                    label: 'Actual Sales',
                  ),
                  const SizedBox(width: 14),
                  _buildLegendItem(
                    shape: BoxShape.circle,
                    color: const Color(0xFFD97706),
                    label: 'AI Forecast Model',
                  ),
                  const SizedBox(width: 14),
                  _buildLegendItem(
                    shape: BoxShape.rectangle,
                    color: const Color(0xFFFEF3C7),
                    label: 'Confidence Range',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Painted Chart
          SizedBox(
            height: 190,
            width: double.infinity,
            child: CustomPaint(
              painter: _VelocityTrackingChartPainter(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required BoxShape shape,
    required Color color,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          width: shape == BoxShape.circle ? 8 : 12,
          height: shape == BoxShape.circle ? 8 : 10,
          decoration: BoxDecoration(
            color: color,
            shape: shape,
            borderRadius: shape == BoxShape.rectangle ? BorderRadius.circular(2) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  // 4. Products Requiring Attention Table
  Widget _buildProductsTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Products Requiring Attention',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                InkWell(
                  onTap: widget.onViewAllProducts,
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Text(
                        'View All',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFFB45309)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Product',
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    'Current Stock',
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                  ),
                ),
                SizedBox(
                  width: 95,
                  child: Text(
                    'Forecast Demand',
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Incoming',
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Coverage',
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    'Risk Level',
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                  ),
                ),
                SizedBox(
                  width: 95,
                  child: Text(
                    'Suggested Action',
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(width: 24),
              ],
            ),
          ),

          // Rows
          ...List.generate(_products.length, (index) {
            final item = _products[index];
            final isLast = index == _products.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  // Product info with image
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            item.imageAsset,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 38,
                              height: 38,
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(Icons.image_outlined, size: 18, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF181513),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.sku,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Current Stock
                  SizedBox(
                    width: 90,
                    child: Text(
                      item.currentStock,
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF181513)),
                    ),
                  ),

                  // Forecast Demand
                  SizedBox(
                    width: 95,
                    child: Text(
                      item.forecastDemand,
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF181513)),
                    ),
                  ),

                  // Incoming (+150, +80, --)
                  SizedBox(
                    width: 70,
                    child: Text(
                      item.incoming,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: item.incoming.startsWith('+') ? FontWeight.w600 : FontWeight.w400,
                        color: item.incoming.startsWith('+') ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),

                  // Coverage
                  SizedBox(
                    width: 80,
                    child: Text(
                      item.coverage,
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF181513)),
                    ),
                  ),

                  // Risk Level Pill
                  SizedBox(
                    width: 120,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: item.riskBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.riskLevel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.riskColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Suggested Action Button
                  SizedBox(
                    width: 95,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () => widget.onCreatePoForRow?.call(item),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Text(
                            item.suggestedAction,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // More action ⋮
                  SizedBox(
                    width: 24,
                    child: IconButton(
                      icon: const Icon(Icons.more_vert_rounded, size: 16, color: Color(0xFF94A3B8)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 5. Right Column: Forecast Inspector Panel
  Widget _buildForecastInspector() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inspector Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Forecast Inspector',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
            ],
          ),
          const SizedBox(height: 14),

          // Hero Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'Assets/silk_evening_dress_mannequin.jpg',
              height: 175,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 175,
                width: double.infinity,
                color: const Color(0xFFE2E8F0),
                child: const Icon(Icons.image_outlined, size: 36, color: Color(0xFF94A3B8)),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title + SKU
          Text(
            'Silk Evening Dress',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'SED-16166 • Lucknow Regent',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Metadata key-value rows
          _buildInspectorRow('Historical Sell-Through', '90.0%', isBold: true),
          const SizedBox(height: 10),
          _buildInspectorRow('Projected Holiday Velocity', 'Critical Stockout', valueColor: const Color(0xFFDC2626), isBold: true),
          const SizedBox(height: 10),
          _buildInspectorRow('Seasonal Trend', '↗ +32%', valueColor: const Color(0xFFDC2626), isBold: true),
          const SizedBox(height: 10),
          _buildInspectorRow('Recommended Order', '80 units', isBold: true),
          const SizedBox(height: 10),
          _buildInspectorRow('Estimated Value', '₹1,82,000', isBold: true),
          const SizedBox(height: 10),
          _buildInspectorRow('Lead Time', '14 Days', isBold: true),
          const SizedBox(height: 16),

          // AI Insight Callout Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Insight',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This style is expected to run out in 11 days based on current velocity. Place an order of 80 units to maintain > 28 days of coverage.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary: Prepare PO (80 units)
          InkWell(
            onTap: () => widget.onPreparePo?.call('SED-16166'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF181513),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Prepare PO (80 units)',
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

          // Secondary: View Full Forecast
          InkWell(
            onTap: widget.onViewFullForecast,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              alignment: Alignment.center,
              child: Text(
                'View Full Forecast',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Related Insights
          Text(
            'Related Insights',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 10),

          // Item 1: Similar styles trending +28%
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF059669)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Similar styles trending +28%',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Item 2: Check alternate suppliers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Check alternate suppliers',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: valueColor ?? const Color(0xFF181513),
          ),
        ),
      ],
    );
  }
}

// Custom Painter for Velocity Tracking (Actual Sales vs AI Forecast & Confidence Band)
class _VelocityTrackingChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 36.0;
    const bottomPad = 24.0;
    const topPad = 8.0;
    const rightPad = 12.0;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    // Y-Axis Ticks & Gridlines
    final yTicks = [0, 50, 100, 150, 200];
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    final textStyle = GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w400,
      color: const Color(0xFF94A3B8),
    );

    for (final tick in yTicks) {
      final y = topPad + chartH - (tick / 200.0) * chartH;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);

      final textSpan = TextSpan(text: '$tick', style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(leftPad - textPainter.width - 8, y - textPainter.height / 2));
    }

    // X-Axis Dates
    final dates = ['Jan 1', 'Jan 5', 'Jan 10', 'Jan 15', 'Jan 20', 'Jan 25', 'Jan 30'];
    final xStep = chartW / (dates.length - 1);

    for (int i = 0; i < dates.length; i++) {
      final x = leftPad + i * xStep;
      final textSpan = TextSpan(text: dates[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, size.height - bottomPad + 6));
    }

    // Coordinates mapping
    double getX(int index) => leftPad + index * xStep;
    double getY(double val) => topPad + chartH - (val / 200.0) * chartH;

    // Actual Sales Points (Jan 1, Jan 5, Jan 10, Jan 15)
    final actualValues = [25.0, 75.0, 35.0, 165.0];
    final actualPoints = List.generate(
      actualValues.length,
      (i) => Offset(getX(i), getY(actualValues[i])),
    );

    // AI Forecast Model Center Points (Jan 15, Jan 20, Jan 25, Jan 30)
    final forecastValues = [165.0, 125.0, 170.0, 155.0];
    final forecastPoints = List.generate(
      forecastValues.length,
      (i) => Offset(getX(i + 3), getY(forecastValues[i])),
    );

    // Upper Confidence Band (Jan 15: 165, Jan 20: 160, Jan 25: 195, Jan 30: 185)
    final upperBand = [165.0, 160.0, 195.0, 185.0];
    // Lower Confidence Band (Jan 15: 165, Jan 20: 105, Jan 25: 145, Jan 30: 130)
    final lowerBand = [165.0, 105.0, 145.0, 130.0];

    // 1. Draw Confidence Range Filled Band
    final bandPath = Path();
    bandPath.moveTo(forecastPoints[0].dx, forecastPoints[0].dy);

    // Curve along upper band
    bandPath.cubicTo(
      getX(3) + xStep * 0.45, getY(162),
      getX(4) - xStep * 0.45, getY(upperBand[1]),
      getX(4), getY(upperBand[1]),
    );
    bandPath.cubicTo(
      getX(4) + xStep * 0.45, getY(178),
      getX(5) - xStep * 0.45, getY(upperBand[2]),
      getX(5), getY(upperBand[2]),
    );
    bandPath.cubicTo(
      getX(5) + xStep * 0.45, getY(190),
      getX(6) - xStep * 0.45, getY(upperBand[3]),
      getX(6), getY(upperBand[3]),
    );

    // Line down to lower band at Jan 30
    bandPath.lineTo(getX(6), getY(lowerBand[3]));

    // Curve back along lower band
    bandPath.cubicTo(
      getX(6) - xStep * 0.45, getY(138),
      getX(5) + xStep * 0.45, getY(lowerBand[2]),
      getX(5), getY(lowerBand[2]),
    );
    bandPath.cubicTo(
      getX(5) - xStep * 0.45, getY(125),
      getX(4) + xStep * 0.45, getY(lowerBand[1]),
      getX(4), getY(lowerBand[1]),
    );
    bandPath.cubicTo(
      getX(4) - xStep * 0.45, getY(135),
      getX(3) + xStep * 0.45, getY(lowerBand[0]),
      getX(3), getY(lowerBand[0]),
    );
    bandPath.close();

    final bandPaint = Paint()
      ..color = const Color(0xFFFEF3C7).withOpacity(0.55)
      ..style = PaintingStyle.fill;
    canvas.drawPath(bandPath, bandPaint);

    // 2. Draw Actual Sales Solid Dark Line
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

    // Draw Actual Nodes (Dots)
    final nodePaint = Paint()
      ..color = const Color(0xFF181513)
      ..style = PaintingStyle.fill;
    for (final pt in actualPoints) {
      canvas.drawCircle(pt, 3.5, nodePaint);
    }

    // 3. Draw AI Forecast Model Center Dashed Amber Line
    final forecastPath = Path();
    forecastPath.moveTo(forecastPoints[0].dx, forecastPoints[0].dy);
    forecastPath.cubicTo(
      getX(3) + xStep * 0.45, getY(145),
      getX(4) - xStep * 0.45, getY(125),
      getX(4), getY(125),
    );
    forecastPath.cubicTo(
      getX(4) + xStep * 0.45, getY(148),
      getX(5) - xStep * 0.45, getY(170),
      getX(5), getY(170),
    );
    forecastPath.cubicTo(
      getX(5) + xStep * 0.45, getY(162),
      getX(6) - xStep * 0.45, getY(155),
      getX(6), getY(155),
    );

    // Draw dashed path
    _drawDashedPath(
      canvas,
      forecastPath,
      Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke,
      dashWidth: 4.0,
      dashSpace: 3.5,
    );

    // Draw Amber Node at Jan 20
    final amberNodePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(getX(4), getY(125)), 3.5, amberNodePaint);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dashWidth,
    required double dashSpace,
  }) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final extractPath = metric.extractPath(distance, distance + length);
        canvas.drawPath(extractPath, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
