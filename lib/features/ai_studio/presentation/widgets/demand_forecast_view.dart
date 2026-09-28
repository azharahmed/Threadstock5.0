// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/demand_forecast_repository.dart';

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
    this.imageAsset,
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
  final String? imageAsset;
}

class DemandForecastView extends StatefulWidget {
  const DemandForecastView({
    super.key,
    this.locationId,
    this.onPreparePo,
    this.onViewFullForecast,
    this.onCreatePoForRow,
    this.onViewAllProducts,
  });

  final String? locationId;
  final ValueChanged<String>? onPreparePo;
  final VoidCallback? onViewFullForecast;
  final ValueChanged<DemandForecastProductRow>? onCreatePoForRow;
  final VoidCallback? onViewAllProducts;

  @override
  State<DemandForecastView> createState() => _DemandForecastViewState();
}

class _DemandForecastViewState extends State<DemandForecastView> {
  int _selectedDateFilterIndex =
      1; // 0: 7 Days, 1: 30 Days, 2: 60 Days, 3: 90 Days
  bool _isLoading = true;
  DemandForecastSummary? _summary;
  final DemandForecastRepository _repository = DemandForecastRepository();

  @override
  void initState() {
    super.initState();
    _loadForecastData();
  }

  @override
  void didUpdateWidget(covariant DemandForecastView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationId != widget.locationId) {
      _loadForecastData();
    }
  }

  Future<void> _loadForecastData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }
    final summary = await _repository.loadDemandForecast(
      locationId: widget.locationId,
    );
    if (mounted) {
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBA8A55)),
          ),
        ),
      );
    }

    final isReady = _summary?.isReady ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1060;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Header, Readiness Banner, KPIs, Velocity Chart, Attention Table
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      if (!isReady) ...[
                        const SizedBox(height: 18),
                        _buildReadinessBanner(),
                      ],
                      const SizedBox(height: 18),
                      _buildKpiCards(isReady),
                      const SizedBox(height: 18),
                      _buildVelocityChartCard(isReady),
                      const SizedBox(height: 22),
                      _buildProductsTableCard(isReady),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Column: Forecast Inspector Panel
                SizedBox(width: 350, child: _buildForecastInspector(isReady)),
              ],
            );
          }

          // Stacked Layout for compact screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (!isReady) ...[
                const SizedBox(height: 18),
                _buildReadinessBanner(),
              ],
              const SizedBox(height: 18),
              _buildKpiCards(isReady),
              const SizedBox(height: 18),
              _buildVelocityChartCard(isReady),
              const SizedBox(height: 22),
              _buildProductsTableCard(isReady),
              const SizedBox(height: 24),
              _buildForecastInspector(isReady),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 1. Header with Title & Date Range Pills
  // ===========================================================================
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF181513)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    dateFilters[idx],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
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

  // ===========================================================================
  // 1b. Readiness & Insufficient Data State Banner
  // ===========================================================================
  Widget _buildReadinessBanner() {
    final conditions = _summary?.readinessConditions ?? [];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEADBCE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.hourglass_empty_rounded,
                  size: 18,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Not enough data yet',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ThreadStock AI will build demand forecasts once there is enough sales and inventory history to identify reliable trends.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (conditions.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1ECE4), height: 1),
            const SizedBox(height: 14),
            Text(
              'FORECAST READINESS CHECKLIST',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: const Color(0xFF8C827A),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: conditions.map((c) => _buildConditionPill(c)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionPill(ForecastReadinessCondition condition) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              condition.isMet
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 16,
              color: condition.isMet
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  condition.title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: condition.isMet
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: condition.isMet
                        ? const Color(0xFF1E293B)
                        : const Color(0xFF64748B),
                  ),
                ),
                if (condition.details.isNotEmpty)
                  Text(
                    '(${condition.details})',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: condition.isMet
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
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
  // 2. 3 Summary Metric KPI Cards
  // ===========================================================================
  Widget _buildKpiCards(bool isReady) {
    final forecastedSales = isReady ? (_summary?.forecastedSales ?? '—') : '—';
    final recommendedOrders = isReady
        ? (_summary?.recommendedOrders ?? '—')
        : '—';
    final highRiskSkus = isReady ? (_summary?.highRiskSkus ?? '—') : '—';

    final subtitle = isReady
        ? 'Based on real velocity'
        : 'Awaiting sufficient history';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 640;
        if (isSmall) {
          return Column(
            children: [
              _buildKpiCard(
                icon: Icons.bar_chart_rounded,
                iconColor: const Color(0xFF94A3B8),
                iconBg: const Color(0xFFF1F5F9),
                label: 'FORECASTED SALES',
                value: forecastedSales,
                subtitle: subtitle,
              ),
              const SizedBox(height: 12),
              _buildKpiCard(
                icon: Icons.inventory_2_outlined,
                iconColor: const Color(0xFF94A3B8),
                iconBg: const Color(0xFFF1F5F9),
                label: 'RECOMMENDED ORDERS',
                value: recommendedOrders,
                subtitle: subtitle,
              ),
              const SizedBox(height: 12),
              _buildKpiCard(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFF94A3B8),
                iconBg: const Color(0xFFF1F5F9),
                label: 'HIGH RISK SKUS',
                value: highRiskSkus,
                subtitle: subtitle,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildKpiCard(
                icon: Icons.bar_chart_rounded,
                iconColor: isReady
                    ? const Color(0xFFD97706)
                    : const Color(0xFF94A3B8),
                iconBg: isReady
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFF1F5F9),
                label: 'FORECASTED SALES',
                value: forecastedSales,
                subtitle: subtitle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.inventory_2_outlined,
                iconColor: isReady
                    ? const Color(0xFFD97706)
                    : const Color(0xFF94A3B8),
                iconBg: isReady
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFF1F5F9),
                label: 'RECOMMENDED ORDERS',
                value: recommendedOrders,
                subtitle: subtitle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildKpiCard(
                icon: Icons.warning_amber_rounded,
                iconColor: isReady
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF94A3B8),
                iconBg: isReady
                    ? const Color(0xFFFEE2E2)
                    : const Color(0xFFF1F5F9),
                label: 'HIGH RISK SKUS',
                value: highRiskSkus,
                subtitle: subtitle,
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
                        color: value == '—'
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF181513),
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

  // ===========================================================================
  // 3. Velocity Tracking Chart Card
  // ===========================================================================
  Widget _buildVelocityChartCard(bool isReady) {
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem(
                    shape: BoxShape.circle,
                    color: isReady
                        ? const Color(0xFF181513)
                        : const Color(0xFFCBD5E1),
                    label: 'Actual Sales',
                  ),
                  const SizedBox(width: 14),
                  _buildLegendItem(
                    shape: BoxShape.circle,
                    color: isReady
                        ? const Color(0xFFD97706)
                        : const Color(0xFFE2E8F0),
                    label: 'AI Forecast Model',
                  ),
                  const SizedBox(width: 14),
                  _buildLegendItem(
                    shape: BoxShape.rectangle,
                    color: isReady
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF1F5F9),
                    label: 'Confidence Range',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Real empty state if not ready / insufficient history
          Container(
            height: 190,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_graph_outlined,
                  size: 32,
                  color: Color(0xFFCBD5E1),
                ),
                const SizedBox(height: 10),
                Text(
                  'No forecast available yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Historical sales over at least 14 days are required to generate velocity predictions.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
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
            borderRadius: shape == BoxShape.rectangle
                ? BorderRadius.circular(2)
                : null,
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

  // ===========================================================================
  // 4. Products Requiring Attention Table
  // ===========================================================================
  Widget _buildProductsTableCard(bool isReady) {
    final products = _summary?.productsRequiringAttention ?? [];
    final trackedCount = _summary?.productsCount ?? 0;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Products Requiring Attention',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$trackedCount tracked',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
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
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFFB45309),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // Empty state when no real AI recommendations exist
          if (products.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 32,
                    color: Color(0xFFCBD5E1),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No AI recommendations yet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Products will be flagged here for reorder or overstock risk once sufficient sales velocity has been established.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else ...[
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
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      'Current Stock',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 95,
                    child: Text(
                      'Forecast Demand',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      'Incoming',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'Coverage',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Risk Level',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 95,
                    child: Text(
                      'Suggested Action',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            // Real products rows
            ...List.generate(products.length, (index) {
              final item = products[index];
              final isLast = index == products.length - 1;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : const Border(
                          bottom: BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
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
                    SizedBox(
                      width: 90,
                      child: Text(
                        item.currentStock,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF181513),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 95,
                      child: Text(
                        item.forecastDemand,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF181513),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text(
                        item.incoming,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text(
                        item.coverage,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF181513),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
                    SizedBox(
                      width: 95,
                      child: InkWell(
                        onTap: () => widget.onCreatePoForRow?.call(item),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
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
                    const SizedBox(width: 24),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. Right Column: Forecast Inspector Panel
  // ===========================================================================
  Widget _buildForecastInspector(bool isReady) {
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
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Clean empty state when no forecast is selected or exists
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.analytics_outlined,
                    size: 22,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select a forecast to inspect',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Forecast details will appear here once enough data is available.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFFB45309),
                ),
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
                        'No AI insight available yet.',
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

          // Prepare PO CTA (disabled when no recommendation exists)
          Container(
            width: double.infinity,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.shopping_cart_outlined,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                Text(
                  'Prepare PO',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Requires active replenishment recommendation',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Secondary Action: View Full Forecast
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
        ],
      ),
    );
  }
}
