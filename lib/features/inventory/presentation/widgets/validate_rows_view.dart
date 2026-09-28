// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/inventory_import_draft.dart';

/// Validate Rows — Step 3 of the inventory import wizard.
class ValidateRowsView extends StatefulWidget {
  final InventoryImportDraft? draft;
  final Map<String, InventoryImportTargetField> columnMappings;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  const ValidateRowsView({
    super.key,
    this.draft,
    this.columnMappings = const {},
    this.onContinue,
    this.onBack,
  });

  @override
  State<ValidateRowsView> createState() => _ValidateRowsViewState();
}

class _ValidateRowsViewState extends State<ValidateRowsView> {
  String _filterTab = 'all'; // 'all' | 'issues' | 'valid'
  int _currentPage = 1;
  final int _rowsPerPage = 10;

  late List<_ImportRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = _buildRowsFromDraft();
  }

  @override
  void didUpdateWidget(covariant ValidateRowsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft?.fileName != widget.draft?.fileName ||
        oldWidget.columnMappings != widget.columnMappings) {
      _rows = _buildRowsFromDraft();
      _currentPage = 1;
    }
  }

  int? _indexFor(InventoryImportTargetField field) {
    final draft = widget.draft;
    if (draft == null) {
      return null;
    }
    for (var i = 0; i < draft.headers.length; i++) {
      if (widget.columnMappings[draft.headers[i]] == field) {
        return i;
      }
    }
    return null;
  }

  String _cell(List<String> row, InventoryImportTargetField field) {
    final index = _indexFor(field);
    if (index == null || index >= row.length) {
      return '';
    }
    return row[index].trim();
  }

  List<_ImportRow> _buildRowsFromDraft() {
    final draft = widget.draft;
    if (draft == null) {
      return const [];
    }

    final result = <_ImportRow>[];
    for (var i = 0; i < draft.rows.length; i++) {
      final row = draft.rows[i];
      final sku = _cell(row, InventoryImportTargetField.sku);
      final name = _cell(row, InventoryImportTargetField.productName);
      final qty = _cell(row, InventoryImportTargetField.quantity);
      final cost = _cell(row, InventoryImportTargetField.cost);
      final retail = _cell(row, InventoryImportTargetField.retailPrice);

      String? error;
      var status = _RowStatus.valid;

      if (sku.isEmpty && name.isEmpty) {
        status = _RowStatus.error;
        error = 'Missing product name and SKU';
      } else if (sku.isEmpty) {
        status = _RowStatus.error;
        error = 'Missing SKU';
      } else if (qty.isNotEmpty &&
          int.tryParse(qty.replaceAll(',', '')) == null) {
        status = _RowStatus.error;
        error = 'Invalid quantity';
      } else if (qty.isNotEmpty &&
          (int.tryParse(qty.replaceAll(',', '')) ?? 0) < 0) {
        status = _RowStatus.error;
        error = 'Negative quantity';
      } else if (cost.isNotEmpty &&
          double.tryParse(cost.replaceAll(',', '')) == null) {
        status = _RowStatus.warning;
        error = 'Unrecognized cost format';
      } else if (retail.isNotEmpty &&
          double.tryParse(retail.replaceAll(',', '')) == null) {
        status = _RowStatus.warning;
        error = 'Unrecognized retail price format';
      }

      final color = _cell(row, InventoryImportTargetField.color);
      final size = _cell(row, InventoryImportTargetField.size);
      final variant = _cell(row, InventoryImportTargetField.variant);
      final variantLabel = variant.isNotEmpty
          ? variant
          : [color, size].where((v) => v.isNotEmpty).join(' / ');

      result.add(
        _ImportRow(
          '${i + 1}',
          name,
          sku,
          variantLabel,
          qty,
          cost,
          retail,
          _cell(row, InventoryImportTargetField.category),
          _cell(row, InventoryImportTargetField.barcode),
          _cell(row, InventoryImportTargetField.location),
          _cell(row, InventoryImportTargetField.supplier),
          status,
          error: error,
        ),
      );
    }
    return result;
  }

  List<_ImportRow> get _filteredRows {
    if (_filterTab == 'issues')
      return _rows.where((r) => r.status != _RowStatus.valid).toList();
    if (_filterTab == 'valid')
      return _rows.where((r) => r.status == _RowStatus.valid).toList();
    return _rows;
  }

  int get _validCount =>
      _rows.where((r) => r.status == _RowStatus.valid).length;
  int get _errorCount =>
      _rows.where((r) => r.status == _RowStatus.error).length;
  int get _warningCount =>
      _rows.where((r) => r.status == _RowStatus.warning).length;

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
          const SizedBox(height: 20),
          _buildSummaryStrip(),
          const SizedBox(height: 16),
          _buildTableCard(),
          const SizedBox(height: 20),
          _buildFooter(),
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
          'Validate Rows',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181614),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Review each row for data issues before importing. Fix errors inline or skip flagged rows.',
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
          _buildStep(3, 'Validate Rows', isActive: true),
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
  // Summary Strip
  // ---------------------------------------------------------------------------

  Widget _buildSummaryStrip() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            '${_rows.length}',
            'Total Rows',
            const Color(0xFF6B6358),
            Icons.table_rows_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            '$_validCount',
            'Valid',
            const Color(0xFF16A34A),
            Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            '$_warningCount',
            'Warnings',
            const Color(0xFFD97706),
            Icons.warning_amber_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            '$_errorCount',
            'Errors',
            const Color(0xFFDC2626),
            Icons.cancel_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String value,
    String label,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8DFD3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1816),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Table Card
  // ---------------------------------------------------------------------------

  Widget _buildTableCard() {
    final filtered = _filteredRows;
    final totalPages = (filtered.length / _rowsPerPage).ceil().clamp(1, 999);
    final start = (_currentPage - 1) * _rowsPerPage;
    final end = (start + _rowsPerPage).clamp(0, filtered.length);
    final pageRows = filtered.sublist(start, end);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DFD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toolbar
          _buildToolbar(filtered.length),

          // Column headers
          _buildTableHeader(),

          // Rows
          ...pageRows.map((row) => _buildTableRow(row, pageRows.last == row)),

          // Pagination
          _buildPagination(totalPages),
        ],
      ),
    );
  }

  Widget _buildToolbar(int filteredCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
      child: Row(
        children: [
          // Filter tabs
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF4EDE4),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                _buildFilterTab('all', 'All Rows', '${_rows.length}'),
                _buildFilterTab(
                  'issues',
                  'Issues',
                  '${_errorCount + _warningCount}',
                  color: const Color(0xFFDC2626),
                ),
                _buildFilterTab(
                  'valid',
                  'Valid',
                  '$_validCount',
                  color: const Color(0xFF16A34A),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Export button
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD5C9BC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.download_outlined,
                    size: 15,
                    color: Color(0xFF5C4F44),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Export Issues',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5C4F44),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Fix All button
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Auto-fixing all resolvable issues…',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                  ),
                  backgroundColor: const Color(0xFF1E1C1A),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.all(20),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8C97A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.auto_fix_high_rounded,
                    size: 15,
                    color: Color(0xFFB5860D),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Auto-Fix',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF92650A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(
    String id,
    String label,
    String count, {
    Color? color,
  }) {
    final isActive = _filterTab == id;
    return GestureDetector(
      onTap: () => setState(() {
        _filterTab = id;
        _currentPage = 1;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? const Color(0xFF1A1816)
                    : const Color(0xFF7E766B),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isActive
                    ? (color ?? const Color(0xFF6B6358)).withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? (color ?? const Color(0xFF6B6358))
                      : const Color(0xFF9E8E7E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    const headerStyle = TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    );
    return Container(
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
          SizedBox(
            width: 36,
            child: Text(
              '#',
              style: GoogleFonts.inter(
                textStyle: headerStyle,
                color: const Color(0xFF8E7F72),
              ),
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              'Product Name',
              style: GoogleFonts.inter(
                textStyle: headerStyle,
                color: const Color(0xFF8E7F72),
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              'SKU',
              style: GoogleFonts.inter(
                textStyle: headerStyle,
                color: const Color(0xFF8E7F72),
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              'Variant',
              style: GoogleFonts.inter(
                textStyle: headerStyle,
                color: const Color(0xFF8E7F72),
              ),
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              'Qty',
              style: GoogleFonts.inter(
                textStyle: headerStyle,
                color: const Color(0xFF8E7F72),
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              'Category',
              style: GoogleFonts.inter(
                textStyle: headerStyle,
                color: const Color(0xFF8E7F72),
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              'Issue',
              style: GoogleFonts.inter(
                textStyle: headerStyle,
                color: const Color(0xFF8E7F72),
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              'Status',
              style: GoogleFonts.inter(
                textStyle: headerStyle,
                color: const Color(0xFF8E7F72),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(_ImportRow row, bool isLast) {
    final hasIssue = row.status != _RowStatus.valid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(
        color: hasIssue
            ? (row.status == _RowStatus.error
                  ? const Color(0xFFFFF8F7)
                  : const Color(0xFFFFFAEF))
            : Colors.white,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF4EDE5), width: 0.8),
              ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              row.rowNumber,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF9E8E7E),
              ),
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              row.productName,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1816),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 14,
            child: Text(
              row.sku.isEmpty ? '—' : row.sku,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: row.sku.isEmpty
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF5A7FA8),
                fontStyle: row.sku.isEmpty
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              row.variant,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF5C5047),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 8,
            child: Text(
              row.quantity,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: row.quantity.startsWith('-')
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF1A1816),
                fontWeight: row.quantity.startsWith('-')
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              row.category,
              style: GoogleFonts.inter(
                fontSize: 13,
                color:
                    row.status == _RowStatus.warning &&
                        row.error?.contains('category') == true
                    ? const Color(0xFFD97706)
                    : const Color(0xFF5C5047),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 18,
            child: row.error != null
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: row.status == _RowStatus.error
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      row.error!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: row.status == _RowStatus.error
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          SizedBox(width: 70, child: _buildRowStatusBadge(row.status)),
        ],
      ),
    );
  }

  Widget _buildRowStatusBadge(_RowStatus status) {
    switch (status) {
      case _RowStatus.valid:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: Color(0xFF22C55E),
            ),
            const SizedBox(width: 4),
            Text(
              'Valid',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        );
      case _RowStatus.warning:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: Color(0xFFD97706),
            ),
            const SizedBox(width: 4),
            Text(
              'Review',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFD97706),
              ),
            ),
          ],
        );
      case _RowStatus.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cancel_rounded,
              size: 14,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 4),
            Text(
              'Error',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        );
    }
  }

  Widget _buildPagination(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEE5D8))),
      ),
      child: Row(
        children: [
          Text(
            'Showing ${((_currentPage - 1) * _rowsPerPage + 1).clamp(1, _filteredRows.length)}–${(_currentPage * _rowsPerPage).clamp(0, _filteredRows.length)} of ${_filteredRows.length} rows',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF7E766B),
            ),
          ),
          const Spacer(),
          _buildPageButton(
            Icons.chevron_left_rounded,
            enabled: _currentPage > 1,
            onTap: () {
              if (_currentPage > 1) setState(() => _currentPage--);
            },
          ),
          const SizedBox(width: 8),
          ...List.generate(totalPages.clamp(0, 5), (i) {
            final page = i + 1;
            final isActive = page == _currentPage;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => setState(() => _currentPage = page),
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF1A1816)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF1A1816)
                          : const Color(0xFFD5C9BC),
                    ),
                  ),
                  child: Text(
                    '$page',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? Colors.white : const Color(0xFF5C4F44),
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 4),
          _buildPageButton(
            Icons.chevron_right_rounded,
            enabled: _currentPage < totalPages,
            onTap: () {
              if (_currentPage < totalPages) setState(() => _currentPage++);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(
    IconData icon, {
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD5C9BC)),
          color: enabled ? Colors.white : const Color(0xFFF4EDE4),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? const Color(0xFF5C4F44) : const Color(0xFFB0A89E),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Footer / CTA
  // ---------------------------------------------------------------------------

  Widget _buildFooter() {
    return Row(
      children: [
        // Back button
        InkWell(
          onTap: widget.onBack,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD5C9BC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_back_rounded,
                  size: 15,
                  color: Color(0xFF5C4F44),
                ),
                const SizedBox(width: 8),
                Text(
                  'Back to Map Columns',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5C4F44),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Skip errors info
        if (_errorCount > 0) ...[
          Text(
            '$_errorCount error rows will be skipped',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF9E8E7E),
            ),
          ),
          const SizedBox(width: 20),
        ],
        // Continue button
        InkWell(
          onTap: widget.onContinue,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1816),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Continue to Review & Import',
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
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

enum _RowStatus { valid, warning, error }

class _ImportRow {
  final String rowNumber;
  final String productName;
  final String sku;
  final String variant;
  final String quantity;
  final String unitCost;
  final String sellingPrice;
  final String category;
  final String barcode;
  final String location;
  final String supplier;
  final _RowStatus status;
  final String? error;

  const _ImportRow(
    this.rowNumber,
    this.productName,
    this.sku,
    this.variant,
    this.quantity,
    this.unitCost,
    this.sellingPrice,
    this.category,
    this.barcode,
    this.location,
    this.supplier,
    this.status, {
    this.error,
  });
}
