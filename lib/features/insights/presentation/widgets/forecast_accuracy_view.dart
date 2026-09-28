// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ForecastAccuracyView extends StatefulWidget {
  final VoidCallback? onNavigateToAutomations;
  final VoidCallback? onNavigateToInventory;

  const ForecastAccuracyView({
    super.key,
    this.onNavigateToAutomations,
    this.onNavigateToInventory,
  });

  @override
  State<ForecastAccuracyView> createState() => _ForecastAccuracyViewState();
}

class _ForecastAccuracyViewState extends State<ForecastAccuracyView> {
  String _selectedPeriod = 'Past 12 Weeks: Aug 5 - Oct 31';
  String _selectedTrendFrequency = 'Weekly';

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

  void _showProductDetailsDialog(
    BuildContext context, {
    required String title,
    required String actualSales,
    required String forecasted,
    required String variance,
    required String reason,
    required String imageAsset,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 520,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF6EE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEADBCA)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.inventory_2_outlined,
                                color: Color(0xFF9E8462),
                              ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF181512),
                            ),
                          ),
                          Text(
                            'SKU Performance & Variance Analysis',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: const Color(0xFF7E766B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF7E766B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEADBCA)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDialogMetric('Actual Sales', actualSales),
                    Container(
                      width: 1,
                      height: 32,
                      color: const Color(0xFFE5DACD),
                    ),
                    _buildDialogMetric('Forecasted', forecasted),
                    Container(
                      width: 1,
                      height: 32,
                      color: const Color(0xFFE5DACD),
                    ),
                    _buildDialogMetric('Variance', variance),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Attribution Reason',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181512),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F5F0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5DACD)),
                ),
                child: Text(
                  reason,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF4A443B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4A443B),
                      side: const BorderSide(color: Color(0xFFDCCFBD)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _showFeedback(
                        'Adjusting forecast parameters for $title...',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF181512),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Retrain Signal Weight',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: const Color(0xFF7E766B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181512),
          ),
        ),
      ],
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

        // 2. 4 Top KPI Score Cards
        _buildKpiMetricsRow(),
        const SizedBox(height: 20),

        // 3. Middle Section: Accuracy Over Time (Weekly Trend) & Model Signal Attribution Weight
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1020;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 58, child: _buildAccuracyTrendCard()),
                  const SizedBox(width: 20),
                  Expanded(flex: 42, child: _buildSignalAttributionCard()),
                ],
              );
            }
            return Column(
              children: [
                _buildAccuracyTrendCard(),
                const SizedBox(height: 20),
                _buildSignalAttributionCard(),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // 4. Table Section: Worst Accuracy Deviations (Requires Attention)
        _buildWorstDeviationsCard(),
        const SizedBox(height: 20),

        // 5. Bottom AI Insight Callout Card
        _buildAiInsightCalloutBanner(),
        const SizedBox(height: 24),
      ],
    );
  }

  // ===========================================================================
  // 1. Header Area
  // ===========================================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Forecast Accuracy',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181512),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Measure and improve demand forecast performance across your product catalog.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6E665A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        PopupMenuButton<String>(
          tooltip: 'Select Timeframe',
          offset: const Offset(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFEADBCA)),
          ),
          color: Colors.white,
          onSelected: (val) {
            setState(() => _selectedPeriod = val);
            _showFeedback('Period updated to $val');
          },
          itemBuilder: (context) => [
            _buildPopupMenuItem('Past 4 Weeks: Oct 1 - Oct 31'),
            _buildPopupMenuItem('Past 12 Weeks: Aug 5 - Oct 31'),
            _buildPopupMenuItem('Past 6 Months: May 1 - Oct 31'),
            _buildPopupMenuItem('Year to Date: Jan 1 - Oct 31'),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8DFD3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF4A443B),
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedPeriod,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2A2520),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF7A7267),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(String value) {
    return PopupMenuItem<String>(
      value: value,
      height: 38,
      child: Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: _selectedPeriod == value
              ? FontWeight.w600
              : FontWeight.w400,
          color: _selectedPeriod == value
              ? const Color(0xFF8C5E33)
              : const Color(0xFF1E1C1A),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. 4 Top KPI Score Cards
  // ===========================================================================
  Widget _buildKpiMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1050;
        final isMedium = constraints.maxWidth >= 640;

        if (isWide) {
          return Row(
            children: [
              Expanded(child: _buildAccuracyScoreCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildMapeErrorCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildModelBiasCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildWeightedAccuracyCard()),
            ],
          );
        }

        if (isMedium) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildAccuracyScoreCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMapeErrorCard()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildModelBiasCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildWeightedAccuracyCard()),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            _buildAccuracyScoreCard(),
            const SizedBox(height: 14),
            _buildMapeErrorCard(),
            const SizedBox(height: 14),
            _buildModelBiasCard(),
            const SizedBox(height: 14),
            _buildWeightedAccuracyCard(),
          ],
        );
      },
    );
  }

  // Card 1: Accuracy Score (Donut Ring + Description + Delta pill)
  Widget _buildAccuracyScoreCard() {
    return _buildBaseKpiCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Progress Ring Donut
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 68,
                  height: 68,
                  child: CircularProgressIndicator(
                    value: 0.87,
                    strokeWidth: 6.5,
                    backgroundColor: const Color(0xFFF0EAE1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFC89748),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '87%',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181512),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Accuracy Score',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181512),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Across all item category mappings in Zone A.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7E766B),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF8F2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        size: 11,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '5% vs last period',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF16A34A),
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

  // Card 2: MAPE (Error)
  Widget _buildMapeErrorCard() {
    return _buildBaseKpiCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeadingIconContainer(
            child: const Icon(
              Icons.bar_chart_rounded,
              size: 22,
              color: Color(0xFFC89748),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MAPE (Error)',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7E766B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '13.2%',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181512),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBF8F2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_downward_rounded,
                            size: 11,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '2.1%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'vs last period',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8C8478),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 3: Model Bias
  Widget _buildModelBiasCard() {
    return _buildBaseKpiCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeadingIconContainer(
            child: const Icon(
              Icons.layers_outlined,
              size: 22,
              color: Color(0xFFC89748),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Model Bias',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7E766B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+2.1%',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181512),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Slight Overestimation',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Predicted higher than actual',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8C8478),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 4: Weighted Accuracy
  Widget _buildWeightedAccuracyCard() {
    return _buildBaseKpiCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLeadingIconContainer(
            child: const Icon(
              Icons.track_changes_rounded,
              size: 22,
              color: Color(0xFFC89748),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weighted Accuracy',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7E766B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '89.4%',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181512),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEBF8F2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Excellent',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Top quartile performance',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8C8478),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingIconContainer({required Widget child}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF6EE),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF1E7D8)),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildBaseKpiCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // ===========================================================================
  // 3. Middle Section: Accuracy Over Time (Weekly Trend) & Signal Attribution
  // ===========================================================================

  // Left Card: Accuracy Over Time (Weekly Trend)
  Widget _buildAccuracyTrendCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
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
          // Header: Title + Weekly dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Accuracy Over Time (Weekly Trend)',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181512),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Frequency',
                offset: const Offset(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFEADBCA)),
                ),
                color: Colors.white,
                onSelected: (val) {
                  setState(() => _selectedTrendFrequency = val);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'Weekly',
                    child: Text(
                      'Weekly',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Monthly',
                    child: Text(
                      'Monthly',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5DACD)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedTrendFrequency,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2A2520),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 15,
                        color: Color(0xFF7A7267),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Line Chart
          SizedBox(height: 195, child: _WeeklyAccuracyTrendChart()),
        ],
      ),
    );
  }

  // Right Card: Model Signal Attribution Weight
  Widget _buildSignalAttributionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
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
            'Model Signal Attribution Weight',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181512),
            ),
          ),
          const SizedBox(height: 22),

          _buildSignalAttributionRow(
            label: 'Seasonality',
            percentage: 42,
            note: 'Strongest driver',
          ),
          const SizedBox(height: 16),

          _buildSignalAttributionRow(
            label: 'Events & Holidays',
            percentage: 28,
            note: 'Diwali surges modelled',
          ),
          const SizedBox(height: 16),

          _buildSignalAttributionRow(
            label: 'Weather Metrics',
            percentage: 18,
            note: 'Regional adjustment',
          ),
          const SizedBox(height: 16),

          _buildSignalAttributionRow(
            label: 'Global Trends',
            percentage: 12,
            note: 'Minimal impact currently',
          ),
        ],
      ),
    );
  }

  Widget _buildSignalAttributionRow({
    required String label,
    required int percentage,
    required String note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181512),
              ),
            ),
            Row(
              children: [
                Text(
                  '$percentage%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181512),
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 140,
                  child: Text(
                    note,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF7E766B),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 7),
        LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth * (percentage / 100);
            return Stack(
              children: [
                Container(
                  height: 6,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2ECE4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  height: 6,
                  width: barWidth,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC89748),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // 4. Table Section: Worst Accuracy Deviations (Requires Attention)
  // ===========================================================================
  Widget _buildWorstDeviationsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Text(
              'Worst Accuracy Deviations (Requires Attention)',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181512),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0EAE1)),

          // Table Content with horizontal scroll on small screens
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 900),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    color: const Color(0xFFFAF7F2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 32,
                          child: Text(
                            'Product',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7E766B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 12,
                          child: Text(
                            'Actual Sales',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7E766B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 12,
                          child: Text(
                            'Forecasted',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7E766B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 12,
                          child: Text(
                            'Variance',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7E766B),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 18,
                          child: Text(
                            'Assigned Reason',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7E766B),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'Action',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF7E766B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0EAE1)),

                  // Row 1: Classic Linen Shirt (Black/M)
                  _buildProductDeviationRow(
                    productName: 'Classic Linen Shirt (Black/M)',
                    actualSales: '847',
                    forecasted: '880',
                    variance: '-3.7%',
                    isPositiveVariance: false,
                    isVarianceGreen: true, // In screenshot, -3.7% is green
                    reasonLabel: 'High Accuracy',
                    reasonType: _ReasonType.green,
                    imageAsset: '',
                  ),
                  const Divider(height: 1, color: Color(0xFFF5EFE6)),

                  // Row 2: Wool Tailored Blazer (Navy/L)
                  _buildProductDeviationRow(
                    productName: 'Wool Tailored Blazer (Navy/L)',
                    actualSales: '124',
                    forecasted: '110',
                    variance: '+12.7%',
                    isPositiveVariance: true,
                    isVarianceGreen: false, // red in screenshot
                    reasonLabel: 'Optimal',
                    reasonType: _ReasonType.green,
                    imageAsset: '',
                  ),
                  const Divider(height: 1, color: Color(0xFFF5EFE6)),

                  // Row 3: Satin Evening Gown (Red/S)
                  _buildProductDeviationRow(
                    productName: 'Satin Evening Gown (Red/S)',
                    actualSales: '98',
                    forecasted: '140',
                    variance: '-30.0%',
                    isPositiveVariance: false,
                    isVarianceGreen: false, // red in screenshot
                    reasonLabel: 'Under-forecasted',
                    reasonType: _ReasonType.red,
                    imageAsset: '',
                  ),
                  const Divider(height: 1, color: Color(0xFFF5EFE6)),

                  // Row 4: Cotton Trench Coat (Beige/M)
                  _buildProductDeviationRow(
                    productName: 'Cotton Trench Coat (Beige/M)',
                    actualSales: '45',
                    forecasted: '80',
                    variance: '-43.7%',
                    isPositiveVariance: false,
                    isVarianceGreen: false, // red in screenshot
                    reasonLabel: 'Model Miss',
                    reasonType: _ReasonType.red,
                    imageAsset: '',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductDeviationRow({
    required String productName,
    required String actualSales,
    required String forecasted,
    required String variance,
    required bool isPositiveVariance,
    required bool isVarianceGreen,
    required String reasonLabel,
    required _ReasonType reasonType,
    required String imageAsset,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Product Thumbnail & Name
          Expanded(
            flex: 32,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7EFE4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5DACD)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.checkroom_rounded,
                      size: 20,
                      color: Color(0xFF9E8462),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    productName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181512),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Actual Sales
          Expanded(
            flex: 12,
            child: Text(
              actualSales,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181512),
              ),
            ),
          ),

          // Forecasted
          Expanded(
            flex: 12,
            child: Text(
              forecasted,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF7E766B),
              ),
            ),
          ),

          // Variance
          Expanded(
            flex: 12,
            child: Text(
              variance,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isVarianceGreen
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
          ),

          // Assigned Reason Chip
          Expanded(
            flex: 18,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: reasonType == _ReasonType.green
                      ? const Color(0xFFEBF8F2)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  reasonLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: reasonType == _ReasonType.green
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ),
          ),

          // Action Button: View Details
          SizedBox(
            width: 100,
            child: OutlinedButton(
              onPressed: () {
                _showProductDetailsDialog(
                  context,
                  title: productName,
                  actualSales: actualSales,
                  forecasted: forecasted,
                  variance: variance,
                  reason: reasonLabel,
                  imageAsset: imageAsset,
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF181512),
                side: const BorderSide(color: Color(0xFFE0D7CB)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                elevation: 0,
              ),
              child: Text(
                'View Details',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF181512),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. Bottom AI Insight Callout Card
  // ===========================================================================
  Widget _buildAiInsightCalloutBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF8F1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEDDFC9)),
      ),
      child: Row(
        children: [
          // Lightbulb icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF5ECE0),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEADBC8)),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              size: 20,
              color: Color(0xFFC89748),
            ),
          ),
          const SizedBox(width: 14),

          // Text Message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insight',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181512),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Forecast accuracy for formal wear is 12% lower during promotional periods. Consider incorporating promotion intensity as an additional model feature.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6E665A),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Outlined Action Button
          OutlinedButton(
            onPressed: () {
              _showFeedback('Opening promotional model recommendations...');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF8C5E33),
              side: const BorderSide(color: Color(0xFFDCCFBD)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Colors.white.withOpacity(0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Recommendations',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8C5E33),
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Color(0xFF8C5E33),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _ReasonType { green, red }

// ===========================================================================
// Custom Weekly Accuracy Trend Line Chart
// ===========================================================================
class _WeeklyAccuracyTrendChart extends StatelessWidget {
  const _WeeklyAccuracyTrendChart();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;
        const leftPadding = 38.0;
        const bottomPadding = 24.0;

        final chartWidth = totalWidth - leftPadding;
        final chartHeight = totalHeight - bottomPadding;

        // Data points (percentage between 0.60 and 1.00)
        // Aug 5 (68%), Aug 19 (76%), Sep 2 (82%), Sep 16 (72%), Sep 30 (81%), Oct 14 (88%), Oct 28 (85%), Trend End (87%)
        final points = <_ChartPoint>[
          _ChartPoint('Aug 5', 0.68),
          _ChartPoint('Aug 19', 0.76),
          _ChartPoint('Sep 2', 0.82),
          _ChartPoint('Sep 16', 0.72),
          _ChartPoint('Sep 30', 0.81),
          _ChartPoint('Oct 14', 0.88),
          _ChartPoint('Oct 28', 0.85),
          _ChartPoint('', 0.87), // right edge extension
        ];

        return Stack(
          children: [
            // Horizontal grid lines & Y-axis labels
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: bottomPadding,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildGridRow('100%', leftPadding),
                  _buildGridRow('90%', leftPadding),
                  _buildGridRow('80%', leftPadding),
                  _buildGridRow('70%', leftPadding),
                  _buildGridRow('60%', leftPadding),
                ],
              ),
            ),

            // Line chart painter
            Positioned(
              left: leftPadding,
              top: 0,
              width: chartWidth,
              height: chartHeight,
              child: CustomPaint(
                painter: _TrendLinePainter(
                  points: points,
                  lineColor: const Color(0xFFC89748),
                ),
              ),
            ),

            // X-Axis Date Labels
            Positioned(
              left: leftPadding,
              bottom: 0,
              width: chartWidth,
              height: bottomPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildXLabel('Aug 5'),
                  _buildXLabel('Aug 19'),
                  _buildXLabel('Sep 2'),
                  _buildXLabel('Sep 16'),
                  _buildXLabel('Sep 30'),
                  _buildXLabel('Oct 14'),
                  _buildXLabel('Oct 28'),
                  const SizedBox(width: 20), // spacer for trend extension
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGridRow(String label, double leftPadding) {
    return Row(
      children: [
        SizedBox(
          width: leftPadding - 8,
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              color: const Color(0xFF9E958A),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Container(height: 1, color: const Color(0xFFEFECE6))),
      ],
    );
  }

  Widget _buildXLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10.5,
        color: const Color(0xFF9E958A),
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

class _ChartPoint {
  final String label;
  final double value; // 0.60 to 1.00
  _ChartPoint(this.label, this.value);
}

class _TrendLinePainter extends CustomPainter {
  final List<_ChartPoint> points;
  final Color lineColor;

  _TrendLinePainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotFillPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.16), lineColor.withOpacity(0.01)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    // Y scale: min 0.60 to max 1.00
    const minY = 0.60;
    const maxY = 1.00;

    double getY(double val) {
      final clamped = val.clamp(minY, maxY);
      final normalized = (clamped - minY) / (maxY - minY);
      return size.height - (normalized * size.height);
    }

    final path = Path();
    final areaPath = Path();

    final count = points.length;
    final dx = size.width / (count - 1);

    final screenPoints = <Offset>[];
    for (int i = 0; i < count; i++) {
      final x = i * dx;
      final y = getY(points[i].value);
      screenPoints.add(Offset(x, y));
    }

    // Build straight segments path
    path.moveTo(screenPoints[0].dx, screenPoints[0].dy);
    areaPath.moveTo(screenPoints[0].dx, size.height);
    areaPath.lineTo(screenPoints[0].dx, screenPoints[0].dy);

    for (int i = 1; i < screenPoints.length; i++) {
      path.lineTo(screenPoints[i].dx, screenPoints[i].dy);
      areaPath.lineTo(screenPoints[i].dx, screenPoints[i].dy);
    }

    areaPath.lineTo(screenPoints.last.dx, size.height);
    areaPath.close();

    // Draw soft area gradient
    canvas.drawPath(areaPath, areaPaint);

    // Draw line
    canvas.drawPath(path, linePaint);

    // Draw circular dots at data points
    for (int i = 0; i < screenPoints.length; i++) {
      // Skip the trailing trend-line end point if desired, or draw on all named points
      if (i < screenPoints.length - 1) {
        final pt = screenPoints[i];
        canvas.drawCircle(pt, 4.2, dotFillPaint);
        canvas.drawCircle(pt, 4.2, dotBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) => false;
}
