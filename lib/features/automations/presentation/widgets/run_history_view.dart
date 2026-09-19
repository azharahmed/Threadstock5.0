import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RunHistoryView extends StatefulWidget {
  const RunHistoryView({
    super.key,
    this.onSelectAutomation,
    this.onSelectRun,
    this.onExportLogs,
    this.onViewInsights,
  });

  final void Function(String automationName)? onSelectAutomation;
  final void Function(String runId)? onSelectRun;
  final VoidCallback? onExportLogs;
  final VoidCallback? onViewInsights;

  @override
  State<RunHistoryView> createState() => _RunHistoryViewState();
}

enum _RunStatus { all, success, failed, skipped }

class _RunLogRecord {
  const _RunLogRecord({
    required this.runId,
    required this.automationName,
    required this.triggerTime,
    required this.duration,
    required this.status,
    required this.itemsAffected,
    required this.action,
  });

  final String runId;
  final String automationName;
  final String triggerTime;
  final String duration;
  final _RunStatus status;
  final String itemsAffected;
  final String action;
}

class _RunHistoryViewState extends State<RunHistoryView> {
  _RunStatus _selectedStatus = _RunStatus.all;
  String _selectedAutomation = 'All Automations';
  String _selectedDateRange = 'Last 30 Days';
  String _selectedLocation = 'All Locations';
  int _currentPage = 1;

  final List<_RunLogRecord> _allRuns = const [
    _RunLogRecord(
      runId: 'RUN-1848',
      automationName: 'Low Stock Auto-Reorder',
      triggerTime: 'Sep 15, 09:30 AM',
      duration: '2.1s',
      status: _RunStatus.success,
      itemsAffected: '3 SKUs',
      action: 'PO-2891 Created',
    ),
    _RunLogRecord(
      runId: 'RUN-1847',
      automationName: 'Low Stock Auto-Reorder',
      triggerTime: 'Sep 15, 08:12 AM',
      duration: '0.4s',
      status: _RunStatus.failed,
      itemsAffected: '18 SKUs',
      action: 'None — API Timeout',
    ),
    _RunLogRecord(
      runId: 'RUN-1846',
      automationName: 'Holiday Pricing Markdown',
      triggerTime: 'Sep 14, 11:45 PM',
      duration: '1.2s',
      status: _RunStatus.success,
      itemsAffected: '42 SKUs',
      action: 'Markdown Approved',
    ),
    _RunLogRecord(
      runId: 'RUN-1845',
      automationName: 'Supplier Sync',
      triggerTime: 'Sep 14, 06:00 AM',
      duration: '4.2s',
      status: _RunStatus.success,
      itemsAffected: '150 SKUs',
      action: 'Inventory Pulled',
    ),
    _RunLogRecord(
      runId: 'RUN-1844',
      automationName: 'Low Stock Auto-Reorder',
      triggerTime: 'Sep 14, 05:15 AM',
      duration: '1.8s',
      status: _RunStatus.success,
      itemsAffected: '1 SKU',
      action: 'PO-2884 Created',
    ),
    _RunLogRecord(
      runId: 'RUN-1843',
      automationName: 'Auto Stock Adjustment',
      triggerTime: 'Sep 13, 02:30 PM',
      duration: '0.1s',
      status: _RunStatus.skipped,
      itemsAffected: '0 SKUs',
      action: 'No threshold hit',
    ),
    _RunLogRecord(
      runId: 'RUN-1842',
      automationName: 'Weekly Report Builder',
      triggerTime: 'Sep 13, 08:00 AM',
      duration: '3.5s',
      status: _RunStatus.success,
      itemsAffected: '1 Report',
      action: 'Email Dispatched',
    ),
    _RunLogRecord(
      runId: 'RUN-1841',
      automationName: 'Supplier Sync',
      triggerTime: 'Sep 12, 11:20 PM',
      duration: '4.0s',
      status: _RunStatus.success,
      itemsAffected: '132 SKUs',
      action: 'Inventory Pulled',
    ),
    _RunLogRecord(
      runId: 'RUN-1840',
      automationName: 'Dead Stock Analysis',
      triggerTime: 'Sep 12, 06:15 PM',
      duration: '2.3s',
      status: _RunStatus.success,
      itemsAffected: '28 SKUs',
      action: 'Report Generated',
    ),
    _RunLogRecord(
      runId: 'RUN-1839',
      automationName: 'Low Stock Auto-Reorder',
      triggerTime: 'Sep 12, 05:00 AM',
      duration: '1.6s',
      status: _RunStatus.success,
      itemsAffected: '6 SKUs',
      action: 'PO-2879 Created',
    ),
  ];

  List<_RunLogRecord> get _filteredRuns {
    return _allRuns.where((run) {
      if (_selectedStatus != _RunStatus.all && run.status != _selectedStatus) {
        return false;
      }
      if (_selectedAutomation != 'All Automations' &&
          run.automationName != _selectedAutomation) {
        return false;
      }
      return true;
    }).toList();
  }

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Controls Bar (Segmented Status Pills + Dropdowns)
        _buildTopFilterBar(),
        const SizedBox(height: 18),

        // 2. 4 KPI Metrics Cards
        _buildKpiCardsRow(),
        const SizedBox(height: 18),

        // 3. Main Run History Data Table Card
        _buildRunHistoryTableCard(),
        const SizedBox(height: 18),

        // 4. Bottom Automation Insight Banner
        _buildAutomationInsightBanner(),
      ],
    );
  }

  // ========================================================
  // 1. TOP FILTER BAR
  // ========================================================
  Widget _buildTopFilterBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 860;

        final segmentedTabs = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusTab(
              label: 'All',
              count: '234',
              status: _RunStatus.all,
            ),
            const SizedBox(width: 8),
            _buildStatusTab(
              label: 'Success',
              count: '228',
              status: _RunStatus.success,
            ),
            const SizedBox(width: 8),
            _buildStatusTab(
              label: 'Failed',
              count: '4',
              status: _RunStatus.failed,
            ),
            const SizedBox(width: 8),
            _buildStatusTab(
              label: 'Skipped',
              count: '2',
              status: _RunStatus.skipped,
            ),
          ],
        );

        final dropdowns = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // All Automations
            _buildDropdown(
              value: _selectedAutomation,
              items: const [
                'All Automations',
                'Low Stock Auto-Reorder',
                'Holiday Pricing Markdown',
                'Supplier Sync',
                'Auto Stock Adjustment',
                'Weekly Report Builder',
                'Dead Stock Analysis',
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedAutomation = val);
                }
              },
            ),
            const SizedBox(width: 10),

            // Date Range
            _buildDropdown(
              icon: Icons.calendar_today_outlined,
              value: _selectedDateRange,
              items: const [
                'Last 7 Days',
                'Last 30 Days',
                'Last 90 Days',
                'This Quarter',
                'All Time',
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedDateRange = val);
                }
              },
            ),
            const SizedBox(width: 10),

            // All Locations
            _buildDropdown(
              icon: Icons.location_on_outlined,
              value: _selectedLocation,
              items: const [
                'All Locations',
                'Central Warehouse',
                'Delhi Flagship',
                'Mumbai Boutique',
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedLocation = val);
                }
              },
            ),
          ],
        );

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: segmentedTabs,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: dropdowns,
              ),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            segmentedTabs,
            dropdowns,
          ],
        );
      },
    );
  }

  Widget _buildStatusTab({
    required String label,
    required String count,
    required _RunStatus status,
  }) {
    final isSelected = _selectedStatus == status;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedStatus = status;
        });
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF181513) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF181513) : const Color(0xFFDFD7CB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF181513),
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2C2825)
                    : const Color(0xFFF3EFE9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF6E675F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown({
    IconData? icon,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFDFD7CB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          icon: const Padding(
            padding: EdgeInsets.only(left: 6),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Color(0xFF6E675F),
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 14, color: const Color(0xFF6E675F)),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    item,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ========================================================
  // 2. 4 KPI METRICS CARDS ROW
  // ========================================================
  Widget _buildKpiCardsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (3 * 14)) / 4;

        return Row(
          children: [
            // Card 1: Total Runs
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                iconWidget: const Icon(
                  Icons.play_arrow_outlined,
                  size: 20,
                  color: Color(0xFFBA8A55),
                ),
                iconBg: const Color(0xFFFAF4EC),
                iconBorder: const Color(0xFFF0E5D8),
                label: 'Total Runs',
                value: '234',
                badgeText: null,
                badgeBg: null,
                badgeTextColor: null,
                sparklineColor: const Color(0xFFB0BEC5),
                sparklineHeights: const [0.4, 0.65, 0.45, 0.85, 1.0],
              ),
            ),
            const SizedBox(width: 14),

            // Card 2: Success
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                iconWidget: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 19,
                  color: Color(0xFF1E7E45),
                ),
                iconBg: const Color(0xFFEAF7EE),
                iconBorder: const Color(0xFFCEEBD6),
                label: 'Success',
                value: '228',
                badgeText: '97.4%',
                badgeBg: const Color(0xFFEAF7EE),
                badgeTextColor: const Color(0xFF1E7E45),
                sparklineColor: const Color(0xFF86EFAC),
                sparklineHeights: const [0.5, 0.7, 0.6, 0.9, 1.0],
              ),
            ),
            const SizedBox(width: 14),

            // Card 3: Failed
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                iconWidget: const Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: Color(0xFFDC2626),
                ),
                iconBg: const Color(0xFFFDE8E8),
                iconBorder: const Color(0xFFFBCACA),
                label: 'Failed',
                value: '4',
                badgeText: '1.7%',
                badgeBg: const Color(0xFFFDE8E8),
                badgeTextColor: const Color(0xFFDC2626),
                sparklineColor: const Color(0xFFFCA5A5),
                sparklineHeights: const [0.2, 0.6, 0.3, 0.8, 0.5],
              ),
            ),
            const SizedBox(width: 14),

            // Card 4: Skipped
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                iconWidget: const Icon(
                  Icons.remove_circle_outline_rounded,
                  size: 19,
                  color: Color(0xFF64748B),
                ),
                iconBg: const Color(0xFFF1F5F9),
                iconBorder: const Color(0xFFE2E8F0),
                label: 'Skipped',
                value: '2',
                badgeText: '0.9%',
                badgeBg: const Color(0xFFF1F5F9),
                badgeTextColor: const Color(0xFF64748B),
                sparklineColor: const Color(0xFFCBD5E1),
                sparklineHeights: const [0.3, 0.4, 0.7, 0.5, 0.6],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required Widget iconWidget,
    required Color iconBg,
    required Color iconBorder,
    required String label,
    required String value,
    String? badgeText,
    Color? badgeBg,
    Color? badgeTextColor,
    required Color sparklineColor,
    required List<double> sparklineHeights,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEBE4DA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Box
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: iconBorder),
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: 12),

          // Label & Value with Badge
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
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: badgeBg ?? const Color(0xFFEAF7EE),
                          borderRadius: BorderRadius.circular(3.5),
                        ),
                        child: Text(
                          badgeText,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: badgeTextColor ?? const Color(0xFF1E7E45),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Mini Vertical Bar Chart (Sparkline)
          SizedBox(
            width: 34,
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: sparklineHeights.map((h) {
                return Container(
                  width: 4,
                  height: 24 * h,
                  decoration: BoxDecoration(
                    color: sparklineColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 3. MAIN RUN HISTORY TABLE CARD
  // ========================================================
  Widget _buildRunHistoryTableCard() {
    final runs = _filteredRuns;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Run History',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Detailed log of all automation runs and their outcomes.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6E675F),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: widget.onExportLogs ??
                    () => _showToast('Exporting automation run logs to CSV...'),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFDFD7CB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.file_download_outlined,
                        size: 15,
                        color: Color(0xFF181513),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Export Logs',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF9F6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                _buildHeaderCell('Run ID', flex: 11),
                _buildHeaderCell('Automation Name', flex: 20),
                _buildHeaderCell('Trigger Time', flex: 15),
                _buildHeaderCell('Duration', flex: 9),
                _buildHeaderCell('Status', flex: 10),
                _buildHeaderCell('Items Affected', flex: 12),
                _buildHeaderCell('Action', flex: 17),
                const SizedBox(width: 24), // Action menu column
              ],
            ),
          ),
          const SizedBox(height: 2),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: runs.length,
            separatorBuilder: (context, index) => const Divider(
              color: Color(0xFFF2ECE4),
              height: 1,
              thickness: 1,
            ),
            itemBuilder: (context, index) {
              final run = runs[index];

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12.5),
                child: Row(
                  children: [
                    // Run ID
                    Expanded(
                      flex: 11,
                      child: InkWell(
                        onTap: () {
                          if (widget.onSelectRun != null) {
                            widget.onSelectRun!(run.runId);
                          } else {
                            _showToast('Viewing execution profile for ${run.runId}');
                          }
                        },
                        child: Text(
                          run.runId,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),
                    ),

                    // Automation Name (Clickable link)
                    Expanded(
                      flex: 20,
                      child: InkWell(
                        onTap: () {
                          if (widget.onSelectAutomation != null) {
                            widget.onSelectAutomation!(run.automationName);
                          } else {
                            _showToast('Viewing details for ${run.automationName}');
                          }
                        },
                        child: Text(
                          run.automationName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),
                    ),

                    // Trigger Time
                    Expanded(
                      flex: 15,
                      child: Text(
                        run.triggerTime,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF6E675F),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    // Duration
                    Expanded(
                      flex: 9,
                      child: Text(
                        run.duration,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF6E675F),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    // Status Badge
                    Expanded(
                      flex: 10,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildStatusBadge(run.status),
                      ),
                    ),

                    // Items Affected
                    Expanded(
                      flex: 12,
                      child: Text(
                        run.itemsAffected,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF475569),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Action
                    Expanded(
                      flex: 17,
                      child: Text(
                        run.action,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF181513),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    // Three dots menu
                    InkWell(
                      onTap: () => _showToast('Options for ${run.runId}'),
                      borderRadius: BorderRadius.circular(4),
                      child: const Padding(
                        padding: EdgeInsets.all(3),
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
          const SizedBox(height: 16),

          // Pagination Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing 1-10 of 234 runs',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF6E675F),
                  fontWeight: FontWeight.w400,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Prev
                  _buildPageNavButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () {
                      if (_currentPage > 1) {
                        setState(() => _currentPage--);
                      }
                    },
                  ),
                  const SizedBox(width: 4),

                  // Page Numbers
                  _buildPageNumberButton(1),
                  _buildPageNumberButton(2),
                  _buildPageNumberButton(3),
                  _buildPageNumberButton(4),
                  _buildPageNumberButton(5),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Text('...', style: TextStyle(color: Color(0xFF8C8276))),
                  ),
                  _buildPageNumberButton(24),
                  const SizedBox(width: 4),

                  // Next
                  _buildPageNavButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () {
                      if (_currentPage < 24) {
                        setState(() => _currentPage++);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex}) {
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

  Widget _buildStatusBadge(_RunStatus status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case _RunStatus.success:
        bg = const Color(0xFFEAF7EE);
        text = const Color(0xFF1E7E45);
        label = 'Success';
        break;
      case _RunStatus.failed:
        bg = const Color(0xFFFDE8E8);
        text = const Color(0xFFDC2626);
        label = 'Failed';
        break;
      case _RunStatus.skipped:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
        label = 'Skipped';
        break;
      case _RunStatus.all:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF64748B);
        label = 'All';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  Widget _buildPageNumberButton(int page) {
    final isSelected = _currentPage == page;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => setState(() => _currentPage = page),
        borderRadius: BorderRadius.circular(5),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFA86E38) : Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFA86E38)
                  : const Color(0xFFDFD7CB),
            ),
          ),
          child: Center(
            child: Text(
              '$page',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF181513),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: const Color(0xFFDFD7CB)),
        ),
        child: Center(
          child: Icon(icon, size: 16, color: const Color(0xFF6E675F)),
        ),
      ),
    );
  }

  // ========================================================
  // 4. BOTTOM AUTOMATION INSIGHT BANNER
  // ========================================================
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
                  'Your Low Stock Auto-Reorder automation has maintained a 98% success rate over the last 30 days, preventing an estimated 12 stockouts.',
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
            onTap: widget.onViewInsights ??
                () => _showToast('Opening 30-day performance report...'),
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
                    'View Insights',
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
