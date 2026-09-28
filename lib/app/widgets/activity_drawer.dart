// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActivityDrawer extends StatefulWidget {
  const ActivityDrawer({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<ActivityDrawer> createState() => _ActivityDrawerState();
}

class _ActivityDrawerState extends State<ActivityDrawer> {
  int _selectedTab = 0; // 0: All Logs, 1: My Tasks, 2: Mentions
  String _selectedModule = 'All Operations';
  final Set<String> _unreadIds = <String>{};

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
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16)),
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
          Expanded(child: _buildFeedList()),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFAF7F2),
                border: Border.all(color: const Color(0xFFDECDB9)),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 26,
                color: Color(0xFFBA8A55),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No activity yet',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF161412),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Activity will appear here as you create products, receive stock, make sales and transfer inventory.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF7A7268),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllLogsFeed() => _buildEmptyState();
  Widget _buildMyTasksFeed() => _buildEmptyState();
  Widget _buildMentionsFeed() => _buildEmptyState();
}
