// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReturnItemData {
  ReturnItemData({
    required this.name,
    required this.sku,
    required this.variant,
    required this.receivedQty,
    required this.returnQty,
    required this.reason,
    required this.unitCost,
    required this.imageAsset,
    this.isSelected = false,
  });

  final String name;
  final String sku;
  final String variant;
  final int receivedQty;
  int returnQty;
  String reason;
  final int unitCost;
  final String imageAsset;
  bool isSelected;

  int get creditExpected => returnQty * unitCost;
}

class ReturnToSupplierView extends StatefulWidget {
  const ReturnToSupplierView({
    super.key,
    this.poNumber = '',
    this.supplier = '',
    this.poDate = '-',
    this.receivedDate = '-',
    this.onViewOriginalPo,
    this.onCreatePurchaseReturn,
    this.onSaveDraft,
  });

  final String poNumber;
  final String supplier;
  final String poDate;
  final String receivedDate;
  final VoidCallback? onViewOriginalPo;
  final VoidCallback? onCreatePurchaseReturn;
  final VoidCallback? onSaveDraft;

  @override
  State<ReturnToSupplierView> createState() => _ReturnToSupplierViewState();
}

class _ReturnToSupplierViewState extends State<ReturnToSupplierView> {
  bool _selectAll = false;

  late final List<ReturnItemData> _items;

  @override
  void initState() {
    super.initState();
    _items = [];
  }

  int get _totalUnitsReturned =>
      _items.fold<int>(0, (sum, item) => sum + item.returnQty);

  int get _totalExpectedCredit =>
      _items.fold<int>(0, (sum, item) => sum + item.creditExpected);

  void _toggleSelectAll(bool? val) {
    setState(() {
      _selectAll = val ?? false;
      for (final item in _items) {
        item.isSelected = _selectAll;
      }
    });
  }

  void _showEditQtyDialog(ReturnItemData item) {
    final controller = TextEditingController(text: '${item.returnQty}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Edit Return Quantity',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181513),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.name} (${item.variant})',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Received: ${item.receivedQty} units • Unit Cost: ₹${item.unitCost}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                labelText: 'Return Quantity',
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text);
              if (newQty != null && newQty >= 0 && newQty <= item.receivedQty) {
                setState(() {
                  item.returnQty = newQty;
                });
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    // Format Indian Rupee currency
    final str = amount.toString();
    if (str.length <= 3) return '₹$str';
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final formattedRest = rest.replaceAllMapped(
      RegExp(r'(\d+?)(?=(\d\d)+$)'),
      (m) => '${m[1]},',
    );
    return '₹$formattedRest,$lastThree';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1060;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Header, PO Info Cards, Table
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),
                      _buildPoInfoCards(),
                      const SizedBox(height: 24),
                      _buildReceivedItemsSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Column: Return Summary Card + Supplier Info Card
                SizedBox(
                  width: 350,
                  child: Column(
                    children: [
                      _buildReturnSummaryCard(),
                      const SizedBox(height: 18),
                      _buildSupplierInfoCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            );
          }

          // Stacked layout for compact screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildPoInfoCards(),
              const SizedBox(height: 24),
              _buildReceivedItemsSection(),
              const SizedBox(height: 24),
              _buildReturnSummaryCard(),
              const SizedBox(height: 18),
              _buildSupplierInfoCard(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // 1. Header with Title, Subtitle, and View Original PO button
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Return to Supplier',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Review received items, specify return quantities and reasons, and create a supplier return.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: widget.onViewOriginalPo,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Original PO',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFB45309),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Color(0xFFB45309),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 2. 4 Summary Info KPI Cards (Original PO, Supplier, PO Date, Received Date)
  Widget _buildPoInfoCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 640;

        if (isSmall) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildPoCard(
                      icon: Icons.article_outlined,
                      label: 'ORIGINAL PO',
                      value: widget.poNumber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPoCard(
                      icon: Icons.storefront_outlined,
                      label: 'SUPPLIER',
                      value: widget.supplier,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildPoCard(
                      icon: Icons.calendar_today_outlined,
                      label: 'PO DATE',
                      value: widget.poDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildPoCard(
                      icon: Icons.local_shipping_outlined,
                      label: 'RECEIVED DATE',
                      value: widget.receivedDate,
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildPoCard(
                icon: Icons.article_outlined,
                label: 'ORIGINAL PO',
                value: widget.poNumber,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildPoCard(
                icon: Icons.storefront_outlined,
                label: 'SUPPLIER',
                value: widget.supplier,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildPoCard(
                icon: Icons.calendar_today_outlined,
                label: 'PO DATE',
                value: widget.poDate,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildPoCard(
                icon: Icons.local_shipping_outlined,
                label: 'RECEIVED DATE',
                value: widget.receivedDate,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
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
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: const Color(0xFFB45309)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Received Items Section with Interactive Return Table
  Widget _buildReceivedItemsSection() {
    if (widget.poNumber.isEmpty || _items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFBF4EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 36,
                color: Color(0xFF92400E),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No purchase order selected',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select a received purchase order from the PO list to initiate a return to supplier.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Received Items',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181513),
          ),
        ),
        const SizedBox(height: 12),

        // Table Container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
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
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Checkbox(
                        value: _selectAll,
                        onChanged: _toggleSelectAll,
                        activeColor: const Color(0xFF181513),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Product',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Variant',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        'Received Qty',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 85,
                      child: Text(
                        'Return Qty',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: Text(
                        'Reason',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 75,
                      child: Text(
                        'Unit Cost',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 95,
                      child: Text(
                        'Credit Expected',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Rows
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                final isLast = index == _items.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: item.isSelected
                        ? const Color(0xFFFBF8F3)
                        : Colors.white,
                    border: isLast
                        ? null
                        : const Border(
                            bottom: BorderSide(color: Color(0xFFF1F5F9)),
                          ),
                  ),
                  child: Row(
                    children: [
                      // Checkbox
                      SizedBox(
                        width: 28,
                        child: Checkbox(
                          value: item.isSelected,
                          onChanged: (val) {
                            setState(() {
                              item.isSelected = val ?? false;
                              _selectAll = _items.every((i) => i.isSelected);
                            });
                          },
                          activeColor: const Color(0xFF181513),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Product Thumbnail + Info
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                item.imageAsset,
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 42,
                                  height: 42,
                                  color: const Color(0xFFE2E8F0),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    size: 20,
                                    color: Color(0xFF94A3B8),
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
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF181513),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.sku,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Variant
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.variant,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),

                      // Received Qty
                      SizedBox(
                        width: 90,
                        child: Text(
                          '${item.receivedQty}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),

                      // Return Qty (Interactive Pill Box)
                      SizedBox(
                        width: 85,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => _showEditQtyDialog(item),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 54,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Text(
                                '${item.returnQty}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF181513),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Reason (Dropdown Pill)
                      SizedBox(
                        width: 140,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: PopupMenuButton<String>(
                            tooltip: 'Select return reason',
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            onSelected: (val) {
                              setState(() {
                                item.reason = val;
                              });
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'Damaged',
                                child: Text('Damaged'),
                              ),
                              const PopupMenuItem(
                                value: 'Quality Issue',
                                child: Text('Quality Issue'),
                              ),
                              const PopupMenuItem(
                                value: 'Wrong Item',
                                child: Text('Wrong Item'),
                              ),
                              const PopupMenuItem(
                                value: 'Excess Inventory',
                                child: Text('Excess Inventory'),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFCBD5E1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.reason,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF181513),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 16,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Unit Cost
                      SizedBox(
                        width: 75,
                        child: Text(
                          '₹${item.unitCost}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),

                      // Credit Expected
                      SizedBox(
                        width: 95,
                        child: Text(
                          _formatCurrency(item.creditExpected),
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Right Column: Return Summary Card
  Widget _buildReturnSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Return Summary',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 14),

          _buildSummaryRow('Original PO', widget.poNumber),
          const SizedBox(height: 10),
          _buildSummaryRow('Supplier', widget.supplier),
          const SizedBox(height: 10),
          _buildSummaryRow('PO Date', widget.poDate),
          const SizedBox(height: 10),
          _buildSummaryRow('Received Date', widget.receivedDate),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 14),

          _buildSummaryRow(
            'Units Returned',
            '$_totalUnitsReturned units',
            isBold: true,
          ),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Inventory Reduction',
            '-$_totalUnitsReturned units',
            valueColor: const Color(0xFFDC2626),
            isBold: true,
          ),
          const SizedBox(height: 16),

          // Expected Credit Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on_outlined,
                      size: 20,
                      color: Color(0xFFD97706),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Expected Credit',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatCurrency(_totalExpectedCredit),
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Warning Alert Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Completing this return will remove $_totalUnitsReturned units from available inventory.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Primary: Create Purchase Return (Solid Black with plane icon)
          Container(
            width: double.infinity,
            height: 42,
            decoration: BoxDecoration(
              color: (widget.poNumber.isEmpty || _items.isEmpty)
                  ? const Color(0xFFE2E8F0)
                  : const Color(0xFF181513),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InkWell(
              onTap: (widget.poNumber.isEmpty || _items.isEmpty)
                  ? null
                  : widget.onCreatePurchaseReturn,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.near_me_outlined,
                    size: 16,
                    color: (widget.poNumber.isEmpty || _items.isEmpty)
                        ? const Color(0xFF94A3B8)
                        : Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Create Purchase Return',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: (widget.poNumber.isEmpty || _items.isEmpty)
                          ? const Color(0xFF94A3B8)
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary: Save Draft (Outline Button with document icon)
          InkWell(
            onTap: (widget.poNumber.isEmpty || _items.isEmpty)
                ? null
                : widget.onSaveDraft,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (widget.poNumber.isEmpty || _items.isEmpty)
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 15,
                    color: (widget.poNumber.isEmpty || _items.isEmpty)
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF181513),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Save Draft',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: (widget.poNumber.isEmpty || _items.isEmpty)
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF181513),
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

  // 5. Right Column: Supplier Information Card
  Widget _buildSupplierInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supplier Information',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 14),

          // Supplier badge row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  size: 18,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.supplier.isEmpty
                        ? 'No Supplier Selected'
                        : widget.supplier,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.supplier.isEmpty
                        ? 'Linked to purchase order'
                        : 'Supplier Partner',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 14),

          // Contact Details
          _buildSupplierContactRow(
            Icons.mail_outline_rounded,
            widget.supplier.isEmpty ? 'No email linked' : 'orders@supplier.com',
          ),
          const SizedBox(height: 10),
          _buildSupplierContactRow(
            Icons.phone_outlined,
            widget.supplier.isEmpty ? 'No phone linked' : 'Primary phone',
          ),
          const SizedBox(height: 10),
          _buildSupplierContactRow(
            Icons.location_on_outlined,
            widget.supplier.isEmpty
                ? 'No address specified'
                : 'Supplier Address',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? const Color(0xFF181513),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
