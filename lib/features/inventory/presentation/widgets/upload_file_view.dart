// ignore_for_file: deprecated_member_use
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/inventory_file_parser.dart';
import '../../domain/models/inventory_import_draft.dart';

/// Import Inventory — Step 1 of the inventory import wizard (Upload File).
class UploadFileView extends StatefulWidget {
  /// Called when a real CSV/XLSX file has been parsed successfully.
  final ValueChanged<InventoryImportDraft>? onFileReady;

  /// Optional navigation callback when the user leaves the import step.
  final VoidCallback? onBack;

  /// True when parent already holds import work (file/mapping/validation).
  final bool hasUnsavedWork;

  /// Accessible tooltip / semantics for the Back control.
  final String backTooltip;

  const UploadFileView({
    super.key,
    this.onFileReady,
    this.onBack,
    this.hasUnsavedWork = false,
    this.backTooltip = 'Back to inventory',
  });

  @override
  State<UploadFileView> createState() => _UploadFileViewState();
}

class _UploadFileViewState extends State<UploadFileView> {
  bool _isDragging = false;
  bool _isPicking = false;
  String? _pickError;
  InventoryImportDraft? _selectedDraft;
  final InventoryFileParser _parser = const InventoryFileParser();
  final FocusNode _pageFocusNode = FocusNode();

  bool get _wouldLoseWork => _selectedDraft != null || widget.hasUnsavedWork;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _pageFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pageFocusNode.dispose();
    super.dispose();
  }

  Future<void> _chooseFile() async {
    if (_isPicking) {
      return;
    }

    setState(() {
      _isPicking = true;
      _pickError = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'xlsx'],
        withData: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        // User cancelled — not an error.
        return;
      }

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw InventoryFileParseException(
          'Could not read the selected file. Try again.',
        );
      }

      final draft = _parser.parse(fileName: file.name, bytes: bytes);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedDraft = draft;
        _pickError = null;
      });

      widget.onFileReady?.call(draft);
    } on InventoryFileParseException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _pickError = error.message);
    } catch (error, stackTrace) {
      debugPrint('Inventory file pick failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      setState(() {
        _pickError =
            'Unable to open the file picker. Check permissions and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  Future<void> _handleBack() async {
    if (_wouldLoseWork) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            'Leave import?',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181614),
            ),
          ),
          content: Text(
            'Your current import setup has not been completed.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF5E574E),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Stay',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                'Leave Import',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8C5E33),
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldLeave != true) {
        return;
      }
    }

    if (!mounted) {
      return;
    }

    if (widget.onBack != null) {
      widget.onBack!.call();
      return;
    }

    if (Navigator.canPop(context)) {
      Navigator.maybePop(context);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _pageFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _handleBack();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            const SizedBox(height: 20),
            _buildStepIndicator(),
            const SizedBox(height: 20),

            if (_pickError != null) ...[
              Text(
                _pickError!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB42318),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_selectedDraft != null) ...[
              Text(
                'Selected: ${_selectedDraft!.fileName} · ${_selectedDraft!.totalRows} data rows',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3D3530),
                ),
              ),
              const SizedBox(height: 12),
            ],

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
        Semantics(
          button: true,
          label: widget.backTooltip,
          child: Tooltip(
            message: widget.backTooltip,
            child: TextButton.icon(
              onPressed: _handleBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(
                'Back',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5E574E),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
      ),
    );
  }

  Widget _buildStep(
    int number,
    String label, {
    bool isActive = false,
    bool isDone = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? const Color(0xFF22C55E)
                : (isActive
                      ? const Color(0xFF8C5E33)
                      : const Color(0xFFF1EBE3)),
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
    return Container(
      width: 34,
      height: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: isDone ? const Color(0xFF22C55E) : const Color(0xFFE8DFD3),
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
          color: _isDragging
              ? const Color(0xFFFFF8EF)
              : const Color(0xFFFFFDF9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDragging
                ? const Color(0xFFD4A96A)
                : const Color(0xFFE0C99A),
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
                const Icon(
                  Icons.shield_outlined,
                  size: 13,
                  color: Color(0xFF9E8E7E),
                ),
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
      onTap: _isPicking ? null : _chooseFile,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: _isPicking ? const Color(0xFF4B4540) : const Color(0xFF1A1816),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isPicking
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Opening…',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Text(
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Downloading import template…',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: const Color(0xFF1E1C1A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 2),
          ),
        );
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
          const Icon(
            Icons.insert_drive_file_outlined,
            size: 20,
            color: Color(0xFF8C5E33),
          ),
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
              const Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Color(0xFFD4A96A),
              ),
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
                const Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: Color(0xFFB5860D),
                ),
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
  // Previous Imports History — real jobs only (never demo filenames)
  // ---------------------------------------------------------------------------

  Widget _buildPreviousImportsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 17,
              color: Color(0xFF8C5E33),
            ),
            const SizedBox(width: 8),
            Text(
              'Previous Imports History',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1816),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8DFD3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.inbox_outlined,
                size: 28,
                color: Color(0xFF9E8E7E),
              ),
              const SizedBox(height: 10),
              Text(
                'No import jobs yet',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1816),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Completed CSV and Excel imports will appear here.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF7E766B),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
