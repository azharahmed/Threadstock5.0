// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _POLineItem {
  _POLineItem({
    required this.name,
    required this.sku,
    required this.variant,
    required this.available,
    required this.incoming,
    required this.aiRec,
    required this.qtyOrder,
    required this.unitCost,
    required this.imageAsset,
    this.isSelected = false,
  });

  final String name;
  final String sku;
  final String variant;
  final int available;
  final int incoming;
  final int aiRec;
  int qtyOrder;
  final int unitCost;
  final String imageAsset;
  bool isSelected;

  int get totalCost => qtyOrder * unitCost;
}

class CreatePurchaseOrderView extends StatefulWidget {
  const CreatePurchaseOrderView({
    super.key,
    this.onCreateOrder,
    this.onSaveDraft,
  });

  final VoidCallback? onCreateOrder;
  final VoidCallback? onSaveDraft;

  @override
  State<CreatePurchaseOrderView> createState() => _CreatePurchaseOrderViewState();
}

class _CreatePurchaseOrderViewState extends State<CreatePurchaseOrderView> {
  String _selectedSupplier = 'Biella Italian Mills Co.';
  String _selectedShipTo = 'Central Warehouse (Zone A)';
  String _selectedDate = '28 Feb 2027';
  final TextEditingController _referenceController = TextEditingController(text: 'SPRING-REPLENISH-01');
  final TextEditingController _searchController = TextEditingController();
  bool _selectAll = false;
  bool _aiRecommendationApplied = false;

  final List<String> _supplierOptions = [
    'Biella Italian Mills Co.',
    'Milano Tessuti',
    'Bangalore Loom Works',
    'Rajkot Cotton House',
  ];
  final List<String> _warehouseOptions = [
    'Central Warehouse (Zone A)',
    'MG Road Store',
    'Delhi Flagship',
    'Mumbai Hub',
  ];

  late final List<_POLineItem> _lineItems;

  @override
  void initState() {
    super.initState();
    _lineItems = [
      _POLineItem(
        name: 'Oxford Linen Shirt',
        sku: 'TS-10492-BLK-M',
        variant: 'Black / M',
        available: 18,
        incoming: 0,
        aiRec: 52,
        qtyOrder: 40,
        unitCost: 980,
        imageAsset: 'Assets/oxford_linen_shirt.jpg',
      ),
      _POLineItem(
        name: 'Oxford Linen Shirt',
        sku: 'TS-10492-WHT-L',
        variant: 'White / L',
        available: 4,
        incoming: 10,
        aiRec: 40,
        qtyOrder: 40,
        unitCost: 980,
        imageAsset: 'Assets/oxford_linen_shirt.jpg',
      ),
    ];
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  int get _totalQty => _lineItems.fold(0, (sum, i) => sum + i.qtyOrder);
  int get _subtotal => _lineItems.fold(0, (sum, i) => sum + i.totalCost);
  int get _freight => 4500;
  int get _customs => 9408;
  int get _estimatedTotal => _subtotal + _freight + _customs;

  void _applyAIRecommendation() {
    setState(() {
      _aiRecommendationApplied = true;
      for (final item in _lineItems) {
        item.qtyOrder = item.aiRec;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI recommendation applied — quantities updated.'),
        backgroundColor: Color(0xFFB45309),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showQtyEditor(_POLineItem item) {
    final controller = TextEditingController(text: '${item.qtyOrder}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Edit Order Quantity', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF181513))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${item.name} (${item.variant})', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF181513))),
            const SizedBox(height: 4),
            Text('AI Recommended: ${item.aiRec} units', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B))),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Qty to Order',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(controller.text);
              if (v != null && v >= 0) {
                setState(() => item.qtyOrder = v);
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCreateOrderConfirmation() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Create Purchase Order?', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF181513))),
        content: Text(
          'Send PO for $_totalQty items ($_subtotal subtotal) to $_selectedSupplier.\n\nEstimated Total: ₹${_estimatedTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF181513), height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B)))),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Purchase Order created successfully.'), backgroundColor: Color(0xFF181513), behavior: SnackBarBehavior.floating),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Create PO'),
          ),
        ],
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
          _buildHeader(),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _buildHeaderFields(),
                        const SizedBox(height: 16),
                        _buildAIBanner(),
                        const SizedBox(height: 16),
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        _buildLineItemsTable(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(width: 300, child: _buildSummaryPanel()),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderFields(),
                const SizedBox(height: 16),
                _buildAIBanner(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 16),
                _buildLineItemsTable(),
                const SizedBox(height: 24),
                _buildSummaryPanel(),
                const SizedBox(height: 32),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Create Purchase Order', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF181513), letterSpacing: -0.4)),
        const SizedBox(height: 4),
        Text('Select supplier, add items, and create a purchase order.', style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildHeaderFields() {
    return Row(
      children: [
        // Supplier
        Expanded(
          child: _FieldBlock(
            label: 'SUPPLIER',
            child: _DropdownPill(
              value: _selectedSupplier,
              options: _supplierOptions,
              icon: Icons.storefront_outlined,
              onChanged: (v) => setState(() => _selectedSupplier = v),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Ship to
        Expanded(
          child: _FieldBlock(
            label: 'SHIP TO',
            child: _DropdownPill(
              value: _selectedShipTo,
              options: _warehouseOptions,
              icon: Icons.warehouse_outlined,
              onChanged: (v) => setState(() => _selectedShipTo = v),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Expected date
        Expanded(
          child: _FieldBlock(
            label: 'EXPECTED DATE',
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF181513)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_selectedDate, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181513)))),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Reference
        Expanded(
          child: _FieldBlock(
            label: 'REFERENCE',
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 15, color: Color(0xFFB45309)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _referenceController,
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF181513)),
                      decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAIBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: _aiRecommendationApplied ? const Color(0xFFF0FDF4) : const Color(0xFFFFFBF0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _aiRecommendationApplied ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _aiRecommendationApplied ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _aiRecommendationApplied ? Icons.check_circle_rounded : Icons.auto_awesome_rounded,
              size: 18,
              color: _aiRecommendationApplied ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _aiRecommendationApplied ? 'AI Recommendation Applied' : 'AI Prediction Recommendation',
                  style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: _aiRecommendationApplied ? const Color(0xFF16A34A) : const Color(0xFFB45309)),
                ),
                const SizedBox(height: 2),
                Text(
                  _aiRecommendationApplied
                      ? 'Quantities updated to match AI-recommended levels based on Delhi Store demand & 14-day lead time.'
                      : 'Supply metrics suggest ordering a total of 92 units across Oxford styles based on Delhi Store demands & current 14 days mill lead time.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B), height: 1.3),
                ),
              ],
            ),
          ),
          if (!_aiRecommendationApplied) ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: _applyAIRecommendation,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text('Apply Recommendation', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFFB45309))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 17, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181513)),
                    decoration: InputDecoration(
                      hintText: 'Type product name, SKU or barcode to add PO line items...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Scan Item button
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, size: 16, color: Color(0xFFB45309)),
                const SizedBox(width: 6),
                Text('Scan Item', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFFB45309))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineItemsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PO Line Items (${_lineItems.length})', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF181513))),
            Row(
              children: [
                _TableActionBtn(icon: Icons.add_rounded, label: '+ Add Items', color: const Color(0xFFB45309)),
                const SizedBox(width: 8),
                _TableActionBtn(icon: Icons.upload_file_outlined, label: 'Import CSV', color: const Color(0xFF475569)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Checkbox(
                        value: _selectAll,
                        onChanged: (v) => setState(() {
                          _selectAll = v ?? false;
                          for (final item in _lineItems) item.isSelected = _selectAll;
                        }),
                        activeColor: const Color(0xFF181513),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(flex: 4, child: _Th('Product↑')),
                    Expanded(flex: 3, child: _Th('Variant / SKU↑')),
                    Expanded(flex: 2, child: _Th('Available')),
                    Expanded(flex: 2, child: _Th('Incoming')),
                    Expanded(flex: 2, child: _Th('AI Rec')),
                    Expanded(flex: 2, child: _Th('Qty Order')),
                    Expanded(flex: 2, child: _Th('Unit Cost')),
                    Expanded(flex: 2, child: _Th('Total Cost↑')),
                    const SizedBox(width: 24),
                  ],
                ),
              ),

              // Rows
              ..._lineItems.map((item) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Checkbox(
                        value: item.isSelected,
                        onChanged: (v) => setState(() {
                          item.isSelected = v ?? false;
                          _selectAll = _lineItems.every((i) => i.isSelected);
                        }),
                        activeColor: const Color(0xFF181513),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Product
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 38,
                              height: 38,
                              color: const Color(0xFFF1F5F9),
                              child: Image.asset(item.imageAsset, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, size: 18, color: Color(0xFF94A3B8))),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)))),
                        ],
                      ),
                    ),
                    // Variant/SKU
                    Expanded(flex: 3, child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.variant, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF181513))),
                        Text(item.sku, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                      ],
                    )),
                    // Available
                    Expanded(flex: 2, child: Text('${item.available}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181513)))),
                    // Incoming
                    Expanded(flex: 2, child: Text('${item.incoming}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181513)))),
                    // AI Rec pill
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text('Rec: ${item.aiRec}', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFB45309))),
                      ),
                    ),
                    // Qty Order (editable)
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _showQtyEditor(item),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text('${item.qtyOrder}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF181513))),
                        ),
                      ),
                    ),
                    // Unit Cost
                    Expanded(flex: 2, child: Text('₹${item.unitCost}', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181513)))),
                    // Total Cost
                    Expanded(
                      flex: 2,
                      child: Text(
                        '₹${item.totalCost.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF181513)),
                      ),
                    ),
                    // More menu
                    SizedBox(
                      width: 24,
                      child: Icon(Icons.more_vert_rounded, size: 18, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('PO Summary', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF181513))),
        const SizedBox(height: 12),

        // Supplier card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SUPPLIER', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: const Color(0xFF94A3B8))),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.storefront_outlined, size: 17, color: Color(0xFFB45309)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selectedSupplier, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF181513))),
                        Text('Prato, Florence, Italy', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Cost breakdown
        _SummaryRow('Subtotal ($_totalQty items)', '₹${_subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'),
        const SizedBox(height: 8),
        _SummaryRow('Est. Freight & Shipping', '₹${_freight.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'),
        const SizedBox(height: 8),
        _SummaryRow('Customs Duties & Taxes', '₹${_customs.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'),
        const SizedBox(height: 10),
        const Divider(color: Color(0xFFE2E8F0), height: 1),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Estimated Total Cost', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF181513))),
            Text(
              '₹${_estimatedTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF181513)),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Exchange rates note
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFFD97706)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Exchange rates calculated dynamically based on current EUR to INR metrics.',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B), height: 1.35),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Buttons
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton(
            onPressed: widget.onCreateOrder ?? _showCreateOrderConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Create Purchase Order', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            onPressed: widget.onSaveDraft ?? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Draft saved.'), duration: Duration(seconds: 1))),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Save Draft', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF181513))),
          ),
        ),
      ],
    );
  }
}

// Helpers
class _FieldBlock extends StatelessWidget {
  const _FieldBlock({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: const Color(0xFF64748B))),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _DropdownPill extends StatelessWidget {
  const _DropdownPill({required this.value, required this.options, required this.icon, required this.onChanged});
  final String value;
  final List<String> options;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF181513)),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF181513)),
                onChanged: (v) { if (v != null) onChanged(v); },
                items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, overflow: TextOverflow.ellipsis))).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Th extends StatelessWidget {
  const _Th(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)));
  }
}

class _TableActionBtn extends StatelessWidget {
  const _TableActionBtn({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(label, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
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
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF181513))),
      ],
    );
  }
}
