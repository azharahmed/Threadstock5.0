// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryEventItem {
  const HistoryEventItem({
    required this.id,
    required this.time,
    required this.dotColor,
    required this.isDotHollow,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusBg,
    required this.statusColor,
    this.isSelected = false,
    this.userRequest,
    this.aiResponseSummary,
    this.triggeredBy = 'Store Admin',
    this.assignedLocation = 'Zone A Warehouse',
    this.executionStatus = 'Completed',
    this.relatedItems = '3 SKUs',
    this.executionTime = '2m 14s',
    this.created = 'Jan 24, 2027, 10:16 AM',
    required this.category, // 'recommendations', 'user_queries', 'reports', 'automations'
  });

  final String id;
  final String time;
  final Color dotColor;
  final bool isDotHollow;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String statusLabel;
  final Color statusBg;
  final Color statusColor;
  final bool isSelected;
  final String? userRequest;
  final String? aiResponseSummary;
  final String triggeredBy;
  final String assignedLocation;
  final String executionStatus;
  final String relatedItems;
  final String executionTime;
  final String created;
  final String category;
}

class AiHistoryView extends StatefulWidget {
  const AiHistoryView({
    super.key,
    this.onExportHistory,
    this.onViewRelatedActions,
    this.onReRunDiagnostic,
  });

  final VoidCallback? onExportHistory;
  final VoidCallback? onViewRelatedActions;
  final VoidCallback? onReRunDiagnostic;

  @override
  State<AiHistoryView> createState() => _AiHistoryViewState();
}

class _AiHistoryViewState extends State<AiHistoryView> {
  int _selectedFilterIndex =
      0; // 0: All, 1: Recommendations, 2: User Queries, 3: Generated Reports, 4: Automations
  String _selectedDateRange = 'Date Range';
  String _selectedActionType = 'Action Type';
  bool _isInspectorOpen = true;

  late String _selectedItemId;

  final List<HistoryEventItem> _todayEvents = const [];

  final List<HistoryEventItem> _yesterdayEvents = const [];

  @override
  void initState() {
    super.initState();
    _selectedItemId = '';
  }

  HistoryEventItem? get _selectedItem {
    for (final item in _todayEvents) {
      if (item.id == _selectedItemId) return item;
    }
    for (final item in _yesterdayEvents) {
      if (item.id == _selectedItemId) return item;
    }
    return null;
  }

  bool _matchesCategory(HistoryEventItem item) {
    if (_selectedFilterIndex == 0) return true;
    if (_selectedFilterIndex == 1) return item.category == 'recommendations';
    if (_selectedFilterIndex == 2) return item.category == 'user_queries';
    if (_selectedFilterIndex == 3) return item.category == 'reports';
    if (_selectedFilterIndex == 4) return item.category == 'automations';
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final filteredToday = _todayEvents.where(_matchesCategory).toList();
    final filteredYesterday = _yesterdayEvents.where(_matchesCategory).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1060;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Main Timeline View
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),
                      _buildFilterRow(),
                      const SizedBox(height: 22),
                      _buildTimelineList(filteredToday, filteredYesterday),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                if (_isInspectorOpen) ...[
                  const SizedBox(width: 22),
                  // Right Column: Activity Inspector Panel
                  SizedBox(width: 350, child: _buildActivityInspector()),
                ],
              ],
            );
          }

          // Stacked Layout for narrow screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildFilterRow(),
              const SizedBox(height: 22),
              _buildTimelineList(filteredToday, filteredYesterday),
              if (_isInspectorOpen) ...[
                const SizedBox(height: 24),
                _buildActivityInspector(),
              ],
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // 1. Header with Title & Export History button
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI History',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A comprehensive audit log of recommendations, custom queries, and automated actions.',
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
        InkWell(
          onTap: widget.onExportHistory,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.download_rounded,
                  size: 16,
                  color: Color(0xFF181513),
                ),
                const SizedBox(width: 8),
                Text(
                  'Export History',
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
      ],
    );
  }

  // 2. Filter Tabs & Date/Action Dropdowns
  Widget _buildFilterRow() {
    final tabs = [
      'All',
      'Recommendations',
      'User Queries',
      'Generated Reports',
      'Automations',
    ];

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(tabs.length, (idx) {
                final isSelected = _selectedFilterIndex == idx;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedFilterIndex = idx;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF181513)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF181513)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        tabs[idx],
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Date Range Dropdown
        PopupMenuButton<String>(
          tooltip: 'Select date range',
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onSelected: (val) {
            setState(() => _selectedDateRange = val);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'All Time', child: Text('All Time')),
            const PopupMenuItem(value: 'Today', child: Text('Today')),
            const PopupMenuItem(
              value: 'Past 7 Days',
              child: Text('Past 7 Days'),
            ),
            const PopupMenuItem(
              value: 'Past 30 Days',
              child: Text('Past 30 Days'),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedDateRange,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Action Type Dropdown
        PopupMenuButton<String>(
          tooltip: 'Select action type',
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onSelected: (val) {
            setState(() => _selectedActionType = val);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'All Actions',
              child: Text('All Actions'),
            ),
            const PopupMenuItem(
              value: 'Replenishment',
              child: Text('Replenishment'),
            ),
            const PopupMenuItem(value: 'Transfers', child: Text('Transfers')),
            const PopupMenuItem(value: 'Pricing', child: Text('Pricing')),
            const PopupMenuItem(value: 'Anomalies', child: Text('Anomalies')),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedActionType,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Timeline Event List
  Widget _buildTimelineList(
    List<HistoryEventItem> todayItems,
    List<HistoryEventItem> yesterdayItems,
  ) {
    if (todayItems.isEmpty && yesterdayItems.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.history_rounded,
              size: 36,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              'No AI history recorded yet',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Audit logs will populate as AI recommendations, queries, and automated actions occur.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (todayItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'TODAY',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ...todayItems.map(_buildEventRow),
          const SizedBox(height: 22),
        ],
        if (yesterdayItems.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Text(
              'YESTERDAY',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ...yesterdayItems.map(_buildEventRow),
        ],
      ],
    );
  }

  // Single Timeline Event Card Row
  Widget _buildEventRow(HistoryEventItem item) {
    final isSelected = item.id == _selectedItemId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedItemId = item.id;
            _isInspectorOpen = true;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFFFDF9) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFFDE68A)
                  : const Color(0xFFE2E8F0),
              width: isSelected ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Dot Indicator
              if (item.isDotHollow)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: item.dotColor, width: 2),
                  ),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 12),

              // Time Stamp
              SizedBox(
                width: 65,
                child: Text(
                  item.time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Circular Icon Badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: 18, color: item.iconColor),
              ),
              const SizedBox(width: 14),

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: item.statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: item.statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Action ⋮
              IconButton(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _selectedItemId = item.id;
                    _isInspectorOpen = true;
                  });
                },
                tooltip: 'More actions',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. Right Column: Activity Inspector Panel
  Widget _buildActivityInspector() {
    final item = _selectedItem;
    if (item == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Inspector Header with Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity Inspector',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              Row(
                children: [
                  Text(
                    '${item.time} Today',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isInspectorOpen = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Request Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'USER REQUEST',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.userRequest ??
                      '“Which stores are currently at the highest stockout risk prior to the holiday weekend?”',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFB37B42),
                      child: Text(
                        'AM',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.triggeredBy,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF181513),
                          ),
                        ),
                        Text(
                          'No workspace configured',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // AI Response Summary Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI RESPONSE SUMMARY',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.aiResponseSummary ??
                      'Lucknow Regent reported 3 core style sell-outs. Intercepted with 42 transfer recommendation. Safety coverage threshold secured.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF181513),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Full response audit trail loaded for ${item.id}.',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                        backgroundColor: const Color(0xFF1E1C1A),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View Full Response',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Color(0xFFB45309),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Metadata key-values
          _buildInspectorMetaRow('Triggered By', item.triggeredBy),
          const SizedBox(height: 10),
          _buildInspectorMetaRow('Assigned Location', item.assignedLocation),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Execution Status',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.executionStatus,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildInspectorMetaRow('Related Items', item.relatedItems),
          const SizedBox(height: 10),
          _buildInspectorMetaRow('Execution Time', item.executionTime),
          const SizedBox(height: 10),
          _buildInspectorMetaRow('Created', item.created),
          const SizedBox(height: 20),

          // Re-Run Diagnostic Query Button (Solid Black)
          InkWell(
            onTap: widget.onReRunDiagnostic,
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
                  const Icon(
                    Icons.play_arrow_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Re-Run Diagnostic Query',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // View Related Actions Button (White Outline)
          InkWell(
            onTap: widget.onViewRelatedActions,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.article_outlined,
                    size: 15,
                    color: Color(0xFF181513),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View Related Actions',
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
    );
  }

  Widget _buildInspectorMetaRow(String label, String value) {
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
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181513),
          ),
        ),
      ],
    );
  }
}
