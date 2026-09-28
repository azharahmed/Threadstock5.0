import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/models/invoice_data.dart';
import '../../domain/services/invoice_pdf_service.dart';

class SaleCompleteModal extends StatefulWidget {
  const SaleCompleteModal({
    super.key,
    required this.invoice,
    required this.onStartNewSale,
  });

  final InvoiceData invoice;
  final VoidCallback onStartNewSale;

  static Future<void> show({
    required BuildContext context,
    required InvoiceData invoice,
    required VoidCallback onStartNewSale,
    bool barrierDismissible = true,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => SaleCompleteModal(
        invoice: invoice,
        onStartNewSale: onStartNewSale,
      ),
    );
  }

  @override
  State<SaleCompleteModal> createState() => _SaleCompleteModalState();
}

class _SaleCompleteModalState extends State<SaleCompleteModal> {
  bool _isActionInProgress = false;
  String? _actionErrorMessage;

  InvoiceData get inv => widget.invoice;

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
              color: isError ? const Color(0xFFD32F2F) : const Color(0xFFBA8A55),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  Future<void> _handlePrint({InvoiceFormat format = InvoiceFormat.a4}) async {
    setState(() {
      _isActionInProgress = true;
      _actionErrorMessage = null;
    });
    try {
      final success = await InvoicePdfService.instance.printInvoice(inv, format: format);
      if (!success) {
        // Platform print canceled or failed
        debugPrint('[SaleCompleteModal] Print dialog closed or returned false');
      }
    } catch (e) {
      setState(() {
        _actionErrorMessage = 'Sale completed. Receipt could not be printed. Try again.';
      });
      _showFeedback('Sale completed. Receipt could not be printed. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleDownloadPdf({InvoiceFormat format = InvoiceFormat.a4}) async {
    setState(() {
      _isActionInProgress = true;
      _actionErrorMessage = null;
    });
    try {
      final savedPath = await InvoicePdfService.instance.downloadPdf(inv, format: format);
      if (savedPath != null && savedPath.isNotEmpty) {
        _showFeedback('PDF saved: $savedPath');
      }
    } catch (e) {
      setState(() {
        _actionErrorMessage = 'Sale completed. PDF could not be saved. Try again.';
      });
      _showFeedback('Sale completed. PDF could not be saved. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleShare({InvoiceFormat format = InvoiceFormat.a4}) async {
    setState(() {
      _isActionInProgress = true;
      _actionErrorMessage = null;
    });
    try {
      await InvoicePdfService.instance.shareInvoice(inv, format: format);
    } catch (e) {
      setState(() {
        _actionErrorMessage = 'Sale completed. Receipt could not be shared. Try again.';
      });
      _showFeedback('Sale completed. Receipt could not be shared. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _handleWhatsApp() async {
    final customerPhone = inv.customer.phone?.trim();
    if (customerPhone != null && customerPhone.isNotEmpty) {
      await _sendWhatsAppTo(customerPhone);
    } else {
      // Prompt user for phone number
      _promptWhatsAppPhone();
    }
  }

  Future<void> _sendWhatsAppTo(String phone) async {
    setState(() {
      _isActionInProgress = true;
      _actionErrorMessage = null;
    });
    try {
      final launched = await InvoicePdfService.instance.openWhatsApp(
        invoice: inv,
        targetPhone: phone,
      );
      if (!launched) {
        setState(() {
          _actionErrorMessage = 'Sale completed. WhatsApp could not be opened. Try again.';
        });
        _showFeedback('Sale completed. WhatsApp could not be opened. Try again.', isError: true);
      }
    } catch (e) {
      setState(() {
        _actionErrorMessage = 'Sale completed. Receipt could not be shared. Try again.';
      });
      _showFeedback('Sale completed. Receipt could not be shared. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  void _promptWhatsAppPhone() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFDFD4C5)),
        ),
        title: Text(
          'Send via WhatsApp',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181513),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${inv.customer.name} has no saved phone number. Enter a mobile number to send receipt:',
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B6358)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: '+91 98765 43210',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF9E958A)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFBA8A55), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF6B6358), fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1C1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final phone = controller.text.trim();
              if (phone.isNotEmpty) {
                Navigator.pop(dialogCtx);
                _sendWhatsAppTo(phone);
              }
            },
            child: Text(
              'Open WhatsApp',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullInvoice() {
    FullInvoicePreviewDialog.show(context: context, invoice: inv);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          backgroundColor: const Color(0xFFFAF7F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFDFD4C5)),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Success Header
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Sale Completed',
                textAlign: TextAlign.center,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Invoice / Receipt #${inv.saleNumber}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6358),
                ),
              ),
              const SizedBox(height: 14),

              // Total + Paid Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    inv.formatCurrency(inv.total),
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F6EE),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFB7E4C7)),
                    ),
                    child: Text(
                      'Paid',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F7A46),
                      ),
                    ),
                  ),
                ],
              ),

              if (_actionErrorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF5C6CB)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFFD32F2F)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _actionErrorMessage!,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF721C24)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 2. Compact Invoice Preview Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2D6C5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E1C1A).withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business & Location
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                inv.business.effectiveName,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF181513),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                inv.location.name,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF6B6358),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          inv.formattedDate,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF7E766B),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 18, color: Color(0xFFEDE5DA)),

                    // Customer Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Customer',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B6358)),
                        ),
                        Text(
                          inv.customer.name,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Items list preview
                    for (final item in inv.items) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.productNameSnapshot} x${item.quantity}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: const Color(0xFF2E2720),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              inv.formatCurrencyMinor(item.lineTotalMinor),
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181513),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Divider(height: 16, color: Color(0xFFEDE5DA)),

                    // Totals
                    _buildPreviewLine('Subtotal', inv.formatCurrency(inv.subtotal)),
                    if (inv.hasDiscount) ...[
                      const SizedBox(height: 4),
                      _buildPreviewLine(
                        'Discount',
                        '-${inv.formatCurrency(inv.discount)}',
                        color: const Color(0xFF1E7E34),
                      ),
                    ],
                    const SizedBox(height: 4),
                    _buildPreviewLine('Tax', inv.formatCurrency(inv.tax)),
                    const Divider(height: 14, color: Color(0xFFDFD4C5)),
                    _buildPreviewLine('Total', inv.formatCurrency(inv.total), isBold: true),

                    const SizedBox(height: 10),
                    // Payment Breakdown
                    Text(
                      'Payment',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B6358),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (inv.payments.isEmpty)
                      _buildPreviewLine('Paid', inv.formatCurrency(inv.total))
                    else
                      for (final p in inv.payments) ...[
                        _buildPreviewLine(
                          _formatPaymentMethod(p.paymentMethod),
                          inv.formatCurrencyMinor(p.amountMinor),
                        ),
                        const SizedBox(height: 3),
                      ],

                    const SizedBox(height: 10),
                    Center(
                      child: TextButton.icon(
                        onPressed: _openFullInvoice,
                        icon: const Icon(Icons.open_in_new_rounded, size: 14, color: Color(0xFFBA8A55)),
                        label: Text(
                          'View Full Invoice',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFBA8A55),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Action Buttons Row (Print, Download PDF, WhatsApp, Share)
              Row(
                children: [
                  // Print (with option popup)
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.print_outlined,
                      label: 'Print',
                      onTap: () => _handlePrint(format: InvoiceFormat.a4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Download PDF
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.download_outlined,
                      label: 'PDF',
                      onTap: () => _handleDownloadPdf(format: InvoiceFormat.a4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // WhatsApp
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'WhatsApp',
                      onTap: _handleWhatsApp,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Share
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      onTap: () => _handleShare(format: InvoiceFormat.a4),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 4. Primary CTA: Start New Sale
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1C1A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  widget.onStartNewSale();
                },
                child: Text(
                  'Start New Sale',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        // 5. Close Button (✕) in Top-Right
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            key: const Key('sale_complete_modal_close_button'),
            icon: const Icon(Icons.close_rounded, size: 20),
            color: const Color(0xFF6B6358),
            tooltip: 'Close (Esc)',
            splashRadius: 18,
            hoverColor: const Color(0xFFEADBCA).withValues(alpha: 0.35),
            highlightColor: Colors.transparent,
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      ],
    ),
  ),
),
),
);
  }

  Widget _buildPreviewLine(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: isBold ? 13.5 : 12,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? const Color(0xFF181513) : const Color(0xFF6B6358),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isBold ? 14.5 : 12.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? (isBold ? const Color(0xFF181513) : const Color(0xFF2E2720)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFDFD4C5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      ),
      onPressed: _isActionInProgress ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1E1C1A)),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1C1A),
            ),
          ),
        ],
      ),
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
}

/// Expansive full invoice dialog displaying the authoritative rendered invoice.
class FullInvoicePreviewDialog extends StatelessWidget {
  const FullInvoicePreviewDialog({super.key, required this.invoice});

  final InvoiceData invoice;

  static Future<void> show({
    required BuildContext context,
    required InvoiceData invoice,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => FullInvoicePreviewDialog(invoice: invoice),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFAF7F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFDFD4C5)),
      ),
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 850),
        child: Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFEDE5DA))),
              ),
              child: Row(
                children: [
                  Text(
                    'Invoice #${invoice.saleNumber}',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.print_outlined, size: 20),
                    tooltip: 'Print A4',
                    onPressed: () => InvoicePdfService.instance.printInvoice(
                      invoice,
                      format: InvoiceFormat.a4,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.receipt_long_outlined, size: 20),
                    tooltip: 'Print 80mm Receipt',
                    onPressed: () => InvoicePdfService.instance.printInvoice(
                      invoice,
                      format: InvoiceFormat.thermal80mm,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.download_outlined, size: 20),
                    tooltip: 'Download PDF',
                    onPressed: () => InvoicePdfService.instance.downloadPdf(
                      invoice,
                      format: InvoiceFormat.a4,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20),
                    tooltip: 'Share',
                    onPressed: () => InvoicePdfService.instance.shareInvoice(
                      invoice,
                      format: InvoiceFormat.a4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Scrollable invoice content (A4 appearance)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5DDD0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E1C1A).withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Business on left, Invoice Info on right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  invoice.business.effectiveName,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF181513),
                                  ),
                                ),
                                if (invoice.business.legalName.isNotEmpty &&
                                    invoice.business.legalName != invoice.business.effectiveName) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    invoice.business.legalName,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFF6B6358),
                                    ),
                                  ),
                                ],
                                if (invoice.business.addressLine.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    invoice.business.addressLine,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: const Color(0xFF6B6358),
                                    ),
                                  ),
                                ],
                                if (invoice.business.phone != null && invoice.business.phone!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tel: ${invoice.business.phone}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: const Color(0xFF6B6358),
                                    ),
                                  ),
                                ],
                                if (invoice.business.email != null && invoice.business.email!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Email: ${invoice.business.email}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: const Color(0xFF6B6358),
                                    ),
                                  ),
                                ],
                                if (invoice.business.website != null && invoice.business.website!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Web: ${invoice.business.website}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: const Color(0xFF6B6358),
                                    ),
                                  ),
                                ],
                                if (invoice.business.isGstRegistered &&
                                    invoice.business.gstin != null &&
                                    invoice.business.gstin!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    'GSTIN: ${invoice.business.gstin}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF181513),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF7F2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE5DDD0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'INVOICE / RECEIPT',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF181513),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  invoice.saleNumber,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFBA8A55),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Date: ${invoice.formattedShortDate}',
                                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B6358)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Location: ${invoice.location.name}',
                                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B6358)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cashier: ${invoice.cashierName}',
                                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B6358)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(color: Color(0xFFEDE5DA)),
                      const SizedBox(height: 12),

                      // Customer bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Customer: ',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B6358),
                              ),
                            ),
                            Text(
                              invoice.customer.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF181513),
                              ),
                            ),
                            if (invoice.customer.phone != null && invoice.customer.phone!.isNotEmpty) ...[
                              const SizedBox(width: 20),
                              Text(
                                'Phone: ${invoice.customer.phone}',
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B6358)),
                              ),
                            ],
                            if (invoice.customer.email != null && invoice.customer.email!.isNotEmpty) ...[
                              const SizedBox(width: 20),
                              Text(
                                'Email: ${invoice.customer.email}',
                                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B6358)),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Items Table
                      Table(
                        border: TableBorder.all(color: const Color(0xFFE5DDD0), width: 0.8),
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFFAF7F2)),
                            children: [
                              _buildTh('Item'),
                              _buildTh('Variant'),
                              _buildTh('SKU'),
                              _buildTh('Qty', align: TextAlign.center),
                              _buildTh('Unit Price', align: TextAlign.right),
                              _buildTh('Discount', align: TextAlign.right),
                              _buildTh('Tax', align: TextAlign.right),
                              _buildTh('Amount', align: TextAlign.right),
                            ],
                          ),
                          for (final item in invoice.items)
                            TableRow(
                              children: [
                                _buildTd(item.productNameSnapshot),
                                _buildTd(item.variantTitleSnapshot ?? '-'),
                                _buildTd(item.skuSnapshot.isNotEmpty ? item.skuSnapshot : '-'),
                                _buildTd(item.quantity.toString(), align: TextAlign.center),
                                _buildTd(invoice.formatCurrencyMinor(item.unitPriceMinor), align: TextAlign.right),
                                _buildTd(
                                  item.discountMinor > 0 ? invoice.formatCurrencyMinor(item.discountMinor) : '-',
                                  align: TextAlign.right,
                                ),
                                _buildTd(invoice.formatCurrencyMinor(item.taxMinor), align: TextAlign.right),
                                _buildTd(
                                  invoice.formatCurrencyMinor(item.lineTotalMinor),
                                  align: TextAlign.right,
                                  isBold: true,
                                ),
                              ],
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Totals & Payments
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Payments
                          Expanded(
                            flex: 5,
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE5DDD0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Payment Details',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF181513),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (invoice.payments.isEmpty)
                                    _buildLine('Paid', invoice.formatCurrency(invoice.total))
                                  else
                                    for (final p in invoice.payments) ...[
                                      _buildLine(
                                        _formatPayment(p.paymentMethod),
                                        invoice.formatCurrencyMinor(p.amountMinor),
                                      ),
                                      const SizedBox(height: 4),
                                    ],
                                  const Divider(height: 14, color: Color(0xFFEDE5DA)),
                                  _buildLine(
                                    'Total Paid',
                                    invoice.formatCurrencyMinor(invoice.totalPaidMinor),
                                    isBold: true,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 32),
                          // Right: Financial breakdown
                          Expanded(
                            flex: 5,
                            child: Column(
                              children: [
                                _buildLine('Subtotal', invoice.formatCurrency(invoice.subtotal)),
                                if (invoice.hasDiscount) ...[
                                  const SizedBox(height: 6),
                                  _buildLine(
                                    'Discount',
                                    '-${invoice.formatCurrency(invoice.discount)}',
                                    color: const Color(0xFF1E7E34),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                _buildLine('Tax', invoice.formatCurrency(invoice.tax)),
                                const SizedBox(height: 10),
                                const Divider(color: Color(0xFF181513), thickness: 1.2),
                                const SizedBox(height: 6),
                                _buildLine(
                                  'Total',
                                  invoice.formatCurrency(invoice.total),
                                  isBold: true,
                                  fontSize: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (invoice.sale.note != null && invoice.sale.note!.trim().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Note: ${invoice.sale.note!.trim()}',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B6358)),
                        ),
                      ],

                      const SizedBox(height: 36),
                      const Divider(color: Color(0xFFEDE5DA)),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Thank you for shopping with ${invoice.business.effectiveName}.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF7E766B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTh(String label, {TextAlign align = TextAlign.left}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        label,
        textAlign: align,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF5E574E),
        ),
      ),
    );
  }

  Widget _buildTd(
    String label, {
    TextAlign align = TextAlign.left,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        label,
        textAlign: align,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          color: const Color(0xFF181513),
        ),
      ),
    );
  }

  Widget _buildLine(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 12.5,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            color: isBold ? const Color(0xFF181513) : const Color(0xFF6B6358),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? (isBold ? const Color(0xFF181513) : const Color(0xFF2E2720)),
          ),
        ),
      ],
    );
  }

  String _formatPayment(String method) {
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
}
