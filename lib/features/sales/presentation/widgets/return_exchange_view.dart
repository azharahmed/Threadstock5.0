// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/business/current_business_service.dart';
import '../../data/sales_repository.dart';
import '../../domain/models/sale.dart';
import '../../domain/models/sale_item.dart';

class ReturnExchangeView extends StatefulWidget {
  const ReturnExchangeView({super.key, this.onBackToSales});

  final VoidCallback? onBackToSales;

  @override
  State<ReturnExchangeView> createState() => _ReturnExchangeViewState();
}

class _ReturnExchangeViewState extends State<ReturnExchangeView> {
  // Sale picker state
  List<Sale> _completedSales = [];
  bool _isLoadingSales = true;
  String? _loadError;

  // Selected sale (after user picks)
  Sale? _selectedSale;

  // Refund method
  String _refundMethod = 'Original Payment Method';

  @override
  void initState() {
    super.initState();
    _loadCompletedSales();
  }

  Future<void> _loadCompletedSales() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSales = true;
      _loadError = null;
    });
    try {
      final businessId = CurrentBusinessService.instance.currentBusinessId;
      if (businessId == null || businessId.isEmpty || businessId.startsWith('biz_')) {
        if (mounted) setState(() => _isLoadingSales = false);
        return;
      }

      final sales = await SalesRepository.instance.getSales(businessId: businessId);
      final completed = sales.where((s) => s.status == 'completed').toList();

      if (mounted) {
        setState(() {
          _completedSales = completed;
          _isLoadingSales = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadError = e.toString();
          _isLoadingSales = false;
        });
      }
    }
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    final buffer = StringBuffer();
    final reversed = intPart.split('').reversed.toList();
    for (int i = 0; i < reversed.length; i++) {
      if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) {
        buffer.write(',');
      }
      buffer.write(reversed[i]);
    }
    final formattedInt = buffer.toString().split('').reversed.join();
    if (decPart == '00') {
      return formattedInt;
    }
    return '$formattedInt.$decPart';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back to Sales Button
          InkWell(
            onTap: widget.onBackToSales,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF181513)),
                  const SizedBox(width: 8),
                  Text(
                    'Back to Sales',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Text(
            'Return / Exchange',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select a completed sale to start a return or exchange process.',
            style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 24),

          if (_selectedSale == null)
            _buildSalePicker()
          else
            _buildReturnWorkflow(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sale Picker
  // ---------------------------------------------------------------------------

  Widget _buildSalePicker() {
    if (_isLoadingSales) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_loadError != null) {
      return _buildErrorCard(_loadError!, onRetry: _loadCompletedSales);
    }

    if (_completedSales.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Completed Sales',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_completedSales.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: _loadCompletedSales,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      'Refresh',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Sales list
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: _completedSales.asMap().entries.map((entry) {
              final sale = entry.value;
              final isLast = entry.key == _completedSales.length - 1;
              return _buildSaleRow(sale, isLast: isLast);
            }).toList(),
          ),
        ),

        // Honest UX note
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Return processing is not yet enabled. You can browse completed sales and plan a return, but processing must be handled manually.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF92400E)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaleRow(Sale sale, {bool isLast = false}) {
    final date = _formatDate(sale.completedAt ?? sale.createdAt);
    final total = '₹${_formatCurrency(sale.total)}';
    final customer = sale.customerName?.isNotEmpty == true ? sale.customerName! : 'Walk-in';
    final itemCount = sale.items.length;
    final itemSummary = itemCount == 0
        ? '—'
        : '$itemCount item${itemCount == 1 ? '' : 's'}';

    return InkWell(
      onTap: () => setState(() => _selectedSale = sale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 0.8),
                ),
        ),
        child: Row(
          children: [
            // Sale number + date
            Expanded(
              flex: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.saleNumber,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),

            // Customer
            Expanded(
              flex: 22,
              child: Text(
                customer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF374151)),
              ),
            ),

            // Items
            Expanded(
              flex: 12,
              child: Text(
                itemSummary,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
              ),
            ),

            // Total
            Expanded(
              flex: 14,
              child: Text(
                total,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
                textAlign: TextAlign.right,
              ),
            ),

            // Select chevron
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFBF4EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFF92400E)),
            ),
            const SizedBox(height: 16),
            Text(
              'No completed sales yet',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Completed sales will appear here and can be selected for return processing.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            if (widget.onBackToSales != null)
              ElevatedButton.icon(
                onPressed: widget.onBackToSales,
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Return to Sales'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF181513),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error, {required VoidCallback onRetry}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 32, color: Color(0xFFEF4444)),
            const SizedBox(height: 12),
            Text(
              'Failed to load sales',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Return Workflow (after sale selected)
  // ---------------------------------------------------------------------------

  Widget _buildReturnWorkflow() {
    final sale = _selectedSale!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          flex: 64,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSelectedSaleCard(sale),
              const SizedBox(height: 20),
              _buildItemsCard(sale),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Right Column
        Expanded(
          flex: 36,
          child: Column(
            children: [
              _buildRefundSummaryCard(sale),
              const SizedBox(height: 16),
              _buildCustomerInfoCard(sale),
              const SizedBox(height: 16),
              _buildReturnNotAvailableCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedSaleCard(Sale sale) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF16A34A)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Sale: ${sale.saleNumber}',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF15803D),
                  ),
                ),
                Text(
                  '${_formatDate(sale.completedAt ?? sale.createdAt)} · ₹${_formatCurrency(sale.total)}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF166534)),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _selectedSale = null),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                'Change',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsCard(Sale sale) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sale Items',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Items from this sale. Return processing must be handled manually.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          if (sale.items.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No item details available for this sale.',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
                ),
              ),
            )
          else
            ...sale.items.map((item) => _buildItemRow(item)),
        ],
      ),
    );
  }

  Widget _buildItemRow(SaleItem item) {
    final name = item.productNameSnapshot.isNotEmpty ? item.productNameSnapshot : 'Product';
    final variant = item.variantTitleSnapshot?.isNotEmpty == true ? item.variantTitleSnapshot! : '';
    final sku = item.skuSnapshot.isNotEmpty ? item.skuSnapshot : '';
    final lineTotal = item.lineTotalMinor / 100.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                if (variant.isNotEmpty || sku.isNotEmpty)
                  Text(
                    [if (variant.isNotEmpty) variant, if (sku.isNotEmpty) sku].join(' · '),
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                  ),
              ],
            ),
          ),
          Text(
            '× ${item.quantity}',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(width: 20),
          Text(
            '₹${_formatCurrency(lineTotal)}',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefundSummaryCard(Sale sale) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sale Summary',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),

          _buildSummaryLine('Subtotal', '₹${_formatCurrency(sale.subtotal)}'),
          const SizedBox(height: 10),
          if (sale.discount > 0) ...[
            _buildSummaryLine('Discount', '-₹${_formatCurrency(sale.discount)}'),
            const SizedBox(height: 10),
          ],
          if (sale.tax > 0) ...[
            _buildSummaryLine('Tax', '₹${_formatCurrency(sale.tax)}'),
            const SizedBox(height: 10),
          ],
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Payments breakdown
          ...sale.payments.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _buildSummaryLine(
                  _paymentMethodLabel(p.paymentMethod),
                  '₹${_formatCurrency(p.amountMinor / 100.0)}',
                ),
              )),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Paid',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                '₹${_formatCurrency(sale.total)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Refund Method
          Text(
            'Planned Refund Method',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _refundMethod,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                items: const [
                  DropdownMenuItem(
                    value: 'Original Payment Method',
                    child: Text('Original Payment Method'),
                  ),
                  DropdownMenuItem(value: 'Cash Refund', child: Text('Cash Refund')),
                  DropdownMenuItem(value: 'Store Credit Voucher', child: Text('Store Credit Voucher')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _refundMethod = val);
                },
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E293B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoCard(Sale sale) {
    final name = sale.customerName?.isNotEmpty == true ? sale.customerName! : 'Walk-in Customer';
    final phone = sale.customerPhone;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (phone != null && phone.isNotEmpty)
                      Text(
                        phone,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReturnNotAvailableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Text(
                'Complete Return / Exchange',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Return processing is not yet supported in the backend. Processing must be completed manually.',
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF94A3B8),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                'Process Return (Not Available)',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _selectedSale = null),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Select a Different Sale',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _paymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Cash';
      case 'card':
        return 'Card';
      case 'upi':
        return 'UPI';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return method[0].toUpperCase() + method.substring(1);
    }
  }
}
