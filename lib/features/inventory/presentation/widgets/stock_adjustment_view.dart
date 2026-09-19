// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StockAdjustmentView extends StatefulWidget {
  const StockAdjustmentView({
    super.key,
    this.onViewHistory,
    this.onAdjustStockCompleted,
    this.onSaveDraft,
    this.initialLocation = 'Central Store',
  });

  final VoidCallback? onViewHistory;
  final VoidCallback? onAdjustStockCompleted;
  final VoidCallback? onSaveDraft;
  final String initialLocation;

  @override
  State<StockAdjustmentView> createState() => _StockAdjustmentViewState();
}

class _StockAdjustmentViewState extends State<StockAdjustmentView> {
  int _currentStep = 1; // 1: Select Product, 2: Adjust Details, 3: Review & Confirm
  bool _isDecrease = true;
  int _quantity = 2;
  final int _currentStock = 24;
  String _selectedReason = 'Damaged';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isProductSelected = true;

  final List<String> _reasons = [
    'Damaged',
    'Lost / Stolen',
    'Found during Audit',
    'Returned by Customer',
    'Sample / Promotion',
    'Expired / Obsolete',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _expectedStock {
    if (_isDecrease) {
      return (_currentStock - _quantity).clamp(0, 999999);
    } else {
      return _currentStock + _quantity;
    }
  }

  void _showHelpGuideModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFD97706), size: 20),
            ),
            const SizedBox(width: 12),
            Text('Stock Adjustment Best Practices', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ThreadStock Inventory Governance & Audit Protocol:',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 12),
              _buildGuideBullet(
                'Mandatory Reason Coding',
                'Every stock deduction must carry a validated reason code (e.g. Damaged, Audit variance) for statutory accounting reconciliations.',
              ),
              const SizedBox(height: 10),
              _buildGuideBullet(
                'Reference Cross-Linking',
                'Link incoming delivery shortages or transit damages directly to their parent PO or carrier claims docket.',
              ),
              const SizedBox(height: 10),
              _buildGuideBullet(
                'Immutable Ledger Entry',
                'Once submitted, adjustments write directly to the double-entry stock journal and cannot be deleted.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideBullet(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
              const SizedBox(height: 2),
              Text(desc, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280), height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header
          _buildHeader(),
          const SizedBox(height: 20),

          // 2. Step Indicator (Wizard)
          _buildStepWizard(),
          const SizedBox(height: 24),

          // 3. Main 2-Column Section
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1020;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Form) (~66%)
                    Expanded(
                      flex: 66,
                      child: _buildAdjustmentFormCard(),
                    ),
                    const SizedBox(width: 24),

                    // Right Column (Summary & Help) (~34%)
                    Expanded(
                      flex: 34,
                      child: Column(
                        children: [
                          _buildSummaryCard(),
                          const SizedBox(height: 20),
                          _buildHelpCard(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Stacked for narrower viewports
              return Column(
                children: [
                  _buildAdjustmentFormCard(),
                  const SizedBox(height: 24),
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildHelpCard(),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 1. Header
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Adjustment',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Correct inventory while maintaining a complete audit trail.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: widget.onViewHistory ??
              () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Viewing complete inventory adjustment audit log.'),
                    backgroundColor: Color(0xFF181513),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
          icon: const Icon(Icons.access_time_rounded, size: 16),
          label: const Text('View Adjustment History'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF374151),
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  // 2. Step Wizard
  Widget _buildStepWizard() {
    return Row(
      children: [
        // Step 1: Select Product
        InkWell(
          onTap: () => setState(() => _currentStep = 1),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _currentStep >= 1 ? const Color(0xFF865D36) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '1',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _currentStep >= 1 ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Select Product',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: _currentStep == 1 ? FontWeight.w700 : FontWeight.w500,
                  color: _currentStep >= 1 ? const Color(0xFF865D36) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Container(width: 48, height: 1, color: const Color(0xFFCBD5E1)),
        const SizedBox(width: 14),

        // Step 2: Adjust Details
        InkWell(
          onTap: () => setState(() => _currentStep = 2),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _currentStep >= 2 ? const Color(0xFF865D36) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '2',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _currentStep >= 2 ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Adjust Details',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: _currentStep >= 2 ? FontWeight.w700 : FontWeight.w500,
                  color: _currentStep >= 2 ? const Color(0xFF865D36) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Container(width: 48, height: 1, color: const Color(0xFFCBD5E1)),
        const SizedBox(width: 14),

        // Step 3: Review & Confirm
        InkWell(
          onTap: () => setState(() => _currentStep = 3),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _currentStep >= 3 ? const Color(0xFF865D36) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '3',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _currentStep >= 3 ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Review & Confirm',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: _currentStep >= 3 ? FontWeight.w700 : FontWeight.w500,
                  color: _currentStep >= 3 ? const Color(0xFF865D36) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. Left Adjustment Form Card
  Widget _buildAdjustmentFormCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Selection Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, color: Color(0xFF92400E), size: 19),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Product Selection',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Search for a product by name, SKU or scan barcode.',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Handheld barcode scanner active (Awaiting input)...'),
                      backgroundColor: Color(0xFF181513),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 15),
                label: const Text('Scan Barcode'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Field
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search product, SKU or barcode...',
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Selected Product Card
          if (_isProductSelected)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  // Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/oxford_linen_shirt.jpg',
                      width: 52,
                      height: 52,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 52,
                        height: 52,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title + SKU + Category Pill
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Oxford Linen Shirt',
                          style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'SKU: TS-10492-BLK-M   |   Black   |   Size: M',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Apparel  >  Shirts',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Current Stock & Close Button
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() => _isProductSelected = false);
                        },
                        child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 18, color: Color(0xFFB45309)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Stock',
                                style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF6B7280)),
                              ),
                              Text(
                                '$_currentStock units',
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Adjustment Parameters Row: Adjustment Type + Quantity Adjustment + New Expected Stock
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Adjustment Type
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Adjustment Type',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Decrease Stock
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isDecrease = true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: _isDecrease ? const Color(0xFFFFFBEB) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isDecrease ? const Color(0xFFB45309) : const Color(0xFFD1D5DB),
                                  width: _isDecrease ? 1.5 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.remove_circle, size: 15, color: _isDecrease ? const Color(0xFFB45309) : const Color(0xFF6B7280)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Decrease Stock',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: _isDecrease ? const Color(0xFFB45309) : const Color(0xFF4B5563),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Increase Stock
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _isDecrease = false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: !_isDecrease ? const Color(0xFFFFFBEB) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !_isDecrease ? const Color(0xFFB45309) : const Color(0xFFD1D5DB),
                                  width: !_isDecrease ? 1.5 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle, size: 15, color: !_isDecrease ? const Color(0xFFB45309) : const Color(0xFF6B7280)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Increase Stock',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: !_isDecrease ? const Color(0xFFB45309) : const Color(0xFF4B5563),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Quantity Adjustment Stepper
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quantity Adjustment',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: () {
                              if (_quantity > 1) {
                                setState(() => _quantity--);
                              }
                            },
                          ),
                          Expanded(
                            child: Text(
                              '$_quantity',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: () {
                              setState(() => _quantity++);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // New Expected Stock Box
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Expected Stock',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isDecrease ? const Color(0xFFFEF2F2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$_expectedStock units',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: _isDecrease ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Reason for Adjustment & Reference Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reason for Adjustment
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason for Adjustment',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedReason,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6B7280)),
                          items: _reasons.map((r) {
                            return DropdownMenuItem(
                              value: r,
                              child: Row(
                                children: [
                                  const Icon(Icons.grid_view_rounded, size: 15, color: Color(0xFF4B5563)),
                                  const SizedBox(width: 8),
                                  Text(r, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827))),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedReason = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Reference (Optional)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reference (Optional)',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 16, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _refController,
                              style: GoogleFonts.inter(fontSize: 13),
                              decoration: const InputDecoration(
                                hintText: 'e.g. PO-9482, Damaged in Transit',
                                hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                                border: InputBorder.none,
                                isDense: true,
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
          ),
          const SizedBox(height: 18),

          // Notes (Optional)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notes (Optional)',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _notesController,
                            maxLines: 3,
                            style: GoogleFonts.inter(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Add any additional details regarding this adjustment...',
                              hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF9CA3AF)),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${_notesController.text.length}/500',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stock Impact Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB).withOpacity(0.55),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF92400E)),
                    const SizedBox(width: 6),
                    Text(
                      'Stock Impact Preview',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Current
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_currentStock',
                          style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                        ),
                        Text(
                          'Current Stock',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    const Icon(Icons.arrow_forward_rounded, color: Color(0xFFB45309), size: 18),
                    const SizedBox(width: 24),

                    // New
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_expectedStock',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _isDecrease ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                          ),
                        ),
                        Text(
                          'New Stock',
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),

                    // Change pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isDecrease ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_isDecrease ? '-' : '+'}$_quantity units',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _isDecrease ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Text(
                        'This adjustment will be recorded in the inventory audit log.',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. Right Summary Card
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: Color(0xFF92400E), size: 20),
              const SizedBox(width: 10),
              Text(
                'Adjustment Summary',
                style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Location
          _buildSummaryRow(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: widget.initialLocation,
          ),
          const SizedBox(height: 14),

          // Product
          _buildSummaryRow(
            icon: Icons.inventory_2_outlined,
            label: 'Product',
            value: 'Oxford Linen Shirt',
            subValue: 'TS-10492-BLK-M',
          ),
          const SizedBox(height: 14),

          // Current Stock
          _buildSummaryRow(
            icon: Icons.inventory_outlined,
            label: 'Current Stock',
            value: '$_currentStock units',
          ),
          const SizedBox(height: 14),

          // Adjustment
          _buildSummaryRow(
            icon: Icons.remove_circle_outline_rounded,
            label: 'Adjustment',
            value: '${_isDecrease ? '-' : '+'}$_quantity units',
            valueColor: _isDecrease ? const Color(0xFFDC2626) : const Color(0xFF15803D),
          ),
          const SizedBox(height: 14),

          // New Expected Stock
          _buildSummaryRow(
            icon: Icons.layers_outlined,
            label: 'New Expected Stock',
            value: '$_expectedStock units',
          ),
          const SizedBox(height: 20),

          // Warning Notice Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB).withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action will create a permanent inventory activity record with timestamp, user and reason.',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF78350F), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Primary Button: Adjust Stock
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Stock for Oxford Linen Shirt successfully adjusted to $_expectedStock units.'),
                    backgroundColor: const Color(0xFF181513),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                widget.onAdjustStockCompleted?.call();
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Adjust Stock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Button: Save as Draft
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Adjustment saved as draft in inventory queue.'),
                    backgroundColor: Color(0xFF181513),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                widget.onSaveDraft?.call();
              },
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text('Save as Draft'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    String? subValue,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                textAlign: TextAlign.end,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? const Color(0xFF111827),
                ),
              ),
              if (subValue != null) ...[
                const SizedBox(height: 2),
                Text(
                  subValue,
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // 5. Help Card
  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFB45309), size: 20),
              const SizedBox(width: 8),
              Text(
                'Need Help?',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Learn more about stock adjustments and best practices.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _showHelpGuideModal,
            child: Row(
              children: [
                Text(
                  'View Help Guide',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFFB45309)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFB45309)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
