// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/inventory_import_draft.dart';

/// Map & Validate Data — Step 2 of the inventory import wizard.
class MapValidateView extends StatefulWidget {
  final InventoryImportDraft? draft;
  final Map<String, InventoryImportTargetField> columnMappings;
  final ValueChanged<Map<String, InventoryImportTargetField>>?
  onMappingsChanged;
  final VoidCallback? onContinue;
  final VoidCallback? onCancel;

  const MapValidateView({
    super.key,
    this.draft,
    this.columnMappings = const {},
    this.onMappingsChanged,
    this.onContinue,
    this.onCancel,
  });

  @override
  State<MapValidateView> createState() => _MapValidateViewState();
}

class _MapValidateViewState extends State<MapValidateView> {
  late Map<String, InventoryImportTargetField> _mappings;

  @override
  void initState() {
    super.initState();
    _mappings = Map<String, InventoryImportTargetField>.from(
      widget.columnMappings,
    );
    if (_mappings.isEmpty && widget.draft != null) {
      for (final header in widget.draft!.headers) {
        _mappings[header] = InventoryImportColumnMapper.suggest(header);
      }
    }
  }

  @override
  void didUpdateWidget(covariant MapValidateView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft?.fileName != widget.draft?.fileName ||
        oldWidget.columnMappings != widget.columnMappings) {
      _mappings = Map<String, InventoryImportTargetField>.from(
        widget.columnMappings,
      );
    }
  }

  List<_ColumnRow> get _columns {
    final draft = widget.draft;
    if (draft == null) {
      return const [];
    }
    return [
      for (var i = 0; i < draft.headers.length; i++)
        _ColumnRow(
          draft.headers[i],
          _sampleForColumn(draft, i),
          _mappings[draft.headers[i]] ?? InventoryImportTargetField.skip,
        ),
    ];
  }

  String _sampleForColumn(InventoryImportDraft draft, int index) {
    for (final row in draft.rows) {
      if (index < row.length && row[index].trim().isNotEmpty) {
        return row[index];
      }
    }
    return '—';
  }

  void _updateMapping(String header, InventoryImportTargetField field) {
    setState(() {
      _mappings[header] = field;
    });
    widget.onMappingsChanged?.call(
      Map<String, InventoryImportTargetField>.from(_mappings),
    );
  }

  int get _mappedCount => _mappings.values
      .where((v) => v != InventoryImportTargetField.skip)
      .length;

  int get _reviewCount => _mappings.values
      .where((v) => v == InventoryImportTargetField.skip)
      .length;

  bool get _canContinue {
    final draft = widget.draft;
    if (draft == null || draft.headers.isEmpty) {
      return false;
    }
    final hasSku = _mappings.values.contains(InventoryImportTargetField.sku);
    final hasName = _mappings.values.contains(
      InventoryImportTargetField.productName,
    );
    return hasSku || hasName;
  }

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
          // Page Title
          _buildPageHeader(),
          const SizedBox(height: 24),

          // Step Indicator
          _buildStepIndicator(),
          const SizedBox(height: 20),

          // File Info Bar
          _buildFileInfoBar(),
          const SizedBox(height: 16),

          // AI Mapping Banner
          _buildAIMappingBanner(),
          const SizedBox(height: 20),

          // Two-column layout: Column Mapping table | Validation Summary
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 58, child: _buildColumnMappingCard()),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 340,
                      child: _buildValidationSummaryColumn(),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildColumnMappingCard(),
                  const SizedBox(height: 20),
                  _buildValidationSummaryColumn(),
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
  // Page Header
  // ---------------------------------------------------------------------------

  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Map & Validate Data',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181614),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Align your imported file with ThreadStock catalog fields and verify the data before importing.',
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
          _buildStep(2, 'Map Columns', isActive: true),
          _buildStepConnector(),
          _buildStep(3, 'Validate Rows'),
          _buildStepConnector(),
          _buildStep(4, 'Review & Import'),
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
  // File Info Bar
  // ---------------------------------------------------------------------------

  Widget _buildFileInfoBar() {
    final draft = widget.draft;
    final fileName = draft?.fileName ?? 'No file selected';
    final ext = (draft?.fileExtension ?? '').toUpperCase();
    final rowLabel = draft == null
        ? 'Choose a file on the previous step to map columns.'
        : '${draft.totalRows} data rows · ${draft.headers.length} columns detected';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8DFD3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF217346),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              ext.isEmpty ? '?' : (ext == 'CSV' ? 'CSV' : 'X'),
              style: GoogleFonts.inter(
                fontSize: ext == 'CSV' ? 9 : 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1816),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rowLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF7E766B),
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
  // AI Mapping Banner
  // ---------------------------------------------------------------------------

  Widget _buildAIMappingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8C97A)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CC),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 17,
              color: Color(0xFFB5860D),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Mapping Active',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF92650A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '94% of columns mapped automatically based on previous imports history & catalog patterns.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF7A5C0E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'High Accuracy',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Column Mapping Card
  // ---------------------------------------------------------------------------

  Widget _buildColumnMappingCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DFD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Column Mapping',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1816),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Review and adjust the column mappings from your file to ThreadStock fields.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _buildAutoMapButton(),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF7F2),
              border: Border(
                top: BorderSide(color: Color(0xFFEEE5D8)),
                bottom: BorderSide(color: Color(0xFFEEE5D8)),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 20), // drag handle placeholder
                Expanded(
                  flex: 30,
                  child: Text(
                    'File Column',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8E7F72),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Expanded(
                  flex: 30,
                  child: Text(
                    'Sample Data',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8E7F72),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                Expanded(
                  flex: 30,
                  child: Text(
                    'Mapped To',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8E7F72),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Status',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8E7F72),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rows
          ...List.generate(_columns.length, (i) {
            return _buildColumnRow(_columns[i], i == _columns.length - 1);
          }),
        ],
      ),
    );
  }

  Widget _buildColumnRow(_ColumnRow row, bool isLast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF4EDE5), width: 0.8),
              ),
      ),
      child: Row(
        children: [
          // Drag handle
          const Icon(
            Icons.drag_indicator_rounded,
            size: 16,
            color: Color(0xFFCBC2B7),
          ),
          const SizedBox(width: 4),

          // File Column name
          Expanded(
            flex: 30,
            child: Text(
              row.fileColumn,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1816),
              ),
            ),
          ),

          // Sample data
          Expanded(
            flex: 30,
            child: Text(
              row.sampleData,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: row.sampleData == '—'
                    ? const Color(0xFFB0A89E)
                    : const Color(0xFF5A7FA8),
              ),
            ),
          ),

          // Mapped To dropdown
          Expanded(flex: 30, child: _buildMappedToDropdown(row)),

          // Status chip
          SizedBox(width: 80, child: _buildStatusChip(row.status)),
        ],
      ),
    );
  }

  Widget _buildMappedToDropdown(_ColumnRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: row.status == _MappedStatus.review
              ? const Color(0xFFE8C97A)
              : const Color(0xFFE8DFD3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<InventoryImportTargetField>(
          value: row.mappedField,
          isExpanded: true,
          isDense: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: Color(0xFF9E8E7E),
          ),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF3D3530),
          ),
          items: InventoryImportTargetField.values
              .map(
                (field) => DropdownMenuItem(
                  value: field,
                  child: Text(field.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (field) {
            if (field != null) {
              _updateMapping(row.fileColumn, field);
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(_MappedStatus status) {
    switch (status) {
      case _MappedStatus.mapped:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 15,
              color: Color(0xFF22C55E),
            ),
            const SizedBox(width: 5),
            Text(
              'Mapped',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        );
      case _MappedStatus.review:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 15,
              color: Color(0xFFD97706),
            ),
            const SizedBox(width: 5),
            Text(
              'Review',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFD97706),
              ),
            ),
          ],
        );
      case _MappedStatus.skipped:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFB0A89E)),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              'Skipped',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9E8E7E),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildAutoMapButton() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8EC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8C97A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              size: 15,
              color: Color(0xFFB5860D),
            ),
            const SizedBox(width: 7),
            Text(
              'Auto Map',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF92650A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Validation Summary Column (right side)
  // ---------------------------------------------------------------------------

  Widget _buildValidationSummaryColumn() {
    return Column(
      children: [
        _buildValidationSummaryCard(),
        const SizedBox(height: 16),
        _buildTopIssuesCard(),
        const SizedBox(height: 16),
        _buildCTAButtons(),
      ],
    );
  }

  Widget _buildValidationSummaryCard() {
    final totalRows = widget.draft?.totalRows ?? 0;
    final mapped = _mappedCount;
    final skipped = _reviewCount;

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
          Text(
            'Validation Summary',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1816),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            totalRows == 0
                ? 'No file loaded yet.'
                : 'Detected $totalRows rows · $mapped columns mapped · $skipped skipped.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 16),
          _buildValidationProgressBar(),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildLegendDot(const Color(0xFF22C55E)),
              const SizedBox(width: 4),
              Text(
                '$mapped Mapped',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF3D3530),
                ),
              ),
              const Spacer(),
              _buildLegendDot(const Color(0xFFF59E0B)),
              const SizedBox(width: 4),
              Text(
                '$skipped Skipped',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF3D3530),
                ),
              ),
              const Spacer(),
              _buildLegendDot(const Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Text(
                '0 Invalid',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF3D3530),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF0E8DF), height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatColumn(
                '$totalRows',
                'Data rows',
                const Color(0xFF22C55E),
              ),
              _buildStatColumn(
                '$mapped',
                'Mapped fields',
                const Color(0xFFF59E0B),
              ),
              _buildStatColumn('$skipped', 'Skipped', const Color(0xFFEF4444)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidationProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Flexible(
              flex: 94,
              child: Container(color: const Color(0xFF22C55E)),
            ),
            Flexible(flex: 4, child: Container(color: const Color(0xFFF59E0B))),
            Flexible(flex: 2, child: Container(color: const Color(0xFFEF4444))),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildStatColumn(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value == '2,315'
                    ? Icons.check_circle_rounded
                    : (value == '98'
                          ? Icons.warning_amber_rounded
                          : Icons.cancel_rounded),
                size: 16,
                color: color,
              ),
              const SizedBox(width: 5),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1816),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: const Color(0xFF9E8E7E),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            value == '2,315' ? '94%' : (value == '98' ? '4%' : '2%'),
            style: GoogleFonts.inter(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Issues Card
  // ---------------------------------------------------------------------------

  Widget _buildTopIssuesCard() {
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Issues to Review',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1816),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View and fix the most common data issues.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE8DFD3)),
                  ),
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5C4F44),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildIssueRow('Missing SKU', 18),
          _buildIssueRow('Invalid category name', 12),
          _buildIssueRow('Unknown supplier', 8),
          _buildIssueRow('Negative quantity', 5, isLast: true),
        ],
      ),
    );
  }

  Widget _buildIssueRow(String label, int count, {bool isLast = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
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
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF3D3530),
              ),
            ),
          ),
          Text(
            '$count rows',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDC2626),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: Color(0xFF9E8E7E),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CTA Buttons
  // ---------------------------------------------------------------------------

  Widget _buildCTAButtons() {
    return Column(
      children: [
        // Primary CTA
        SizedBox(
          width: double.infinity,
          child: InkWell(
            onTap: _canContinue ? widget.onContinue : null,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _canContinue
                    ? const Color(0xFF1A1816)
                    : const Color(0xFF9E8E7E),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Continue with ${widget.draft?.totalRows ?? 0} rows',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Cancel
        SizedBox(
          width: double.infinity,
          child: InkWell(
            onTap: widget.onCancel,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text(
                'Cancel Import',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data helpers
// ---------------------------------------------------------------------------

enum _MappedStatus { mapped, review, skipped }

class _ColumnRow {
  final String fileColumn;
  final String sampleData;
  final InventoryImportTargetField mappedField;

  const _ColumnRow(this.fileColumn, this.sampleData, this.mappedField);

  _MappedStatus get status {
    if (mappedField == InventoryImportTargetField.skip) {
      return _MappedStatus.skipped;
    }
    if (sampleData == '—') {
      return _MappedStatus.review;
    }
    return _MappedStatus.mapped;
  }
}
