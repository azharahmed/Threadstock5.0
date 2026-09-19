// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityDrawer extends StatefulWidget {
  const ActivityDrawer({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  @override
  State<ActivityDrawer> createState() => _ActivityDrawerState();
}

class _ActivityDrawerState extends State<ActivityDrawer> {
  int _selectedTab = 0; // 0: All Logs, 1: My Tasks, 2: Mentions
  String _selectedModule = 'All Operations';
  final Set<String> _unreadIds = {'approval_req', 'stock_alert', 'transfer_done'};

  final List<String> _modules = const [
    'All Operations',
    'Purchasing',
    'Inventory',
    'Transfers',
    'Sales',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
        ),
        border: const Border(
          left: BorderSide(color: Color(0xFFEADBCA), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E160E).withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header: Title & Close Button
          _buildHeader(),

          // 2. Navigation Tabs (All Logs, My Tasks, Mentions)
          _buildTabs(),
          const Divider(color: Color(0xFFEDE5DA), height: 1),

          // 3. Filter Row: Module Dropdown & Mark all as read
          _buildFilterRow(),

          // 4. Scrollable Notifications Feed
          Expanded(
            child: _buildFeedList(),
          ),
        ],
      ),
    );
  }

  // Header with Cormorant Garamond title and sleek close button
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Activity',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF161412),
            ),
          ),
          InkWell(
            onTap: widget.onClose,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFAF7F2),
                border: Border.all(color: const Color(0xFFDECDB9)),
              ),
              child: const Center(
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Color(0xFF5E574E),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tabs: All Logs, My Tasks (2), Mentions (1)
  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildTabItem(index: 0, label: 'All Logs'),
          const SizedBox(width: 24),
          _buildTabItem(
            index: 1,
            label: 'My Tasks',
            badgeText: '2',
            badgeBg: const Color(0xFFFAF0E1),
            badgeColor: const Color(0xFF9E7744),
          ),
          const SizedBox(width: 24),
          _buildTabItem(
            index: 2,
            label: 'Mentions',
            badgeText: '1',
            badgeBg: const Color(0xFFEFF6FF),
            badgeColor: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String label,
    String? badgeText,
    Color? badgeBg,
    Color? badgeColor,
  }) {
    final isSelected = _selectedTab == index;

    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? const Color(0xFF1E1C1A)
                        : const Color(0xFF6B6358),
                  ),
                ),
                if (badgeText != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeBg ?? const Color(0xFFF3EDE4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: badgeColor ?? const Color(0xFF7A7268),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 2.5,
              width: 28,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF9E7744)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Filter Row with Module Dropdown and Mark all as read
  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Module dropdown selector
          PopupMenuButton<String>(
            tooltip: 'Filter by Module',
            onSelected: (val) => setState(() => _selectedModule = val),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFDECDB9)),
            ),
            itemBuilder: (context) => _modules.map((m) {
              return PopupMenuItem<String>(
                value: m,
                height: 38,
                child: Text(
                  m,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: _selectedModule == m
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
              );
            }).toList(),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0xFFDCCFBE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Module: $_selectedModule',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF2C2721),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Color(0xFF7A7268),
                  ),
                ],
              ),
            ),
          ),

          // Mark all as read action
          InkWell(
            onTap: () {
              setState(() => _unreadIds.clear());
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Mark all as read',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7A7268),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Feed list responding to tab selection
  Widget _buildFeedList() {
    if (_selectedTab == 1) {
      return _buildMyTasksFeed();
    } else if (_selectedTab == 2) {
      return _buildMentionsFeed();
    }
    return _buildAllLogsFeed();
  }

  Widget _buildAllLogsFeed() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        // TODAY Section
        _buildSectionTitle('TODAY'),
        const SizedBox(height: 10),

        // Item 1: Approval Requested
        _buildNotificationCard(
          id: 'approval_req',
          icon: Icons.description_outlined,
          iconBg: const Color(0xFFFAF4EC),
          iconBorder: const Color(0xFFDECDB9),
          iconColor: const Color(0xFF9E7744),
          title: 'Approval Requested',
          body: 'PO-2024-8902 limits exceed ₹50k. Waiting on your approval.',
          time: '10 mins ago',
          actionWidget: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(0, 30),
              side: const BorderSide(color: Color(0xFFDECDB9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              backgroundColor: Colors.white,
            ),
            child: Text(
              'View Details',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1C1A),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Item 2: Critical Stock Alert
        _buildNotificationCard(
          id: 'stock_alert',
          icon: Icons.info_outline_rounded,
          iconBg: const Color(0xFFF5F5F5),
          iconBorder: const Color(0xFFE5E7EB),
          iconColor: const Color(0xFF4B5563),
          title: 'No recent activity',
          body: 'Start adding products and stock movements to see activity here.',
          time: 'Now',
        ),
        const SizedBox(height: 22),

        // YESTERDAY Section
        _buildSectionTitle('YESTERDAY'),
        const SizedBox(height: 10),

        // Item 3: Transfer Completed
        _buildNotificationCard(
          id: 'transfer_done',
          icon: Icons.check_circle_outline_rounded,
          iconBg: const Color(0xFFEBF5EE),
          iconBorder: const Color(0xFFCEE8D7),
          iconColor: const Color(0xFF2E7D32),
          title: 'No recent transfers',
          body: 'Your transfer activity will appear here once real data is created.',
          time: 'No data',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildMyTasksFeed() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        _buildSectionTitle('TODAY'),
        const SizedBox(height: 10),
        _buildNotificationCard(
          id: 'approval_req',
          icon: Icons.description_outlined,
          iconBg: const Color(0xFFFAF4EC),
          iconBorder: const Color(0xFFDECDB9),
          iconColor: const Color(0xFF9E7744),
          title: 'Approval Requested',
          body: 'PO-2024-8902 limits exceed ₹50k. Waiting on your approval.',
          time: '10 mins ago',
          actionWidget: OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: const Size(0, 30),
              side: const BorderSide(color: Color(0xFFDECDB9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              backgroundColor: Colors.white,
            ),
            child: Text(
              'View Details',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1C1A),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildNotificationCard(
          id: 'task_audit',
          icon: Icons.inventory_2_outlined,
          iconBg: const Color(0xFFFAF4EC),
          iconBorder: const Color(0xFFDECDB9),
          iconColor: const Color(0xFF9E7744),
          title: 'Zone A Stock Audit',
          body: 'Discrepancy of 4 units detected in Linen Fabric roll. Verification required.',
          time: '3 hrs ago',
        ),
      ],
    );
  }

  Widget _buildMentionsFeed() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
        _buildSectionTitle('TODAY'),
        const SizedBox(height: 10),
        _buildNotificationCard(
          id: 'mention_priya',
          icon: Icons.alternate_email_rounded,
          iconBg: const Color(0xFFEFF6FF),
          iconBorder: const Color(0xFFDBEAFE),
          iconColor: const Color(0xFF2563EB),
          title: 'No mentions yet',
          body: 'Team mentions and approvals will appear once your workspace starts receiving real activity.',
          time: 'Waiting',
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: const Color(0xFF8C8478),
      ),
    );
  }

  Widget _buildNotificationCard({
    required String id,
    required IconData icon,
    required Color iconBg,
    required Color iconBorder,
    required Color iconColor,
    required String title,
    required String body,
    required String time,
    Widget? actionWidget,
  }) {
    final isUnread = _unreadIds.contains(id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular Icon badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              border: Border.all(color: iconBorder),
            ),
            child: Center(
              child: Icon(icon, size: 19, color: iconColor),
            ),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1C1A),
                        ),
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 6.5,
                        height: 6.5,
                        decoration: const BoxDecoration(
                          color: Color(0xFFBA8A55),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5E574E),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF8C8478),
                      ),
                    ),
                    ?actionWidget,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
