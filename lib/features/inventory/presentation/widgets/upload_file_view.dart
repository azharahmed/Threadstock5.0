// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Import Inventory — Step 1 of the inventory import wizard (Upload File).
class UploadFileView extends StatefulWidget {
  /// Called when the user picks a file and continues to step 2.
  final VoidCallback? onFilePicked;

  const UploadFileView({super.key, this.onFilePicked});

  @override
  State<UploadFileView> createState() => _UploadFileViewState();
}

class _UploadFileViewState extends State<UploadFileView> {
  bool _isDragging = false;

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 20),
          _buildStepIndicator(),
          const SizedBox(height: 20),

          // Main two-column content
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 62, child: _buildLeftColumn()),
                    const SizedBox(width: 20),
                    SizedBox(width: 296, child: _buildAIImportPrepCard()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildLeftColumn(),
                  const SizedBox(height: 16),
                  _buildAIImportPrepCard(),
                ],
              );
            },
          ),
          const SizedBox(height: 28),

          // Previous Imports History
          _buildPreviousImportsSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page Header
  // ---------------------------------------------------------------------------

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import Inventory',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181614),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add or update inventory from CSV or Excel files.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6B6358),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step Indicator
  // ---------------------------------------------------------------------------

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8DFD3)),
      ),
      child: Row(
        children: [
          _buildStep(1, 'Upload File', isActive: true),
          _buildStepConnector(),
          _buildStep(2, 'Map Columns'),
          _buildStepConnector(),
          _buildStep(3, 'Validate Rows'),
          _buildStepConnector(),
          _buildStep(4, 'Review & Import'),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String label, {bool isActive = false, bool isDone = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF22C55E)
                : (isActive ? const Color(0xFF8C5E33) : const Color(0xFFF1EBE3)),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
              : Text(
                  '$number',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF9E8E7E),
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? const Color(0xFF181614) : const Color(0xFF9E8E7E),
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({bool isDone = false}) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: isDone ? const Color(0xFF22C55E) : const Color(0xFFE8DFD3),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Left Column
  // ---------------------------------------------------------------------------

  Widget _buildLeftColumn() {
    return Column(
      children: [
        _buildDropzoneCard(),
        const SizedBox(height: 14),
        _buildImportDetailsCard(),
      ],
    );
  }

  Widget _buildDropzoneCard() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isDragging = true),
      onExit: (_) => setState(() => _isDragging = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 28),
        decoration: BoxDecoration(
          color: _isDragging ? const Color(0xFFFFF8EF) : const Color(0xFFFFFDF9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDragging ? const Color(0xFFD4A96A) : const Color(0xFFE0C99A),
            width: 1.5,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            // Upload icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF5EDE0),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.upload_rounded,
                size: 28,
                color: Color(0xFF8C5E33),
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Drag and drop your spreadsheet here',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1816),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Supports .CSV, .XLSX up to 25MB',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF7E766B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // CTA buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildChooseFileButton(),
                const SizedBox(width: 12),
                _buildDownloadTemplateButton(),
              ],
            ),
            const SizedBox(height: 18),

            // Footer privacy note
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield_outlined, size: 13, color: Color(0xFF9E8E7E)),
                const SizedBox(width: 5),
                Text(
                  'CSV / XLSX  ·  Maximum 25 MB  ·  Data remains private',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9E8E7E),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChooseFileButton() {
    return InkWell(
      onTap: widget.onFilePicked,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1816),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Choose File',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadTemplateButton() {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Downloading import template…',
            style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E1C1A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 2),
        ));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD5C9BC)),
        ),
        child: Text(
          'Download Template',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF3D3530),
          ),
        ),
      ),
    );
  }

  Widget _buildImportDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8DFD3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 20, color: Color(0xFF8C5E33)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import details',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1816),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Map and upload new styles or update existing stock quantities dynamically. Your inventory catalog, prices, custom attributes, and barcodes will automatically update based on SKUs matching existing patterns.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF7E766B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI Import Prep Card (right column)
  // ---------------------------------------------------------------------------

  Widget _buildAIImportPrepCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DFD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFFD4A96A)),
              const SizedBox(width: 8),
              Text(
                'AI Import Prep',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1816),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Save time with AI-powered data preparation.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 18),

          // Feature bullets
          _buildAIFeatureBullet(
            icon: Icons.insert_drive_file_outlined,
            title: 'Auto-detect columns',
            subtitle: 'We identify and map your data fields.',
          ),
          const SizedBox(height: 14),
          _buildAIFeatureBullet(
            icon: Icons.style_outlined,
            title: 'Recognize variants and SKUs',
            subtitle: 'Handles size, color and variant data.',
          ),
          const SizedBox(height: 14),
          _buildAIFeatureBullet(
            icon: Icons.warning_amber_rounded,
            title: 'Flag invalid rows before import',
            subtitle: 'Catch issues early to ensure a smooth import.',
          ),
          const SizedBox(height: 16),

          // Info box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9EC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEED49F)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFB5860D)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ensure the first row contains column headers like "Variant SKU", "Retail Price", "Opening Stock".',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF92650A),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIFeatureBullet({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF5EDE0),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 17, color: const Color(0xFF8C5E33)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1816),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Previous Imports History
  // ---------------------------------------------------------------------------

  Widget _buildPreviousImportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 17, color: Color(0xFF8C5E33)),
            const SizedBox(width: 8),
            Text(
              'Previous Imports History',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1816),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all imports',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB5860D),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFB5860D)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8DFD3)),
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              _buildHistoryRow(
                filename: 'summer_collection_replenish.csv',
                fileType: 'csv',
                totalRows: '450 rows',
                imported: '442 SKUs',
                status: _ImportStatus.issues,
                statusLabel: '8 issues resolved',
                user: 'Alex Morgan',
                date: 'Yesterday, 14:20',
              ),
              _buildHistoryRow(
                filename: 'surat_hub_opening_stock.xlsx',
                fileType: 'xlsx',
                totalRows: '1,200 rows',
                imported: '1,200 SKUs',
                status: _ImportStatus.completed,
                statusLabel: 'Completed',
                user: 'Alex Morgan',
                date: 'Feb 08, 2027',
              ),
              _buildHistoryRow(
                filename: 'delhi_boutique_special_order.csv',
                fileType: 'csv',
                totalRows: '85 rows',
                imported: '82 SKUs',
                status: _ImportStatus.skipped,
                statusLabel: '3 items skipped',
                user: 'Priya Sharma',
                date: 'Jan 28, 2027',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    final style = GoogleFonts.inter(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF8E7F72),
      letterSpacing: 0.3,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(11),
          topRight: Radius.circular(11),
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFEEE5D8))),
      ),
      child: Row(
        children: [
          Expanded(flex: 30, child: Text('FILE NAME', style: style)),
          Expanded(flex: 12, child: Text('TOTAL ROWS', style: style)),
          Expanded(flex: 12, child: Text('IMPORTED', style: style)),
          Expanded(flex: 20, child: Text('STATUS / ERRORS', style: style)),
          Expanded(flex: 16, child: Text('BY USER', style: style)),
          Expanded(flex: 14, child: Text('DATE', style: style)),
          const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildHistoryRow({
    required String filename,
    required String fileType,
    required String totalRows,
    required String imported,
    required _ImportStatus status,
    required String statusLabel,
    required String user,
    required String date,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF4EDE5), width: 0.8)),
      ),
      child: Row(
        children: [
          // File name + icon
          Expanded(
            flex: 30,
            child: Row(
              children: [
                _buildFileTypeIcon(fileType),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    filename,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1816),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              totalRows,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5C5047)),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              imported,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF1A1816)),
            ),
          ),
          Expanded(
            flex: 20,
            child: _buildStatusBadge(status, statusLabel),
          ),
          Expanded(
            flex: 16,
            child: Text(
              user,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5C5047)),
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              date,
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF9E8E7E)),
            ),
          ),
          // Actions
          SizedBox(
            width: 36,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(6),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.more_horiz_rounded, size: 18, color: Color(0xFF9E8E7E)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileTypeIcon(String type) {
    final isCsv = type == 'csv';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF217346),
        borderRadius: BorderRadius.circular(5),
      ),
      alignment: Alignment.center,
      child: Text(
        isCsv ? 'CSV' : 'XLS',
        style: GoogleFonts.inter(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(_ImportStatus status, String label) {
    Color bg, fg;
    switch (status) {
      case _ImportStatus.completed:
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      case _ImportStatus.issues:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
      case _ImportStatus.skipped:
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == _ImportStatus.completed ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            size: 13,
            color: fg,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ImportStatus { completed, issues, skipped }
