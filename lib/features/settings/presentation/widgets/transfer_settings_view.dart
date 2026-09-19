// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class TransferRouteItem {
  String fromLocation;
  String toLocation;
  int defaultDays;

  TransferRouteItem({
    required this.fromLocation,
    required this.toLocation,
    required this.defaultDays,
  });
}

class TransferSettingsView extends StatefulWidget {
  final VoidCallback? onBackToSettings;
  final void Function(String title, String subtitle)? onSubNavChanged;
  final void Function(String sectionKey)? onSelectSection;

  const TransferSettingsView({
    super.key,
    this.onBackToSettings,
    this.onSubNavChanged,
    this.onSelectSection,
  });

  @override
  State<TransferSettingsView> createState() => _TransferSettingsViewState();
}

class _TransferSettingsViewState extends State<TransferSettingsView> {
  int _activeTabIndex = 1; // "Transfer Settings" is index 1
  int _highlightedStepIndex = 3; // "In Transit" is index 3

  final List<String> _tabs = const [
    'Purchasing Defaults',
    'Transfer Settings',
    'Import / Export',
    'API & Webhooks',
    'Audit Log',
  ];

  final List<String> _workflowSteps = const [
    'Requested',
    'Approved',
    'Dispatched',
    'In Transit',
    'Received',
  ];

  // Routes data
  final List<TransferRouteItem> _routes = [
    TransferRouteItem(
      fromLocation: 'Central Warehouse',
      toLocation: 'Delhi Flagship Hub',
      defaultDays: 2,
    ),
    TransferRouteItem(
      fromLocation: 'Central Warehouse',
      toLocation: 'Mumbai Phoenix',
      defaultDays: 3,
    ),
    TransferRouteItem(
      fromLocation: 'Delhi Flagship Hub',
      toLocation: 'Lucknow Regent',
      defaultDays: 1,
    ),
  ];

  // Transfer Approvals
  final TextEditingController _thresholdAmountController =
      TextEditingController(text: '₹ 10,000');
  bool _autoApproveLowValue = true;

  // Packing & Receiving
  bool _autoGeneratePackingSlips = true;
  bool _includeFinancialCost = false;
  bool _requireItemScan = true;
  bool _allowPartialReceiving = true;

  @override
  void dispose() {
    _thresholdAmountController.dispose();
    super.dispose();
  }

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

  void _showAddRouteDialog() {
    final fromController = TextEditingController();
    final toController = TextEditingController();
    final daysController = TextEditingController(text: '2');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEADBCA)),
          ),
          title: Text(
            'Add Transit Route',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FROM LOCATION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: fromController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Central Warehouse',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFA89F91),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAF8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5DCD2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5DCD2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF7A481B)),
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'TO LOCATION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: toController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Kolkata Hub',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFA89F91),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAF8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5DCD2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5DCD2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF7A481B)),
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'DEFAULT DAYS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '2',
                    filled: true,
                    fillColor: const Color(0xFFFAFAF8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5DCD2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5DCD2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF7A481B)),
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (fromController.text.trim().isEmpty ||
                    toController.text.trim().isEmpty) {
                  return;
                }
                final days = int.tryParse(daysController.text.trim()) ?? 1;
                setState(() {
                  _routes.add(
                    TransferRouteItem(
                      fromLocation: fromController.text.trim(),
                      toLocation: toController.text.trim(),
                      defaultDays: days,
                    ),
                  );
                });
                Navigator.pop(ctx);
                _showFeedback('Added route to ${toController.text.trim()}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A481B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Add Route',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 980;

        return DesktopContentConstraint(
          maxWidth: 1320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Area matching screenshot
                _buildHeader(),

                const SizedBox(height: 20),

                // Sub-Navigation Tabs Row
                _buildTabsRow(),

                const SizedBox(height: 24),

                // 2-Column Grid (4 Cards total)
                if (isNarrow) ...[
                  _buildLeftColumn(),
                  const SizedBox(height: 24),
                  _buildRightColumn(),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Default Transfer Workflow & Transit Time Defaults Per Route
                      Expanded(
                        flex: 52,
                        child: _buildLeftColumn(),
                      ),

                      const SizedBox(width: 24),

                      // Right Column: Transfer Approvals & Packing & Receiving
                      Expanded(
                        flex: 48,
                        child: _buildRightColumn(),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 24),

                // Bottom Pro Tip Banner
                _buildProTipBanner(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Header matching Transfer Settings screenshot
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Warm circular avatar with swap horizontal arrows icon
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFFAF2E6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.swap_horiz_rounded,
            size: 28,
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
                'Transfer Settings',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure stock transfer workflows, transit times and receiving preferences.',
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
                  // Navigate to Purchasing Defaults
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('purchasing_defaults');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > Purchasing Defaults > Central Warehouse (Zone A)',
                      'Configure buying, receiving and cost settings for your business.',
                    );
                  }
                } else if (i == 2) {
                  // Navigate to Import / Export Center
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('import_export');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > Import / Export Center > Central Warehouse (Zone A)',
                      'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.',
                    );
                  }
                } else if (i == 3) {
                  // Navigate to API & Webhooks
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('api_webhooks');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > API & Webhooks > Central Warehouse (Zone A)',
                      'Manage API access, configure webhooks, and integrate with external systems.',
                    );
                  }
                } else if (i == 4) {
                  // Navigate to System Audit Log
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('audit_log');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > System Audit Log > Central Warehouse (Zone A)',
                      'Track all system changes, user actions, and important events across ThreadStock.',
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

  // Left Column containing Default Transfer Workflow & Transit Time Defaults Per Route
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Default Transfer Workflow
        _buildDefaultTransferWorkflowCard(),

        const SizedBox(height: 24),

        // Card 2: Transit Time Defaults Per Route
        _buildTransitTimeDefaultsCard(),
      ],
    );
  }

  // Right Column containing Transfer Approvals & Packing & Receiving
  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 3: Transfer Approvals
        _buildTransferApprovalsCard(),

        const SizedBox(height: 24),

        // Card 4: Packing & Receiving
        _buildPackingReceivingCard(),
      ],
    );
  }

  // Card 1: Default Transfer Workflow
  Widget _buildDefaultTransferWorkflowCard() {
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
          // Card Header with Tree / Hierarchy icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_tree_outlined,
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
                      'Default Transfer Workflow',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Define the default status flow for stock transfers.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Stepper Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF8F5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDE5D8)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < _workflowSteps.length; i++) ...[
                    _buildWorkflowStepPill(
                      label: _workflowSteps[i],
                      isHighlighted: i == _highlightedStepIndex,
                      onTap: () {
                        setState(() => _highlightedStepIndex = i);
                        _showFeedback('Selected step: ${_workflowSteps[i]}');
                      },
                    ),
                    if (i < _workflowSteps.length - 1) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '>',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFA89F91),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStepPill({
    required String label,
    required bool isHighlighted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFFB58E58) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isHighlighted ? const Color(0xFFB58E58) : const Color(0xFFDFD4C5),
          ),
          boxShadow: isHighlighted
              ? const [
                  BoxShadow(
                    color: Color(0x20B58E58),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
            color: isHighlighted ? Colors.white : const Color(0xFF181513),
          ),
        ),
      ),
    );
  }

  // Card 2: Transit Time Defaults Per Route
  Widget _buildTransitTimeDefaultsCard() {
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
          // Card Header with Truck icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
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
                      'Transit Time Defaults Per Route',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Set default in-transit time between locations.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                    ),
                  ],
                ),
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
                  'FROM LOCATION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'TO LOCATION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'DEFAULT DAYS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  'ACTIONS',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF0E7DD), height: 1, thickness: 1),

          // Table Rows
          for (int i = 0; i < _routes.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      _routes[i].fromLocation,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _routes[i].toLocation,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${_routes[i].defaultDays} ${_routes[i].defaultDays == 1 ? "Day" : "Days"}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
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
                          if (action == 'delete') {
                            setState(() {
                              _routes.removeAt(i);
                            });
                            _showFeedback('Removed route');
                          } else {
                            _showFeedback('Route options for ${_routes[i].toLocation}');
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'Edit Route',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete Route',
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
            if (i < _routes.length - 1)
              const Divider(color: Color(0xFFF7F1EA), height: 1, thickness: 1),
          ],

          const SizedBox(height: 16),

          // Add Route Button
          OutlinedButton.icon(
            onPressed: _showAddRouteDialog,
            icon: const Icon(Icons.add, size: 16, color: Color(0xFF181513)),
            label: Text(
              'Add Route',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              side: const BorderSide(color: Color(0xFFDFD4C5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Card 3: Transfer Approvals
  Widget _buildTransferApprovalsCard() {
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
          // Card Header with Groups icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.groups_outlined,
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
                      'Transfer Approvals',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Set approval requirements for inter-location transfers.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Field: Approval Threshold Amount
          Text(
            'Approval Threshold Amount',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _thresholdAmountController,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFFAFAF8),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5DCD2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5DCD2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF7A481B)),
              ),
            ),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Transfers below this amount can be auto-approved.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF7E766B),
            ),
          ),

          const SizedBox(height: 22),

          // Auto-Approve Low Value Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Approve Low Value',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Auto-approve transfers under ₹10,000 threshold.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildLuxuryToggle(
                value: _autoApproveLowValue,
                onChanged: (val) {
                  setState(() => _autoApproveLowValue = val);
                  _showFeedback(
                    val
                        ? 'Auto-approve low value transfers enabled'
                        : 'Auto-approve low value transfers disabled',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 4: Packing & Receiving
  Widget _buildPackingReceivingCard() {
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
          // Card Header with Box icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
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
                      'Packing & Receiving',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Configure packing slip generation and receiving rules.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Toggle 1: Auto-Generate Packing Slips
          _buildToggleRow(
            title: 'Auto-Generate Packing Slips',
            subtitle: 'Print slip immediately upon dispatch approval.',
            value: _autoGeneratePackingSlips,
            onChanged: (val) {
              setState(() => _autoGeneratePackingSlips = val);
              _showFeedback(
                val
                    ? 'Auto-generate packing slips enabled'
                    : 'Auto-generate packing slips disabled',
              );
            },
          ),

          const SizedBox(height: 20),

          // Toggle 2: Include Financial Cost
          _buildToggleRow(
            title: 'Include Financial Cost',
            subtitle: 'Hide cost from packing slips for warehouse staff.',
            value: _includeFinancialCost,
            onChanged: (val) {
              setState(() => _includeFinancialCost = val);
              _showFeedback(
                val
                    ? 'Include financial cost enabled'
                    : 'Include financial cost disabled',
              );
            },
          ),

          const SizedBox(height: 20),

          // Toggle 3: Require Item-by-Item Scan
          _buildToggleRow(
            title: 'Require Item-by-Item Scan',
            subtitle: 'Enforce individual barcode scans for receiving.',
            value: _requireItemScan,
            onChanged: (val) {
              setState(() => _requireItemScan = val);
              _showFeedback(
                val
                    ? 'Require item-by-item scan enabled'
                    : 'Require item-by-item scan disabled',
              );
            },
          ),

          const SizedBox(height: 20),

          // Toggle 4: Allow Partial Receiving
          _buildToggleRow(
            title: 'Allow Partial Receiving',
            subtitle: 'Acknowledge split shipment arrivals dynamically.',
            value: _allowPartialReceiving,
            onChanged: (val) {
              setState(() => _allowPartialReceiving = val);
              _showFeedback(
                val
                    ? 'Allow partial receiving enabled'
                    : 'Allow partial receiving disabled',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildLuxuryToggle(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  // Bottom Pro Tip Banner matching screenshot
  Widget _buildProTipBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3E7D3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 24,
            color: Color(0xFF7A481B),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Tip',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7A481B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You can override transit times and approval limits for specific locations or user roles.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF7E766B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Luxury espresso toggle switch
  Widget _buildLuxuryToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value ? const Color(0xFF5C3E21) : const Color(0xFFE2D8CC),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 19,
            height: 19,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x28000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
