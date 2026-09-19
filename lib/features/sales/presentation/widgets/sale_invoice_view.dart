// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SaleInvoiceView extends StatefulWidget {
  const SaleInvoiceView({
    super.key,
    this.saleNumber = 'TS-10482',
    this.invoiceId = 'PO-10482',
    this.status = 'Paid',
    this.storeName = 'Central Store, Indiranagar',
    this.storeAddress = 'Bangalore, KA 560038',
    this.storeTel = 'Tel: +91 80 4928 2901',
    this.dateTime = '14 Feb 2027, 11:32 AM',
    this.cashier = 'Rahul Sharma',
    this.customer = 'Aditya Roy',
    this.customerEmail = 'aditya.roy@domain.com',
    this.subtotal = '₹21,300',
    this.discountLabel = 'Discount (WAITLIST10)',
    this.discountAmount = '-₹2,130',
    this.gst = '₹2,300',
    this.totalPaid = '₹21,470',
    this.paymentMethod = 'Credit Card (ending in 4920)',
    this.barcode = '*TS-10482*',
    this.gstin = '29AAFT4091A1ZX',
    this.invoiceIdMeta = 'INV-TS-10482',
    this.posTerminal = 'POS-01',
    this.generatedOn = '14 Feb 2027, 11:32 AM',
    this.subjectTo = 'Bangalore Jurisdiction',
    this.gstRate = '12%',
  });

  final String saleNumber;
  final String invoiceId;
  final String status;
  final String storeName;
  final String storeAddress;
  final String storeTel;
  final String dateTime;
  final String cashier;
  final String customer;
  final String customerEmail;
  final String subtotal;
  final String discountLabel;
  final String discountAmount;
  final String gst;
  final String totalPaid;
  final String paymentMethod;
  final String barcode;
  final String gstin;
  final String invoiceIdMeta;
  final String posTerminal;
  final String generatedOn;
  final String subjectTo;
  final String gstRate;

  @override
  State<SaleInvoiceView> createState() => _SaleInvoiceViewState();
}

class _SaleInvoiceViewState extends State<SaleInvoiceView> {
  bool _showTaxBreakdown = true;
  bool _showProductSKUs = true;
  bool _showBarcodeReference = true;
  bool _showCustomerDetails = true;
  bool _showBusinessTaxId = false;

  final _sendToEmailController = TextEditingController(text: 'aditya.roy@domain.com');

  final List<_InvoiceItem> _items = const [
    _InvoiceItem(
      name: 'Oxford Linen Shirt',
      size: 'M',
      sku: 'TS-10492-BLK-M',
      qty: 2,
      unitPrice: 4900,
      lineTotal: 9800,
      imageAsset: 'Assets/oxford_linen_shirt.jpg',
    ),
    _InvoiceItem(
      name: 'Merino Wool Blazer',
      size: 'L',
      sku: 'TS-39202-NVY-L',
      qty: 1,
      unitPrice: 11500,
      lineTotal: 11500,
      imageAsset: 'Assets/merino_wool_blazer.jpg',
    ),
  ];

  @override
  void dispose() {
    _sendToEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: LayoutBuilder(builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildInvoiceCard()),
              const SizedBox(width: 24),
              SizedBox(width: 300, child: _buildRightPanel()),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInvoiceCard(),
            const SizedBox(height: 24),
            _buildRightPanel(),
          ],
        );
      }),
    );
  }

  Widget _buildInvoiceCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Logo + store info
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(color: Color(0xFFB45309), shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'THREADSTOCK',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w900, color: const Color(0xFF181513), letterSpacing: 1.0),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(widget.storeName, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              Text(widget.storeAddress, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
              Text(widget.storeTel, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE2E8F0), height: 1),
          const SizedBox(height: 16),

          // Sale metadata
          _MetaRow('Sale #', widget.saleNumber),
          const SizedBox(height: 4),
          _MetaRow('Date & Time', widget.dateTime),
          const SizedBox(height: 4),
          _MetaRow('Cashier', widget.cashier),
          const SizedBox(height: 4),
          _MetaRow('Customer', widget.customer),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE8ECEF), height: 1, endIndent: 0),
          const SizedBox(height: 16),

          // Items
          ..._items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 44,
                    height: 44,
                    color: const Color(0xFFF1F5F9),
                    child: Image.asset(
                      item.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, size: 20, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF181513))),
                      Text('Size: ${item.size}   |   SKU: ${item.sku}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.qty} × ₹${item.unitPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF181513)),
                    ),
                    Text(
                      '₹${item.lineTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
          )),

          const Divider(color: Color(0xFFE8ECEF), height: 1),
          const SizedBox(height: 12),

          // Totals
          _TotalsRow('Subtotal', widget.subtotal),
          const SizedBox(height: 4),
          _TotalsRow(widget.discountLabel, widget.discountAmount, isDiscount: true),
          const SizedBox(height: 4),
          _TotalsRow('GST (${widget.gstRate})', widget.gst),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Paid', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF181513))),
              Text(widget.totalPaid, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF181513))),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE8ECEF), height: 1),
          const SizedBox(height: 12),

          // Payment method
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment Method', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
              Text(widget.paymentMethod, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF181513))),
            ],
          ),

          const SizedBox(height: 20),

          // Barcode
          Column(
            children: [
              Text(widget.barcode, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF181513), letterSpacing: 1.5)),
              const SizedBox(height: 6),
              Container(
                height: 42,
                width: 140,
                decoration: BoxDecoration(
                  color: const Color(0xFF181513),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(38, (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.8),
                    width: i % 3 == 0 ? 2.4 : 1.2,
                    height: i % 5 == 0 ? 42 : 30,
                    color: Colors.white,
                  )),
                ),
              ),
              const SizedBox(height: 16),
              Text('Thank you for shopping with ThreadStock.', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
              Text('All returns must be accompanied by receipt.', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Text('RECEIPT ACTIONS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: const Color(0xFF94A3B8))),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _ActionBtn(
                icon: Icons.print_outlined,
                label: 'Print Invoice',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sending to printer...'), duration: Duration(seconds: 1))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionBtn(
                icon: Icons.download_outlined,
                label: 'Download PDF',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating PDF...'), duration: Duration(seconds: 1))),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Send to customer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mail_outlined, size: 15, color: Color(0xFFB45309)),
                  const SizedBox(width: 6),
                  Text('SEND TO CUSTOMER', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: const Color(0xFFB45309))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: TextField(
                          controller: _sendToEmailController,
                          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF181513)),
                          decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice sent to ${_sendToEmailController.text}'), behavior: SnackBarBehavior.floating)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF181513),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text('Send', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Document Display Options
        _SectionCard(
          title: 'DOCUMENT DISPLAY OPTIONS',
          child: Column(
            children: [
              _ToggleRow('Show tax breakdown', _showTaxBreakdown, (v) => setState(() => _showTaxBreakdown = v)),
              _ToggleRow('Show product SKUs', _showProductSKUs, (v) => setState(() => _showProductSKUs = v)),
              _ToggleRow('Show barcode reference', _showBarcodeReference, (v) => setState(() => _showBarcodeReference = v)),
              _ToggleRow('Show customer details', _showCustomerDetails, (v) => setState(() => _showCustomerDetails = v)),
              _ToggleRow('Show business tax ID', _showBusinessTaxId, (v) => setState(() => _showBusinessTaxId = v), isLast: true),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Invoice Metadata
        _SectionCard(
          title: 'INVOICE METADATA',
          child: Column(
            children: [
              _MetaKeyValue('GSTIN', widget.gstin),
              const Divider(color: Color(0xFFF1F5F9), height: 16),
              _MetaKeyValue('Invoice ID', widget.invoiceIdMeta),
              const Divider(color: Color(0xFFF1F5F9), height: 16),
              _MetaKeyValue('POS Terminal', widget.posTerminal),
              const Divider(color: Color(0xFFF1F5F9), height: 16),
              _MetaKeyValue('Generated On', widget.generatedOn),
              const Divider(color: Color(0xFFF1F5F9), height: 16),
              _MetaKeyValue('Subject to', widget.subjectTo),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _InvoiceItem {
  const _InvoiceItem({
    required this.name,
    required this.size,
    required this.sku,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    required this.imageAsset,
  });
  final String name;
  final String size;
  final String sku;
  final int qty;
  final int unitPrice;
  final int lineTotal;
  final String imageAsset;
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF94A3B8)))),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF181513)))),
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
        Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: isDiscount ? const Color(0xFFDC2626) : const Color(0xFF181513),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF181513)),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF181513))),
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
          Text(title, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: const Color(0xFF94A3B8))),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow(this.label, this.value, this.onChanged, {this.isLast = false});
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
            Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181513))),
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

class _MetaKeyValue extends StatelessWidget {
  const _MetaKeyValue(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
        Flexible(child: Text(value, textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF181513)))),
      ],
    );
  }
}
