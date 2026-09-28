// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class PurchasingDefaultsView extends StatefulWidget {
  final VoidCallback? onBackToSettings;
  final void Function(String title, String subtitle)? onSubNavChanged;
  final void Function(String sectionKey)? onSelectSection;

  const PurchasingDefaultsView({
    super.key,
    this.onBackToSettings,
    this.onSubNavChanged,
    this.onSelectSection,
  });

  @override
  State<PurchasingDefaultsView> createState() => _PurchasingDefaultsViewState();
}

class _PurchasingDefaultsViewState extends State<PurchasingDefaultsView> {
  int _activeTabIndex = 0;
  String _selectedWarehouse = 'All Locations';

  // General Purchasing Rules
  String _defaultPaymentTerms = 'Net 30';
  bool _autoGeneratePOs = true;

  // Default Receiving Rules
  bool _requireQuantityCheck = true;
  bool _allowOverReceiving = true;
  final TextEditingController _maxOverReceiveController = TextEditingController(
    text: '10',
  );

  // PO Approval Workflows
  bool _enablePoApprovals = true;
  final TextEditingController _thresholdAmountController =
      TextEditingController(text: '₹ 50,000');
  String _approverRole = 'Central Administrator';

  // Cost Tracking & Duties
  bool _calculateLandedCost = false;
  final TextEditingController _customsDutyRateController =
      TextEditingController(text: '12.5');

  final List<String> _tabs = const [
    'Purchasing Defaults',
    'Transfer Settings',
    'Import / Export',
    'API & Webhooks',
    'Audit Log',
  ];

  final List<String> _warehouses = const ['All Locations'];

  final List<String> _paymentTermsOptions = const [
    'Net 15',
    'Net 30',
    'Net 60',
    'Due on Receipt',
    'Cash on Delivery (COD)',
  ];

  final List<String> _approverRoleOptions = const [
    'Central Administrator',
    'Inventory Manager',
    'Financial Controller',
    'Store General Manager',
  ];

  @override
  void dispose() {
    _maxOverReceiveController.dispose();
    _thresholdAmountController.dispose();
    _customsDutyRateController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1040;

        return DesktopContentConstraint(
          maxWidth: 1320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 24,
              bottom: 48,
              left: 28,
              right: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Area with Location Selector on top right
                _buildHeader(),

                const SizedBox(height: 20),

                // Operational Navigation Tabs Row
                _buildTabsRow(),

                const SizedBox(height: 26),

                // Main 2-Column Responsive Layout
                if (isCompact) ...[
                  _buildLeftColumn(),
                  const SizedBox(height: 24),
                  _buildRightColumn(),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: General Purchasing Rules & Default Receiving Rules (50% / 50%)
                      Expanded(flex: 50, child: _buildLeftColumn()),

                      const SizedBox(width: 24),

                      // Right Column: PO Approval Workflows & Cost Tracking & Duties (50% / 50%)
                      Expanded(flex: 50, child: _buildRightColumn()),
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

  // Header matching Purchasing Defaults screenshot
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Warm circular avatar with shopping cart icon
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFFAF2E6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.shopping_cart_outlined,
            size: 26,
            color: Color(0xFF7A481B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Purchasing Defaults',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: const Color(0xFF181513),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure buying, receiving and cost settings for your business.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6357),
                ),
              ),
            ],
          ),
        ),

        // Warehouse Location Dropdown Button on Top Right
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDFD4C5)),
          ),
          child: PopupMenuButton<String>(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFDFD4C5)),
            ),
            offset: const Offset(0, 42),
            itemBuilder: (ctx) => _warehouses.map((wh) {
              return PopupMenuItem<String>(
                value: wh,
                child: Row(
                  children: [
                    const Icon(
                      Icons.warehouse_outlined,
                      size: 16,
                      color: Color(0xFF7A481B),
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
                'Settings > Purchasing Defaults > $val',
                'Configure buying, receiving and cost settings for your business.',
              );
              _showFeedback('Switched to $val');
            },
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
                if (i == 1) {
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('transfer_settings');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > Transfer Settings',
                      'Configure stock transfer workflows, transit times and receiving preferences.',
                    );
                  }
                } else if (i == 2) {
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('import_export');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > Import / Export Center',
                      'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.',
                    );
                  }
                } else if (i == 3) {
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('api_webhooks');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > API & Webhooks',
                      'Manage API access, configure webhooks, and integrate with external systems.',
                    );
                  }
                } else if (i == 4) {
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('audit_log');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > System Audit Log',
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
            color: isSelected
                ? const Color(0xFF7A481B)
                : const Color(0xFFDFD4C5),
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

  // Left Column containing General Purchasing Rules & Default Receiving Rules
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: General Purchasing Rules
        _buildGeneralPurchasingRulesCard(),

        const SizedBox(height: 24),

        // Card 2: Default Receiving Rules
        _buildDefaultReceivingRulesCard(),
      ],
    );
  }

  // Card 1: General Purchasing Rules
  Widget _buildGeneralPurchasingRulesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with document icon badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  size: 19,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'General Purchasing Rules',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Set default terms and automation for purchase orders.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Default Payment Terms
          Text(
            'Default Payment Terms',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _defaultPaymentTerms,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF5E574E),
                  size: 20,
                ),
                items: _paymentTermsOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt,
                    child: Text(
                      opt,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _defaultPaymentTerms = val);
                    _showFeedback('Default terms set to $val');
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This will be used as the default for all new purchase orders.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8E867B),
            ),
          ),

          const SizedBox(height: 24),

          // Auto-Generate Purchase Orders Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Generate Purchase Orders',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Automatically create drafts when low stock is detected.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _buildLuxuryToggle(
                value: _autoGeneratePOs,
                onChanged: (val) {
                  setState(() => _autoGeneratePOs = val);
                  _showFeedback(
                    'Auto-generation of POs ${val ? "enabled" : "disabled"}',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 2: Default Receiving Rules
  Widget _buildDefaultReceivingRulesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with box icon badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 19,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default Receiving Rules',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Configure inspection and acceptance rules for incoming stock.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Require Quantity Check Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Require Quantity Check',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Force manual input of received counts on delivery.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _buildLuxuryToggle(
                value: _requireQuantityCheck,
                onChanged: (val) {
                  setState(() => _requireQuantityCheck = val);
                  _showFeedback(
                    'Quantity check requirement ${val ? "enabled" : "disabled"}',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Allow Over-Receiving Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allow Over-Receiving',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Accept items past PO specified quantity threshold.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _buildLuxuryToggle(
                value: _allowOverReceiving,
                onChanged: (val) {
                  setState(() => _allowOverReceiving = val);
                  _showFeedback(
                    'Over-receiving ${val ? "permitted" : "restricted"}',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Max Over-Receive Percentage
          Text(
            'Max Over-Receive Percentage',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _maxOverReceiveController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181513),
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      _showFeedback('Max over-receive set to $val%');
                    },
                  ),
                ),
                Text(
                  '%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7E766B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Maximum allowed quantity variance beyond the ordered amount.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8E867B),
            ),
          ),
        ],
      ),
    );
  }

  // Right Column containing PO Approval Workflows & Cost Tracking & Duties
  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 3: PO Approval Workflows
        _buildPoApprovalWorkflowsCard(),

        const SizedBox(height: 24),

        // Card 4: Cost Tracking & Duties
        _buildCostTrackingDutiesCard(),
      ],
    );
  }

  // Card 3: PO Approval Workflows
  Widget _buildPoApprovalWorkflowsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with groups icon badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  size: 20,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PO Approval Workflows',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Set approval requirements for purchase orders.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Enable PO Approvals Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable PO Approvals',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Orders exceeding threshold require formal approval.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _buildLuxuryToggle(
                value: _enablePoApprovals,
                onChanged: (val) {
                  setState(() => _enablePoApprovals = val);
                  _showFeedback('PO Approvals ${val ? "enabled" : "disabled"}');
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Threshold Amount
          Text(
            'Threshold Amount',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 42,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: TextField(
              controller: _thresholdAmountController,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Approver Role
          Text(
            'Approver Role',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _approverRole,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF5E574E),
                  size: 20,
                ),
                items: _approverRoleOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt,
                    child: Text(
                      opt,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _approverRole = val);
                    _showFeedback('Approver role set to $val');
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Users with this role will be notified for approval.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8E867B),
            ),
          ),
        ],
      ),
    );
  }

  // Card 4: Cost Tracking & Duties
  Widget _buildCostTrackingDutiesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with coins icon badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.monetization_on_outlined,
                  size: 19,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cost Tracking & Duties',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage landed cost calculations and duty settings.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Calculate Landed Cost Toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calculate Landed Cost',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Incorporate freight, customs, and fees into unit cost.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _buildLuxuryToggle(
                value: _calculateLandedCost,
                onChanged: (val) {
                  setState(() => _calculateLandedCost = val);
                  _showFeedback(
                    'Landed cost calculation ${val ? "enabled" : "disabled"}',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Default Customs / Duty Rate
          Text(
            'Default Customs / Duty Rate',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customsDutyRateController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181513),
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      _showFeedback('Customs rate set to $val%');
                    },
                  ),
                ),
                Text(
                  '%',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF7E766B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Default rate applied to imported goods.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8E867B),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Pro Tip Banner
  Widget _buildProTipBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3E7D3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFFBF0DF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFF8B5E34),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Tip',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'These settings can be overridden at the supplier or purchase order level when needed.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF736B5E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Luxury Pill Toggle matching ThreadStock design system
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
