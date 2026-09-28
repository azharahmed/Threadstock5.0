// ignore_for_file: deprecated_member_use, unnecessary_underscores
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Models ──────────────────────────────────────────────────────────────────
class _PO10482Item {
  const _PO10482Item({
    required this.index,
    required this.name,
    required this.variant,
    required this.sku,
    required this.qty,
    required this.unitCost,
    required this.totalCost,
    required this.receivedQty,
    required this.imageAsset,
  });

  final int index;
  final String name;
  final String variant;
  final String sku;
  final int qty;
  final int unitCost;
  final int totalCost;
  final int receivedQty;
  final String imageAsset;

  bool get fullyReceived => receivedQty >= qty;
}

class _POActivity {
  const _POActivity({
    required this.actor,
    required this.action,
    required this.time,
    required this.isSystem,
  });
  final String actor;
  final String action;
  final String time;
  final bool isSystem;
}

// ─── Widget ───────────────────────────────────────────────────────────────────
class PO10482DetailView extends StatefulWidget {
  const PO10482DetailView({
    super.key,
    this.onBackToOverview,
    this.onNavigateToInvoice,
  });

  final VoidCallback? onBackToOverview;
  final VoidCallback? onNavigateToInvoice;

  @override
  State<PO10482DetailView> createState() => _PO10482DetailViewState();
}

class _PO10482DetailViewState extends State<PO10482DetailView> {
  final String _poNumber = '#10482';
  final String _status = 'Awaiting Approval';
  final String _statusSub = 'Ready for Finance Dept.';
  final String _supplier = 'Primary Supplier';
  final String _supplierSub = 'Verified Partner';
  final String _shipTo = 'Main Warehouse';
  final String _shipToSub = 'Primary Storage Facility';
  final String _expectedArrival = '14 Mar 2027';
  final String _paymentTerms = 'Net 30';
  final String _createdBy = 'Store Admin';
  final String _createdOn = '14 Feb 2027, 11:14 AM';
  final String _currency = 'INR';
  final String _reference = 'REPLENISH-01';

  final List<_PO10482Item> _items = const [];

  final List<_POActivity> _activities = const [
    _POActivity(
      actor: 'System',
      action: 'Purchase order created and queued for review.',
      time: '11:14 AM',
      isSystem: true,
    ),
  ];

  int get _subtotal => _items.fold(0, (sum, i) => sum + i.totalCost);
  int get _shipping => _items.isEmpty ? 0 : 4500;
  int get _customs => _items.isEmpty ? 0 : 9408;
  int get _total => _subtotal + _shipping + _customs;

  void _approveOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PO #10482 approved.'),
        backgroundColor: Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _requestRevision() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Revision requested for PO #10482.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBanner(),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoCards(),
                          const SizedBox(height: 20),
                          _buildItemsTable(),
                          const SizedBox(height: 20),
                          _buildActivitySection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    SizedBox(width: 300, child: _buildRightPanel()),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCards(),
                  const SizedBox(height: 20),
                  _buildItemsTable(),
                  const SizedBox(height: 20),
                  _buildRightPanel(),
                  const SizedBox(height: 20),
                  _buildActivitySection(),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'PO $_poNumber',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusBadge(
                      _status,
                      bgColor: const Color(0xFFFBF0DF),
                      textColor: const Color(0xFF9E6516),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$_statusSub · Created by $_createdBy on $_createdOn',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _HeaderActionBtn(
                icon: Icons.download_outlined,
                label: 'Export PDF',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _HeaderActionBtn(
                icon: Icons.mail_outline_rounded,
                label: 'Email Supplier',
                onTap: () {},
              ),
              const SizedBox(width: 8),
              _HeaderActionBtn(
                icon: Icons.more_horiz_rounded,
                label: '',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        _InfoCard(
          icon: Icons.storefront_outlined,
          title: 'Supplier',
          value: _supplier,
          subtitle: _supplierSub,
        ),
        const SizedBox(width: 12),
        _InfoCard(
          icon: Icons.warehouse_outlined,
          title: 'Ship To',
          value: _shipTo,
          subtitle: _shipToSub,
        ),
        const SizedBox(width: 12),
        _InfoCard(
          icon: Icons.calendar_today_outlined,
          title: 'Expected Arrival',
          value: _expectedArrival,
          subtitle: 'Standard Freight',
        ),
        const SizedBox(width: 12),
        _InfoCard(
          icon: Icons.receipt_outlined,
          title: 'Payment Terms',
          value: _paymentTerms,
          subtitle: 'Currency: $_currency',
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Items (${_items.length})',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181513),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header row
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    _Th('#', flex: 1),
                    _Th('Product', flex: 5),
                    _Th('Variant / SKU', flex: 4),
                    _Th('Qty', flex: 2),
                    _Th('Unit Cost', flex: 2),
                    _Th('Total', flex: 2),
                    _Th('Received', flex: 2),
                  ],
                ),
              ),

              // Rows
              if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 36,
                        color: Color(0xFFCBD5E1),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No items recorded on this purchase order',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Purchase order line items will appear once confirmed with the vendor.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._items.map(
                  (item) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      border: _items.last != item
                          ? const Border(
                              bottom: BorderSide(color: Color(0xFFF1F5F9)),
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Index
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${item.index}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ),

                        // Product
                        Expanded(
                          flex: 5,
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  color: const Color(0xFFF1F5F9),
                                  child: Image.asset(
                                    item.imageAsset,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_not_supported_outlined,
                                      size: 18,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF181513),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Variant / SKU
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.variant,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF181513),
                                ),
                              ),
                              Text(
                                item.sku,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Qty
                        Expanded(
                          flex: 2,
                          child: Text(
                            '${item.qty} pcs',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ),

                        // Unit cost
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${item.unitCost}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ),

                        // Total
                        Expanded(
                          flex: 2,
                          child: Text(
                            '₹${item.totalCost.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ),

                        // Received
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.fullyReceived
                                    ? '${item.qty} / ${item.qty}'
                                    : '${item.receivedQty} / ${item.qty}',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: item.fullyReceived
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                              LinearProgressIndicator(
                                value: item.qty == 0
                                    ? 0.0
                                    : item.receivedQty / item.qty,
                                backgroundColor: const Color(0xFFF1F5F9),
                                color: const Color(0xFF16A34A),
                                minHeight: 3,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity & Notes',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181513),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              ..._activities.asMap().entries.map((e) {
                final i = e.key;
                final act = e.value;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: i < _activities.length - 1
                        ? const Border(
                            bottom: BorderSide(color: Color(0xFFF1F5F9)),
                          )
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: act.isSystem
                              ? const Color(0xFFF1F5F9)
                              : const Color(0xFFFEF3C7),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          act.isSystem
                              ? Icons.settings_outlined
                              : Icons.person_outline_rounded,
                          size: 16,
                          color: act.isSystem
                              ? const Color(0xFF64748B)
                              : const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF181513),
                                ),
                                children: [
                                  TextSpan(
                                    text: '${act.actor}  ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  TextSpan(text: act.action),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        act.time,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // Add note field
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Add a note or comment...',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181513),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Post',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cost summary card
        _PanelCard(
          title: 'COST SUMMARY',
          child: Column(
            children: [
              _SummaryRow(
                'Subtotal (${_items.length} items)',
                '₹${_subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
              ),
              const SizedBox(height: 6),
              _SummaryRow(
                'Est. Freight & Shipping',
                '₹${_shipping.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
              ),
              const SizedBox(height: 6),
              _SummaryRow(
                'Customs Duties & Taxes',
                '₹${_customs.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  Text(
                    '₹${_total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // PO Details
        _PanelCard(
          title: 'PO DETAILS',
          child: Column(
            children: [
              _DetailRow('Reference', _reference),
              const Divider(color: Color(0xFFF1F5F9), height: 14),
              _DetailRow('Payment Terms', _paymentTerms),
              const Divider(color: Color(0xFFF1F5F9), height: 14),
              _DetailRow('Currency', _currency),
              const Divider(color: Color(0xFFF1F5F9), height: 14),
              _DetailRow('Created By', _createdBy),
              const Divider(color: Color(0xFFF1F5F9), height: 14),
              _DetailRow('Created On', _createdOn),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Approval Actions
        _PanelCard(
          title: 'APPROVAL ACTIONS',
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Awaiting Finance department approval.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: _approveOrder,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                    'Approve Order',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: _requestRevision,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: Color(0xFF181513),
                  ),
                  label: Text(
                    'Request Revision',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: widget.onNavigateToInvoice ?? () {},
                  icon: const Icon(
                    Icons.receipt_long_outlined,
                    size: 14,
                    color: Color(0xFF181513),
                  ),
                  label: Text(
                    'View Invoice',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge(
    this.label, {
    required this.bgColor,
    required this.textColor,
  });
  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _HeaderActionBtn extends StatelessWidget {
  const _HeaderActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: label.isEmpty ? 10 : 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF181513)),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, size: 15, color: const Color(0xFFB45309)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.text, {required this.flex});
  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF181513),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
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
