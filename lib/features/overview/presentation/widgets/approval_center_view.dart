// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ApprovalCategoryFilter {
  all,
  purchaseOrders,
  transfers,
  priceChanges,
  writeOffs,
}

class ApprovalItemData {
  const ApprovalItemData({
    required this.id,
    required this.category,
    required this.categoryLabel,
    required this.urgencyLabel,
    required this.urgencyType,
    required this.title,
    required this.requestorInfo,
    required this.calloutIcon,
    required this.calloutText,
    required this.valueImpactLabel,
    this.valueImpactSubtitle,
    required this.iconData,
    required this.iconBgColor,
    required this.iconColor,
    required this.badgeBgColor,
    required this.badgeTextColor,
    required this.urgencyBgColor,
    required this.urgencyTextColor,
    this.hasReviewAndApprove = false,
  });

  final String id;
  final ApprovalCategoryFilter category;
  final String categoryLabel;
  final String urgencyLabel;
  final String urgencyType;
  final String title;
  final String requestorInfo;
  final IconData calloutIcon;
  final String calloutText;
  final String valueImpactLabel;
  final String? valueImpactSubtitle;
  final IconData iconData;
  final Color iconBgColor;
  final Color iconColor;
  final Color badgeBgColor;
  final Color badgeTextColor;
  final Color urgencyBgColor;
  final Color urgencyTextColor;
  final bool hasReviewAndApprove;
}

class ApprovalCenterView extends StatefulWidget {
  const ApprovalCenterView({
    super.key,
    this.onViewOperationalOverview,
  });

  final VoidCallback? onViewOperationalOverview;

  @override
  State<ApprovalCenterView> createState() => _ApprovalCenterViewState();
}

class _ApprovalCenterViewState extends State<ApprovalCenterView> {
  ApprovalCategoryFilter _activeFilter = ApprovalCategoryFilter.all;
  String _selectedSort = 'Newest First';
  final Set<String> _selectedItemIds = {};

  final List<ApprovalItemData> _items = const [
    ApprovalItemData(
      id: 'po_2891',
      category: ApprovalCategoryFilter.purchaseOrders,
      categoryLabel: 'PURCHASE ORDER',
      urgencyLabel: 'Normal Urgency',
      urgencyType: 'normal',
      title: 'PO-2891 Auto-Reorder — 3 SKUs',
      requestorInfo: 'Requestor: System (Low Stock Automation)  •  Today, 09:30 AM',
      calloutIcon: Icons.inventory_2_outlined,
      calloutText: 'Includes 3 SKUs: Oxford Linen Shirt, Merino Wool Blazer, Silk Evening Dress',
      valueImpactLabel: '₹18,400',
      iconData: Icons.description_outlined,
      iconBgColor: Color(0xFFFFF9EE),
      iconColor: Color(0xFFD97706),
      badgeBgColor: Color(0xFFFEF3C7),
      badgeTextColor: Color(0xFFB45309),
      urgencyBgColor: Color(0xFFF1F5F9),
      urgencyTextColor: Color(0xFF64748B),
    ),
    ApprovalItemData(
      id: 'tr_445',
      category: ApprovalCategoryFilter.transfers,
      categoryLabel: 'TRANSFER',
      urgencyLabel: 'High Urgency',
      urgencyType: 'high',
      title: 'Transfer #TR-445 Central Warehouse → Indiranagar',
      requestorInfo: 'Requestor: Priya S. (Store Manager)  •  Today, 07:15 AM',
      calloutIcon: Icons.inventory_2_outlined,
      calloutText: '42 units  |  4 SKUs  |  Target: Indiranagar Store',
      valueImpactLabel: '42 units',
      iconData: Icons.swap_horiz_rounded,
      iconBgColor: Color(0xFFEFF6FF),
      iconColor: Color(0xFF2563EB),
      badgeBgColor: Color(0xFFDBEAFE),
      badgeTextColor: Color(0xFF1D4ED8),
      urgencyBgColor: Color(0xFFFEE2E2),
      urgencyTextColor: Color(0xFFDC2626),
    ),
    ApprovalItemData(
      id: 'md_summer',
      category: ApprovalCategoryFilter.priceChanges,
      categoryLabel: 'PRICE CHANGE',
      urgencyLabel: 'Attention Urgency',
      urgencyType: 'attention',
      title: 'Markdown 12 items — Summer Collection (-20%)',
      requestorInfo: 'Requestor: ThreadStock AI Recommendation  •  Yesterday, 04:30 PM',
      calloutIcon: Icons.bar_chart_rounded,
      calloutText: '12 items  |  Estimated impact: ₹82,000  |  Collection: Summer \'27',
      valueImpactLabel: '₹82,000',
      valueImpactSubtitle: 'projected impact',
      iconData: Icons.local_offer_outlined,
      iconBgColor: Color(0xFFFAF5FF),
      iconColor: Color(0xFF9333EA),
      badgeBgColor: Color(0xFFF3E8FF),
      badgeTextColor: Color(0xFF7E22CE),
      urgencyBgColor: Color(0xFFFFEDD5),
      urgencyTextColor: Color(0xFFC2410C),
      hasReviewAndApprove: true,
    ),
  ];

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: isError ? const Color(0xFF991B1B) : const Color(0xFF181513),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<ApprovalItemData> get _filteredItems {
    if (_activeFilter == ApprovalCategoryFilter.all) {
      return _items;
    }
    return _items.where((item) => item.category == _activeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Page Header: Title + Subtitle + Batch Action Buttons
          _buildHeaderRow(),
          const SizedBox(height: 22),

          // 2. Filters & Sort Bar
          _buildFilterAndSortBar(),
          const SizedBox(height: 18),

          // 3. Approvals Cards List
          ..._filteredItems.map(_buildApprovalCard),

          if (_filteredItems.isEmpty) _buildEmptyState(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. PAGE HEADER ROW
  // ===========================================================================
  Widget _buildHeaderRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final titleWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pending Approvals',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181513),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Select and take batch action or inspect individual drafts.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        );

        final buttonsWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Approve All (12) Button (Dark solid)
            InkWell(
              onTap: () => _showNotification('Approved all 12 pending requests.'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF181513),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Approve All (12)',
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
            const SizedBox(width: 10),

            // Reject Selected Button (White outline)
            InkWell(
              onTap: () {
                if (_selectedItemIds.isEmpty) {
                  _showNotification('No items selected to reject.', isError: true);
                } else {
                  final count = _selectedItemIds.length;
                  setState(() => _selectedItemIds.clear());
                  _showNotification('Rejected $count selected item(s).');
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      Icons.cancel_outlined,
                      size: 18,
                      color: Color(0xFF181513),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Reject Selected',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
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

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleWidget,
              const SizedBox(height: 14),
              buttonsWidget,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            titleWidget,
            buttonsWidget,
          ],
        );
      },
    );
  }

  // ===========================================================================
  // 2. FILTER TABS & SORT ROW
  // ===========================================================================
  Widget _buildFilterAndSortBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 840;

        final tabs = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill(
                filter: ApprovalCategoryFilter.all,
                label: 'All',
                count: 12,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                filter: ApprovalCategoryFilter.purchaseOrders,
                label: 'Purchase Orders',
                count: 5,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                filter: ApprovalCategoryFilter.transfers,
                label: 'Transfers',
                count: 3,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                filter: ApprovalCategoryFilter.priceChanges,
                label: 'Price Changes',
                count: 2,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                filter: ApprovalCategoryFilter.writeOffs,
                label: 'Write-Offs',
                count: 2,
              ),
            ],
          ),
        );

        final controls = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sort Dropdown
            PopupMenuButton<String>(
              offset: const Offset(0, 42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              color: Colors.white,
              onSelected: (val) {
                setState(() => _selectedSort = val);
              },
              itemBuilder: (context) => [
                _buildSortMenuItem('Newest First'),
                _buildSortMenuItem('Highest Value Impact'),
                _buildSortMenuItem('Most Urgent First'),
                _buildSortMenuItem('Oldest First'),
              ],
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedSort,
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
                      color: Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Filter Funnel Button
            InkWell(
              onTap: () {
                _showNotification('Advanced filter drawer toggled.');
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tabs,
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: controls),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: tabs),
            const SizedBox(width: 14),
            controls,
          ],
        );
      },
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(String text) {
    final isSelected = _selectedSort == text;
    return PopupMenuItem<String>(
      value: text,
      height: 38,
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            size: 16,
            color: isSelected ? const Color(0xFF181513) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: const Color(0xFF181513),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required ApprovalCategoryFilter filter,
    required String label,
    required int count,
  }) {
    final isSelected = _activeFilter == filter;

    return InkWell(
      onTap: () {
        setState(() {
          _activeFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 36,
        padding: const EdgeInsets.only(left: 14, right: 8, top: 4, bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF181513) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2C2825) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 3. APPROVAL CARD ITEM
  // ===========================================================================
  Widget _buildApprovalCard(ApprovalItemData item) {
    final isChecked = _selectedItemIds.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isChecked ? const Color(0xFFBA8A55) : const Color(0xFFE2E8F0),
          width: isChecked ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 840;

          // Main content on left side
          final leftMainContent = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selection Checkbox
              Padding(
                padding: const EdgeInsets.only(top: 14, right: 14),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isChecked) {
                        _selectedItemIds.remove(item.id);
                      } else {
                        _selectedItemIds.add(item.id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    width: 19,
                    height: 19,
                    decoration: BoxDecoration(
                      color: isChecked ? const Color(0xFF181513) : Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: isChecked ? const Color(0xFF181513) : const Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                    ),
                    child: isChecked
                        ? const Center(
                            child: Icon(Icons.check_rounded, size: 13, color: Colors.white),
                          )
                        : null,
                  ),
                ),
              ),

              // Category Icon Container
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(item.iconData, size: 23, color: item.iconColor),
                ),
              ),
              const SizedBox(width: 16),

              // Middle Column: Badges, Title, Requestor, Callout
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges Row
                    Row(
                      children: [
                        // Category Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: item.badgeBgColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            item.categoryLabel,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: item.badgeTextColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Urgency Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: item.urgencyBgColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            item.urgencyLabel,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: item.urgencyTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Requestor & Timestamp Line
                    Text(
                      item.requestorInfo,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Callout Box with SKUs / stats
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.calloutIcon,
                            size: 16,
                            color: const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.calloutText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          // Right Column: Value Impact + Actions
          final rightActionContent = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Value Impact Block
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'VALUE IMPACT',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.valueImpactLabel,
                    style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (item.valueImpactSubtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      item.valueImpactSubtitle!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 24),

              // Actions Row
              if (item.hasReviewAndApprove) ...[
                // Solid Dark Review & Approve Button
                InkWell(
                  onTap: () {
                    _showNotification('Opened review draft for "${item.title}".');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF181513),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Review & Approve',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Green Outline Approve Button
                InkWell(
                  onTap: () {
                    _showNotification('Approved "${item.title}".');
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
                    ),
                    child: Center(
                      child: Text(
                        'Approve',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 10),

              // Red Outline Reject Button
              InkWell(
                onTap: () {
                  _showNotification('Rejected "${item.title}".', isError: true);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
                  ),
                  child: Center(
                    child: Text(
                      'Reject',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE11D48),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Overflow Menu Button
              PopupMenuButton<String>(
                offset: const Offset(0, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                color: Colors.white,
                onSelected: (val) {
                  _showNotification('$val selected for "${item.title}".');
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'Inspect Draft Details',
                    height: 34,
                    child: Text(
                      'Inspect Draft Details',
                      style: GoogleFonts.inter(fontSize: 12.5),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Assign to Team Member',
                    height: 34,
                    child: Text(
                      'Assign to Team Member',
                      style: GoogleFonts.inter(fontSize: 12.5),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'Download Audit JSON',
                    height: 34,
                    child: Text(
                      'Download Audit JSON',
                      style: GoogleFonts.inter(fontSize: 12.5),
                    ),
                  ),
                ],
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 19,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          );

          if (isStacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leftMainContent,
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: rightActionContent,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: leftMainContent),
              const SizedBox(width: 24),
              rightActionContent,
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
          const SizedBox(height: 12),
          Text(
            'All caught up!',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No pending approvals matching this filter category.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
