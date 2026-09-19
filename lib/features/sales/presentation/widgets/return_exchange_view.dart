// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReturnExchangeView extends StatefulWidget {
  const ReturnExchangeView({
    super.key,
    this.onBackToSales,
  });

  final VoidCallback? onBackToSales;

  @override
  State<ReturnExchangeView> createState() => _ReturnExchangeViewState();
}

class _ReturnExchangeViewState extends State<ReturnExchangeView> {
  // Item 1 state
  bool _item1Selected = true;
  int _item1ReturnQty = 1;
  final int _item1OriginalQty = 2;
  final double _item1UnitPrice = 2490.0;
  String _item1Reason = 'Size fits too small';

  // Item 2 state
  bool _item2Selected = false;
  int _item2ReturnQty = 0;
  final int _item2OriginalQty = 1;
  final double _item2UnitPrice = 2890.0;
  String _item2Reason = 'Select reason';

  // Exchange state
  bool _processAsExchange = true;
  String _exchangeProduct = 'Oxford Linen Shirt';
  String _exchangeSize = 'Size L';

  // Refund method
  String _refundMethod = 'Refund to original card (...4292)';

  // Calculations
  double get _returnedItemsValue {
    double total = 0;
    if (_item1Selected) total += _item1ReturnQty * _item1UnitPrice;
    if (_item2Selected) total += _item2ReturnQty * _item2UnitPrice;
    return total;
  }

  double get _exchangedItemsCost {
    if (!_processAsExchange) return 0;
    // Assume 1 exchanged item costs same as item1 unit price
    return _item1Selected ? (_item1ReturnQty * _item1UnitPrice) : 0;
  }

  double get _difference => _returnedItemsValue - _exchangedItemsCost;

  double get _restockingFee => _returnedItemsValue * 0.05; // 5%

  double get _totalRefund {
    if (_processAsExchange) {
      // In screenshot: returned 2490, exchanged 2490, diff 0, fee 124.50 -> Total Refund 2365.50 (or 2490 - 124.50)
      return (_returnedItemsValue - _restockingFee).clamp(0, double.infinity);
    }
    return (_returnedItemsValue - _restockingFee).clamp(0, double.infinity);
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

          // Two-Column Layout
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Items Selection + Exchange Options
              Expanded(
                flex: 64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReturnItemsCard(),
                    const SizedBox(height: 20),
                    _buildExchangeOptionCard(),
                  ],
                ),
              ),
              const SizedBox(width: 24),

              // Right Column: Summary, Customer, Policy
              Expanded(
                flex: 36,
                child: Column(
                  children: [
                    _buildRefundSummaryCard(),
                    const SizedBox(height: 16),
                    _buildCustomerInfoCard(),
                    const SizedBox(height: 16),
                    _buildReturnPolicyCard(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Card 1: Select Items for Return
  Widget _buildReturnItemsCard() {
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
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Items for Return',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reference Order: Sale #TS-10482  •  Customer: Emma Carter  •  16 Sep 2026',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Barcode scanner active. Ready for item scan.'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: Color(0xFF181513),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 16, color: Color(0xFFB45309)),
                label: const Text('Scan Barcode'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(color: Color(0xFFFDE68A)),
                  backgroundColor: const Color(0xFFFFFBEB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  flex: 38,
                  child: Text(
                    'Product',
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: Text(
                    'Original Qty',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                  ),
                ),
                Expanded(
                  flex: 22,
                  child: Text(
                    'Return Qty',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                  ),
                ),
                Expanded(
                  flex: 24,
                  child: Text(
                    'Return Reason',
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Row 1: Oxford Linen Shirt
          _buildItemRow(
            isSelected: _item1Selected,
            onToggleSelected: (val) {
              setState(() {
                _item1Selected = val ?? false;
                if (_item1Selected && _item1ReturnQty == 0) _item1ReturnQty = 1;
              });
            },
            imageAsset: 'assets/black_linen_shirt.jpg',
            fallbackAsset: 'assets/oxford_linen_shirt.jpg',
            name: 'Oxford Linen Shirt',
            sku: 'TS-10492  •  Black - M',
            tag: 'Shirts',
            tagBg: const Color(0xFFFEF3C7),
            tagText: const Color(0xFFB45309),
            originalQty: _item1OriginalQty,
            returnQty: _item1ReturnQty,
            onDecrement: () {
              if (_item1ReturnQty > 1) {
                setState(() => _item1ReturnQty--);
              } else if (_item1ReturnQty == 1) {
                setState(() {
                  _item1ReturnQty = 0;
                  _item1Selected = false;
                });
              }
            },
            onIncrement: () {
              if (_item1ReturnQty < _item1OriginalQty) {
                setState(() {
                  _item1ReturnQty++;
                  _item1Selected = true;
                });
              }
            },
            reasonValue: _item1Reason,
            reasonOptions: const [
              'Size fits too small',
              'Size fits too large',
              'Defective / Damaged',
              'Changed mind',
              'Incorrect item delivered',
            ],
            onReasonChanged: (val) {
              if (val != null) setState(() => _item1Reason = val);
            },
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // Row 2: Raw Denim Jeans
          _buildItemRow(
            isSelected: _item2Selected,
            onToggleSelected: (val) {
              setState(() {
                _item2Selected = val ?? false;
                if (_item2Selected && _item2ReturnQty == 0) _item2ReturnQty = 1;
              });
            },
            imageAsset: 'assets/raw_denim_jeans.jpg',
            fallbackAsset: 'assets/raw_denim_jeans.jpg',
            name: 'Raw Denim Jeans',
            sku: 'RDJ-22322  •  Indigo - L',
            tag: 'Bottoms',
            tagBg: const Color(0xFFFFEDD5),
            tagText: const Color(0xFFC2410C),
            originalQty: _item2OriginalQty,
            returnQty: _item2ReturnQty,
            onDecrement: () {
              if (_item2ReturnQty > 0) {
                setState(() {
                  _item2ReturnQty--;
                  if (_item2ReturnQty == 0) _item2Selected = false;
                });
              }
            },
            onIncrement: () {
              if (_item2ReturnQty < _item2OriginalQty) {
                setState(() {
                  _item2ReturnQty++;
                  _item2Selected = true;
                });
              }
            },
            reasonValue: _item2Reason,
            reasonOptions: const [
              'Select reason',
              'Size fits too small',
              'Defective / Damaged',
              'Changed mind',
              'Incorrect item delivered',
            ],
            onReasonChanged: (val) {
              if (val != null) setState(() => _item2Reason = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow({
    required bool isSelected,
    required ValueChanged<bool?> onToggleSelected,
    required String imageAsset,
    required String fallbackAsset,
    required String name,
    required String sku,
    required String tag,
    required Color tagBg,
    required Color tagText,
    required int originalQty,
    required int returnQty,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required String reasonValue,
    required List<String> reasonOptions,
    required ValueChanged<String?> onReasonChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 32,
            child: InkWell(
              onTap: () => onToggleSelected(!isSelected),
              child: Icon(
                isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 18,
                color: isSelected ? const Color(0xFF181513) : const Color(0xFFCBD5E1),
              ),
            ),
          ),

          // Product Image & Info
          Expanded(
            flex: 38,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    imageAsset,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      fallbackAsset,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.checkroom_rounded, size: 22, color: Color(0xFF94A3B8)),
                      ),
                    ),
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
                      const SizedBox(height: 2),
                      Text(
                        sku,
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: tagBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tag,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: tagText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Original Qty
          Expanded(
            flex: 16,
            child: Center(
              child: Text(
                '$originalQty',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
          ),

          // Return Qty Stepper
          Expanded(
            flex: 22,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: onDecrement,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: const Icon(Icons.remove, size: 14, color: Color(0xFF475569)),
                        ),
                      ),
                      Container(
                        width: 28,
                        alignment: Alignment.center,
                        child: Text(
                          '$returnQty',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: onIncrement,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: const Icon(Icons.add, size: 14, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'of $originalQty',
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // Return Reason Dropdown
          Expanded(
            flex: 24,
            child: Container(
              height: 34,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: reasonOptions.contains(reasonValue) ? reasonValue : reasonOptions.first,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  items: reasonOptions.map((opt) {
                    return DropdownMenuItem<String>(
                      value: opt,
                      child: Text(
                        opt,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: opt == 'Select reason' ? const Color(0xFF9CA3AF) : const Color(0xFF1E293B),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: onReasonChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Card 2: Exchange Option (Optional)
  Widget _buildExchangeOptionCard() {
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
          // Header Row with Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exchange Option (Optional)',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Process as Exchange',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    value: _processAsExchange,
                    activeColor: const Color(0xFFD97706),
                    activeTrackColor: const Color(0xFFFDE68A),
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                    onChanged: (val) => setState(() => _processAsExchange = val),
                  ),
                ],
              ),
            ],
          ),

          if (_processAsExchange) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exchange Oxford Linen Shirt (Black - M) for:',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Product Dropdown
                      Expanded(
                        flex: 5,
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _exchangeProduct,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              items: const [
                                DropdownMenuItem(value: 'Oxford Linen Shirt', child: Text('Oxford Linen Shirt')),
                                DropdownMenuItem(value: 'Merino Wool Crewneck', child: Text('Merino Wool Crewneck')),
                                DropdownMenuItem(value: 'Raw Denim Jeans', child: Text('Raw Denim Jeans')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _exchangeProduct = val);
                              },
                              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E293B)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Size Dropdown
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _exchangeSize,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                              items: const [
                                DropdownMenuItem(value: 'Size S', child: Text('Size S')),
                                DropdownMenuItem(value: 'Size M', child: Text('Size M')),
                                DropdownMenuItem(value: 'Size L', child: Text('Size L')),
                                DropdownMenuItem(value: 'Size XL', child: Text('Size XL')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _exchangeSize = val);
                              },
                              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E293B)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // In Stock Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Color(0xFF15803D)),
                            const SizedBox(width: 6),
                            Text(
                              'In Stock (Delhi Store)',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Card 3: Refund & Summary
  Widget _buildRefundSummaryCard() {
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
            'Refund & Summary',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),

          _buildSummaryLine('Returned items value', '₹${_formatCurrency(_returnedItemsValue)}'),
          const SizedBox(height: 10),
          _buildSummaryLine('Exchanged items cost', '₹${_formatCurrency(_exchangedItemsCost)}'),
          const SizedBox(height: 10),
          _buildSummaryLine('Difference', '₹${_formatCurrency(_difference)}'),
          const SizedBox(height: 10),
          _buildSummaryLine('Restocking fee (5%)', '₹${_formatCurrency(_restockingFee)}'),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Refund Method
          Text(
            'Refund Method',
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
                  DropdownMenuItem(value: 'Refund to original card (...4292)', child: Text('Refund to original card (...4292)')),
                  DropdownMenuItem(value: 'Store Credit Voucher', child: Text('Store Credit Voucher')),
                  DropdownMenuItem(value: 'Cash Refund', child: Text('Cash Refund')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _refundMethod = val);
                },
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E293B)),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Total Refund Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Refund',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                '₹${_formatCurrency(_totalRefund)}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Return / Exchange Processed'),
                    content: const Text('Return #RET-99214 has been recorded. Inventory & restock ledger updated.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          widget.onBackToSales?.call();
                        },
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(
                'Complete Return / Exchange',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.onBackToSales,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Cancel Process',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
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

  // Card 4: Customer Information
  Widget _buildCustomerInfoCard() {
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
            'Customer Information',
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
                child: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emma Carter',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'emma.carter@email.com',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+91 98765 43210',
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
            ],
          ),
        ],
      ),
    );
  }

  // Card 5: Return Policy
  Widget _buildReturnPolicyCard() {
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
              const Icon(Icons.description_outlined, size: 16, color: Color(0xFFD97706)),
              const SizedBox(width: 8),
              Text(
                'Return Policy',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPolicyBullet('Returns accepted within 30 days of purchase'),
          const SizedBox(height: 6),
          _buildPolicyBullet('Items must be in original condition with tags'),
          const SizedBox(height: 6),
          _buildPolicyBullet('Exchange subject to stock availability'),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Full Policy',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFD97706)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
        ),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6B7280),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
