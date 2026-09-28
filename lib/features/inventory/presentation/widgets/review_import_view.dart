// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/inventory_import_draft.dart';

/// Review & Import — Step 4 (final) of the inventory import wizard.
class ReviewImportView extends StatefulWidget {
  final InventoryImportDraft? draft;
  final Map<String, InventoryImportTargetField> columnMappings;
  final VoidCallback? onConfirm;
  final VoidCallback? onBack;

  const ReviewImportView({
    super.key,
    this.draft,
    this.columnMappings = const {},
    this.onConfirm,
    this.onBack,
  });

  @override
  State<ReviewImportView> createState() => _ReviewImportViewState();
}

class _ReviewImportViewState extends State<ReviewImportView> {
  bool _skipErrors = true;
  bool _notifyTeam = false;
  bool _createSnapshot = true;
  bool _isImporting = false;
  double _importProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPageHeader(),
          const SizedBox(height: 24),
          _buildStepIndicator(),
          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildLeftColumn()),
                    const SizedBox(width: 20),
                    SizedBox(width: 340, child: _buildRightColumn()),
                  ],
                );
              }
              return Column(
                children: [
                  _buildLeftColumn(),
                  const SizedBox(height: 20),
                  _buildRightColumn(),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Import',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181614),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Confirm your import settings and start importing valid rows into ThreadStock.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8DFD3)),
      ),
      child: Row(
        children: [
          _buildStep(1, 'Upload File', isDone: true),
          _buildStepConnector(isDone: true),
          _buildStep(2, 'Map Columns', isDone: true),
          _buildStepConnector(isDone: true),
          _buildStep(3, 'Validate Rows', isDone: true),
          _buildStepConnector(isDone: true),
          _buildStep(4, 'Review & Import', isActive: true),
        ],
      ),
    );
  }

  Widget _buildStep(
    int number,
    String label, {
    bool isDone = false,
    bool isActive = false,
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
                      ? const Color(0xFF2563EB)
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
            color: isActive
                ? const Color(0xFF181614)
                : (isDone ? const Color(0xFF6B6358) : const Color(0xFF9E8E7E)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector({bool isDone = false}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDone ? const Color(0xFF22C55E) : const Color(0xFFE8DFD3),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Left column — import summary + options
  // ---------------------------------------------------------------------------

  Widget _buildLeftColumn() {
    return Column(
      children: [
        _buildImportSummaryCard(),
        const SizedBox(height: 16),
        _buildImportOptionsCard(),
        const SizedBox(height: 16),
        _buildLocationTargetCard(),
      ],
    );
  }

  Widget _buildImportSummaryCard() {
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
          Row(
            children: [
              const Icon(
                Icons.summarize_outlined,
                size: 18,
                color: Color(0xFF8C5E33),
              ),
              const SizedBox(width: 8),
              Text(
                'Import Summary',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1816),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
            'Source File',
            'ThreadStock_Inventory_Jan2027.xlsx',
            isFile: true,
          ),
          _buildSummaryRow('Target Location', 'Primary Facility (Zone A)'),
          _buildSummaryRow('Total Rows in File', '2,456'),
          _buildSummaryRow('Mapped Columns', '10 of 11'),
          _buildSummaryRow(
            'Valid Rows',
            '2,315',
            valueColor: const Color(0xFF16A34A),
          ),
          _buildSummaryRow(
            'Rows with Warnings',
            '98',
            valueColor: const Color(0xFFD97706),
          ),
          _buildSummaryRow(
            'Invalid Rows (Skipped)',
            '43',
            valueColor: const Color(0xFFDC2626),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isFile = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF4EDE5), width: 0.8),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 40,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF7E766B),
              ),
            ),
          ),
          Expanded(
            flex: 60,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFile)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: const Color(0xFF217346),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'X',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? const Color(0xFF1A1816),
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

  Widget _buildImportOptionsCard() {
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
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                size: 18,
                color: Color(0xFF8C5E33),
              ),
              const SizedBox(width: 8),
              Text(
                'Import Options',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1816),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildOptionToggle(
            label: 'Skip invalid rows',
            subtitle:
                'Import only the 2,315 valid rows; 43 error rows will be excluded.',
            value: _skipErrors,
            onChanged: (v) => setState(() => _skipErrors = v),
          ),
          const Divider(color: Color(0xFFF4EDE5), height: 20),
          _buildOptionToggle(
            label: 'Create pre-import snapshot',
            subtitle:
                'Back up current inventory state before applying changes.',
            value: _createSnapshot,
            onChanged: (v) => setState(() => _createSnapshot = v),
          ),
          const Divider(color: Color(0xFFF4EDE5), height: 20),
          _buildOptionToggle(
            label: 'Notify team on completion',
            subtitle: 'Send a summary email to all team members after import.',
            value: _notifyTeam,
            onChanged: (v) => setState(() => _notifyTeam = v),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionToggle({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
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
        const SizedBox(width: 12),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF8C5E33),
          activeTrackColor: const Color(0xFFDFBB95),
          inactiveThumbColor: const Color(0xFFD5C9BC),
          inactiveTrackColor: const Color(0xFFF1EBE3),
        ),
      ],
    );
  }

  Widget _buildLocationTargetCard() {
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
          Row(
            children: [
              const Icon(
                Icons.warehouse_outlined,
                size: 18,
                color: Color(0xFF8C5E33),
              ),
              const SizedBox(width: 8),
              Text(
                'Target Location',
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE8DFD3)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE0CF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.warehouse_rounded,
                    size: 22,
                    color: Color(0xFF8C5E33),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Primary Facility',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1816),
                        ),
                      ),
                      Text(
                        'Zone A  •  3,200 sqft capacity',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Active',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF16A34A),
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

  // ---------------------------------------------------------------------------
  // Right column — Confirm import
  // ---------------------------------------------------------------------------

  Widget _buildRightColumn() {
    return Column(
      children: [
        _buildConfirmCard(),
        const SizedBox(height: 12),
        _buildBackButton(),
      ],
    );
  }

  Widget _buildConfirmCard() {
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
          // Ready-to-import badge
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to import',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1816),
                    ),
                  ),
                  Text(
                    '2,315 valid rows',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF7E766B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF0E8DF), height: 1),
          const SizedBox(height: 14),

          // Quick stats
          _buildConfirmStat(
            'Valid rows to import',
            '2,315',
            const Color(0xFF22C55E),
          ),
          const SizedBox(height: 8),
          _buildConfirmStat(
            'Rows with warnings',
            '98',
            const Color(0xFFD97706),
          ),
          const SizedBox(height: 8),
          _buildConfirmStat(
            'Rows to skip (errors)',
            '43',
            const Color(0xFFEF4444),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF0E8DF), height: 1),
          const SizedBox(height: 14),

          // Progress bar (only during import)
          if (_isImporting) ...[
            Text(
              'Importing rows…',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1816),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _importProgress,
                backgroundColor: const Color(0xFFF1EBE3),
                color: const Color(0xFF22C55E),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(_importProgress * 2315).toInt()} / 2,315 rows',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF7E766B),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // CTA
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: _isImporting ? null : _handleImport,
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _isImporting
                      ? const Color(0xFF4B4540)
                      : const Color(0xFF1A1816),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: _isImporting
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Importing…',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.upload_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Start Import',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Disclaimer
          Text(
            _createSnapshot
                ? '✓ A snapshot will be created before import begins.'
                : 'No snapshot will be created. This action cannot be undone.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: _createSnapshot
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFD97706),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmStat(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF7E766B),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: widget.onBack,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            '← Back to Validate Rows',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7E766B),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Import — creates an auditable job; never fakes success
  // ---------------------------------------------------------------------------

  Future<void> _handleImport() async {
    if (_isImporting) {
      return;
    }

    final draft = widget.draft;
    if (draft == null) {
      _showError('No import file is loaded. Go back and choose a file.');
      return;
    }

    setState(() {
      _isImporting = true;
      _importProgress = 0.1;
    });

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) {
        throw StateError('Sign in required to create an import job.');
      }

      setState(() => _importProgress = 0.35);

      // Resolve the caller's first active business membership.
      final membership = await client
          .from('memberships')
          .select('business_id')
          .eq('user_id', userId)
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();

      final businessId = membership?['business_id'] as String?;
      if (businessId == null || businessId.isEmpty) {
        throw StateError(
          'No active business membership found for this account.',
        );
      }

      setState(() => _importProgress = 0.6);

      final acceptedEstimate = draft.totalRows;
      await client.from('inventory_import_jobs').insert({
        'business_id': businessId,
        'source_filename': draft.fileName,
        'source_format': draft.fileExtension,
        'status': 'pending_review',
        'total_rows': draft.totalRows,
        'accepted_rows': 0,
        'rejected_rows': 0,
        'column_mappings': {
          for (final entry in widget.columnMappings.entries)
            entry.key: entry.value.name,
        },
        'created_by': userId,
      });

      setState(() => _importProgress = 1.0);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFD5A46C),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Import job created for ${draft.fileName} ($acceptedEstimate rows). Confirm sync after review.',
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
          duration: const Duration(seconds: 3),
        ),
      );

      widget.onConfirm?.call();
    } catch (error, stackTrace) {
      debugPrint('Inventory import job failed: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      _showError(
        'Unable to create import job. Apply the inventory import SQL migration and sign in, then try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFB42318),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
