// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationComparisonView extends StatefulWidget {
  final VoidCallback? onNavigateToTransfers;
  final VoidCallback? onNavigateToInventory;

  const LocationComparisonView({
    super.key,
    this.onNavigateToTransfers,
    this.onNavigateToInventory,
  });

  @override
  State<LocationComparisonView> createState() => _LocationComparisonViewState();
}

class _LocationComparisonViewState extends State<LocationComparisonView> {
  String _selectedPeriod = 'Past 30 Days: Oct 1 - Oct 31';
  String _selectedFrequency = 'Monthly';
  String _selectedMetric = 'Revenue';

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
        // 1. Page Header (Title + Subtitle on Left, Date Selector on Right)
        _buildHeader(),
        const SizedBox(height: 20),

        // 2. 4 Location Cards (Grid / Row)
        _buildLocationCardsGrid(),
        const SizedBox(height: 20),

        // 3. Middle Section: Revenue Trend Comparison Card
        _buildRevenueTrendComparisonCard(),
        const SizedBox(height: 20),

        // 4. Bottom Section: Performance Matrix (Left) & AI Transfer Opportunities (Right)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1020;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 58,
                    child: _buildPerformanceMatrixCard(),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 42,
                    child: _buildAiTransferOpportunitiesCard(),
                  ),
                ],
              );
            }
            return Column(
              children: [
                _buildPerformanceMatrixCard(),
                const SizedBox(height: 20),
                _buildAiTransferOpportunitiesCard(),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ===========================================================================
  // 1. HEADER ROW
  // ===========================================================================
  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 750;

        final leftContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Comparison',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181512),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Compare performance across your locations to identify opportunities and drive growth.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B6358),
              ),
            ),
          ],
        );

        final rightContent = PopupMenuButton<String>(
          tooltip: 'Select date range',
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
            'Past 30 Days: Oct 1 - Oct 31',
            'Past 7 Days',
            'This Quarter (Q4)',
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
  // 2. 4 LOCATION CARDS GRID
  // ===========================================================================
  Widget _buildLocationCardsGrid() {
    final locations = const [
      _LocationCardData(
        title: 'Central Warehouse',
        isPrimary: true,
        imageAsset: 'Assets/warehouse_building.jpg',
        revenue: '₹24.8L',
        revenueGrowth: '↑ 12%',
        isRevenuePositive: true,
        unitsSold: '4,200',
        unitsGrowth: '↑ 8%',
        isUnitsPositive: true,
        avgMargin: '64.2%',
        stockValue: '₹82.5L',
      ),
      _LocationCardData(
        title: 'MG Road Flagship',
        isPrimary: false,
        imageAsset: 'Assets/central_store.jpg',
        revenue: '₹12.6L',
        revenueGrowth: '↑ 6%',
        isRevenuePositive: true,
        unitsSold: '2,150',
        unitsGrowth: '↑ 3%',
        isUnitsPositive: true,
        avgMargin: '68.5%',
        stockValue: '₹18.4L',
      ),
      _LocationCardData(
        title: 'Indiranagar',
        isPrimary: false,
        imageAsset: 'Assets/central_store.jpg',
        revenue: '₹8.4L',
        revenueGrowth: '↑ 18%',
        isRevenuePositive: true,
        unitsSold: '1,400',
        unitsGrowth: '↑ 11%',
        isUnitsPositive: true,
        avgMargin: '66.1%',
        stockValue: '₹12.2L',
      ),
      _LocationCardData(
        title: 'Koramangala',
        isPrimary: false,
        imageAsset: 'Assets/central_store.jpg',
        revenue: '₹6.1L',
        revenueGrowth: '↓ 4%',
        isRevenuePositive: false,
        unitsSold: '980',
        unitsGrowth: '↓ 6%',
        isUnitsPositive: false,
        avgMargin: '61.4%',
        stockValue: '₹9.8L',
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
            children: locations
                .map(
                  (loc) => SizedBox(
                    width: (constraints.maxWidth - cardSpacing) / 2,
                    child: _buildLocationCard(loc),
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: locations
              .asMap()
              .entries
              .map(
                (entry) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: entry.key == 0 ? 0 : cardSpacing / 2,
                      right: entry.key == locations.length - 1
                          ? 0
                          : cardSpacing / 2,
                    ),
                    child: _buildLocationCard(entry.value),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildLocationCard(_LocationCardData data) {
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
          // Header: Location Thumbnail + Name + Primary Badge
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  width: 36,
                  height: 36,
                  color: const Color(0xFFF4ECE2),
                  child: Image.asset(
                    data.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.storefront_outlined,
                      size: 18,
                      color: Color(0xFF8B6B46),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            data.title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181512),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (data.isPrimary) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7F7ED),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Primary',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E7E34),
                              ),
                            ),
                          ),
                        ],
                      ],
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
              // Left Column: Revenue & Avg Margin
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue',
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
                          data.revenue,
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
                            color: data.isRevenuePositive
                                ? const Color(0xFFE7F7ED)
                                : const Color(0xFFFDECEB),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            data.revenueGrowth,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: data.isRevenuePositive
                                  ? const Color(0xFF1E7E34)
                                  : const Color(0xFFD9534F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Avg Margin',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7E7569),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.avgMargin,
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

              // Right Column: Units Sold & Stock Value
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Units Sold',
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
                          data.unitsSold,
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
                            color: data.isUnitsPositive
                                ? const Color(0xFFE7F7ED)
                                : const Color(0xFFFDECEB),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            data.unitsGrowth,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: data.isUnitsPositive
                                  ? const Color(0xFF1E7E34)
                                  : const Color(0xFFD9534F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Stock Value',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7E7569),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.stockValue,
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
  // 3. REVENUE TREND COMPARISON CARD
  // ===========================================================================
  Widget _buildRevenueTrendComparisonCard() {
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
          // Header: Title & Dropdown controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue Trend Comparison',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181512),
                ),
              ),
              Row(
                children: [
                  // Frequency Dropdown
                  PopupMenuButton<String>(
                    tooltip: 'Frequency',
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Color(0xFFEADBCA)),
                    ),
                    onSelected: (val) {
                      setState(() => _selectedFrequency = val);
                      _showFeedback('Frequency changed to $val');
                    },
                    itemBuilder: (context) => ['Daily', 'Weekly', 'Monthly']
                        .map(
                          (f) => PopupMenuItem(
                            value: f,
                            height: 34,
                            child: Text(
                              f,
                              style: GoogleFonts.inter(fontSize: 12.5),
                            ),
                          ),
                        )
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFDFD4C5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedFrequency,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF181512),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: Color(0xFF8A8275),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Metric Dropdown
                  PopupMenuButton<String>(
                    tooltip: 'Metric',
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: const BorderSide(color: Color(0xFFEADBCA)),
                    ),
                    onSelected: (val) {
                      setState(() => _selectedMetric = val);
                      _showFeedback('Metric changed to $val');
                    },
                    itemBuilder: (context) =>
                        ['Revenue', 'Units Sold', 'Gross Profit']
                            .map(
                              (m) => PopupMenuItem(
                                value: m,
                                height: 34,
                                child: Text(
                                  m,
                                  style: GoogleFonts.inter(fontSize: 12.5),
                                ),
                              ),
                            )
                            .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFDFD4C5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedMetric,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF181512),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: Color(0xFF8A8275),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: const [
              _LegendItem(label: 'Central Warehouse', color: Color(0xFF3B82F6)),
              _LegendItem(label: 'MG Road Flagship', color: Color(0xFFC89748)),
              _LegendItem(label: 'Indiranagar', color: Color(0xFF10B981)),
              _LegendItem(label: 'Koramangala', color: Color(0xFFEF4444)),
            ],
          ),
          const SizedBox(height: 16),

          // Custom 4-Line Area Chart
          SizedBox(
            height: 200,
            child: _MultiLocationTrendChart(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4A. PERFORMANCE MATRIX CARD (GROWTH VS MARGIN)
  // ===========================================================================
  Widget _buildPerformanceMatrixCard() {
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
            'Performance Matrix (Growth vs Margin)',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181512),
            ),
          ),
          const SizedBox(height: 16),

          // 4-Quadrant Scatter Matrix with labels & axes
          SizedBox(
            height: 215,
            child: _PerformanceMatrixChart(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4B. AI TRANSFER OPPORTUNITIES CARD
  // ===========================================================================
  Widget _buildAiTransferOpportunitiesCard() {
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
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Color(0xFF9B6E39),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Transfer Opportunities',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181512),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  _showFeedback('Viewing all AI inventory transfer recommendations...');
                },
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7C4E1F),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Item 1: Oxford Linen Shirt (Black/M)
          _buildTransferItem(
            imageAsset: 'Assets/black_linen_shirt.jpg',
            title: 'Oxford Linen Shirt (Black/M)',
            route: 'Central Warehouse → MG Road Flagship',
            reason: 'Reason: Delhi surge 42%',
            onTransfer: () => _showFeedback(
                'Initiating transfer: Oxford Linen Shirt to MG Road Flagship'),
          ),
          const SizedBox(height: 10),

          // Item 2: Merino Wool Blazer (Navy/L)
          _buildTransferItem(
            imageAsset: 'Assets/merino_wool_blazer.jpg',
            title: 'Merino Wool Blazer (Navy/L)',
            route: 'Central Warehouse → Indiranagar',
            reason: 'Reason: Low stock alert',
            onTransfer: () => _showFeedback(
                'Initiating transfer: Merino Wool Blazer to Indiranagar'),
          ),
          const SizedBox(height: 14),

          // AI Insight Callout Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF2E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 14,
                    color: Color(0xFF9B6E39),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Insight',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181512),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rebalance stock across locations to reduce lost sales by an estimated 12%.',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B6358),
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

  Widget _buildTransferItem({
    required String imageAsset,
    required String title,
    required String route,
    required String reason,
    required VoidCallback onTransfer,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF8F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEFE7DC)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 36,
              height: 36,
              color: const Color(0xFFEADBCA),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.checkroom_rounded,
                  size: 18,
                  color: Color(0xFF8B6B46),
                ),
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
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181512),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  route,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6358),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  reason,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF946A36),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onTransfer,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFC89748),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Create Transfer',
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
    );
  }
}

// Data models
class _LocationCardData {
  final String title;
  final bool isPrimary;
  final String imageAsset;
  final String revenue;
  final String revenueGrowth;
  final bool isRevenuePositive;
  final String unitsSold;
  final String unitsGrowth;
  final bool isUnitsPositive;
  final String avgMargin;
  final String stockValue;

  const _LocationCardData({
    required this.title,
    required this.isPrimary,
    required this.imageAsset,
    required this.revenue,
    required this.revenueGrowth,
    required this.isRevenuePositive,
    required this.unitsSold,
    required this.unitsGrowth,
    required this.isUnitsPositive,
    required this.avgMargin,
    required this.stockValue,
  });
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

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
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5A5348),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// MULTI-LOCATION TREND CHART (4 LINES WITH GRADIENT & DOTS)
// =============================================================================
class _MultiLocationTrendChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final xLabels = [
          'Oct 1',
          'Oct 5',
          'Oct 10',
          'Oct 15',
          'Oct 20',
          'Oct 25',
          'Oct 31'
        ];
        final yLabels = ['25L', '20L', '15L', '10L', '5L', '0'];

        const leftGutter = 34.0;
        const bottomGutter = 24.0;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: yLabels
                    .map((label) => Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF9E958A),
                          ),
                        ))
                    .toList(),
              ),
            ),

            // Canvas for lines, fills and nodes
            Positioned(
              left: leftGutter,
              top: 0,
              width: plotWidth,
              height: plotHeight,
              child: CustomPaint(
                size: Size(plotWidth, plotHeight),
                painter: _MultiLinePainter(),
              ),
            ),

            // X Axis Ticks
            Positioned(
              left: leftGutter,
              bottom: 0,
              width: plotWidth,
              height: bottomGutter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: xLabels
                    .map((label) => Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF9E958A),
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

class _MultiLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid lines (6 lines for 25L, 20L, 15L, 10L, 5L, 0)
    final gridPaint = Paint()
      ..color = const Color(0xFFF1EAE0)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 6; i++) {
      final y = size.height * (i / 5.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Series definitions (out of 25.0)
    final cwPoints = [10.5, 14.8, 22.4, 17.5, 12.8, 16.5, 22.0];
    final mgPoints = [5.2, 7.8, 12.6, 10.4, 7.8, 10.2, 12.6];
    final indPoints = [2.1, 3.2, 7.4, 6.1, 4.8, 6.0, 6.2];
    final korPoints = [1.2, 2.1, 3.8, 3.2, 2.4, 3.1, 3.0];

    final numPoints = cwPoints.length;
    final stepX = size.width / (numPoints - 1);

    List<Offset> toOffsets(List<double> data) {
      List<Offset> list = [];
      for (int i = 0; i < numPoints; i++) {
        final x = i * stepX;
        final y = size.height - (data[i] / 25.0) * size.height;
        list.add(Offset(x, y));
      }
      return list;
    }

    final cwOffsets = toOffsets(cwPoints);
    final mgOffsets = toOffsets(mgPoints);
    final indOffsets = toOffsets(indPoints);
    final korOffsets = toOffsets(korPoints);

    Path buildSmoothPath(List<Offset> points) {
      final path = Path();
      if (points.isEmpty) return path;
      path.moveTo(points[0].dx, points[0].dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX1 = p0.dx + (p1.dx - p0.dx) / 2.0;
        final controlY1 = p0.dy;
        final controlX2 = p0.dx + (p1.dx - p0.dx) / 2.0;
        final controlY2 = p1.dy;
        path.cubicTo(controlX1, controlY1, controlX2, controlY2, p1.dx, p1.dy);
      }
      return path;
    }

    void drawSeries(
      List<Offset> points,
      Color color, {
      bool drawFill = false,
    }) {
      final path = buildSmoothPath(points);

      if (drawFill) {
        final fillPath = Path.from(path)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();

        final fillPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withOpacity(0.12),
              color.withOpacity(0.0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
          ..style = PaintingStyle.fill;

        canvas.drawPath(fillPath, fillPaint);
      }

      // Draw stroke
      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(path, strokePaint);

      // Draw node dots on points
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      final innerWhitePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      for (final p in points) {
        canvas.drawCircle(p, 3.2, dotPaint);
        canvas.drawCircle(p, 1.2, innerWhitePaint);
      }
    }

    // Draw in ascending order so top line sits on top
    drawSeries(korOffsets, const Color(0xFFEF4444), drawFill: true);
    drawSeries(indOffsets, const Color(0xFF10B981), drawFill: true);
    drawSeries(mgOffsets, const Color(0xFFC89748), drawFill: true);
    drawSeries(cwOffsets, const Color(0xFF3B82F6), drawFill: true);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// PERFORMANCE MATRIX (GROWTH VS MARGIN) QUADRANT CHART
// =============================================================================
class _PerformanceMatrixChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        const leftGutter = 42.0;
        const bottomGutter = 24.0;

        final plotWidth = width - leftGutter;
        final plotHeight = height - bottomGutter;

        final yTicks = ['80%', '60%', '40%', '20%', '0%'];
        final xTicks = ['-20%', '-10%', '0%', '10%', '20%'];

        return Stack(
          children: [
            // Rotated "Margin %" label on Y axis
            Positioned(
              left: 0,
              top: plotHeight / 2 - 24,
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  'Margin %',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9E958A),
                  ),
                ),
              ),
            ),

            // Y Ticks
            Positioned(
              left: 12,
              top: 0,
              width: leftGutter - 16,
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

            // Main Plot Area (Quadrants, dashed axes, dots, labels)
            Positioned(
              left: leftGutter,
              top: 0,
              width: plotWidth,
              height: plotHeight,
              child: Stack(
                children: [
                  // Quadrant labels
                  Positioned(
                    left: 10,
                    top: 8,
                    child: Text(
                      'High Margin / Low Growth',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB5ACA0),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 8,
                    child: Text(
                      'High Margin / High Growth',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB5ACA0),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 8,
                    child: Text(
                      'Low Margin / Low Growth',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB5ACA0),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 8,
                    child: Text(
                      'Low Margin / High Growth',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB5ACA0),
                      ),
                    ),
                  ),

                  // Custom Paint for border, grid & dashed axes
                  CustomPaint(
                    size: Size(plotWidth, plotHeight),
                    painter: _MatrixAxesPainter(),
                  ),

                  // Plotted Points
                  // 1. CW: Growth ~ -9%, Margin ~ 64%
                  _buildPlottedPoint(
                    plotWidth: plotWidth,
                    plotHeight: plotHeight,
                    growthPct: -9,
                    marginPct: 64,
                    label: 'CW',
                    color: const Color(0xFF3B82F6),
                  ),

                  // 2. MG Road: Growth ~ +8%, Margin ~ 68%
                  _buildPlottedPoint(
                    plotWidth: plotWidth,
                    plotHeight: plotHeight,
                    growthPct: 8,
                    marginPct: 68,
                    label: 'MG Road',
                    color: const Color(0xFFC89748),
                  ),

                  // 3. Indiranagar: Growth ~ +6%, Margin ~ 51%
                  _buildPlottedPoint(
                    plotWidth: plotWidth,
                    plotHeight: plotHeight,
                    growthPct: 5.5,
                    marginPct: 51,
                    label: 'Indiranagar',
                    color: const Color(0xFF10B981),
                  ),

                  // 4. Koramangala: Growth ~ -10%, Margin ~ 28%
                  _buildPlottedPoint(
                    plotWidth: plotWidth,
                    plotHeight: plotHeight,
                    growthPct: -10,
                    marginPct: 28,
                    label: 'Koramangala',
                    color: const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),

            // X Axis Ticks & Label
            Positioned(
              left: leftGutter,
              bottom: 0,
              width: plotWidth,
              height: bottomGutter,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: xTicks
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
                  const SizedBox(height: 1),
                  Text(
                    'Revenue Growth %',
                    style: GoogleFonts.inter(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9E958A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlottedPoint({
    required double plotWidth,
    required double plotHeight,
    required double growthPct, // range -20 to +20
    required double marginPct, // range 0 to 80
    required String label,
    required Color color,
  }) {
    // Map -20..+20 to 0..plotWidth
    final x = ((growthPct - (-20)) / 40.0) * plotWidth;
    // Map 0..80 to plotHeight..0
    final y = plotHeight - (marginPct / 80.0) * plotHeight;

    return Positioned(
      left: x - 6,
      top: y - 6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181512),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatrixAxesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Border around plot area
    final borderPaint = Paint()
      ..color = const Color(0xFFEADBCA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    // Dashed center axes:
    // Vertical axis at X = 0% -> midway (size.width * 0.5)
    final vX = size.width * 0.5;
    // Horizontal axis at Y = 40% -> midway (size.height * 0.5)
    final hY = size.height * 0.5;

    final dashPaint = Paint()
      ..color = const Color(0xFFDCCFBE)
      ..strokeWidth = 1.2;

    void drawDashedLine(Offset start, Offset end) {
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final distance = (dx != 0 ? dx : dy).abs();
      const dashLength = 4.0;
      const spaceLength = 3.0;
      double current = 0;

      while (current < distance) {
        final currentEnd = (current + dashLength).clamp(0.0, distance);
        final p1 = dx != 0
            ? Offset(start.dx + current, start.dy)
            : Offset(start.dx, start.dy + current);
        final p2 = dx != 0
            ? Offset(start.dx + currentEnd, start.dy)
            : Offset(start.dx, start.dy + currentEnd);
        canvas.drawLine(p1, p2, dashPaint);
        current += dashLength + spaceLength;
      }
    }

    drawDashedLine(Offset(vX, 0), Offset(vX, size.height));
    drawDashedLine(Offset(0, hY), Offset(size.width, hY));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
