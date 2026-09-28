// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/invoice_data.dart';

class InvoicePdfService {
  InvoicePdfService._();
  static final InvoicePdfService instance = InvoicePdfService._();

  /// Generates standard PDF document bytes for the authoritative invoice.
  Future<Uint8List> generateInvoicePdf(
    InvoiceData invoice, {
    InvoiceFormat format = InvoiceFormat.a4,
  }) async {
    final pdf = pw.Document(
      title: 'Invoice_${invoice.saleNumber}',
      author: invoice.business.effectiveName,
    );

    if (format == InvoiceFormat.thermal80mm) {
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(
            72 * PdfPageFormat.mm,
            double.infinity,
            marginAll: 4 * PdfPageFormat.mm,
          ),
          build: (context) => _buildThermalReceipt(context, invoice),
        ),
      );
    } else {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => _buildA4Invoice(context, invoice),
        ),
      );
    }

    return await pdf.save();
  }

  pw.Widget _buildA4Invoice(pw.Context context, InvoiceData invoice) {
    const primaryColor = PdfColor.fromInt(0xFF1E1C1A);
    const secondaryColor = PdfColor.fromInt(0xFF5E574E);
    const borderColor = PdfColor.fromInt(0xFFE5DDD0);
    const headerBgColor = PdfColor.fromInt(0xFFFAF7F2);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // 1. Header (Logo / Business Info & Invoice Badge)
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    invoice.business.effectiveName,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  if (invoice.business.legalName.isNotEmpty &&
                      invoice.business.legalName != invoice.business.effectiveName) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      invoice.business.legalName,
                      style: const pw.TextStyle(fontSize: 10, color: secondaryColor),
                    ),
                  ],
                  if (invoice.business.addressLine.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      invoice.business.addressLine,
                      style: const pw.TextStyle(fontSize: 9, color: secondaryColor),
                    ),
                  ],
                  if (invoice.business.phone != null && invoice.business.phone!.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Tel: ${invoice.business.phone}',
                      style: const pw.TextStyle(fontSize: 9, color: secondaryColor),
                    ),
                  ],
                  if (invoice.business.email != null && invoice.business.email!.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Email: ${invoice.business.email}',
                      style: const pw.TextStyle(fontSize: 9, color: secondaryColor),
                    ),
                  ],
                  if (invoice.business.website != null && invoice.business.website!.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Web: ${invoice.business.website}',
                      style: const pw.TextStyle(fontSize: 9, color: secondaryColor),
                    ),
                  ],
                  if (invoice.business.isGstRegistered &&
                      invoice.business.gstin != null &&
                      invoice.business.gstin!.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'GSTIN: ${invoice.business.gstin}',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: headerBgColor,
                border: pw.Border.all(color: borderColor),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'INVOICE / RECEIPT',
                    style: pw.TextStyle(
                      fontSize: 13,
                      fontWeight: pw.FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    invoice.saleNumber,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFFBA8A55),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Date: ${invoice.formattedShortDate}',
                    style: const pw.TextStyle(fontSize: 9, color: secondaryColor),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Location: ${invoice.location.name}',
                    style: const pw.TextStyle(fontSize: 9, color: secondaryColor),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Cashier: ${invoice.cashierName}',
                    style: const pw.TextStyle(fontSize: 9, color: secondaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 18),
        pw.Divider(color: borderColor, thickness: 0.8),
        pw.SizedBox(height: 10),

        // 2. Customer Section
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const pw.BoxDecoration(
            color: headerBgColor,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            children: [
              pw.Text(
                'Customer: ',
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: secondaryColor),
              ),
              pw.Text(
                invoice.customer.name,
                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: primaryColor),
              ),
              if (invoice.customer.phone != null && invoice.customer.phone!.isNotEmpty) ...[
                pw.SizedBox(width: 16),
                pw.Text(
                  'Phone: ${invoice.customer.phone}',
                  style: const pw.TextStyle(fontSize: 9, color: secondaryColor),
                ),
              ],
              if (invoice.customer.email != null && invoice.customer.email!.isNotEmpty) ...[
                pw.SizedBox(width: 16),
                pw.Text(
                  'Email: ${invoice.customer.email}',
                  style: const pw.TextStyle(fontSize: 9, color: secondaryColor),
                ),
              ],
            ],
          ),
        ),

        pw.SizedBox(height: 14),

        // 3. Items Table
        pw.Table(
          border: pw.TableBorder.all(color: borderColor, width: 0.5),
          children: [
            // Table Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: headerBgColor),
              children: [
                _buildTableCell('Item', isHeader: true, flex: 3),
                _buildTableCell('Variant', isHeader: true, flex: 2),
                _buildTableCell('SKU', isHeader: true, flex: 2),
                _buildTableCell('Qty', isHeader: true, align: pw.TextAlign.center),
                _buildTableCell('Unit Price', isHeader: true, align: pw.TextAlign.right),
                _buildTableCell('Discount', isHeader: true, align: pw.TextAlign.right),
                _buildTableCell('Tax', isHeader: true, align: pw.TextAlign.right),
                _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
              ],
            ),
            // Item rows
            for (final item in invoice.items)
              pw.TableRow(
                children: [
                  _buildTableCell(item.productNameSnapshot, flex: 3),
                  _buildTableCell(item.variantTitleSnapshot ?? '-', flex: 2),
                  _buildTableCell(item.skuSnapshot.isNotEmpty ? item.skuSnapshot : '-', flex: 2),
                  _buildTableCell(item.quantity.toString(), align: pw.TextAlign.center),
                  _buildTableCell(invoice.formatCurrencyMinor(item.unitPriceMinor), align: pw.TextAlign.right),
                  _buildTableCell(
                    item.discountMinor > 0 ? invoice.formatCurrencyMinor(item.discountMinor) : '-',
                    align: pw.TextAlign.right,
                  ),
                  _buildTableCell(invoice.formatCurrencyMinor(item.taxMinor), align: pw.TextAlign.right),
                  _buildTableCell(
                    invoice.formatCurrencyMinor(item.lineTotalMinor),
                    isBold: true,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
          ],
        ),

        pw.SizedBox(height: 16),

        // 4. Totals and Payments section
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Left: Payment Breakdown
            pw.Expanded(
              flex: 5,
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: borderColor),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Payment Details',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    if (invoice.payments.isEmpty)
                      _buildPaymentLine('Paid', invoice.formatCurrencyMinor(invoice.totalMinor))
                    else
                      for (final p in invoice.payments)
                        _buildPaymentLine(
                          _formatPaymentMethod(p.paymentMethod),
                          invoice.formatCurrencyMinor(p.amountMinor),
                        ),
                    pw.Divider(color: borderColor, thickness: 0.5),
                    _buildPaymentLine(
                      'Total Paid',
                      invoice.formatCurrencyMinor(invoice.totalPaidMinor),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 24),
            // Right: Financial Totals
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                children: [
                  _buildSummaryLine('Subtotal', invoice.formatCurrencyMinor(invoice.subtotalMinor)),
                  if (invoice.hasDiscount) ...[
                    pw.SizedBox(height: 4),
                    _buildSummaryLine(
                      'Discount',
                      '-${invoice.formatCurrencyMinor(invoice.discountMinor)}',
                      color: const PdfColor.fromInt(0xFF1E7E34),
                    ),
                  ],
                  pw.SizedBox(height: 4),
                  _buildSummaryLine('Tax', invoice.formatCurrencyMinor(invoice.taxMinor)),
                  pw.SizedBox(height: 6),
                  pw.Divider(color: primaryColor, thickness: 1),
                  pw.SizedBox(height: 4),
                  _buildSummaryLine(
                    'Total',
                    invoice.formatCurrencyMinor(invoice.totalMinor),
                    isBold: true,
                    fontSize: 13,
                  ),
                ],
              ),
            ),
          ],
        ),

        if (invoice.sale.note != null && invoice.sale.note!.trim().isNotEmpty) ...[
          pw.SizedBox(height: 14),
          pw.Text(
            'Note: ${invoice.sale.note!.trim()}',
            style: const pw.TextStyle(fontSize: 9, color: secondaryColor),
          ),
        ],

        pw.Spacer(),

        // 5. Footer
        pw.Divider(color: borderColor, thickness: 0.8),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text(
            'Thank you for shopping with ${invoice.business.effectiveName}.',
            style: const pw.TextStyle(
              fontSize: 10,
              color: secondaryColor,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildThermalReceipt(pw.Context context, InvoiceData invoice) {
    const primaryColor = PdfColor.fromInt(0xFF000000);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          invoice.business.effectiveName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primaryColor),
        ),
        if (invoice.business.addressLine.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            invoice.business.addressLine,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 7.5),
          ),
        ],
        if (invoice.business.phone != null && invoice.business.phone!.isNotEmpty) ...[
          pw.SizedBox(height: 1),
          pw.Text('Tel: ${invoice.business.phone}', style: const pw.TextStyle(fontSize: 7.5)),
        ],
        if (invoice.business.isGstRegistered &&
            invoice.business.gstin != null &&
            invoice.business.gstin!.isNotEmpty) ...[
          pw.SizedBox(height: 2),
          pw.Text('GSTIN: ${invoice.business.gstin}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ],
        pw.SizedBox(height: 4),
        pw.Divider(thickness: 0.5),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Receipt: ${invoice.saleNumber}', style: const pw.TextStyle(fontSize: 7.5)),
            pw.Text(invoice.formattedShortDate, style: const pw.TextStyle(fontSize: 7.5)),
          ],
        ),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Loc: ${invoice.location.name}', style: const pw.TextStyle(fontSize: 7.5)),
            pw.Text('Cust: ${invoice.customer.name}', style: const pw.TextStyle(fontSize: 7.5)),
          ],
        ),
        pw.Divider(thickness: 0.5),
        for (final item in invoice.items) ...[
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  '${item.productNameSnapshot} x${item.quantity}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.Text(
                invoice.formatCurrencyMinor(item.lineTotalMinor),
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ),
          if (item.variantTitleSnapshot != null && item.variantTitleSnapshot!.isNotEmpty)
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                '  (${item.variantTitleSnapshot})',
                style: const pw.TextStyle(fontSize: 7),
              ),
            ),
        ],
        pw.Divider(thickness: 0.5),
        _buildThermalLine('Subtotal', invoice.formatCurrencyMinor(invoice.subtotalMinor)),
        if (invoice.hasDiscount)
          _buildThermalLine('Discount', '-${invoice.formatCurrencyMinor(invoice.discountMinor)}'),
        _buildThermalLine('Tax', invoice.formatCurrencyMinor(invoice.taxMinor)),
        pw.Divider(thickness: 0.8),
        _buildThermalLine('Total', invoice.formatCurrencyMinor(invoice.totalMinor), isBold: true, fontSize: 10),
        pw.SizedBox(height: 4),
        for (final p in invoice.payments)
          _buildThermalLine(
            _formatPaymentMethod(p.paymentMethod),
            invoice.formatCurrencyMinor(p.amountMinor),
          ),
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 4),
        pw.Text(
          'Thank you for shopping with ${invoice.business.effectiveName}.',
          textAlign: pw.TextAlign.center,
          style: const pw.TextStyle(fontSize: 8),
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
    int flex = 1,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight: (isHeader || isBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildSummaryLine(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 9.5,
    PdfColor? color,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPaymentLine(String method, String amount, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          method,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          amount,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildThermalLine(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 8,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'upi':
        return 'UPI';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return method.toUpperCase();
    }
  }

  /// Opens the native platform print dialog.
  Future<bool> printInvoice(
    InvoiceData invoice, {
    InvoiceFormat format = InvoiceFormat.a4,
  }) async {
    try {
      final pdfBytes = await generateInvoicePdf(invoice, format: format);
      return await Printing.layoutPdf(
        onLayout: (PdfPageFormat pageFormat) async => pdfBytes,
        name: invoice.suggestedPdfFileName,
      );
    } catch (e) {
      debugPrint('[InvoicePdfService] Print error: $e');
      return false;
    }
  }

  /// Saves / downloads the PDF to local storage.
  Future<String?> downloadPdf(
    InvoiceData invoice, {
    InvoiceFormat format = InvoiceFormat.a4,
  }) async {
    try {
      final pdfBytes = await generateInvoicePdf(invoice, format: format);
      final filename = invoice.suggestedPdfFileName;

      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Invoice PDF',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (outputPath != null && outputPath.isNotEmpty) {
          final file = File(outputPath);
          await file.writeAsBytes(pdfBytes);
          return outputPath;
        }
      }

      // Mobile / Web fallback
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);
      return filename;
    } catch (e) {
      debugPrint('[InvoicePdfService] Download PDF error: $e');
      return null;
    }
  }

  /// Triggers native platform share for the PDF.
  Future<bool> shareInvoice(
    InvoiceData invoice, {
    InvoiceFormat format = InvoiceFormat.a4,
  }) async {
    try {
      final pdfBytes = await generateInvoicePdf(invoice, format: format);
      final filename = invoice.suggestedPdfFileName;

      // Use SharePlus XFile
      final xFile = XFile.fromData(
        pdfBytes,
        name: filename,
        mimeType: 'application/pdf',
      );
      final result = await Share.shareXFiles(
        [xFile],
        text: invoice.generateWhatsAppMessage(),
        subject: 'Invoice #${invoice.saleNumber}',
      );
      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('[InvoicePdfService] Share error: $e');
      // Fallback to Printing.sharePdf
      try {
        final pdfBytes = await generateInvoicePdf(invoice, format: format);
        return await Printing.sharePdf(
          bytes: pdfBytes,
          filename: invoice.suggestedPdfFileName,
        );
      } catch (_) {
        return false;
      }
    }
  }

  /// Launches WhatsApp with the invoice summary and targeted phone number.
  Future<bool> openWhatsApp({
    required InvoiceData invoice,
    required String targetPhone,
  }) async {
    try {
      final clean = InvoiceData.normalizePhone(targetPhone);
      final msg = invoice.generateWhatsAppMessage();
      final uri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(msg)}');
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[InvoicePdfService] WhatsApp error: $e');
      return false;
    }
  }
}
