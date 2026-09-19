// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class SettingsSearchResultItem {
  const SettingsSearchResultItem({
    required this.id,
    required this.title,
    required this.breadcrumb,
    required this.description,
    required this.icon,
    required this.targetSection,
  });

  final String id;
  final String title;
  final String breadcrumb;
  final String description;
  final IconData icon;
  final String targetSection;
}

class SettingsSearchResultsView extends StatefulWidget {
  const SettingsSearchResultsView({
    super.key,
    this.searchQuery = 'tax',
    this.onSelectSection,
    this.onClearSearch,
    this.onBrowseAllSettings,
  });

  final String searchQuery;
  final ValueChanged<String>? onSelectSection;
  final VoidCallback? onClearSearch;
  final VoidCallback? onBrowseAllSettings;

  @override
  State<SettingsSearchResultsView> createState() =>
      _SettingsSearchResultsViewState();
}

class _SettingsSearchResultsViewState extends State<SettingsSearchResultsView> {
  final List<SettingsSearchResultItem> _results = const [
    SettingsSearchResultItem(
      id: 'taxes_currency',
      title: 'Taxes & Currency Settings',
      breadcrumb: 'Settings > Business Settings > Finance',
      description:
          'Configure standard global GST/VAT setups, regional business compliance codes, and base display currency multipliers.',
      icon: Icons.description_outlined,
      targetSection: 'taxes_currency',
    ),
    SettingsSearchResultItem(
      id: 'location_tax',
      title: 'Default Location Tax assignment',
      breadcrumb: 'Settings > Locations > Zone A Warehouse',
      description:
          'Auto tax application rules for incoming purchase orders arriving from international suppliers.',
      icon: Icons.location_on_outlined,
      targetSection: 'locations',
    ),
    SettingsSearchResultItem(
      id: 'tax_rules',
      title: 'Automatic Tax Assignment Rules',
      breadcrumb: 'Settings > Roles & Permissions > Purchasing',
      description:
          'Establish rule parameters for automatic regional tax code calculations on PO generation workflows.',
      icon: Icons.settings_outlined,
      targetSection: 'roles_permissions',
    ),
    SettingsSearchResultItem(
      id: 'pricing_toggles',
      title: 'Tax-inclusive Pricing toggles',
      breadcrumb: 'Settings > Sales Channels > POS Terminals',
      description:
          'Enable/disable tax-inclusive calculations at billing checkout endpoints on local physical counters.',
      icon: Icons.local_offer_outlined,
      targetSection: 'sales_channels',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 24,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isStacked = constraints.maxWidth < 980;

            if (isStacked) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSubnavColumn(isFullWidth: true),
                    const SizedBox(height: 20),
                    _buildResultsColumn(),
                  ],
                ),
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Sub-navigation (230 px)
                SizedBox(
                  width: 230,
                  child: _buildSubnavColumn(isFullWidth: false),
                ),
                const SizedBox(width: 24),

                // Right Column: Search Results
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildResultsColumn(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ==========================================
  // LEFT COLUMN: SUB-NAVIGATION
  // ==========================================
  Widget _buildSubnavColumn({required bool isFullWidth}) {
    final navItems = [
      {'id': 'general_settings', 'label': 'General Settings', 'icon': Icons.settings_outlined},
      {'id': 'locations', 'label': 'Locations', 'icon': Icons.location_on_outlined},
      {'id': 'roles_permissions', 'label': 'Roles & Permissions', 'icon': Icons.people_outline_rounded},
      {'id': 'data_retention', 'label': 'Data Retention', 'icon': Icons.storage_rounded},
      {'id': 'integrations', 'label': 'Integrations', 'icon': Icons.link_rounded},
    ];

    return Column(
      children: [
        for (int i = 0; i < navItems.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildNavItem(
            id: navItems[i]['id'] as String,
            label: navItems[i]['label'] as String,
            icon: navItems[i]['icon'] as IconData,
          ),
        ],
      ],
    );
  }

  Widget _buildNavItem({
    required String id,
    required String label,
    required IconData icon,
  }) {
    return InkWell(
      onTap: () => widget.onSelectSection?.call(id),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFEFE7DC),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: const Color(0xFF5A5248),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // RIGHT COLUMN: SEARCH RESULTS
  // ==========================================
  Widget _buildResultsColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header: Search Results for “tax” (4 matches found) + Clear Search
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Search Results for “${widget.searchQuery}” (${_results.length} matches found)',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181513),
              ),
            ),
            InkWell(
              onTap: widget.onClearSearch,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Color(0xFF9E6721),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Clear Search',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF9E6721),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. 4 Search Result Cards
        for (int i = 0; i < _results.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _buildResultCard(_results[i]),
        ],
        const SizedBox(height: 18),

        // 3. Helpful Fallback Banner
        _buildHelpfulBanner(),
        const SizedBox(height: 24),

        // 4. Bottom-Left Brand Quote
        _buildQuote(),
      ],
    );
  }

  Widget _buildResultCard(SettingsSearchResultItem item) {
    return InkWell(
      onTap: () => widget.onSelectSection?.call(item.targetSection),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Icon Container
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF4EC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFF0E5D4),
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  size: 20,
                  color: const Color(0xFF8D6433),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Text Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(height: 3),

                  // Breadcrumb
                  Text(
                    item.breadcrumb,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFB27B3D),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    item.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B6357),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Trailing Chevron
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: Color(0xFFA89F93),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 3. HELPFUL FALLBACK BANNER
  // ==========================================
  Widget _buildHelpfulBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4D0B8), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Lightbulb Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF0E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEBDBC8), width: 1.0),
            ),
            child: const Center(
              child: Icon(
                Icons.lightbulb_outline_rounded,
                size: 22,
                color: Color(0xFF8D6433),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Text Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "DIDN'T FIND WHAT YOU'RE LOOKING FOR?",
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: const Color(0xFF8C8377),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Try different keywords or browse all settings.',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF34281E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You can also contact your administrator for help.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7E766B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),

          // Browse All Settings Button
          InkWell(
            onTap: widget.onBrowseAllSettings,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBA8A55), width: 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.grid_view_rounded,
                    size: 15,
                    color: Color(0xFF8D6433),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Browse All Settings',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6E491F),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFF6E491F),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. BOTTOM-LEFT BRAND QUOTE
  // ==========================================
  Widget _buildQuote() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gold vertical bar
          Container(
            width: 2.5,
            height: 38,
            color: const Color(0xFFBA8A55),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“Simple settings. Powerful operations.”',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 15.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4137),
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '— ThreadStock',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8C8377),
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
