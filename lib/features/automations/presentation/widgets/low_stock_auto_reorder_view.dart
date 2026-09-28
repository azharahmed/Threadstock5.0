import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LowStockAutoReorderView extends StatefulWidget {
  const LowStockAutoReorderView({
    super.key,
    this.onEditConfiguration,
    this.onEditAutomation,
    this.onPauseAutomation,
    this.onViewRunLogs,
    this.onDeleteAutomation,
    this.onViewRecommendations,
    this.onViewAllActivity,
    this.onViewProductSkus,
  });

  final VoidCallback? onEditConfiguration;
  final VoidCallback? onEditAutomation;
  final VoidCallback? onPauseAutomation;
  final VoidCallback? onViewRunLogs;
  final VoidCallback? onDeleteAutomation;
  final VoidCallback? onViewRecommendations;
  final VoidCallback? onViewAllActivity;
  final void Function(String skuGroup)? onViewProductSkus;

  @override
  State<LowStockAutoReorderView> createState() =>
      _LowStockAutoReorderViewState();
}

class _ActivityLogItem {
  const _ActivityLogItem({
    required this.dateTime,
    required this.trigger,
    required this.products,
    required this.actionTaken,
    required this.result,
    required this.duration,
  });

  final String dateTime;
  final String trigger;
  final String products;
  final String actionTaken;
  final String result;
  final String duration;
}

class _LowStockAutoReorderViewState extends State<LowStockAutoReorderView> {
  bool _isPaused = false;

  final List<_ActivityLogItem> _activityLogs = const [
    _ActivityLogItem(
      dateTime: 'Sep 15, 09:30',
      trigger: 'Stock below safety',
      products: '3 SKUs',
      actionTaken: 'PO-2891 created',
      result: 'Success',
      duration: '2.1s',
    ),
    _ActivityLogItem(
      dateTime: 'Sep 14, 14:15',
      trigger: 'Stock below safety',
      products: '1 SKU',
      actionTaken: 'PO-2884 created',
      result: 'Success',
      duration: '1.8s',
    ),
    _ActivityLogItem(
      dateTime: 'Sep 12, 11:05',
      trigger: 'Stock below safety',
      products: '5 SKUs',
      actionTaken: 'PO-2879 created',
      result: 'Success',
      duration: '2.5s',
    ),
    _ActivityLogItem(
      dateTime: 'Sep 10, 08:00',
      trigger: 'Stock below safety',
      products: '2 SKUs',
      actionTaken: 'PO-2872 created',
      result: 'Success',
      duration: '1.9s',
    ),
  ];

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header: Title + ACTIVE Badge + Subtitle
            _buildPageHeader(),
            const SizedBox(height: 20),

            // Two-column layout or stacked layout for narrower screens
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column (~73% width)
                  Expanded(
                    flex: 73,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 4 KPI Cards
                        _buildKpiCardsRow(),
                        const SizedBox(height: 18),

                        // Configuration Summary Card
                        _buildConfigurationSummaryCard(),
                        const SizedBox(height: 18),

                        // Recent Activity Log Card
                        _buildRecentActivityLogCard(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Right Column (~27% width)
                  SizedBox(width: 280, child: _buildAutomationActionsCard()),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiCardsRow(),
                  const SizedBox(height: 18),
                  _buildConfigurationSummaryCard(),
                  const SizedBox(height: 18),
                  _buildRecentActivityLogCard(),
                  const SizedBox(height: 18),
                  _buildAutomationActionsCard(),
                ],
              ),

            const SizedBox(height: 18),

            // Bottom Automation Insight Banner
            _buildAutomationInsightBanner(),
          ],
        );
      },
    );
  }

  // ==========================================
  // 1. PAGE HEADER
  // ==========================================
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Low Stock Auto-Reorder',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181513),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: _isPaused
                    ? const Color(0xFFF3ECE1)
                    : const Color(0xFFEAF7EE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _isPaused ? 'PAUSED' : 'ACTIVE',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: _isPaused
                      ? const Color(0xFF8C5A2B)
                      : const Color(0xFF1E7E45),
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Automatically creates purchase orders for low stock items to prevent stockouts.',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: const Color(0xFF6E675F),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 2. 4 KPI METRICS CARDS ROW
  // ==========================================
  Widget _buildKpiCardsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (3 * 14)) / 4;

        return Row(
          children: [
            // Card 1: Runs This Month
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                iconWidget: const Icon(
                  Icons.play_arrow_outlined,
                  size: 20,
                  color: Color(0xFFBA8A55),
                ),
                label: 'Runs This Month',
                value: '47 Runs',
                footer: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7EE),
                        borderRadius: BorderRadius.circular(3.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_upward_rounded,
                            size: 10,
                            color: Color(0xFF1E7E45),
                          ),
                          const SizedBox(width: 1),
                          Text(
                            '98%',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E7E45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Success rate',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF8C8276),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Card 2: POs Created
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                iconWidget: const Icon(
                  Icons.description_outlined,
                  size: 19,
                  color: Color(0xFFBA8A55),
                ),
                label: 'POs Created',
                value: '12 POs',
                footer: Text(
                  'Auto-generated',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF8C8276),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Card 3: Auto-Ordered Value
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                iconWidget: Center(
                  child: Text(
                    '₹',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFBA8A55),
                    ),
                  ),
                ),
                label: 'Auto-Ordered Value',
                value: '₹3,40,000',
                footer: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EE),
                    borderRadius: BorderRadius.circular(3.5),
                  ),
                  child: Text(
                    'Within budget',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E7E45),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Card 4: Success Rate
            SizedBox(
              width: cardWidth,
              child: _buildMetricCard(
                iconWidget: const Icon(
                  Icons.track_changes_rounded,
                  size: 19,
                  color: Color(0xFFBA8A55),
                ),
                label: 'Success Rate',
                value: '98%',
                footer: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(3.5),
                      ),
                      child: Text(
                        '1 failure',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Out of 47 runs',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF8C8276),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required Widget iconWidget,
    required String label,
    required String value,
    required Widget footer,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEBE4DA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF6EF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF0E5D8)),
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6E675F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                footer,
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. CONFIGURATION SUMMARY CARD
  // ==========================================
  Widget _buildConfigurationSummaryCard() {
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.settings_outlined,
                    size: 20,
                    color: Color(0xFFA86E38),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Configuration Summary',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8C5A2B),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap:
                    widget.onEditConfiguration ??
                    () => _showToast('Opening configuration editor...'),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFDCC8B0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Color(0xFF8C5A2B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Edit Configuration',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8C5A2B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Row 1: Trigger
          _buildConfigRow(
            label: 'Trigger',
            child: Text(
              'When any product falls below safety stock level',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Row 2: Conditions
          _buildConfigRow(
            label: 'Conditions',
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF181513),
                  fontWeight: FontWeight.w400,
                ),
                children: [
                  const TextSpan(text: 'Product is active '),
                  TextSpan(
                    text: 'AND',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFA86E38),
                    ),
                  ),
                  const TextSpan(text: ' supplier is verified '),
                  TextSpan(
                    text: 'AND',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFA86E38),
                    ),
                  ),
                  const TextSpan(text: ' order value > ₹500'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Row 3: Actions (Steps Flow)
          _buildConfigRow(
            label: 'Actions',
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Step 1
                  _buildActionStep(
                    icon: Icons.description_outlined,
                    label: 'Create draft PO',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Color(0xFF9E958A),
                    ),
                  ),
                  // Step 2
                  _buildActionStep(
                    icon: Icons.check_circle_outline_rounded,
                    label: 'Route for approval',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Color(0xFF9E958A),
                    ),
                  ),
                  // Step 3
                  _buildActionStep(
                    icon: Icons.notifications_none_outlined,
                    label: 'Notify purchasing team',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow({required String label, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6E675F),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildActionStep({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFDFD4C5)),
          ),
          child: Icon(icon, size: 15, color: const Color(0xFF8C5A2B)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF181513),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 4. RECENT ACTIVITY LOG CARD
  // ==========================================
  Widget _buildRecentActivityLogCard() {
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity Log',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              InkWell(
                onTap:
                    widget.onViewAllActivity ??
                    () => _showToast('Navigating to full activity logs...'),
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8C5A2B),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF8C5A2B),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF9F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                _buildTableHeaderCell('Date & Time', flex: 11),
                _buildTableHeaderCell('Trigger', flex: 15),
                _buildTableHeaderCell('Products', flex: 10),
                _buildTableHeaderCell('Action Taken', flex: 14),
                _buildTableHeaderCell('Result', flex: 10),
                _buildTableHeaderCell('Duration', flex: 8),
                const SizedBox(width: 28), // Menu column
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Table Data Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activityLogs.length,
            separatorBuilder: (context, index) => const Divider(
              color: Color(0xFFF2ECE4),
              height: 1,
              thickness: 1,
            ),
            itemBuilder: (context, index) {
              final log = _activityLogs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Date & Time
                    Expanded(
                      flex: 11,
                      child: Text(
                        log.dateTime,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF181513),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    // Trigger
                    Expanded(
                      flex: 15,
                      child: Text(
                        log.trigger,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF181513),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    // Products (Blue link)
                    Expanded(
                      flex: 10,
                      child: InkWell(
                        onTap: () {
                          if (widget.onViewProductSkus != null) {
                            widget.onViewProductSkus!(log.products);
                          } else {
                            _showToast('Viewing ${log.products} for log run');
                          }
                        },
                        child: Text(
                          log.products,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    // Action Taken
                    Expanded(
                      flex: 14,
                      child: Text(
                        log.actionTaken,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF181513),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    // Result
                    Expanded(
                      flex: 10,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7EE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            log.result,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E7E45),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Duration
                    Expanded(
                      flex: 8,
                      child: Text(
                        log.duration,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF6E675F),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    // 3 dots action menu
                    InkWell(
                      onTap: () => _showToast(
                        'Log entry options for ${log.actionTaken}',
                      ),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.more_vert_rounded,
                          size: 16,
                          color: Color(0xFF9E958A),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6E675F),
        ),
      ),
    );
  }

  // ==========================================
  // 5. AUTOMATION ACTIONS CARD (RIGHT COLUMN)
  // ==========================================
  Widget _buildAutomationActionsCard() {
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
          Text(
            'Automation Actions',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 16),

          // Button 1: Edit Automation (Dark Solid)
          InkWell(
            onTap:
                widget.onEditAutomation ??
                () => _showToast('Opening Automation Rule Builder...'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFF181513),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_outline_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Automation',
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

          // Button 2: Pause Automation (White Outline)
          InkWell(
            onTap: () {
              setState(() {
                _isPaused = !_isPaused;
              });
              if (widget.onPauseAutomation != null) {
                widget.onPauseAutomation!();
              } else {
                _showToast(
                  _isPaused ? 'Automation paused' : 'Automation resumed',
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDFD7CB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isPaused
                        ? Icons.play_circle_outline_rounded
                        : Icons.pause_circle_outline_rounded,
                    size: 18,
                    color: const Color(0xFF181513),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isPaused ? 'Resume Automation' : 'Pause Automation',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Button 3: View Run Logs (White Outline)
          InkWell(
            onTap:
                widget.onViewRunLogs ??
                () => _showToast(
                  'Fetching complete run logs for Low Stock Auto-Reorder...',
                ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDFD7CB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: Color(0xFF181513),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View Run Logs',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Button 4: Delete Automation (Red Outline)
          InkWell(
            onTap:
                widget.onDeleteAutomation ??
                () => _showToast('Delete confirmation triggered'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delete Automation',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Metadata key-values
          _buildMetaRow('Created by', 'Store Admin'),
          const SizedBox(height: 12),
          _buildMetaRow('Created on', 'Aug 12, 2026'),
          const SizedBox(height: 12),
          _buildMetaRow('Last modified', 'Sep 01, 2026'),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0xFF6E675F),
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181513),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 6. BOTTOM AUTOMATION INSIGHT BANNER
  // ==========================================
  Widget _buildAutomationInsightBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2DCBE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 26,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Automation Insight',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Consider increasing safety stock for fast-moving knitwear items to reduce reorder frequency by ~20%.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6E675F),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap:
                widget.onViewRecommendations ??
                () => _showToast('Opening safety stock recommendations...'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC8A275)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Recommendations',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8C5A2B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFF8C5A2B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
