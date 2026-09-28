// ignore_for_file: deprecated_member_use, unused_element
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/business/current_business_service.dart';

class SaleInvoiceView extends StatefulWidget {
  const SaleInvoiceView({
    super.key,
    this.saleNumber,
    this.invoiceId,
    this.status,
    this.storeName,
    this.storeAddress,
    this.storeTel,
    this.dateTime,
    this.cashier,
    this.customer,
    this.customerEmail,
    this.subtotal,
    this.discountLabel,
    this.discountAmount,
    this.taxLabel,
    this.taxAmount,
    this.totalPaid,
    this.paymentMethod,
    this.barcode,
    this.taxIdentifier,
    this.posTerminal,
    this.items = const [],
  });

  final String? saleNumber;
  final String? invoiceId;
  final String? status;
  final String? storeName;
  final String? storeAddress;
  final String? storeTel;
  final String? dateTime;
  final String? cashier;
  final String? customer;
  final String? customerEmail;
  final String? subtotal;
  final String? discountLabel;
  final String? discountAmount;
  final String? taxLabel;
  final String? taxAmount;
  final String? totalPaid;
  final String? paymentMethod;
  final String? barcode;
  final String? taxIdentifier;
  final String? posTerminal;
  final List<InvoiceItemData> items;

  @override
  State<SaleInvoiceView> createState() => _SaleInvoiceViewState();
}

class InvoiceItemData {
  const InvoiceItemData({
    required this.name,
    required this.sku,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    this.size,
  });

  final String name;
  final String sku;
  final int qty;
  final double unitPrice;
  final double lineTotal;
  final String? size;
}

class _SaleInvoiceViewState extends State<SaleInvoiceView> {
  bool _showTaxBreakdown = true;
  bool _showProductSKUs = true;
  bool _showCustomerDetails = true;

  late final TextEditingController _sendToEmailController;

  bool get _hasInvoice =>
      widget.saleNumber != null && widget.saleNumber!.trim().isNotEmpty;

  String get _currencySymbol {
    final code =
        CurrentBusinessService.instance.currentBusiness?.currencyCode
            .toUpperCase() ??
        'USD';
    switch (code) {
      case 'INR':
        return '₹';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      case 'AED':
        return 'AED ';
      default:
        return '$code ';
    }
  }

  @override
  void initState() {
    super.initState();
    _sendToEmailController = TextEditingController(
      text: widget.customerEmail ?? '',
    );
  }

  @override
  void dispose() {
    _sendToEmailController.dispose();
    super.dispose();
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFFBA8A55),
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 980;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _hasInvoice
                      ? _buildInvoiceCard()
                      : _buildNoInvoiceSelectedCard(),
                ),
                const SizedBox(width: 24),
                SizedBox(width: 320, child: _buildRightPanel()),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hasInvoice ? _buildInvoiceCard() : _buildNoInvoiceSelectedCard(),
              const SizedBox(height: 24),
              _buildRightPanel(),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // Empty State: No invoice selected
  // ===========================================================================
  Widget _buildNoInvoiceSelectedCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFF5EDE1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 28,
                color: Color(0xFFBA8A55),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No invoice selected',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181512),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'An invoice will be available after a completed sale.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF7E766B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Populated Invoice Card (Only if a real sale invoice exists)
  // ===========================================================================
  Widget _buildInvoiceCard() {
    final bizName =
        widget.storeName ??
        CurrentBusinessService.instance.currentBusiness?.legalName ??
        'ThreadStock Store';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                Text(
                  bizName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                if (widget.storeAddress != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    widget.storeAddress!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
                if (widget.storeTel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    widget.storeTel!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE8ECEF), height: 1),
          const SizedBox(height: 16),

          // Sale Metadata
          _MetaRow('Sale Number', widget.saleNumber ?? '—'),
          const SizedBox(height: 6),
          _MetaRow('Date & Time', widget.dateTime ?? '—'),
          if (widget.cashier != null) ...[
            const SizedBox(height: 6),
            _MetaRow('Cashier', widget.cashier!),
          ],
          if (_showCustomerDetails && widget.customer != null) ...[
            const SizedBox(height: 6),
            _MetaRow('Customer', widget.customer!),
          ],
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE8ECEF), height: 1),
          const SizedBox(height: 16),

          // Items
          if (widget.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No items recorded for this invoice.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            ...widget.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          if (_showProductSKUs)
                            Text(
                              'SKU: ${item.sku}${item.size != null ? ' | Size: ${item.size}' : ''}',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.qty} × $_currencySymbol${item.unitPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Divider(color: Color(0xFFE8ECEF), height: 1),
          const SizedBox(height: 14),

          // Totals
          _TotalsRow('Subtotal', widget.subtotal ?? '${_currencySymbol}0'),
          if (widget.discountAmount != null) ...[
            const SizedBox(height: 6),
            _TotalsRow(
              widget.discountLabel ?? 'Discount',
              widget.discountAmount!,
              isDiscount: true,
            ),
          ],
          const SizedBox(height: 6),
          if (_showTaxBreakdown)
            _TotalsRow(
              widget.taxLabel ?? 'Tax',
              widget.taxAmount ?? 'Tax not configured',
            ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFE8ECEF), height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Paid',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              Text(
                widget.totalPaid ?? '${_currencySymbol}0',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF181513),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Right Panel: Actions & Settings
  // ===========================================================================
  Widget _buildRightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Actions Card
        _SectionCard(
          title: 'INVOICE ACTIONS',
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.print_outlined,
                      label: 'Print Invoice',
                      onTap: _hasInvoice
                          ? () => _showFeedback('Printing invoice...')
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.download_outlined,
                      label: 'Download PDF',
                      onTap: _hasInvoice
                          ? () => _showFeedback('Downloading PDF...')
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _sendToEmailController,
                enabled: _hasInvoice,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: _hasInvoice
                      ? 'Customer email'
                      : 'No customer email',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _hasInvoice
                      ? () => _showFeedback('Invoice sent to customer.')
                      : null,
                  icon: const Icon(Icons.send_outlined, size: 14),
                  label: const Text('Send to Customer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF181512),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Tax Engine Status
        _SectionCard(
          title: 'TAX CONFIGURATION',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tax not configured',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Tax calculation will activate once tax rules are configured for your business jurisdiction.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Display Options
        _SectionCard(
          title: 'DISPLAY OPTIONS',
          child: Column(
            children: [
              _ToggleRow(
                'Show Tax Breakdown',
                _showTaxBreakdown,
                (v) => setState(() => _showTaxBreakdown = v),
              ),
              _ToggleRow(
                'Show Product SKUs',
                _showProductSKUs,
                (v) => setState(() => _showProductSKUs = v),
              ),
              _ToggleRow(
                'Show Customer Details',
                _showCustomerDetails,
                (v) => setState(() => _showCustomerDetails = v),
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  const _MetaRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow(this.label, this.value, {this.isDiscount = false});
  final String label;
  final String value;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: isDiscount
                ? const Color(0xFFDC2626)
                : const Color(0xFF181513),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? const Color(0xFFE2E8F0) : const Color(0xFFEDF2F7),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: enabled
                  ? const Color(0xFF181513)
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: enabled
                    ? const Color(0xFF181513)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow(
    this.label,
    this.value,
    this.onChanged, {
    this.isLast = false,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF181513),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFFD97706),
              activeTrackColor: const Color(0xFFFDE68A),
              inactiveThumbColor: const Color(0xFFCBD5E1),
              inactiveTrackColor: const Color(0xFFF1F5F9),
            ),
          ],
        ),
        if (!isLast) const Divider(color: Color(0xFFF1F5F9), height: 1),
      ],
    );
  }
}
