// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class ImportServiceItem {
  final String title;
  final IconData icon;
  final String lastImport;

  const ImportServiceItem({
    required this.title,
    required this.icon,
    required this.lastImport,
  });
}

class ExportServiceItem {
  final String title;
  final IconData icon;
  String selectedFormat;

  ExportServiceItem({
    required this.title,
    required this.icon,
    this.selectedFormat = 'CSV',
  });
}

class ImportLogRecord {
  final String fileName;
  final String type;
  final String records;
  final String status;
  final bool isSuccess;
  final String date;
  final String user;

  const ImportLogRecord({
    required this.fileName,
    required this.type,
    required this.records,
    required this.status,
    required this.isSuccess,
    required this.date,
    required this.user,
  });
}

class ImportExportCenterView extends StatefulWidget {
  final VoidCallback? onBackToSettings;
  final void Function(String title, String subtitle)? onSubNavChanged;
  final void Function(String sectionKey)? onSelectSection;

  const ImportExportCenterView({
    super.key,
    this.onBackToSettings,
    this.onSubNavChanged,
    this.onSelectSection,
  });

  @override
  State<ImportExportCenterView> createState() => _ImportExportCenterViewState();
}

class _ImportExportCenterViewState extends State<ImportExportCenterView> {
  int _activeTabIndex = 2; // "Import / Export" is index 2
  String _selectedWarehouse = 'All Locations';

  final List<String> _tabs = const [
    'Purchasing Defaults',
    'Transfer Settings',
    'Import / Export',
    'API & Webhooks',
    'Audit Log',
  ];

  final List<String> _warehouses = const ['All Locations'];

  final List<ImportServiceItem> _importServices = const [
    ImportServiceItem(
      title: 'Products',
      icon: Icons.inventory_2_outlined,
      lastImport: 'Last import: 2 days ago',
    ),
    ImportServiceItem(
      title: 'Customers',
      icon: Icons.people_outline_rounded,
      lastImport: 'Last import: 2 days ago',
    ),
    ImportServiceItem(
      title: 'Inventory',
      icon: Icons.inventory_2_outlined,
      lastImport: 'Last import: 2 days ago',
    ),
    ImportServiceItem(
      title: 'Purchase Orders',
      icon: Icons.description_outlined,
      lastImport: 'Last import: 2 days ago',
    ),
    ImportServiceItem(
      title: 'Suppliers',
      icon: Icons.local_shipping_outlined,
      lastImport: 'Last import: 2 days ago',
    ),
  ];

  late final List<ExportServiceItem> _exportServices;

  final List<ImportLogRecord> _logs = const [
    ImportLogRecord(
      fileName: 'products_batch_v2.csv',
      type: 'Products',
      records: '1,204 rows',
      status: 'Complete',
      isSuccess: true,
      date: 'Oct 24, 11:24 AM',
      user: 'Admin User',
    ),
    ImportLogRecord(
      fileName: 'inventory_counts_hub.xlsx',
      type: 'Inventory',
      records: '450 rows',
      status: 'Failed (Line 42)',
      isSuccess: false,
      date: 'Oct 23, 04:12 PM',
      user: 'Store Manager',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _exportServices = [
      ExportServiceItem(title: 'Products', icon: Icons.inventory_2_outlined),
      ExportServiceItem(title: 'Inventory', icon: Icons.inventory_2_outlined),
      ExportServiceItem(title: 'Reports', icon: Icons.bar_chart_outlined),
      ExportServiceItem(title: 'Audit Log', icon: Icons.article_outlined),
    ];
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

  void _showImportModal(String entityName) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEADBCA)),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.upload_file_outlined,
                  size: 20,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Import $entityName',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload your CSV or Excel file containing $entityName data.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B6357),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFDFD4C5),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        size: 36,
                        color: Color(0xFF7A481B),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Drag & drop your file here, or browse',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supports .csv, .xls, .xlsx (up to 25MB)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF8C827A),
                        ),
                      ),
                    ],
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
                Navigator.pop(ctx);
                _showFeedback('Importing $entityName file...');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7A481B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Upload & Validate',
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
    return DesktopContentConstraint(
      maxWidth: 1320,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Area with warehouse dropdown
            _buildHeader(),

            const SizedBox(height: 20),

            // Operational Sub-Navigation Tabs Row
            _buildTabsRow(),

            const SizedBox(height: 24),

            // Section 1: Data Import Services Card
            _buildDataImportServicesCard(),

            const SizedBox(height: 24),

            // Section 2: Data Export Services Card
            _buildDataExportServicesCard(),

            const SizedBox(height: 24),

            // Section 3: Recent Import Logs Card
            _buildRecentImportLogsCard(),

            const SizedBox(height: 24),

            // Bottom Pro Tip Banner
            _buildProTipBanner(),
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
        // Warm circular avatar with upload icon
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFFAF2E6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.file_upload_outlined,
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
                'Import / Export Center',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.',
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
                'Settings > Import / Export Center > $val',
                'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.',
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
                      'Settings > Purchasing Defaults',
                      'Configure buying, receiving and cost settings for your business.',
                    );
                  }
                } else if (i == 1) {
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('transfer_settings');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > Transfer Settings',
                      'Configure stock transfer workflows, transit times and receiving preferences.',
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

  // Section 1: Data Import Services
  Widget _buildDataImportServicesCard() {
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
                  Icons.file_upload_outlined,
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
                      'Data Import Services',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Import your master and transactional data from CSV or Excel files.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showFeedback('Opening Import Guide...'),
                icon: const Icon(
                  Icons.menu_book_outlined,
                  size: 16,
                  color: Color(0xFF181513),
                ),
                label: Text(
                  'View Import Guide',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  side: const BorderSide(color: Color(0xFFDFD4C5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 5 Import Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 950) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _importServices
                      .map(
                        (item) => SizedBox(
                          width: (constraints.maxWidth - 16) / 2,
                          child: _buildImportItemCard(item),
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: [
                  for (int i = 0; i < _importServices.length; i++) ...[
                    Expanded(child: _buildImportItemCard(_importServices[i])),
                    if (i < _importServices.length - 1)
                      const SizedBox(width: 16),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImportItemCard(ImportServiceItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE5D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF2E6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 18, color: const Color(0xFF7A481B)),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.lastImport,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8C827A),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showImportModal(item.title),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                side: const BorderSide(color: Color(0xFFDFD4C5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Import CSV / Excel',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section 2: Data Export Services
  Widget _buildDataExportServicesCard() {
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
                  Icons.file_download_outlined,
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
                      'Data Export Services',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Export your data for reporting, analysis or external systems.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showFeedback('Opening Export Scheduler...'),
                icon: const Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: Color(0xFF181513),
                ),
                label: Text(
                  'Schedule Exports',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  side: const BorderSide(color: Color(0xFFDFD4C5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 4 Export Cards Row
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 950) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: _exportServices
                      .map(
                        (item) => SizedBox(
                          width: (constraints.maxWidth - 16) / 2,
                          child: _buildExportItemCard(item),
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                children: [
                  for (int i = 0; i < _exportServices.length; i++) ...[
                    Expanded(child: _buildExportItemCard(_exportServices[i])),
                    if (i < _exportServices.length - 1)
                      const SizedBox(width: 16),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExportItemCard(ExportServiceItem item) {
    const formats = ['CSV', 'Excel', 'PDF'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDE5D8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF2E6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 18, color: const Color(0xFF7A481B)),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 12),

          // Format Segmented Pills
          Row(
            children: formats.map((fmt) {
              final isFmtSelected = item.selectedFormat == fmt;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() => item.selectedFormat = fmt);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: isFmtSelected
                          ? const Color(0xFFF3EADB)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: isFmtSelected
                          ? Border.all(color: const Color(0xFFE0D4C3))
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        fmt,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: isFmtSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isFmtSelected
                              ? const Color(0xFF181513)
                              : const Color(0xFF7E766B),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Export Now Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showFeedback(
                  'Exporting ${item.title} as ${item.selectedFormat}...',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Export Now',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Section 3: Recent Import Logs
  Widget _buildRecentImportLogsCard() {
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
                  Icons.schedule_rounded,
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
                      'Recent Import Logs',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'View the status of your recent import activities.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    _showFeedback('Loading complete activity log...'),
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  size: 15,
                  color: Color(0xFF181513),
                ),
                label: Text(
                  'View All Logs',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  side: const BorderSide(color: Color(0xFFDFD4C5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Logs Table Header
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'FILE NAME',
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
                  'TYPE',
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
                  'RECORDS',
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
                  'STATUS',
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
                  'DATE',
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
                  'USER',
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

          // Logs Table Rows
          for (int i = 0; i < _logs.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      _logs[i].fileName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _logs[i].type,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF5E574E),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _logs[i].records,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF5E574E),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _logs[i].isSuccess
                              ? const Color(0xFFEAF7EE)
                              : const Color(0xFFFCECEB),
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
                                color: _logs[i].isSuccess
                                    ? const Color(0xFF28A745)
                                    : const Color(0xFFE53E3E),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _logs[i].status,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _logs[i].isSuccess
                                    ? const Color(0xFF1E7E34)
                                    : const Color(0xFFC53030),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _logs[i].date,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF5E574E),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _logs[i].user,
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
                          _showFeedback(
                            'Selected $action for ${_logs[i].fileName}',
                          );
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'download',
                            child: Text(
                              'Download Source File',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'view_details',
                            child: Text(
                              'View Details',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < _logs.length - 1)
              const Divider(color: Color(0xFFF7F1EA), height: 1, thickness: 1),
          ],
        ],
      ),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 24, color: Color(0xFF7A481B)),
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
                  'Use consistent column headers and download our templates to ensure a smooth import process.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF7E766B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed: () => _showFeedback('Downloading templates...'),
            icon: const Icon(
              Icons.download_outlined,
              size: 16,
              color: Color(0xFF181513),
            ),
            label: Text(
              'Download Templates',
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
}
