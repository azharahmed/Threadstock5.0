// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';
import '../widgets/anomaly_center_view.dart';
import '../widgets/dead_stock_view.dart';
import '../widgets/forecast_accuracy_view.dart';
import '../widgets/location_comparison_view.dart';
import '../widgets/profitability_analysis_view.dart';
import '../widgets/report_studio_view.dart';
import '../widgets/restock_recommendation_view.dart';
import '../widgets/schedule_automated_report_dialog.dart';
import '../widgets/shrinkage_investigation_view.dart';
import '../widgets/supplier_performance_view.dart';
import '../widgets/weekly_sales_summary_view.dart';

enum InsightsViewMode {
  forecastAccuracy,
  supplierPerformance,
  locationComparison,
  profitabilityAnalysis,
  weeklySalesSummary,
  reportStudio,
  executiveOverview,
  deadStock,
  anomalyCenter,
  shrinkageInvestigation,
  restockRecommendation,
}

class InsightsPage extends StatefulWidget {
  final InsightsViewMode initialMode;
  final bool showScheduleDialogOnInit;
  final ValueChanged<String>? onTitleChanged;
  final VoidCallback? onNavigateToAutomations;
  final VoidCallback? onNavigateToInventory;
  final VoidCallback? onNavigateToPurchasing;
  final VoidCallback? onNavigateToSuppliers;

  const InsightsPage({
    super.key,
    this.initialMode = InsightsViewMode.forecastAccuracy,
    this.showScheduleDialogOnInit = false,
    this.onTitleChanged,
    this.onNavigateToAutomations,
    this.onNavigateToInventory,
    this.onNavigateToPurchasing,
    this.onNavigateToSuppliers,
  });

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _StylePerformance {
  const _StylePerformance({
    required this.name,
    required this.sku,
    required this.unitsSold,
    required this.growth,
    required this.imageAsset,
  });

  final String name;
  final String sku;
  final String unitsSold;
  final String growth;
  final String imageAsset;
}

class _InsightsPageState extends State<InsightsPage> {
  late InsightsViewMode _currentMode;
  String _selectedTimeframe = 'Last 30 Days';
  String _selectedMetric = 'Sales Value';

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentMode == InsightsViewMode.forecastAccuracy) {
        widget.onTitleChanged?.call('Forecast Accuracy');
      } else if (_currentMode == InsightsViewMode.supplierPerformance) {
        widget.onTitleChanged?.call('Supplier Performance');
      } else if (_currentMode == InsightsViewMode.locationComparison) {
        widget.onTitleChanged?.call('Location Comparison');
      } else if (_currentMode == InsightsViewMode.profitabilityAnalysis) {
        widget.onTitleChanged?.call('Profitability Analysis');
      } else if (_currentMode == InsightsViewMode.weeklySalesSummary) {
        widget.onTitleChanged?.call('Weekly Sales Summary');
      } else if (_currentMode == InsightsViewMode.reportStudio) {
        widget.onTitleChanged?.call('Report Studio');
      } else if (_currentMode == InsightsViewMode.deadStock) {
        widget.onTitleChanged?.call('Dead Stock Analysis');
      } else if (_currentMode == InsightsViewMode.anomalyCenter) {
        widget.onTitleChanged?.call('Anomaly Center');
      } else if (_currentMode == InsightsViewMode.shrinkageInvestigation) {
        widget.onTitleChanged?.call('Shrinkage Investigation');
      } else if (_currentMode == InsightsViewMode.restockRecommendation) {
        widget.onTitleChanged?.call('Restock Recommendation');
      } else {
        widget.onTitleChanged?.call('Insights & Analytics');
      }

      if (widget.showScheduleDialogOnInit &&
          _currentMode == InsightsViewMode.reportStudio &&
          mounted) {
        ScheduleAutomatedReportDialog.show(context);
      }
    });
  }

  final List<_StylePerformance> _topStyles = const [];

  // 30 Days of sales trend in lakhs (max ~10L)
  final List<double> _dailySales = const [
    1.3,
    1.8,
    1.5,
    2.2,
    2.7,
    3.4,
    2.9,
    3.2,
    3.8,
    3.6,
    4.0,
    3.9,
    4.6,
    4.2,
    4.2,
    4.7,
    4.5,
    5.2,
    5.6,
    5.9,
    6.2,
    5.8,
    5.9,
    6.4,
    6.0,
    6.5,
    7.1,
    7.8,
    7.6,
    8.92,
  ];

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
    if (_currentMode == InsightsViewMode.anomalyCenter) {
      return AnomalyCenterView(
        onNavigateToInventory: widget.onNavigateToInventory,
        onNavigateToAutomations: widget.onNavigateToAutomations,
        onLaunchDeepInvestigation: () {
          setState(() {
            _currentMode = InsightsViewMode.shrinkageInvestigation;
            widget.onTitleChanged?.call('Shrinkage Investigation');
          });
        },
      );
    }

    if (_currentMode == InsightsViewMode.shrinkageInvestigation) {
      return ShrinkageInvestigationView(
        onBackToAnomalies: () {
          setState(() {
            _currentMode = InsightsViewMode.anomalyCenter;
            widget.onTitleChanged?.call('Anomaly Center');
          });
        },
        onNavigateToInventory: widget.onNavigateToInventory,
        onNavigateToAutomations: widget.onNavigateToAutomations,
      );
    }

    if (_currentMode == InsightsViewMode.deadStock) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 24,
          child: SingleChildScrollView(child: DeadStockView()),
        ),
      );
    }

    if (_currentMode == InsightsViewMode.forecastAccuracy) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 24,
          child: SingleChildScrollView(
            child: ForecastAccuracyView(
              onNavigateToAutomations: widget.onNavigateToAutomations,
              onNavigateToInventory: widget.onNavigateToInventory,
            ),
          ),
        ),
      );
    }

    if (_currentMode == InsightsViewMode.restockRecommendation) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 16,
          child: RestockRecommendationView(
            onCreatePo: widget.onNavigateToPurchasing,
            onViewAllWarnings: () {
              setState(() {
                _currentMode = InsightsViewMode.anomalyCenter;
                widget.onTitleChanged?.call('Anomaly Center');
              });
            },
          ),
        ),
      );
    }

    if (_currentMode == InsightsViewMode.supplierPerformance) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 24,
          child: SingleChildScrollView(
            child: SupplierPerformanceView(
              onNavigateToPurchasing: widget.onNavigateToPurchasing,
              onNavigateToSuppliers: widget.onNavigateToSuppliers,
            ),
          ),
        ),
      );
    }

    if (_currentMode == InsightsViewMode.locationComparison) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 24,
          child: SingleChildScrollView(
            child: LocationComparisonView(
              onNavigateToTransfers: () => Navigator.of(context).maybePop(),
              onNavigateToInventory: widget.onNavigateToInventory,
            ),
          ),
        ),
      );
    }

    if (_currentMode == InsightsViewMode.profitabilityAnalysis) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 24,
          child: SingleChildScrollView(
            child: ProfitabilityAnalysisView(
              onNavigateToAutomations: widget.onNavigateToAutomations,
              onNavigateToInventory: widget.onNavigateToInventory,
            ),
          ),
        ),
      );
    }

    if (_currentMode == InsightsViewMode.weeklySalesSummary) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 24,
          child: SingleChildScrollView(
            child: WeeklySalesSummaryView(
              onBackToReports: () {
                setState(() {
                  _currentMode = InsightsViewMode.reportStudio;
                  widget.onTitleChanged?.call('Report Studio');
                });
              },
              onNavigateToInventory: widget.onNavigateToInventory,
            ),
          ),
        ),
      );
    }

    if (_currentMode == InsightsViewMode.reportStudio) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 24,
          child: SingleChildScrollView(
            child: ReportStudioView(
              onManageAutomations: widget.onNavigateToAutomations,
              onSelectReport: (reportName) {
                if (reportName == 'Weekly Sales Summary') {
                  setState(() {
                    _currentMode = InsightsViewMode.weeklySalesSummary;
                    widget.onTitleChanged?.call('Weekly Sales Summary');
                  });
                }
              },
              onViewAllReports: () {
                setState(() {
                  _currentMode = InsightsViewMode.executiveOverview;
                  widget.onTitleChanged?.call('Insights & Analytics');
                });
              },
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 24,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Executive Performance Overview + Actions
              _buildHeader(),
              const SizedBox(height: 20),

              // 2. Top 3 KPI Cards
              _buildKpiMetricsRow(),
              const SizedBox(height: 20),

              // 3. Middle Section: Daily Sales Trend (Zone A) vs Top Performing Styles
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1050;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Daily Sales Trend (60% width)
                        Expanded(flex: 3, child: _buildDailySalesCard()),
                        const SizedBox(width: 20),

                        // Right: Top Performing Styles (40% width)
                        Expanded(flex: 2, child: _buildTopStylesCard()),
                      ],
                    );
                  }

                  // Compact / Stacked Layout
                  return Column(
                    children: [
                      _buildDailySalesCard(),
                      const SizedBox(height: 20),
                      _buildTopStylesCard(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // 4. Bottom Section: Stock & Inventory Insights vs AI Insights
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1050;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Stock & Inventory Insights (60% width)
                        Expanded(
                          flex: 3,
                          child: _buildStockInventoryInsightsCard(),
                        ),
                        const SizedBox(width: 20),

                        // Right: AI Insights (40% width)
                        Expanded(flex: 2, child: _buildAiInsightsCard()),
                      ],
                    );
                  }

                  // Compact / Stacked Layout
                  return Column(
                    children: [
                      _buildStockInventoryInsightsCard(),
                      const SizedBox(height: 20),
                      _buildAiInsightsCard(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // 1. HEADER ROW: Executive Performance Overview + Actions
  // ========================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title & Timeframe Selector
        Row(
          children: [
            Text(
              'Executive Performance Overview',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
            ),
            const SizedBox(width: 14),
            PopupMenuButton<String>(
              tooltip: 'Select timeframe',
              initialValue: _selectedTimeframe,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFEADBCA)),
              ),
              onSelected: (val) {
                setState(() => _selectedTimeframe = val);
                _showFeedback('Timeframe changed to $val');
              },
              itemBuilder: (context) =>
                  ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'This Year']
                      .map(
                        (t) => PopupMenuItem(
                          value: t,
                          height: 36,
                          child: Text(
                            t,
                            style: GoogleFonts.inter(fontSize: 12.5),
                          ),
                        ),
                      )
                      .toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD6E3F7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedTimeframe,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2662BA),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 15,
                      color: Color(0xFF2662BA),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Action Buttons: Report Studio + Export CSV + Schedule Automated Report
        Row(
          children: [
            // Report Studio
            Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5EBE1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEADBCA)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _currentMode = InsightsViewMode.reportStudio;
                      widget.onTitleChanged?.call('Report Studio');
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bar_chart_rounded,
                          size: 16,
                          color: Color(0xFF8D6433),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Report Studio',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8D6433),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Export CSV
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDFD4C5)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showFeedback(
                    'Exporting executive insights CSV report...',
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.file_upload_outlined,
                          size: 16,
                          color: Color(0xFF1E1C1A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Export CSV',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E1C1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Schedule Automated Report
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1C1A),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E1C1A).withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () =>
                      _showFeedback('Schedule automated report dialog opened.'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Schedule Automated Report',
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
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================
  // 2. TOP 3 KPI METRIC CARDS
  // ========================================================
  Widget _buildKpiMetricsRow() {
    return Row(
      children: [
        // 1. Gross Revenue
        Expanded(
          child: _buildTopKpiCard(
            icon: Icons.inventory_2_outlined,
            label: 'Gross Revenue',
            value: '₹42,84,200',
            trendText: '↑ 14.2%',
            subtext: 'vs previous 30 days',
          ),
        ),
        const SizedBox(width: 16),

        // 2. Units Sold
        Expanded(
          child: _buildTopKpiCard(
            icon: Icons.inventory_2_outlined,
            label: 'Units Sold',
            value: '24,842 items',
            trendText: '↑ 8.4%',
            subtext: 'vs previous 30 days',
          ),
        ),
        const SizedBox(width: 16),

        // 3. Sell-Through Velocity
        Expanded(child: _buildVelocityKpiCard()),
      ],
    );
  }

  Widget _buildTopKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required String trendText,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF4EA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEADBCA)),
                ),
                child: Icon(icon, size: 15, color: const Color(0xFF946A36)),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6358),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trendText,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F7A46),
                    ),
                  ),
                  Text(
                    subtext,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8A8275),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVelocityKpiCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF3E8),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFEADBCA)),
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      size: 16,
                      color: Color(0xFF9E6516),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Sell-Through Velocity',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B6358),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF3E8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Optimal',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9E6516),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  '78.4%',
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
              ),
              Text(
                '+2.1% vs last period',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 3. MIDDLE ROW - LEFT: DAILY SALES TREND (ZONE A) CHART
  // ========================================================
  Widget _buildDailySalesCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Daily Sales Trend (Zone A) + Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Sales Trend (Zone A)',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Select metric',
                initialValue: _selectedMetric,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFEADBCA)),
                ),
                onSelected: (val) {
                  setState(() => _selectedMetric = val);
                  _showFeedback('Metric changed to $val');
                },
                itemBuilder: (context) =>
                    ['Sales Value', 'Units Sold', 'Gross Margin']
                        .map(
                          (m) => PopupMenuItem(
                            value: m,
                            height: 36,
                            child: Text(
                              m,
                              style: GoogleFonts.inter(fontSize: 12.5),
                            ),
                          ),
                        )
                        .toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
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
                        _selectedMetric,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E1C1A),
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
          const SizedBox(height: 22),

          // Custom ThreadStock Bar Chart
          SizedBox(
            height: 210,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Y-Axis Labels: 10L, 8L, 6L, 4L, 2L, 0
                SizedBox(
                  width: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildYLabel('10L'),
                      _buildYLabel('8L'),
                      _buildYLabel('6L'),
                      _buildYLabel('4L'),
                      _buildYLabel('2L'),
                      _buildYLabel('0'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Chart Bars Area with Horizontal Reference Lines
                Expanded(
                  child: Stack(
                    children: [
                      // Subtle Horizontal Grid Lines
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(6, (index) {
                          return Container(
                            height: 1,
                            color: const Color(0xFFF1EAE0),
                          );
                        }),
                      ),

                      // 30 Daily Bars
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final barCount = _dailySales.length;
                            final availableWidth = constraints.maxWidth;
                            final spacing = 4.0;
                            final barWidth =
                                ((availableWidth - (barCount - 1) * spacing) /
                                        barCount)
                                    .clamp(4.0, 16.0);

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(barCount, (index) {
                                final val = _dailySales[index];
                                final heightRatio = (val / 10.0).clamp(
                                  0.05,
                                  1.0,
                                );
                                final isPeak =
                                    index ==
                                    barCount -
                                        1; // Day 30 is highlighted in gold!

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Tooltip(
                                      message:
                                          'Day ${index + 1}: ₹${(val * 100000).toInt()}',
                                      child: Container(
                                        width: barWidth,
                                        height:
                                            (constraints.maxHeight - 20) *
                                            heightRatio,
                                        decoration: BoxDecoration(
                                          color: isPeak
                                              ? const Color(0xFFBA8A55)
                                              : const Color(0xFF1E1C1A),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(2),
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'D${index + 1}',
                                      style: GoogleFonts.inter(
                                        fontSize: 8.5,
                                        fontWeight: isPeak
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                        color: isPeak
                                            ? const Color(0xFFBA8A55)
                                            : const Color(0xFF8A8275),
                                      ),
                                    ),
                                  ],
                                );
                              }),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFF1EAE0), height: 1),
          const SizedBox(height: 14),

          // Chart Footer: Peak Day + Regional driver note
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Peak Day: Day 30 (₹8,92,400)',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6358),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    size: 15,
                    color: Color(0xFF1F7A46),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Retail channels driving volume',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1F7A46),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF8A8275),
      ),
    );
  }

  // ========================================================
  // 3. MIDDLE ROW - RIGHT: TOP PERFORMING STYLES CARD
  // ========================================================
  Widget _buildTopStylesCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Top Performing Styles + View All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Performing Styles',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
              InkWell(
                onTap: () =>
                    _showFeedback('All styles performance ranking opened.'),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFBA8A55),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Color(0xFFBA8A55),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table Subheaders: STYLE, UNITS SOLD, GROWTH
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'STYLE',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8A8275),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'UNITS SOLD',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8A8275),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              SizedBox(
                width: 64,
                child: Text(
                  'GROWTH',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8A8275),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFF1EAE0), height: 1),
          const SizedBox(height: 10),

          // Product Style Rows
          if (_topStyles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No style performance data recorded yet.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF7E766B),
                  ),
                ),
              ),
            )
          else
            ..._topStyles.map((style) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    // Product Thumbnail Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 38,
                        height: 38,
                        color: const Color(0xFF1E1C1A),
                        child: Image.asset(
                          style.imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.checkroom_rounded,
                                color: Color(0xFFBA8A55),
                                size: 18,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Style Name & SKU
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            style.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E1C1A),
                            ),
                          ),
                          Text(
                            style.sku,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF7E766B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Units Sold
                    Expanded(
                      flex: 2,
                      child: Text(
                        style.unitsSold,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5E574E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Growth Pill
                    Container(
                      width: 64,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9F6EE),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Text(
                          style.growth,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1F7A46),
                          ),
                        ),
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

  // ========================================================
  // 4. BOTTOM ROW - LEFT: STOCK & INVENTORY INSIGHTS CARD
  // ========================================================
  Widget _buildStockInventoryInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Stock & Inventory Insights + View Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stock & Inventory Insights',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
              InkWell(
                onTap: () =>
                    _showFeedback('Inventory diagnostics modal opened.'),
                child: Row(
                  children: [
                    Text(
                      'View Details',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFBA8A55),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Color(0xFFBA8A55),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 3 Inset KPI Cards
          Row(
            children: [
              // Tile 1: Low Stock Items
              Expanded(
                child: _buildStockInsetTile(
                  icon: Icons.inventory_2_outlined,
                  iconBg: const Color(0xFFFAF4EA),
                  iconColor: const Color(0xFF9E6516),
                  title: 'Low Stock Items',
                  value: '18 SKUs',
                  statusText: 'Need attention',
                  statusColor: const Color(0xFFB83A28),
                ),
              ),
              const SizedBox(width: 12),

              // Tile 2: Overstock Items
              Expanded(
                child: _buildStockInsetTile(
                  icon: Icons.format_list_bulleted_rounded,
                  iconBg: const Color(0xFFFAF4EA),
                  iconColor: const Color(0xFF9E6516),
                  title: 'Overstock Items',
                  value: '7 SKUs',
                  statusText: 'Consider markdown',
                  statusColor: const Color(0xFFC2410C),
                ),
              ),
              const SizedBox(width: 12),

              // Tile 3: Inventory Turnover
              Expanded(
                child: _buildStockInsetTile(
                  icon: Icons.sync_rounded,
                  iconBg: const Color(0xFFFAF4EA),
                  iconColor: const Color(0xFF9E6516),
                  title: 'Inventory Turnover',
                  value: '4.2x',
                  statusText: 'Healthy',
                  statusColor: const Color(0xFF1F7A46),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStockInsetTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String statusText,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE5DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Icon(icon, size: 15, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B6358),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E1C1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusText,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 4. BOTTOM ROW - RIGHT: AI INSIGHTS CARD
  // ========================================================
  Widget _buildAiInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: AI Insights + View All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: Color(0xFFBA8A55),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Insights',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1C1A),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => _showFeedback('All AI Insights view opened.'),
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFBA8A55),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Color(0xFFBA8A55),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Suggestion 1: Increase purchase qty
          _buildAiInsightItem(
            icon: Icons.inventory_2_outlined,
            title: 'Increase purchase qty for linen blend shirts',
            subtitle: 'Expected 25% demand increase next month.',
            onTap: () => _showFeedback(
              'Opening purchase proposal for linen blend shirts...',
            ),
          ),
          const SizedBox(height: 10),

          // Suggestion 2: Reallocate stock
          _buildAiInsightItem(
            icon: Icons.sync_alt_rounded,
            title: 'Reallocate stock to high-demand locations',
            subtitle: 'Secondary store showing higher velocity.',
            onTap: () => _showFeedback('Drafting stock transfer proposal...'),
          ),
          const SizedBox(height: 10),

          // Suggestion 3: Run seasonal campaign
          _buildAiInsightItem(
            icon: Icons.campaign_outlined,
            title: 'Run seasonal campaign for evening wear',
            subtitle: 'Projected 18% lift based on last year\'s trend.',
            onTap: () => _showFeedback('Campaign briefing initiated...'),
          ),
        ],
      ),
    );
  }

  Widget _buildAiInsightItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEDE5DA)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF4EA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFEADBCA)),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF9E6516)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1C1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF7E766B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF8A8275),
            ),
          ],
        ),
      ),
    );
  }
}
