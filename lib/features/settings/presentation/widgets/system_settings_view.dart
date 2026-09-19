// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class SettingsCategoryItem {
  final String title;
  final String? badgeText;
  final Color? badgeBgColor;
  final Color? badgeTextColor;
  final String? sectionKey;

  const SettingsCategoryItem({
    required this.title,
    this.badgeText,
    this.badgeBgColor,
    this.badgeTextColor,
    this.sectionKey,
  });
}

class SettingsCategoryGroup {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<SettingsCategoryItem> items;

  const SettingsCategoryGroup({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.items,
  });
}

class SystemSettingsView extends StatefulWidget {
  const SystemSettingsView({
    super.key,
    this.onSelectSection,
  });

  final ValueChanged<String>? onSelectSection;

  @override
  State<SystemSettingsView> createState() => _SystemSettingsViewState();
}

class _SystemSettingsViewState extends State<SystemSettingsView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<SettingsCategoryGroup> _groups = const [
    SettingsCategoryGroup(
      id: 'business',
      title: 'BUSINESS',
      subtitle: 'Organization and legal setup',
      icon: Icons.account_balance_outlined,
      items: [
        SettingsCategoryItem(
          title: 'Business Profile',
          sectionKey: 'business_profile',
        ),
        SettingsCategoryItem(
          title: 'Locations',
          badgeText: '3 ACTIVE',
          badgeBgColor: Color(0xFFEAF2FB),
          badgeTextColor: Color(0xFF2A6496),
          sectionKey: 'locations',
        ),
        SettingsCategoryItem(
          title: 'Taxes & Currency',
          sectionKey: 'taxes_currency',
        ),
        SettingsCategoryItem(
          title: 'Documents & Templates',
          sectionKey: 'documents_templates',
        ),
      ],
    ),
    SettingsCategoryGroup(
      id: 'people',
      title: 'PEOPLE & ACCESS',
      subtitle: 'Manage your team and permissions',
      icon: Icons.people_outline_rounded,
      items: [
        SettingsCategoryItem(
          title: 'Team Directory',
          badgeText: '24 STAFF',
          badgeBgColor: Color(0xFFE8F5E9),
          badgeTextColor: Color(0xFF2E7D32),
          sectionKey: 'team_directory',
        ),
        SettingsCategoryItem(
          title: 'Roles & Permissions',
          sectionKey: 'roles_permissions',
        ),
        SettingsCategoryItem(
          title: 'Security & SSO',
          sectionKey: 'security_sso',
        ),
        SettingsCategoryItem(
          title: 'Activity Logs',
          sectionKey: 'activity_logs',
        ),
      ],
    ),
    SettingsCategoryGroup(
      id: 'commerce',
      title: 'COMMERCE',
      subtitle: 'Sales and payment configuration',
      icon: Icons.credit_card_outlined,
      items: [
        SettingsCategoryItem(
          title: 'Sales Channels',
          sectionKey: 'sales_channels',
        ),
        SettingsCategoryItem(
          title: 'Payments & Gateway',
          sectionKey: 'payments_gateway',
        ),
        SettingsCategoryItem(
          title: 'Receipt & POS Settings',
          sectionKey: 'receipt_pos',
        ),
        SettingsCategoryItem(
          title: 'Pricing & Promotions',
          sectionKey: 'pricing_promotions',
        ),
      ],
    ),
    SettingsCategoryGroup(
      id: 'operations',
      title: 'OPERATIONS',
      subtitle: 'Day-to-day operational settings',
      icon: Icons.inventory_2_outlined,
      items: [
        SettingsCategoryItem(
          title: 'Barcode & Printing',
          sectionKey: 'barcode_printing',
        ),
        SettingsCategoryItem(
          title: 'Inventory Rules',
          sectionKey: 'inventory_rules',
        ),
        SettingsCategoryItem(
          title: 'Purchasing Defaults',
          sectionKey: 'purchasing_defaults',
        ),
        SettingsCategoryItem(
          title: 'Transfer Defaults',
          sectionKey: 'transfer_defaults',
        ),
      ],
    ),
    SettingsCategoryGroup(
      id: 'system',
      title: 'SYSTEM',
      subtitle: 'Integrations and platform settings',
      icon: Icons.settings_outlined,
      items: [
        SettingsCategoryItem(
          title: 'System Integration Sync',
          badgeText: 'LIVE',
          badgeBgColor: Color(0xFFFEF3C7),
          badgeTextColor: Color(0xFFD97706),
          sectionKey: 'sync_queue',
        ),
        SettingsCategoryItem(
          title: 'Integrations',
          sectionKey: 'integrations',
        ),
        SettingsCategoryItem(
          title: 'Notifications Schema',
          sectionKey: 'notifications_schema',
        ),
        SettingsCategoryItem(
          title: 'Import/Export Studio',
          sectionKey: 'import_export',
        ),
        SettingsCategoryItem(
          title: 'API & Webhooks',
          sectionKey: 'api_webhooks',
        ),
      ],
    ),
    SettingsCategoryGroup(
      id: 'account',
      title: 'ACCOUNT',
      subtitle: 'Billing and personal preferences',
      icon: Icons.person_outline_rounded,
      items: [
        SettingsCategoryItem(
          title: 'Subscription Plan',
          sectionKey: 'subscription',
        ),
        SettingsCategoryItem(
          title: 'Billing & Invoices',
          sectionKey: 'billing',
        ),
        SettingsCategoryItem(
          title: 'Personal Preferences',
          sectionKey: 'preferences',
        ),
        SettingsCategoryItem(
          title: 'Support & Help',
          sectionKey: 'help',
        ),
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleItemTap(SettingsCategoryItem item) {
    if (item.sectionKey != null && widget.onSelectSection != null) {
      widget.onSelectSection!(item.sectionKey!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFBA8A55), size: 18),
              const SizedBox(width: 10),
              Text(
                'Opening ${item.title} configuration...',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1C1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter groups based on search query
    final filteredGroups = _searchQuery.isEmpty
        ? _groups
        : _groups.map((group) {
            final matchingItems = group.items.where((item) {
              return item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  group.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  group.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();
            return SettingsCategoryGroup(
              id: group.id,
              title: group.title,
              subtitle: group.subtitle,
              icon: group.icon,
              items: matchingItems,
            );
          }).where((group) => group.items.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 20,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row: System Settings Title + Subtitle + Search Bar
              _buildHeader(),
              const SizedBox(height: 24),

              // 6 Category Cards in a 3-Column Layout
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 860 ? 3 : (constraints.maxWidth > 580 ? 2 : 1);
                  final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount;

                  return Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: filteredGroups.map((group) {
                      return SizedBox(
                        width: itemWidth,
                        child: _buildCategoryCard(group),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // HEADER ROW: System Settings Title + Find a Setting Search
  // ========================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Settings',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure operations, locations, staff permissions, commercial triggers, and intelligence settings.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6E665B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // Find a Setting Search Field
        Container(
          width: 230,
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDFD4C5)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A231A).withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                size: 16,
                color: Color(0xFF8C8478),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF181513),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Find a setting...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF9E958A),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                InkWell(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Color(0xFF8C8478),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ========================================================
  // CATEGORY CARD (e.g. BUSINESS, PEOPLE & ACCESS)
  // ========================================================
  Widget _buildCategoryCard(SettingsCategoryGroup group) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Amber Badge Icon + Title + Subtitle
          Padding(
            padding: const EdgeInsets.only(left: 18, right: 18, top: 18, bottom: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    group.icon,
                    size: 19,
                    color: const Color(0xFFBA8A55),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        group.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Hairline separator below header
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF1EAE0),
          ),

          // 4 Category Items
          ...List.generate(group.items.length, (index) {
            final item = group.items[index];
            final isLast = index == group.items.length - 1;

            return InkWell(
              onTap: () => _handleItemTap(item),
              borderRadius: BorderRadius.vertical(
                bottom: isLast ? const Radius.circular(12) : Radius.zero,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: isLast
                        ? BorderSide.none
                        : const BorderSide(color: Color(0xFFF6F1EA), width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    // Item Title
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E1C1A),
                      ),
                    ),

                    // Optional Pill Badge (e.g. 3 ACTIVE, 24 STAFF)
                    if (item.badgeText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: item.badgeBgColor ?? const Color(0xFFEAF2FB),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.badgeText!,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: item.badgeTextColor ?? const Color(0xFF2A6496),
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Trailing Chevron
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF8E867B),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
