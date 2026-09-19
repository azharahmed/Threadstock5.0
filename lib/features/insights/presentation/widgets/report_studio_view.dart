// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'schedule_automated_report_dialog.dart';

class ReportItem {
  final String title;
  final String category;
  final Color categoryBg;
  final Color categoryBorder;
  final Color categoryColor;
  final String pages;
  final String date;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const ReportItem({
    required this.title,
    required this.category,
    required this.categoryBg,
    required this.categoryBorder,
    required this.categoryColor,
    required this.pages,
    required this.date,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

class AutomationPipelineItem {
  final String name;
  final String frequency;
  final String nextDelivery;
  final String recipients;
  final String status;
  final bool isActive;

  const AutomationPipelineItem({
    required this.name,
    required this.frequency,
    required this.nextDelivery,
    required this.recipients,
    required this.status,
    required this.isActive,
  });
}

class ReportStudioView extends StatefulWidget {
  final VoidCallback? onManageAutomations;
  final VoidCallback? onViewAllReports;
  final ValueChanged<String>? onSelectReport;

  const ReportStudioView({
    super.key,
    this.onManageAutomations,
    this.onViewAllReports,
    this.onSelectReport,
  });

  @override
  State<ReportStudioView> createState() => _ReportStudioViewState();
}

class _ReportStudioViewState extends State<ReportStudioView> {
  final List<ReportItem> _recentReports = const [
    ReportItem(
      title: 'Weekly Sales Summary',
      category: 'SALES',
      categoryBg: Color(0xFFFDF4E7),
      categoryBorder: Color(0xFFF6E3C5),
      categoryColor: Color(0xFFA86718),
      pages: '4 pages',
      date: 'Generated on Sep 14, 2024',
      icon: Icons.bar_chart_rounded,
      iconColor: Color(0xFF8D6433),
      iconBg: Color(0xFFFAF4EC),
    ),
    ReportItem(
      title: 'Monthly Inventory Health',
      category: 'INVENTORY',
      categoryBg: Color(0xFFEBF3EC),
      categoryBorder: Color(0xFFD5E8D8),
      categoryColor: Color(0xFF2E6E38),
      pages: '12 pages',
      date: 'Generated on Sep 01, 2024',
      icon: Icons.inventory_2_outlined,
      iconColor: Color(0xFF8D6433),
      iconBg: Color(0xFFFAF4EC),
    ),
    ReportItem(
      title: 'Quarterly P&L Projections',
      category: 'FINANCE',
      categoryBg: Color(0xFFEDF3FA),
      categoryBorder: Color(0xFFD4E4F7),
      categoryColor: Color(0xFF2662A6),
      pages: '8 pages',
      date: 'Generated on Aug 15, 2024',
      icon: Icons.pie_chart_outline_rounded,
      iconColor: Color(0xFF2662A6),
      iconBg: Color(0xFFEDF3FA),
    ),
    ReportItem(
      title: 'Supplier Audit Report',
      category: 'OPERATIONS',
      categoryBg: Color(0xFFF2ECF7),
      categoryBorder: Color(0xFFE2D5EE),
      categoryColor: Color(0xFF6D38A4),
      pages: '6 pages',
      date: 'Generated on Aug 10, 2024',
      icon: Icons.description_outlined,
      iconColor: Color(0xFF8D6433),
      iconBg: Color(0xFFFAF4EC),
    ),
  ];

  final List<AutomationPipelineItem> _pipelines = const [
    AutomationPipelineItem(
      name: 'Weekly Performance Summary',
      frequency: 'Weekly (Mon)',
      nextDelivery: 'Sep 16, 2024',
      recipients: 'Alex, Sarah, Exec-list',
      status: 'Active',
      isActive: true,
    ),
    AutomationPipelineItem(
      name: 'Monthly Inventory Health Audit',
      frequency: 'Monthly (1st)',
      nextDelivery: 'Oct 01, 2024',
      recipients: 'Alex, Inventory-HQ',
      status: 'Active',
      isActive: true,
    ),
    AutomationPipelineItem(
      name: 'Quarterly P&L Projection',
      frequency: 'Quarterly',
      nextDelivery: 'Oct 01, 2024',
      recipients: 'Alex, Finance-Team',
      status: 'Paused',
      isActive: false,
    ),
    AutomationPipelineItem(
      name: 'Supplier Performance & Sourcing Audit',
      frequency: 'Bi-Weekly (Wed)',
      nextDelivery: 'Sep 25, 2024',
      recipients: 'Alex, Sourcing-Group',
      status: 'Active',
      isActive: true,
    ),
  ];

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFBA8A55), size: 18),
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openScheduleDialog() {
    ScheduleAutomatedReportDialog.show(
      context,
      onScheduled: () {
        _showNotification('New recurring delivery schedule activated for Weekly Sales Summary.');
      },
    );
  }

  void _openCreateCustomReportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFEADBCA)),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF4EC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF0E5D4)),
              ),
              child: const Icon(Icons.add_chart_rounded, size: 18, color: Color(0xFF8D6433)),
            ),
            const SizedBox(width: 12),
            Text(
              'Create Custom Report',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Build a tailored operational or financial report by specifying entities, date ranges, and grouping metrics.',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B6357)),
              ),
              const SizedBox(height: 18),
              Text(
                'Report Name',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF181513)),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDFD5C6)),
                  color: const Color(0xFFFAF8F5),
                ),
                child: Text(
                  'Zone A Quarterly GMV & Return Metrics',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181513)),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Category',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF181513)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFDFD5C6)),
                            color: const Color(0xFFFAF8F5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Sales & Revenue', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF181513))),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF6B6357)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Format',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF181513)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFDFD5C6)),
                            color: const Color(0xFFFAF8F5),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('PDF + CSV Archive', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF181513))),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF6B6357)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF6B6357)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A481B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _showNotification('Custom report generated successfully! Preparing download...');
            },
            child: Text(
              'Generate Report',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Banner
        _buildHeaderBanner(),
        const SizedBox(height: 28),

        // 2. Recent Generated Reports Section
        _buildRecentGeneratedReportsSection(),
        const SizedBox(height: 32),

        // 3. Scheduled Automation Pipelines Section
        _buildScheduledAutomationPipelinesSection(),
        const SizedBox(height: 32),

        // 4. Bottom Row: Quote on Left + Custom Report Card on Right
        _buildBottomRow(),
        const SizedBox(height: 24),
      ],
    );
  }

  // ==========================================
  // 1. HEADER BANNER
  // ==========================================
  Widget _buildHeaderBanner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 880;

        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderTitleLeft(),
              const SizedBox(height: 16),
              _buildHeaderActionsRight(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildHeaderTitleLeft()),
            const SizedBox(width: 24),
            _buildHeaderActionsRight(),
          ],
        );
      },
    );
  }

  Widget _buildHeaderTitleLeft() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Square Icon Badge
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF5EBE1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
          ),
          child: const Center(
            child: Icon(
              Icons.bar_chart_rounded,
              size: 26,
              color: Color(0xFF8D6433),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Studio',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Design, view, and schedule tailored operational intelligence reports.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6357),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActionsRight() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Tagline quote
        Text(
          'Turn your data\ninto smarter decisions.',
          textAlign: TextAlign.end,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 15.5,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF7E5B37),
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),

        // Action Buttons Row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Schedule Report Button
            InkWell(
              onTap: _openScheduleDialog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDFD5C6), width: 1.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: Color(0xFF2B231D),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Schedule Report',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2B231D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Create Custom Report Button
            InkWell(
              onTap: _openCreateCustomReportDialog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFF7A481B),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Create Custom Report',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // 2. RECENT GENERATED REPORTS SECTION
  // ==========================================
  Widget _buildRecentGeneratedReportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Generated Reports',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181513),
              ),
            ),
            InkWell(
              onTap: widget.onViewAllReports ?? () => _showNotification('Showing all 24 generated reports archive.'),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All Reports',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8D6433),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF8D6433),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 4 Cards Grid / Row
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            if (width >= 1050) {
              return Row(
                children: _recentReports.map((report) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: report == _recentReports.last ? 0 : 16,
                      ),
                      child: _buildReportCard(report),
                    ),
                  );
                }).toList(),
              );
            } else if (width >= 620) {
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: _recentReports.map((report) {
                  return SizedBox(
                    width: (width - 14) / 2,
                    child: _buildReportCard(report),
                  );
                }).toList(),
              );
            } else {
              return Column(
                children: _recentReports.map((report) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildReportCard(report),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildReportCard(ReportItem report) {
    return InkWell(
      onTap: () {
        if (widget.onSelectReport != null) {
          widget.onSelectReport!(report.title);
        } else {
          _showNotification('Opening detailed report view for "${report.title}"...');
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon + Category Badge + Pages
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Square Icon Box
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: report.iconBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF0E5D4), width: 1.0),
                ),
                child: Center(
                  child: Icon(
                    report.icon,
                    size: 18,
                    color: report.iconColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Category Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: report.categoryBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: report.categoryBorder, width: 1.0),
                ),
                child: Text(
                  report.category,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: report.categoryColor,
                  ),
                ),
              ),
              const Spacer(),

              // Pages indicator
              Text(
                report.pages,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8C8377),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Report Title
          Text(
            report.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 4),

          // Date Generated
          Text(
            report.date,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8C8377),
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons Row: PDF, Share, Re-run
          Row(
            children: [
              // PDF Button
              _buildPillButton(
                label: 'PDF',
                icon: Icons.download_rounded,
                isHighlight: false,
                onTap: () => _showNotification('Downloading PDF for "${report.title}"...'),
              ),
              const SizedBox(width: 6),

              // Share Button
              _buildPillButton(
                label: 'Share',
                icon: Icons.ios_share_rounded,
                isHighlight: false,
                onTap: () => _showNotification('Share link copied to clipboard for "${report.title}".'),
              ),
              const SizedBox(width: 6),

              // Re-run Button
              _buildPillButton(
                label: 'Re-run',
                icon: Icons.refresh_rounded,
                isHighlight: true,
                onTap: () => _showNotification('Re-running operational intelligence query for "${report.title}"...'),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required bool isHighlight,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isHighlight ? const Color(0xFFFAF4EC) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isHighlight ? const Color(0xFFECDCC8) : const Color(0xFFE5DACB),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12.5,
              color: isHighlight ? const Color(0xFFA86718) : const Color(0xFF2B231D),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.w500,
                color: isHighlight ? const Color(0xFFA86718) : const Color(0xFF2B231D),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. SCHEDULED AUTOMATION PIPELINES SECTION
  // ==========================================
  Widget _buildScheduledAutomationPipelinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Scheduled Automation Pipelines',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181513),
              ),
            ),
            InkWell(
              onTap: widget.onManageAutomations ?? () => _showNotification('Navigating to Automations Management...'),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Manage Automations',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8D6433),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: Color(0xFF8D6433),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Pipelines Table Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth > 860 ? constraints.maxWidth : 860),
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFEADBCA), width: 1.0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: Text(
                                'Report Name',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8C8377),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Frequency',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8C8377),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                'Next Delivery',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8C8377),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                'Recipients',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8C8377),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'Status',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8C8377),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 68,
                              child: Text(
                                'Actions',
                                textAlign: TextAlign.end,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8C8377),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Rows
                      ..._pipelines.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final isLast = index == _pipelines.length - 1;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : const Border(
                                    bottom: BorderSide(color: Color(0xFFF3EDE4), width: 1.0),
                                  ),
                          ),
                          child: Row(
                            children: [
                              // Report Name
                              Expanded(
                                flex: 6,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.description_outlined,
                                      size: 17,
                                      color: Color(0xFF8C8377),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF181513),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Frequency
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.frequency,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF5E574E),
                                  ),
                                ),
                              ),

                              // Next Delivery
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.nextDelivery,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF5E574E),
                                  ),
                                ),
                              ),

                              // Recipients
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.recipients,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF5E574E),
                                  ),
                                ),
                              ),

                              // Status Badge
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: item.isActive ? const Color(0xFFE6F5EA) : const Color(0xFFEFECE7),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: item.isActive ? const Color(0xFFC6E7CE) : const Color(0xFFDFDAD1),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Text(
                                      item.status,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: item.isActive ? const Color(0xFF257B39) : const Color(0xFF736B5E),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Actions
                              SizedBox(
                                width: 68,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF5E574E)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'Edit pipeline',
                                      onPressed: () => _showNotification('Opening pipeline configuration for "${item.name}"...'),
                                    ),
                                    const SizedBox(width: 10),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_horiz_rounded, size: 18, color: Color(0xFF5E574E)),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      color: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: const BorderSide(color: Color(0xFFEADBCA)),
                                      ),
                                      onSelected: (action) {
                                        _showNotification('Action "$action" executed on "${item.name}".');
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(value: 'run_now', child: Text('Run Pipeline Now')),
                                        const PopupMenuItem(value: 'pause', child: Text('Toggle Pause/Resume')),
                                        const PopupMenuItem(value: 'view_history', child: Text('View Delivery History')),
                                        const PopupMenuDivider(),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete Pipeline', style: TextStyle(color: Color(0xFFDC2626))),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 4. BOTTOM ROW: QUOTE & CUSTOM REPORT CARD
  // ==========================================
  Widget _buildBottomRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (!isWide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuote(),
              const SizedBox(height: 20),
              _buildCustomReportBanner(),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildQuote()),
            const SizedBox(width: 24),
            _buildCustomReportBanner(),
          ],
        );
      },
    );
  }

  Widget _buildQuote() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Gold vertical bar
        Container(
          width: 2.5,
          height: 38,
          color: const Color(0xFFBA8A55),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '“Reports don’t just show what happened,\nthey help you decide what’s next.”',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 15.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF362B21),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '— ThreadStock',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF7E766B),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomReportBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E9DD),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
            ),
            child: const Center(
              child: Icon(
                Icons.bar_chart_rounded,
                size: 20,
                color: Color(0xFF8D6433),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Text details
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Need a custom report?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Create a tailored report with specific fields, filters, and schedules.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6357),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),

          // Action Button
          InkWell(
            onTap: _openCreateCustomReportDialog,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC89B67), width: 1.0),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.add_rounded,
                    size: 15,
                    color: Color(0xFF8D6433),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Create Custom Report',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8D6433),
                    ),
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
