// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class DataRetentionView extends StatefulWidget {
  const DataRetentionView({super.key, this.onSelectNav, this.onBackToSettings});

  final ValueChanged<String>? onSelectNav;
  final VoidCallback? onBackToSettings;

  @override
  State<DataRetentionView> createState() => _DataRetentionViewState();
}

class _DataRetentionViewState extends State<DataRetentionView> {
  String _selectedNav = 'data_retention';

  // Dropdown states
  String _transactionRetention = '7 Years (Mandatory)';
  String _auditLogsRetention = '90 Days (Default)';
  String _customerDataRetention = 'Retain until requested deletion';
  String _deletedRecordsRetention = '30 Days (Soft Delete)';
  String _automatedBackupsRetention = 'Retain 90 Days';

  bool _isExporting = false;

  void _handleExport() {
    setState(() => _isExporting = true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFD5A46C),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Compiling GDPR archive (invoices, audit trails, customer records)...',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B18),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isExporting = false);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Color(0xFFD5A46C),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Data export ready: ThreadStock_Workspace_Archive_2026.zip (48.2 MB) downloaded.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1B18),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(milliseconds: 3500),
        ),
      );
    });
  }

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
                    _buildMainContent(),
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

                // Right Column: Data Retention Policy & Settings
                Expanded(
                  child: SingleChildScrollView(child: _buildMainContent()),
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
      {
        'id': 'general_settings',
        'label': 'General Settings',
        'icon': Icons.settings_outlined,
      },
      {
        'id': 'locations',
        'label': 'Locations',
        'icon': Icons.location_on_outlined,
      },
      {
        'id': 'roles_permissions',
        'label': 'Roles & Permissions',
        'icon': Icons.people_outline_rounded,
      },
      {
        'id': 'data_retention',
        'label': 'Data Retention',
        'icon': Icons.storage_rounded,
      },
      {
        'id': 'integrations',
        'label': 'Integrations',
        'icon': Icons.link_rounded,
      },
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
    final isSelected = id == _selectedNav;

    return InkWell(
      onTap: () {
        setState(() => _selectedNav = id);
        widget.onSelectNav?.call(id);
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9E6721) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF8B5719)
                : const Color(0xFFEFE7DC),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF9E6721).withOpacity(0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF5A5248),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF1E1C1A),
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFFF7EFE4),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // RIGHT COLUMN: MAIN CONTENT
  // ==========================================
  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Card: Data Retention Policy + Editorial Quote
        _buildHeaderCard(),
        const SizedBox(height: 16),

        // 2. Policy Card 1: Transaction Records
        _buildPolicyCard(
          icon: Icons.description_outlined,
          title: 'Transaction Records',
          description:
              'Sales invoices, stock transfers, purchasing billing summaries, and custom ledger adjustments.',
          footnote:
              'Cannot reduce below regulatory minimum tax requirement for audits.',
          currentValue: _transactionRetention,
          options: const [
            '5 Years',
            '7 Years (Mandatory)',
            '10 Years',
            'Indefinite Retention',
          ],
          onChanged: (val) => setState(() => _transactionRetention = val),
        ),
        const SizedBox(height: 14),

        // 3. Policy Card 2: Audit Logs
        _buildPolicyCard(
          icon: Icons.shield_outlined,
          title: 'Audit Logs',
          description:
              'System sign-ins, user edits, transfer authorizations, automated workflow trigger events.',
          footnote: 'Extendable up to 1 year on advanced plans.',
          currentValue: _auditLogsRetention,
          options: const [
            '30 Days',
            '60 Days',
            '90 Days (Default)',
            '180 Days',
            '1 Year (Extended)',
          ],
          onChanged: (val) => setState(() => _auditLogsRetention = val),
        ),
        const SizedBox(height: 14),

        // 4. Policy Card 3: Customer Data
        _buildPolicyCard(
          icon: Icons.people_outline_rounded,
          title: 'Customer Data',
          description:
              'Customer profiles, historic purchases, discount assignments, contact notes.',
          footnote: 'Fully compliant with GDPR & data protection tools.',
          currentValue: _customerDataRetention,
          options: const [
            'Retain until requested deletion',
            'Anonymize after 2 Years',
            'Purge after 3 Years of Inactivity',
          ],
          onChanged: (val) => setState(() => _customerDataRetention = val),
        ),
        const SizedBox(height: 14),

        // 5. Policy Card 4: Deleted Records (Red trash icon)
        _buildPolicyCard(
          icon: Icons.delete_outline_rounded,
          isAlertIcon: true,
          title: 'Deleted Records',
          description:
              'Soft-deleted files, archived invoices, and product variants removed from catalog.',
          footnote:
              'Permanently erased from background databases after window.',
          currentValue: _deletedRecordsRetention,
          options: const [
            '7 Days (Immediate)',
            '14 Days',
            '30 Days (Soft Delete)',
            '60 Days (Extended Recovery)',
          ],
          onChanged: (val) => setState(() => _deletedRecordsRetention = val),
        ),
        const SizedBox(height: 14),

        // 6. Policy Card 5: Automated Backups
        _buildPolicyCard(
          icon: Icons.cloud_outlined,
          title: 'Automated Backups',
          description:
              'Daily system snapshots of current inventory state, warehouse configurations.',
          footnote: 'Cold storage archive is triggered monthly.',
          currentValue: _automatedBackupsRetention,
          options: const [
            'Retain 30 Days',
            'Retain 60 Days',
            'Retain 90 Days',
            'Retain 180 Days',
            'Retain 365 Days',
          ],
          onChanged: (val) => setState(() => _automatedBackupsRetention = val),
        ),
        const SizedBox(height: 16),

        // 7. Bottom Card: GDPR & Compliance Data Export
        _buildGdprExportCard(),
      ],
    );
  }

  // ==========================================
  // 1. HEADER CARD
  // ==========================================
  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storage / Database Disc Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF4EC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF0E5D4), width: 1.0),
            ),
            child: const Center(
              child: Icon(
                Icons.storage_rounded,
                size: 22,
                color: Color(0xFF8D6433),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Title & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Retention Policy',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure automated archival, backup storage intervals, and GDPR deletion cycles.',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6357),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Right Italic Serif Quote
          Text(
            'Keep your data secure,\ncompliant and organized.',
            textAlign: TextAlign.right,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7E5B37),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // POLICY SETTING CARD TEMPLATE
  // ==========================================
  Widget _buildPolicyCard({
    required IconData icon,
    bool isAlertIcon = false,
    required String title,
    required String description,
    required String footnote,
    required String currentValue,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
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
              color: isAlertIcon
                  ? const Color(0xFFFDF2F2)
                  : const Color(0xFFFAF4EC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isAlertIcon
                    ? const Color(0xFFFDE2E2)
                    : const Color(0xFFF0E5D4),
                width: 1.0,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 20,
                color: isAlertIcon
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF8D6433),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Center Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF5A5248),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Color(0xFF8C8377),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        footnote,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Right Dropdown Selector
          PopupMenuButton<String>(
            tooltip: 'Change retention duration',
            onSelected: onChanged,
            offset: const Offset(0, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFEADBCA)),
            ),
            color: Colors.white,
            elevation: 4,
            itemBuilder: (context) => options.map((opt) {
              final isSelected = opt == currentValue;
              return PopupMenuItem<String>(
                value: opt,
                height: 38,
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: Color(0xFF9E6721),
                      )
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(
                      opt,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? const Color(0xFF9E6721)
                            : const Color(0xFF1E1C1A),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDFD4C5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentValue,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1E1C1A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: Color(0xFF5E574E),
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
  // 7. BOTTOM BANNER: GDPR DATA EXPORT
  // ==========================================
  Widget _buildGdprExportCard() {
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
          // Tray Download Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF0E2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEBDBC8), width: 1.0),
            ),
            child: const Center(
              child: Icon(
                Icons.file_download_outlined,
                size: 22,
                color: Color(0xFF8D6433),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Middle Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GDPR & Compliance Data Export',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Generate and download a complete archive of all system records associated with this workspace.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6357),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Action Button: Export All My Data
          SizedBox(
            height: 42,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _handleExport,
              icon: _isExporting
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.file_download_outlined,
                      size: 17,
                      color: Colors.white,
                    ),
              label: Text(
                _isExporting ? 'Preparing Archive...' : 'Export All My Data',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF382B21),
                disabledBackgroundColor: const Color(0xFF5E574E),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
