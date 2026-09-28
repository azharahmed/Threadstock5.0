// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfitabilityAnalysisView extends StatefulWidget {
  final VoidCallback? onNavigateToAutomations;
  final VoidCallback? onNavigateToInventory;

  const ProfitabilityAnalysisView({
    super.key,
    this.onNavigateToAutomations,
    this.onNavigateToInventory,
  });

  @override
  State<ProfitabilityAnalysisView> createState() =>
      _ProfitabilityAnalysisViewState();
}

class _ProfitabilityAnalysisViewState extends State<ProfitabilityAnalysisView> {
  String _selectedPeriod = 'Past 30 Days: Oct 1 - Oct 31';
  String _selectedFrequency = 'Weekly';

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
        // 1. Page Header (Title + Subtitle on Left, Italic Quote + Date Picker on Right)
        _buildHeader(),
        const SizedBox(height: 18),

        // 2. AI Recommendation Highlight Card
        _buildAiRecommendationBanner(),
        const SizedBox(height: 20),

        // 3. 5 KPI Metric Summary Cards
        _buildKpiMetricsRow(),
        const SizedBox(height: 20),

        // 4. Middle Charts Section: Revenue vs COGS Over Time (Left) & Margin by Category (Right)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1020;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 62, child: _buildRevenueVsCogsChartCard()),
                  const SizedBox(width: 20),
                  Expanded(flex: 38, child: _buildMarginByCategoryCard()),
                ],
              );
            }
            return Column(
              children: [
                _buildRevenueVsCogsChartCard(),
                const SizedBox(height: 20),
                _buildMarginByCategoryCard(),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // 5. Product Profitability Table
        _buildProductProfitabilityTableCard(),
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
        final isCompact = constraints.maxWidth < 800;

        final leftContent = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profitability Analysis',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 34,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181512),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Understand what drives your profit and make smarter inventory and sourcing decisions.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B6358),
              ),
            ),
          ],
        );

        final rightContent = Column(
          crossAxisAlignment: isCompact
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            Text(
              'Smarter insights. Stronger growth.',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8B6B46),
              ),
            ),
            const SizedBox(height: 8),
            PopupMenuButton<String>(
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
              itemBuilder: (context) =>
                  [
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
            ),
          ],
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
  // 2. AI RECOMMENDATION BANNER
  // ===========================================================================
  Widget _buildAiRecommendationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
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
          // Sparkle Icon Badge
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

          // Message
          Expanded(
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF2A2621),
                ),
                children: [
                  TextSpan(
                    text: 'AI Recommendation: ',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF7C4E1F),
                    ),
                  ),
                  const TextSpan(
                    text:
                        'Silk Scarves margin dropped 8% — supplier cost increase detected. Advise negotiation or switching to alternative supplier.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),

          // View Details Button
          InkWell(
            onTap: () => _showFeedback(
              'Opening AI Supplier Margin Analysis & Negotiation Insights...',
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
                    'View Details',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
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

  // ===========================================================================
  // 3. 5 KPI METRICS ROW
  // ===========================================================================
  Widget _buildKpiMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        final cardSpacing = 12.0;

        final cards = [
          _buildKpiCard(
            label: 'Gross Profit',
            value: '₹8,20,000',
            badgeText: '↑ 14%',
            isPositive: true,
            icon: Icons.toll_outlined,
            subtitle: 'vs previous period',
          ),
          _buildKpiCard(
            label: 'Revenue',
            value: '₹12,40,000',
            badgeText: '↑ 8%',
            isPositive: true,
            icon: Icons.bar_chart_rounded,
            subtitle: 'vs previous period',
          ),
          _buildKpiCard(
            label: 'COGS',
            value: '₹4,20,000',
            badgeText: '↓ 2%',
            isPositive: false,
            icon: Icons.inventory_2_outlined,
            subtitle: 'vs previous period',
          ),
          _buildKpiCard(
            label: 'Margin %',
            value: '66.1%',
            badgeText: '↑ 1.4%',
            isPositive: true,
            icon: Icons.pie_chart_outline_rounded,
            subtitle: 'vs previous period',
          ),
          _buildKpiCard(
            label: 'Avg Markup',
            value: '2.1x',
            badgeText: 'Optimal',
            isPositive: true,
            icon: Icons.local_offer_outlined,
            subtitle: null,
          ),
        ];

        if (isCompact) {
          return Wrap(
            spacing: cardSpacing,
            runSpacing: cardSpacing,
            children: cards
                .map(
                  (c) => SizedBox(
                    width: (constraints.maxWidth - cardSpacing) / 2,
                    child: c,
                  ),
                )
                .toList(),
          );
        }

        return Row(
          children: cards
              .asMap()
              .entries
              .map(
                (entry) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: entry.key == 0 ? 0 : cardSpacing / 2,
                      right: entry.key == cards.length - 1
                          ? 0
                          : cardSpacing / 2,
                    ),
                    child: entry.value,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String badgeText,
    required bool isPositive,
    required IconData icon,
    required String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon badge in warm beige square
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF4EB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Icon(icon, size: 17, color: const Color(0xFF9B6E39)),
          ),
          const SizedBox(width: 12),

          // Label, Value & Trend Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7E7569),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181512),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? const Color(0xFFE7F7ED)
                            : const Color(0xFFFDECEB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isPositive
                              ? const Color(0xFF1E7E34)
                              : const Color(0xFFD9534F),
                        ),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9E958A),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4A. LEFT CHART: REVENUE VS COGS OVER TIME
  // ===========================================================================
  Widget _buildRevenueVsCogsChartCard() {
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
          // Header: Title & Weekly Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue vs COGS Over Time',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181512),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Aggregation frequency',
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
                    horizontal: 8,
                    vertical: 4,
                  ),
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
            ],
          ),
          const SizedBox(height: 8),

          // Legend: Blue dot Revenue, Gold dot COGS
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Revenue',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5A5348),
                ),
              ),
              const SizedBox(width: 18),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFC89748),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'COGS',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5A5348),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Custom Painted Smooth Dual-Curve Area Chart
          SizedBox(height: 200, child: _DualAreaLineChart()),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4B. RIGHT CARD: MARGIN BY CATEGORY
  // ===========================================================================
  Widget _buildMarginByCategoryCard() {
    final categories = const [
      _CategoryMarginItem('Silk Shirts', 0.74, Color(0xFFC89748)),
      _CategoryMarginItem('Linen Blazers', 0.68, Color(0xFF3B82F6)),
      _CategoryMarginItem('Trousers', 0.62, Color(0xFF475569)),
      _CategoryMarginItem('Accessories', 0.45, Color(0xFF94A3B8)),
      _CategoryMarginItem('Silk Scarves', 0.38, Color(0xFFEF4444)),
    ];

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
            'Margin by Category',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181512),
            ),
          ),
          const SizedBox(height: 18),
          Column(
            children: categories
                .map(
                  (cat) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat.name,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2E2A24),
                              ),
                            ),
                            Text(
                              '${(cat.ratio * 100).toInt()}%',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF181512),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            children: [
                              Container(
                                height: 8,
                                color: const Color(0xFFF3ECE4),
                              ),
                              FractionallySizedBox(
                                widthFactor: cat.ratio,
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: cat.color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. BOTTOM TABLE: PRODUCT PROFITABILITY
  // ===========================================================================
  Widget _buildProductProfitabilityTableCard() {
    final products = const <_ProductProfitItem>[];

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
            'Product Profitability',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181512),
            ),
          ),
          const SizedBox(height: 14),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEFE7DC), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 32,
                  child: Text(
                    'Product',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7E7569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: Text(
                    'Revenue',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7E7569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: Text(
                    'Cost',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7E7569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: Text(
                    'Profit',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7E7569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 12,
                  child: Text(
                    'Margin %',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7E7569),
                    ),
                  ),
                ),
                Expanded(
                  flex: 14,
                  child: Text(
                    'Status',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7E7569),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Rows
          if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'No product profitability data available yet.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF7E7569),
                  ),
                ),
              ),
            )
          else
            Column(
              children: products
                  .map(
                    (item) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: item.isCritical
                            ? const Color(0xFFFFF0F0) // Soft red highlight
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Product image & title
                          Expanded(
                            flex: 32,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    color: const Color(0xFFF3ECE4),
                                    child: Image.asset(
                                      item.imageAsset,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.checkroom_rounded,
                                        size: 16,
                                        color: Color(0xFF8B6B46),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF181512),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Revenue
                          Expanded(
                            flex: 16,
                            child: Text(
                              item.revenue,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2E2A24),
                              ),
                            ),
                          ),

                          // Cost
                          Expanded(
                            flex: 15,
                            child: Text(
                              item.cost,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF5A5348),
                              ),
                            ),
                          ),

                          // Profit
                          Expanded(
                            flex: 15,
                            child: Text(
                              item.profit,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181512),
                              ),
                            ),
                          ),

                          // Margin %
                          Expanded(
                            flex: 12,
                            child: Text(
                              item.margin,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: item.isCritical
                                    ? const Color(0xFFD9534F)
                                    : const Color(0xFF1E7E34),
                              ),
                            ),
                          ),

                          // Status Pill
                          Expanded(
                            flex: 14,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: item.isCritical
                                      ? const Color(0xFFFFDFDF)
                                      : const Color(0xFFE7F7ED),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item.status,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: item.isCritical
                                        ? const Color(0xFFD32F2F)
                                        : const Color(0xFF1E7E34),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// Data models
class _CategoryMarginItem {
  final String name;
  final double ratio;
  final Color color;

  const _CategoryMarginItem(this.name, this.ratio, this.color);
}

class _ProductProfitItem {
  final String title;
  final String imageAsset;
  final String revenue;
  final String cost;
  final String profit;
  final String margin;
  final String status;
  final bool isCritical;

  const _ProductProfitItem({
    required this.title,
    required this.imageAsset,
    required this.revenue,
    required this.cost,
    required this.profit,
    required this.margin,
    required this.status,
    required this.isCritical,
  });
}

// =============================================================================
// SMOOTH DUAL-CURVE CHART WITH GRADIENT FILL & AXIS
// =============================================================================
class _DualAreaLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Labels
        final xLabels = [
          'Oct 1',
          'Oct 5',
          'Oct 10',
          'Oct 15',
          'Oct 20',
          'Oct 25',
          'Oct 31',
        ];
        final yLabels = ['15L', '10L', '5L', '0'];

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
                    .map(
                      (label) => Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E958A),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            // Main Canvas for Grid Lines, Curves, and Gradient Fills
            Positioned(
              left: leftGutter,
              top: 0,
              width: plotWidth,
              height: plotHeight,
              child: CustomPaint(
                size: Size(plotWidth, plotHeight),
                painter: _SmoothCurvesPainter(),
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
                    .map(
                      (label) => Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E958A),
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

class _SmoothCurvesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Horizontal Grid Lines (4 lines)
    final gridPaint = Paint()
      ..color = const Color(0xFFF1EAE0)
      ..strokeWidth = 1.0;

    for (int i = 0; i < 4; i++) {
      final y = size.height * (i / 3.0);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Revenue points in Lakhs: [4.2, 5.8, 8.8, 13.5, 10.8, 13.0, 14.8] out of 15.0 max
    final revenuePoints = [4.2, 5.8, 8.8, 13.5, 10.8, 13.0, 14.8];
    // COGS points in Lakhs: [2.1, 3.5, 5.0, 7.2, 5.5, 6.2, 6.9] out of 15.0 max
    final cogsPoints = [2.1, 3.5, 5.0, 7.2, 5.5, 6.2, 6.9];

    final numPoints = revenuePoints.length;
    final stepX = size.width / (numPoints - 1);

    List<Offset> revOffsets = [];
    List<Offset> cogsOffsets = [];

    for (int i = 0; i < numPoints; i++) {
      final x = i * stepX;
      final yRev = size.height - (revenuePoints[i] / 15.0) * size.height;
      final yCogs = size.height - (cogsPoints[i] / 15.0) * size.height;
      revOffsets.add(Offset(x, yRev));
      cogsOffsets.add(Offset(x, yCogs));
    }

    // Build smooth cubic bezier path
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

    final revPath = buildSmoothPath(revOffsets);
    final cogsPath = buildSmoothPath(cogsOffsets);

    // 2. Draw Filled Gradients under curves
    final revFillPath = Path.from(revPath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final revGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF3B82F6).withOpacity(0.18),
        const Color(0xFF3B82F6).withOpacity(0.01),
      ],
    );

    final revFillPaint = Paint()
      ..shader = revGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(revFillPath, revFillPaint);

    final cogsFillPath = Path.from(cogsPath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final cogsGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFC89748).withOpacity(0.15),
        const Color(0xFFC89748).withOpacity(0.01),
      ],
    );

    final cogsFillPaint = Paint()
      ..shader = cogsGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;
    canvas.drawPath(cogsFillPath, cogsFillPaint);

    // 3. Draw Strokes
    final revStrokePaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(revPath, revStrokePaint);

    final cogsStrokePaint = Paint()
      ..color = const Color(0xFFC89748)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(cogsPath, cogsStrokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
