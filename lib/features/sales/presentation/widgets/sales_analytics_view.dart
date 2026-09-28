// ignore_for_file: deprecated_member_use, unused_element
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/business/current_business_service.dart';

class SalesAnalyticsView extends StatefulWidget {
  final VoidCallback? onNavigateToOverview;
  final VoidCallback? onNavigateToNewSale;
  final ValueChanged<String>? onNavigateToSaleDetail;

  const SalesAnalyticsView({
    super.key,
    this.onNavigateToOverview,
    this.onNavigateToNewSale,
    this.onNavigateToSaleDetail,
  });

  @override
  State<SalesAnalyticsView> createState() => _SalesAnalyticsViewState();
}

class _SalesAnalyticsViewState extends State<SalesAnalyticsView> {
  String _selectedDateRange = 'Last 30 Days';
  String _selectedCategory = 'All Categories';

  String get _currencySymbol {
    final code =
        CurrentBusinessService.instance.currentBusiness?.currencyCode
            .toUpperCase() ??
        'USD';
    switch (code) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      case 'AED':
        return 'AED ';
      default:
        return '$code ';
    }
  }

  String get _businessName {
    final name = CurrentBusinessService.instance.currentBusiness?.legalName;
    return (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : 'Current Business';
  }

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
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
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

  void _showScheduleReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(26),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F3EB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                          color: Color(0xFF946A36),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Schedule Automated Report',
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181512),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: const Color(0xFF7E766B),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Receive comprehensive periodic sales reports directly in your inbox.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF635B4F),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEADBCA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Frequency',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181512),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Weekly on Monday at 9:00 AM • $_businessName',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF4A443B),
                      ),
                    ),
                  ],
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
                        horizontal: 16,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
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
                        'Automated report scheduled successfully for $_businessName.',
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF181512),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Schedule',
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Action Filter Bar
        _buildActionFilterBar(),
        const SizedBox(height: 20),

        // 2. Hero Card: Total Sales Revenue
        _buildHeroRevenueCard(),
        const SizedBox(height: 18),

        // 3. 4 KPI Metric Cards (Transactions, Average Order, Units Sold, Returns)
        _buildKpiMetricsRow(),
        const SizedBox(height: 18),

        // 4. Honest Empty State
        _buildEmptyStateCard(),
        const SizedBox(height: 24),
      ],
    );
  }

  // ===========================================================================
  // 1. Action Filter Bar
  // ===========================================================================
  Widget _buildActionFilterBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 760;

        final filterControls = Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Date Filter Pill
            PopupMenuButton<String>(
              tooltip: 'Time Range',
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFEADBCA)),
              ),
              color: Colors.white,
              onSelected: (val) {
                setState(() => _selectedDateRange = val);
                _showFeedback('Filtered to $val');
              },
              itemBuilder: (context) => [
                _buildFilterMenuItem('Last 7 Days'),
                _buildFilterMenuItem('Last 30 Days'),
                _buildFilterMenuItem('Last 90 Days'),
                _buildFilterMenuItem('Year to Date'),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8.5,
                ),
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
                      _selectedDateRange,
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

            // Category Filter Pill
            PopupMenuButton<String>(
              tooltip: 'Category Filter',
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Color(0xFFEADBCA)),
              ),
              color: Colors.white,
              onSelected: (val) {
                setState(() => _selectedCategory = val);
                _showFeedback('Filtered to $val');
              },
              itemBuilder: (context) => [
                _buildFilterMenuItem('All Categories'),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8.5,
                ),
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
                      Icons.local_offer_outlined,
                      size: 15,
                      color: Color(0xFF4A443B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCategory,
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

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Export CSV Button
            OutlinedButton(
              onPressed: () {
                _showFeedback('No sales dataset available to export.');
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2A2520),
                side: const BorderSide(color: Color(0xFFE5DACD)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.file_download_outlined,
                    size: 16,
                    color: Color(0xFF4A443B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Export CSV',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2A2520),
                    ),
                  ),
                ],
              ),
            ),

            // Schedule Report Button
            ElevatedButton(
              onPressed: _showScheduleReportDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181512),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Schedule Report',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              filterControls,
              const SizedBox(height: 12),
              actionButtons,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: filterControls),
            actionButtons,
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _buildFilterMenuItem(String value) {
    final isSelected =
        _selectedDateRange == value || _selectedCategory == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? const Color(0xFF181512)
                  : const Color(0xFF4A443B),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_rounded, size: 16, color: Color(0xFFBA8A55)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. Hero Card: Total Sales Revenue
  // ===========================================================================
  Widget _buildHeroRevenueCard() {
    return Container(
      padding: const EdgeInsets.all(22),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Revenue
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Sales Revenue',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7E766B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_currencySymbol}0',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF181512),
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No sales recorded yet',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7E766B),
                  ),
                ),
              ],
            ),
          ),

          // Right Sparkline Area
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '30-DAY TREND',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: const Color(0xFF9E958A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No trend data yet',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFB5ABA0),
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
  // 3. 4 KPI Metric Cards
  // ===========================================================================
  Widget _buildKpiMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1050;
        final isMedium = constraints.maxWidth >= 640;

        final card1 = _buildKpiCard(
          icon: Icons.description_outlined,
          label: 'Transactions',
          value: '0',
          deltaText: '—',
          isPositiveDelta: true,
        );
        final card2 = _buildKpiCard(
          icon: Icons.shopping_cart_outlined,
          label: 'Average Order',
          value: '${_currencySymbol}0',
          deltaText: '—',
          isPositiveDelta: true,
        );
        final card3 = _buildKpiCard(
          icon: Icons.inventory_2_outlined,
          label: 'Units Sold',
          value: '0',
          deltaText: '—',
          isPositiveDelta: true,
        );
        final card4 = _buildKpiCard(
          icon: Icons.replay_rounded,
          label: 'Returns',
          value: '${_currencySymbol}0',
          deltaText: '—',
          isPositiveDelta: true,
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: card1),
              const SizedBox(width: 16),
              Expanded(child: card2),
              const SizedBox(width: 16),
              Expanded(child: card3),
              const SizedBox(width: 16),
              Expanded(child: card4),
            ],
          );
        }

        if (isMedium) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 16),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 16),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            card1,
            const SizedBox(height: 14),
            card2,
            const SizedBox(height: 14),
            card3,
            const SizedBox(height: 14),
            card4,
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String label,
    required String value,
    required String deltaText,
    required bool isPositiveDelta,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7E766B),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEADBCA)),
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF7E766B)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181512),
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3EFEA),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  deltaText,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7E766B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. Honest Zero-Data Empty State Card
  // ===========================================================================
  Widget _buildEmptyStateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
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
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF5EDE1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 28,
                color: Color(0xFFBA8A55),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No sales data yet',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181512),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Analytics will appear after completed sales are recorded.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF7E766B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
