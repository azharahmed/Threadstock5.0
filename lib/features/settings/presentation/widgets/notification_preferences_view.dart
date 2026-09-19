// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class NotificationItem {
  final String id;
  final String title;
  final String description;
  bool inApp;
  bool email;
  bool push;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.inApp,
    required this.email,
    required this.push,
  });

  NotificationItem copy() {
    return NotificationItem(
      id: id,
      title: title,
      description: description,
      inApp: inApp,
      email: email,
      push: push,
    );
  }
}

class NotificationCategoryGroup {
  final String name;
  final IconData icon;
  final List<NotificationItem> items;

  NotificationCategoryGroup({
    required this.name,
    required this.icon,
    required this.items,
  });
}

class NotificationPreferencesView extends StatefulWidget {
  final VoidCallback? onBackToSettings;
  final void Function(String title, String subtitle)? onSubNavChanged;

  const NotificationPreferencesView({
    super.key,
    this.onBackToSettings,
    this.onSubNavChanged,
  });

  @override
  State<NotificationPreferencesView> createState() =>
      _NotificationPreferencesViewState();
}

class _NotificationPreferencesViewState
    extends State<NotificationPreferencesView> {
  late List<NotificationCategoryGroup> _categories;

  @override
  void initState() {
    super.initState();
    _resetToDefaults(showFeedbackMsg: false);
  }

  void _resetToDefaults({bool showFeedbackMsg = true}) {
    setState(() {
      _categories = [
        // 1. INVENTORY
        NotificationCategoryGroup(
          name: 'INVENTORY',
          icon: Icons.inventory_2_outlined,
          items: [
            NotificationItem(
              id: 'low_stock',
              title: 'Low stock alert',
              description:
                  'Triggered when a product hits its minimum threshold limit',
              inApp: true,
              email: true,
              push: false,
            ),
            NotificationItem(
              id: 'stock_count_due',
              title: 'Stock count due',
              description:
                  'Notification to perform the scheduled manual counts',
              inApp: true,
              email: false,
              push: false,
            ),
            NotificationItem(
              id: 'reorder_point_reached',
              title: 'Reorder point reached',
              description:
                  'Automatic reminder to place POs for high-velocity items',
              inApp: true,
              email: true,
              push: true,
            ),
          ],
        ),

        // 2. PURCHASING
        NotificationCategoryGroup(
          name: 'PURCHASING',
          icon: Icons.shopping_cart_outlined,
          items: [
            NotificationItem(
              id: 'po_approved',
              title: 'PO approved',
              description:
                  'When a purchase order is digitally signed by management',
              inApp: true,
              email: true,
              push: false,
            ),
            NotificationItem(
              id: 'po_received',
              title: 'PO received',
              description:
                  'Upon arrival and validation of supply stock at warehouse',
              inApp: true,
              email: false,
              push: false,
            ),
            NotificationItem(
              id: 'supplier_price_change',
              title: 'Supplier price change',
              description:
                  'Alert for adjustments on recorded base catalogs',
              inApp: false,
              email: true,
              push: false,
            ),
          ],
        ),

        // 3. SALES
        NotificationCategoryGroup(
          name: 'SALES',
          icon: Icons.bar_chart_rounded,
          items: [
            NotificationItem(
              id: 'daily_sales_summary',
              title: 'Daily sales summary',
              description:
                  'Daily compilation report on store activity and margins',
              inApp: true,
              email: true,
              push: false,
            ),
            NotificationItem(
              id: 'refund_processed',
              title: 'Refund processed',
              description:
                  'When a cashier triggers a refund matrix on POS',
              inApp: true,
              email: false,
              push: false,
            ),
          ],
        ),
      ];
    });

    if (showFeedbackMsg) {
      _showFeedback('Notification preferences reset to system defaults.');
    }
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFFBA8A55), size: 18),
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
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAF7F2),
      child: SingleChildScrollView(
        child: DesktopContentConstraint(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Icon + Title + Subtitle + Reset to Defaults Button
                _buildHeaderRow(),
                const SizedBox(height: 22),

                // Main Preferences Table Card
                _buildPreferencesTableCard(),
                const SizedBox(height: 20),

                // Bottom Callout Banner
                _buildBottomCalloutBanner(),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // HEADER ROW: Bell Avatar + Title + Subtitle + Reset Button
  // ========================================================
  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Avatar + Title + Subtitle
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFFE8DDD0), width: 1.2),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF7A481B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Preferences',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose which alerts you wish to receive across each system channel.',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6E665B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Right: Reset to Defaults Outlined Button
        OutlinedButton.icon(
          onPressed: () => _resetToDefaults(showFeedbackMsg: true),
          icon: const Icon(
            Icons.refresh_rounded,
            size: 16,
            color: Color(0xFF181513),
          ),
          label: Text(
            'Reset to Defaults',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE2D8CC)),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // PREFERENCES TABLE CARD
  // ========================================================
  Widget _buildPreferencesTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE2D5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            // Table Column Headers: ALERT CATEGORY | IN-APP | EMAIL | PUSH
            _buildTableHeader(),

            // Category Sections
            for (int i = 0; i < _categories.length; i++) ...[
              _buildCategorySection(_categories[i]),
            ],
          ],
        ),
      ),
    );
  }

  // Column Headers
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEBE2D5)),
        ),
      ),
      child: Row(
        children: [
          // Left: ALERT CATEGORY
          Expanded(
            child: Text(
              'ALERT CATEGORY',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: const Color(0xFF6E665B),
              ),
            ),
          ),

          // Channel 1: IN-APP
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.phone_iphone_rounded,
                  size: 15,
                  color: Color(0xFF181513),
                ),
                const SizedBox(width: 6),
                Text(
                  'IN-APP',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF181513),
                  ),
                ),
              ],
            ),
          ),

          // Channel 2: EMAIL
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mail_outline_rounded,
                  size: 15,
                  color: Color(0xFF181513),
                ),
                const SizedBox(width: 6),
                Text(
                  'EMAIL',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF181513),
                  ),
                ),
              ],
            ),
          ),

          // Channel 3: PUSH
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.near_me_outlined,
                  size: 15,
                  color: Color(0xFF181513),
                ),
                const SizedBox(width: 6),
                Text(
                  'PUSH',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF181513),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // Category Section with Warm Banner + List of Alert Rows
  Widget _buildCategorySection(NotificationCategoryGroup group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Banner (Soft warm beige background)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: const BoxDecoration(
            color: Color(0xFFFDF8F0),
            border: Border(
              bottom: BorderSide(color: Color(0xFFF4ECE1)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                group.icon,
                size: 15,
                color: const Color(0xFF7A481B),
              ),
              const SizedBox(width: 8),
              Text(
                group.name,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF7A481B),
                ),
              ),
            ],
          ),
        ),

        // Items in category
        for (int i = 0; i < group.items.length; i++) ...[
          _buildNotificationRow(group.items[i]),
          if (i < group.items.length - 1)
            const Divider(height: 1, color: Color(0xFFF4ECE1)),
        ],
      ],
    );
  }

  // Notification Row
  Widget _buildNotificationRow(NotificationItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Left: Title + Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7E766B),
                  ),
                ),
              ],
            ),
          ),

          // IN-APP Toggle
          Container(
            width: 100,
            alignment: Alignment.center,
            child: _buildToggle(
              value: item.inApp,
              onChanged: (val) {
                setState(() => item.inApp = val);
                _showFeedback(
                    '${item.title}: In-App alert ${val ? "enabled" : "disabled"}');
              },
            ),
          ),

          // EMAIL Toggle
          Container(
            width: 100,
            alignment: Alignment.center,
            child: _buildToggle(
              value: item.email,
              onChanged: (val) {
                setState(() => item.email = val);
                _showFeedback(
                    '${item.title}: Email alert ${val ? "enabled" : "disabled"}');
              },
            ),
          ),

          // PUSH Toggle
          Container(
            width: 100,
            alignment: Alignment.center,
            child: _buildToggle(
              value: item.push,
              onChanged: (val) {
                setState(() => item.push = val);
                _showFeedback(
                    '${item.title}: Push notification ${val ? "enabled" : "disabled"}');
              },
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  // ========================================================
  // LUXURY PILL TOGGLE
  // ========================================================
  Widget _buildToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF5C3E21) : const Color(0xFFE2D8CC),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 19,
          height: 19,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // BOTTOM CALLOUT: Stay informed, your way
  // ========================================================
  Widget _buildBottomCalloutBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3E7D3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 22,
            color: Color(0xFFBA8A55),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay informed, your way',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF734E1D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You can update notification preferences at any time. Critical system alerts may still be sent.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6E665B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
