// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class SaleDetailItem {
  final String title;
  final String variant;
  final String sku;
  final String imageAsset;
  final int unitPrice;
  final int quantity;

  const SaleDetailItem({
    required this.title,
    required this.variant,
    required this.sku,
    required this.imageAsset,
    required this.unitPrice,
    required this.quantity,
  });

  int get totalPrice => unitPrice * quantity;
}

class SaleDetailView extends StatefulWidget {
  const SaleDetailView({
    super.key,
    required this.saleId,
    this.onBackToOverview,
  });

  final String saleId;
  final VoidCallback? onBackToOverview;

  @override
  State<SaleDetailView> createState() => _SaleDetailViewState();
}

class _SaleDetailViewState extends State<SaleDetailView> {
  final TextEditingController _noteController = TextEditingController();
  bool _isAddingNote = false;
  String? _savedNote;

  final List<SaleDetailItem> _items = const [
    SaleDetailItem(
      title: 'Oxford Linen Shirt',
      variant: 'Black • M',
      sku: 'TS-10492',
      imageAsset: 'Assets/oxford_linen_shirt_blue.jpg',
      unitPrice: 2490,
      quantity: 2,
    ),
    SaleDetailItem(
      title: 'Raw Denim Jeans',
      variant: 'Indigo • L',
      sku: 'RDJ-22322',
      imageAsset: 'Assets/raw_denim_jeans.jpg',
      unitPrice: 3440,
      quantity: 1,
    ),
    SaleDetailItem(
      title: 'Silk Evening Dress',
      variant: 'Red • S',
      sku: 'SED-16166',
      imageAsset: 'Assets/silk_evening_dress.jpg',
      unitPrice: 5940,
      quantity: 1,
    ),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFBA8A55), size: 18),
            const SizedBox(width: 10),
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
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

  String _formatCurrency(int amount) {
    final str = amount.toString();
    if (str.length <= 3) return str;
    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);
    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(rest[i]);
    }
    return '${buffer.toString()},$lastThree';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 20,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1050;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column (~65% width)
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBreadcrumbAndHeader(),
                          const SizedBox(height: 18),
                          _buildItemsCard(),
                          const SizedBox(height: 18),
                          _buildTransactionActivityCard(),
                          const SizedBox(height: 18),
                          _buildCustomerNotesCard(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Column (~35% width, 380px)
                  SizedBox(
                    width: 380,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCustomerAndPaymentCard(),
                          const SizedBox(height: 18),
                          _buildMoreActionsCard(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // Stacked layout for compact screen
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBreadcrumbAndHeader(),
                  const SizedBox(height: 18),
                  _buildItemsCard(),
                  const SizedBox(height: 18),
                  _buildCustomerAndPaymentCard(),
                  const SizedBox(height: 18),
                  _buildTransactionActivityCard(),
                  const SizedBox(height: 18),
                  _buildCustomerNotesCard(),
                  const SizedBox(height: 18),
                  _buildMoreActionsCard(),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ========================================================
  // 1. BREADCRUMBS & METADATA HEADER
  // ========================================================
  Widget _buildBreadcrumbAndHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb and Action Buttons Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Breadcrumb: Sales > Sale #TS-10482
            Row(
              children: [
                InkWell(
                  onTap: widget.onBackToOverview,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      'Sales',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6E665B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: Color(0xFF9E958A),
                ),
                const SizedBox(width: 8),
                Text(
                  'Sale ${widget.saleId}',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
              ],
            ),

            // Actions: [...] and [Print]
            Row(
              children: [
                // [...] More options
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showFeedback('More options for sale ${widget.saleId}'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDFD6C9)),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.more_horiz_rounded,
                        size: 18,
                        color: Color(0xFF332D26),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // [Print]
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showFeedback('Printing official invoice for ${widget.saleId}...'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDFD6C9)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.print_outlined,
                            size: 16,
                            color: Color(0xFF332D26),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Print',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF332D26),
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
        const SizedBox(height: 10),

        // Metadata row: Date, Time, Location, Cashier, Status
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 6,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF7A7268),
                ),
                const SizedBox(width: 6),
                Text(
                  '16 Sep 2026',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B6358),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('•', style: TextStyle(color: Color(0xFF9E958A))),
                const SizedBox(width: 6),
                Text(
                  '10:42 AM',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B6358),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('•', style: TextStyle(color: Color(0xFF9E958A))),
                const SizedBox(width: 6),
                Text(
                  'Central Store',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B6358),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            Container(width: 1, height: 14, color: const Color(0xFFDFD6C9)),
            Text(
              'Cashier: Priya S.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B6358),
                fontWeight: FontWeight.w400,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC3E6CB)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 13,
                    color: Color(0xFF1E7E34),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Completed',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E7E34),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================
  // 2. ITEMS (3) TABLE CARD
  // ========================================================
  Widget _buildItemsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DDD0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Items (${_items.length})',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 16),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFECE4D8))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Product',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'SKU',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Unit Price',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Quantity',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Color(0xFFF1EAE0),
            ),
            itemBuilder: (context, index) {
              final item = _items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product Column
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 44,
                              height: 44,
                              color: const Color(0xFFF7F4EF),
                              child: Image.asset(
                                item.imageAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.image_outlined,
                                  size: 22,
                                  color: Colors.grey,
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
                                  item.title,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF181513),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.variant,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF7A7268),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // SKU Column
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.sku,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF4A4237),
                        ),
                      ),
                    ),

                    // Unit Price Column
                    Expanded(
                      flex: 3,
                      child: Text(
                        '₹${_formatCurrency(item.unitPrice)}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF181513),
                        ),
                      ),
                    ),

                    // Quantity Column
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                      ),
                    ),

                    // Total Column
                    Expanded(
                      flex: 3,
                      child: Text(
                        '₹${_formatCurrency(item.totalPrice)}',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 3. TRANSACTION ACTIVITY CARD
  // ========================================================
  Widget _buildTransactionActivityCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DDD0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Activity',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 20),

          // Timeline Step 1: Invoice Printed & Finalized
          _buildTimelineStep(
            title: 'Invoice Printed & Finalized',
            timestamp: '10:44 AM • Priya S. (Cashier)',
            rightTagIcon: Icons.receipt_long_outlined,
            rightTagLabel: 'Receipt #RCP-20260916-10482',
            isFirst: true,
            isLast: false,
          ),

          // Timeline Step 2: Payment authorized successfully
          _buildTimelineStep(
            title: 'Payment authorized successfully',
            timestamp: '10:43 AM • UPI Payment Gateway (Ref: 20148812)',
            rightTagIcon: Icons.credit_card_outlined,
            rightTagLabel: 'UPI •••• 4292',
            isFirst: false,
            isLast: false,
          ),

          // Timeline Step 3: Transaction Initiated
          _buildTimelineStep(
            title: 'Transaction Initiated',
            timestamp: '10:42 AM • Priya S. (Cashier)',
            rightTagIcon: Icons.description_outlined,
            rightTagLabel: 'Sale ${widget.saleId}',
            isFirst: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String timestamp,
    required IconData rightTagIcon,
    required String rightTagLabel,
    required bool isFirst,
    required bool isLast,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicator column with icon and vertical connector line
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF1E7E34),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 36,
                color: const Color(0xFFC3E6CB),
              ),
          ],
        ),
        const SizedBox(width: 14),

        // Event Text Info
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timestamp,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7A7268),
                  ),
                ),
                if (!isLast) const SizedBox(height: 14),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Right side Reference Badge
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(rightTagIcon, size: 15, color: const Color(0xFF7A7268)),
            const SizedBox(width: 6),
            Text(
              rightTagLabel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5A5248),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================
  // 4. CUSTOMER NOTES CARD
  // ========================================================
  Widget _buildCustomerNotesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DDD0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Customer Notes + [+ Add Note]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.note_alt_outlined,
                    size: 18,
                    color: Color(0xFFBA8A55),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Customer Notes',
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _isAddingNote = !_isAddingNote),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDFD6C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          size: 15,
                          color: Color(0xFF332D26),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add Note',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF332D26),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Input or Display Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5DDD0)),
            ),
            child: _isAddingNote
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      TextField(
                        controller: _noteController,
                        maxLines: 3,
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181513)),
                        decoration: InputDecoration(
                          hintText: 'Add a note to this sale...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFFA1978A),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _isAddingNote = false),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7A7268)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E1C1A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            onPressed: () {
                              setState(() {
                                _savedNote = _noteController.text.trim();
                                _isAddingNote = false;
                              });
                              _showFeedback('Customer note updated');
                            },
                            child: Text(
                              'Save',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Text(
                    _savedNote?.isNotEmpty == true
                        ? _savedNote!
                        : 'Add a note to this sale...',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: _savedNote?.isNotEmpty == true
                          ? const Color(0xFF181513)
                          : const Color(0xFFA1978A),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 5. RIGHT COLUMN: CUSTOMER & PAYMENT CARD
  // ========================================================
  Widget _buildCustomerAndPaymentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DDD0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Customer & Payment + [Edit]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer & Payment',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showFeedback('Editing customer profile...'),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFDFD6C9)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF332D26)),
                        const SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF332D26),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Customer Info: Avatar + Details
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipOval(
                child: Container(
                  width: 52,
                  height: 52,
                  color: const Color(0xFFFAF7F2),
                  child: Image.asset(
                    'Assets/emma_carter.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.person,
                      size: 28,
                      color: Color(0xFF9E958A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Emma Carter',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF5E6),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFF0DEC0)),
                          ),
                          child: Text(
                            'Regular Customer',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94672D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'emma.carter@gmail.com',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF7A7268),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 13,
                          color: Color(0xFF7A7268),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+91 98765 43210',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5A5248),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFEAE1D5)),
          const SizedBox(height: 14),

          // Pricing Breakdown
          _buildDetailSummaryRow(label: 'Subtotal', value: '₹11,870'),
          const SizedBox(height: 8),
          _buildDetailSummaryRow(
            label: 'Discount Applied',
            value: '-₹1,200',
            valueColor: const Color(0xFF1E7E34),
          ),
          const SizedBox(height: 8),
          _buildDetailSummaryRow(label: 'Tax (CGST 9%)', value: '₹757.80'),
          const SizedBox(height: 8),
          _buildDetailSummaryRow(label: 'Tax (SGST 9%)', value: '₹757.80'),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFEAE1D5)),
          const SizedBox(height: 12),

          // Total Charged (large bold)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Charged',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              Text(
                '₹11,890',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFEAE1D5)),
          const SizedBox(height: 14),

          // Payment Method Row
          Text(
            'Payment Method',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7A7268),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9EFE4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.credit_card_rounded,
                      size: 16,
                      color: Color(0xFFB57E42),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Visa Ending 4292',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC3E6CB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: Color(0xFF1E7E34),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Paid',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E7E34),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action 1: Print Receipt
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showFeedback('Printing official receipt...'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF382718),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E1C1A).withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.print_outlined, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Print Receipt',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Action 2: Email Receipt
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showFeedback('Receipt emailed to emma.carter@gmail.com'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDFD6C9)),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.email_outlined, size: 16, color: Color(0xFF332D26)),
                    const SizedBox(width: 8),
                    Text(
                      'Email Receipt',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF332D26),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Action 3: Return / Exchange Items
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showFeedback('Opening Return / Exchange wizard...'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF5C6CB)),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFC0392B)),
                    const SizedBox(width: 8),
                    Text(
                      'Return / Exchange Items',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC0392B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSummaryRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF6B6358),
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF181513),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // 6. RIGHT COLUMN: MORE ACTIONS CARD
  // ========================================================
  Widget _buildMoreActionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DDD0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'More Actions',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 12),

          // 1. View Invoice
          _buildMoreActionTile(
            icon: Icons.description_outlined,
            title: 'View Invoice',
            onTap: () => _showFeedback('Generating printable PDF invoice...'),
          ),
          const SizedBox(height: 8),

          // 2. Apply Discount
          _buildMoreActionTile(
            icon: Icons.percent_rounded,
            title: 'Apply Discount',
            onTap: () => _showFeedback('Retroactive discount dialog opened'),
          ),
          const SizedBox(height: 8),

          // 3. Create Return
          _buildMoreActionTile(
            icon: Icons.reply_rounded,
            title: 'Create Return',
            onTap: () => _showFeedback('Initiating return order for ${widget.saleId}...'),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF7F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFEADBCA)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 17, color: const Color(0xFFBA8A55)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF332D26),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: Color(0xFF9E958A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
