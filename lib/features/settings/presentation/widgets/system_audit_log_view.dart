// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

enum AuditActionType { update, create, delete, login }

class AuditLogItem {
  final String timestamp;
  final String user;
  final AuditActionType action;
  final String module;
  final String description;
  final String ipAddress;

  const AuditLogItem({
    required this.timestamp,
    required this.user,
    required this.action,
    required this.module,
    required this.description,
    required this.ipAddress,
  });
}

class SystemAuditLogView extends StatefulWidget {
  final VoidCallback? onBackToSettings;
  final void Function(String title, String subtitle)? onSubNavChanged;
  final void Function(String sectionKey)? onSelectSection;

  const SystemAuditLogView({
    super.key,
    this.onBackToSettings,
    this.onSubNavChanged,
    this.onSelectSection,
  });

  @override
  State<SystemAuditLogView> createState() => _SystemAuditLogViewState();
}

class _SystemAuditLogViewState extends State<SystemAuditLogView> {
  int _activeTabIndex = 4; // "Audit Log" is index 4
  String _selectedWarehouse = 'Central Warehouse (Zone A)';

  final List<String> _tabs = const [
    'Purchasing Defaults',
    'Transfer Settings',
    'Import / Export',
    'API & Webhooks',
    'Audit Log',
  ];

  final List<String> _warehouses = const [
    'Central Warehouse (Zone A)',
    'Delhi Flagship (Zone B)',
    'Mumbai Boutique (Zone C)',
  ];

  // Filters
  String _selectedDateRange = 'Past 7 Days';
  String _selectedUser = 'All Users';
  String _selectedAction = 'Update';
  String _selectedModule = 'All Modules';

  final List<String> _dateRangeOptions = const [
    'Past 7 Days',
    'Today',
    'Past 30 Days',
    'This Quarter',
    'Custom Range',
  ];

  final List<String> _userOptions = const [
    'All Users',
    'Alex Mercer',
    'Priya Sharma',
    'System Daemon',
  ];

  final List<String> _actionOptions = const [
    'All Actions',
    'Update',
    'Create',
    'Delete',
  ];

  final List<String> _moduleOptions = const [
    'All Modules',
    'Purchasing',
    'Transfers',
    'API & Webhooks',
    'Inventory Rules',
    'Security & Auth',
  ];

  final List<AuditLogItem> _allLogs = const [
    AuditLogItem(
      timestamp: 'Oct 24, 2026, 11:24:02 AM',
      user: 'Alex Mercer',
      action: AuditActionType.update,
      module: 'Purchasing',
      description: 'Changed default PO threshold from ₹40,000 to ₹50,000',
      ipAddress: '192.168.1.42',
    ),
    AuditLogItem(
      timestamp: 'Oct 24, 2026, 10:15:40 AM',
      user: 'Priya Sharma',
      action: AuditActionType.create,
      module: 'Transfers',
      description: 'Initiated Transfer T-1084 from Zone A to Delhi flagship',
      ipAddress: '192.168.2.115',
    ),
    AuditLogItem(
      timestamp: 'Oct 23, 2026, 05:04:12 PM',
      user: 'Alex Mercer',
      action: AuditActionType.delete,
      module: 'API & Webhooks',
      description: 'Deleted old production legacy webhook endpoint',
      ipAddress: '192.168.1.42',
    ),
  ];

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _selectedDateRange = 'Past 7 Days';
      _selectedUser = 'All Users';
      _selectedAction = 'Update';
      _selectedModule = 'All Modules';
    });
    _showFeedback('Filters reset to default');
  }

  void _exportCsv() {
    _showFeedback('Exporting filtered audit log to CSV...');
  }

  @override
  Widget build(BuildContext context) {
    return DesktopContentConstraint(
      maxWidth: 1320,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Area
            _buildHeader(),

            const SizedBox(height: 20),

            // Operational Sub-Navigation Tabs Row
            _buildTabsRow(),

            const SizedBox(height: 24),

            // Filter Controls Card
            _buildFilterCard(),

            const SizedBox(height: 24),

            // Audit Log Entries Table Card
            _buildAuditLogCard(),
          ],
        ),
      ),
    );
  }

  // Header matching screenshot
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Warm circular avatar with sheet/article icon
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFFAF2E6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.article_outlined,
            size: 26,
            color: Color(0xFF7A481B),
          ),
        ),

        const SizedBox(width: 16),

        // Title and Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Audit Log',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track all system changes, user actions, and important events across ThreadStock.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6357),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Location Selector Dropdown
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDFD4C5)),
          ),
          child: PopupMenuButton<String>(
            tooltip: 'Select Location',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFFEADBCA)),
            ),
            offset: const Offset(0, 42),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context) => _warehouses.map((wh) {
              return PopupMenuItem<String>(
                value: wh,
                child: Row(
                  children: [
                    Icon(
                      Icons.warehouse_outlined,
                      size: 16,
                      color: wh == _selectedWarehouse
                          ? const Color(0xFF7A481B)
                          : const Color(0xFF8C827A),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      wh,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: wh == _selectedWarehouse
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onSelected: (val) {
              setState(() => _selectedWarehouse = val);
              widget.onSubNavChanged?.call(
                'Settings > System Audit Log > $val',
                'Track all system changes, user actions, and important events across ThreadStock.',
              );
              _showFeedback('Switched to $val');
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warehouse_outlined,
                    size: 17,
                    color: Color(0xFF7A481B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedWarehouse,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Color(0xFF5E574E),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Operational Sub-Navigation Tabs Row
  Widget _buildTabsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < _tabs.length; i++) ...[
            _buildTabPill(
              title: _tabs[i],
              isSelected: _activeTabIndex == i,
              onTap: () {
                setState(() => _activeTabIndex = i);
                if (i == 0) {
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('purchasing_defaults');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > Purchasing Defaults > Central Warehouse (Zone A)',
                      'Configure buying, receiving and cost settings for your business.',
                    );
                  }
                } else if (i == 1) {
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('transfer_settings');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > Transfer Settings > Central Warehouse (Zone A)',
                      'Configure stock transfer workflows, transit times and receiving preferences.',
                    );
                  }
                } else if (i == 2) {
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('import_export');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > Import / Export Center > Central Warehouse (Zone A)',
                      'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.',
                    );
                  }
                } else if (i == 3) {
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('api_webhooks');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > API & Webhooks > Central Warehouse (Zone A)',
                      'Manage API access, configure webhooks, and integrate with external systems.',
                    );
                  }
                } else {
                  _showFeedback('Viewing ${_tabs[i]}');
                }
              },
            ),
            if (i < _tabs.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7A481B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7A481B) : const Color(0xFFDFD4C5),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF181513),
          ),
        ),
      ),
    );
  }

  // Filter Bar Card
  Widget _buildFilterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 950;

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDateRangeFilter()),
                    const SizedBox(width: 14),
                    Expanded(child: _buildUserFilter()),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildActionFilter()),
                    const SizedBox(width: 14),
                    Expanded(child: _buildModuleFilter()),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildResetButton(),
                    const SizedBox(width: 10),
                    _buildExportButton(),
                  ],
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 1. Date Range
              Expanded(flex: 3, child: _buildDateRangeFilter()),
              const SizedBox(width: 14),

              // 2. User
              Expanded(flex: 3, child: _buildUserFilter()),
              const SizedBox(width: 14),

              // 3. Action Type
              Expanded(flex: 3, child: _buildActionFilter()),
              const SizedBox(width: 14),

              // 4. Module
              Expanded(flex: 3, child: _buildModuleFilter()),
              const SizedBox(width: 18),

              // 5. Reset Button
              _buildResetButton(),
              const SizedBox(width: 10),

              // 6. Export CSV Button
              _buildExportButton(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B6357),
          ),
        ),
        const SizedBox(height: 6),
        _buildDropdownContainer(
          icon: Icons.calendar_today_outlined,
          currentValue: _selectedDateRange,
          options: _dateRangeOptions,
          onSelected: (val) => setState(() => _selectedDateRange = val),
        ),
      ],
    );
  }

  Widget _buildUserFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B6357),
          ),
        ),
        const SizedBox(height: 6),
        _buildDropdownContainer(
          icon: Icons.person_outline_rounded,
          currentValue: _selectedUser,
          options: _userOptions,
          onSelected: (val) => setState(() => _selectedUser = val),
        ),
      ],
    );
  }

  Widget _buildActionFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Action Type',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B6357),
          ),
        ),
        const SizedBox(height: 6),
        _buildDropdownContainer(
          icon: Icons.bolt_rounded,
          currentValue: _selectedAction,
          options: _actionOptions,
          onSelected: (val) => setState(() => _selectedAction = val),
        ),
      ],
    );
  }

  Widget _buildModuleFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Module',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B6357),
          ),
        ),
        const SizedBox(height: 6),
        _buildDropdownContainer(
          icon: Icons.grid_view_rounded,
          currentValue: _selectedModule,
          options: _moduleOptions,
          onSelected: (val) => setState(() => _selectedModule = val),
        ),
      ],
    );
  }

  Widget _buildDropdownContainer({
    required IconData icon,
    required String currentValue,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5DCD2)),
      ),
      child: PopupMenuButton<String>(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFFEADBCA)),
        ),
        offset: const Offset(0, 42),
        onSelected: onSelected,
        itemBuilder: (ctx) => options.map((opt) {
          final isSel = opt == currentValue;
          return PopupMenuItem(
            value: opt,
            child: Text(
              opt,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                color: isSel ? const Color(0xFF7A481B) : const Color(0xFF181513),
              ),
            ),
          );
        }).toList(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF7E766B)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentValue,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181513),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Color(0xFF5E574E),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: _resetFilters,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          side: const BorderSide(color: Color(0xFFDFD4C5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          backgroundColor: Colors.white,
        ),
        child: Text(
          'Reset',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181513),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: _exportCsv,
        icon: const Icon(Icons.download_outlined, size: 16, color: Colors.white),
        label: Text(
          'Export CSV',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2A160A),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  // Audit Log Entries Table Card
  Widget _buildAuditLogCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audit Log Entries',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'View system activity and changes across all modules.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  RichText(
                    text: TextSpan(
                      text: 'Total Records: ',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                      children: [
                        TextSpan(
                          text: '${_allLogs.length}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Pagination Arrows
                  _buildPaginationButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => _showFeedback('Already on first page'),
                  ),
                  const SizedBox(width: 6),
                  _buildPaginationButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => _showFeedback('No more pages'),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Table Header
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Timestamp',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5E574E),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'User',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5E574E),
                  ),
                ),
              ),
              Expanded(
                flex: 15,
                child: Text(
                  'Action',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5E574E),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Module',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5E574E),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'Description',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5E574E),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'IP Address',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5E574E),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  'Actions',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5E574E),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF0E7DD), height: 1, thickness: 1),

          // Table Rows
          for (int i = 0; i < _allLogs.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      _allLogs[i].timestamp,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF5E574E),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _allLogs[i].user,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 15,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _buildActionBadge(_allLogs[i].action),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _allLogs[i].module,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF5E574E),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      _allLogs[i].description,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF5E574E),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _allLogs[i].ipAddress,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF5E574E),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: Color(0xFF7E766B),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (action) {
                          _showFeedback('Selected: $action');
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'view_json',
                            child: Text(
                              'View Event JSON',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'filter_user',
                            child: Text(
                              'Filter by User (${_allLogs[i].user})',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'revert',
                            child: Text(
                              'Revert Action',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFC25424),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < _allLogs.length - 1)
              const Divider(color: Color(0xFFF7F1EA), height: 1, thickness: 1),
          ],

          const SizedBox(height: 20),

          // Bottom Retention Notice Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDE5D8)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFF7A481B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Logs retained for 90 days. Contact support for extended retention parameters.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF7E766B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDFD4C5)),
        ),
        child: Center(
          child: Icon(icon, size: 16, color: const Color(0xFF5E574E)),
        ),
      ),
    );
  }

  Widget _buildActionBadge(AuditActionType action) {
    Color bg;
    Color text;
    Color dot;
    String label;

    switch (action) {
      case AuditActionType.update:
        bg = const Color(0xFFEAF2FC);
        text = const Color(0xFF2463EB);
        dot = const Color(0xFF2463EB);
        label = 'Update';
        break;
      case AuditActionType.create:
        bg = const Color(0xFFEAF7EE);
        text = const Color(0xFF1E7E34);
        dot = const Color(0xFF28A745);
        label = 'Create';
        break;
      case AuditActionType.delete:
        bg = const Color(0xFFFCECEB);
        text = const Color(0xFFC53030);
        dot = const Color(0xFFE53E3E);
        label = 'Delete';
        break;
      case AuditActionType.login:
        bg = const Color(0xFFF3EADB);
        text = const Color(0xFF7A481B);
        dot = const Color(0xFF7A481B);
        label = 'Login';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dot,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: text,
            ),
          ),
        ],
      ),
    );
  }
}
