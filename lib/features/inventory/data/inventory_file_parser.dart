import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';

import '../domain/models/inventory_import_draft.dart';

class InventoryFileParseException implements Exception {
  InventoryFileParseException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Parses CSV / XLSX inventory uploads into an [InventoryImportDraft].
///
/// Never invents SKUs, prices, or quantities. Empty cells stay empty.
class InventoryFileParser {
  const InventoryFileParser();

  static const int maxFileBytes = 25 * 1024 * 1024;
  static const int maxPreviewRows = 5000;

  InventoryImportDraft parse({
    required String fileName,
    required Uint8List bytes,
  }) {
    if (bytes.isEmpty) {
      throw InventoryFileParseException('The selected file is empty.');
    }
    if (bytes.length > maxFileBytes) {
      throw InventoryFileParseException('File exceeds the 25 MB limit.');
    }

    final lower = fileName.toLowerCase();
    if (lower.endsWith('.csv')) {
      return _parseCsv(fileName: fileName, bytes: bytes);
    }
    if (lower.endsWith('.xlsx')) {
      return _parseXlsx(fileName: fileName, bytes: bytes);
    }
    throw InventoryFileParseException(
      'Unsupported file type. Choose a .csv or .xlsx file.',
    );
  }

  InventoryImportDraft _parseCsv({
    required String fileName,
    required Uint8List bytes,
  }) {
    final content = utf8.decode(bytes, allowMalformed: true);
    final lines = const LineSplitter()
        .convert(content)
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) {
      throw InventoryFileParseException('CSV has no readable rows.');
    }

    final headers = _splitCsvLine(lines.first);
    if (headers.every((h) => h.trim().isEmpty)) {
      throw InventoryFileParseException('CSV header row is empty.');
    }

    final rows = <List<String>>[];
    for (var i = 1; i < lines.length && rows.length < maxPreviewRows; i++) {
      final cells = _splitCsvLine(lines[i]);
      rows.add(_padRow(cells, headers.length));
    }

    return InventoryImportDraft(
      fileName: fileName,
      fileExtension: 'csv',
      headers: headers.map((h) => h.trim()).toList(),
      rows: rows,
      pickedAt: DateTime.now(),
      fileSizeBytes: bytes.length,
    );
  }

  InventoryImportDraft _parseXlsx({
    required String fileName,
    required Uint8List bytes,
  }) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      throw InventoryFileParseException('Excel workbook has no sheets.');
    }

    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];
    if (sheet == null || sheet.maxRows < 1) {
      throw InventoryFileParseException('Excel sheet is empty.');
    }

    final rawRows = sheet.rows;
    if (rawRows.isEmpty) {
      throw InventoryFileParseException('Excel sheet has no rows.');
    }

    final headerCells = rawRows.first;
    final headers = headerCells
        .map((cell) => (cell?.value?.toString() ?? '').trim())
        .toList();
    while (headers.isNotEmpty && headers.last.isEmpty) {
      headers.removeLast();
    }
    if (headers.isEmpty || headers.every((h) => h.isEmpty)) {
      throw InventoryFileParseException('Excel header row is empty.');
    }

    final rows = <List<String>>[];
    for (var i = 1; i < rawRows.length && rows.length < maxPreviewRows; i++) {
      final cells = rawRows[i]
          .map((cell) => (cell?.value?.toString() ?? '').trim())
          .toList();
      if (cells.every((c) => c.isEmpty)) {
        continue;
      }
      rows.add(_padRow(cells, headers.length));
    }

    return InventoryImportDraft(
      fileName: fileName,
      fileExtension: 'xlsx',
      headers: headers,
      rows: rows,
      pickedAt: DateTime.now(),
      fileSizeBytes: bytes.length,
    );
  }

  List<String> _padRow(List<String> cells, int width) {
    if (cells.length == width) {
      return cells;
    }
    if (cells.length > width) {
      return cells.sublist(0, width);
    }
    return [...cells, ...List.filled(width - cells.length, '')];
  }

  /// Minimal CSV splitter supporting quoted fields.
  List<String> _splitCsvLine(String line) {
    final result = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }
      if (char == ',' && !inQuotes) {
        result.add(buffer.toString());
        buffer.clear();
        continue;
      }
      buffer.write(char);
    }
    result.add(buffer.toString());
    return result;
  }
}
