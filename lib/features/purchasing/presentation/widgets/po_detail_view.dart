// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class PoItemLine {
  final int index;
  final String name;
  final String categoryDetails;
  final String itemCode;
  final String quantity;
  final int unitPrice;
  final int totalPrice;
  final String imageAsset;

  const PoItemLine({
    required this.index,
    required this.name,
    required this.categoryDetails,
    required this.itemCode,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.imageAsset,
  });
}

class PoDetailView extends StatefulWidget {
  const PoDetailView({
    super.key,
    this.poNumber = 'PO-8902',
    this.onBackToOverview,
  });

  final String poNumber;
  final VoidCallback? onBackToOverview;

  @override
  State<PoDetailView> createState() => _PoDetailViewState();
}

class _PoDetailViewState extends State<PoDetailView> {
  String _approvalStatus = 'Awaiting Approval';

  final List<PoItemLine> _items = const [];

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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Awaiting Approval Banner
              _buildApprovalBanner(),
              const SizedBox(height: 20),

              // 2. Breadcrumbs, Heading PO-8902, Supplier & Date Tags
              _buildPoHeaderSection(),
              const SizedBox(height: 20),

              // 3. Approval Flow Status Stepper Card
              _buildApprovalFlowCard(),
              const SizedBox(height: 20),

              // 4. Order Items (3) Table Card with Terms, Notes & Total Order Value
              _buildOrderItemsCard(),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // 1. AWAITING APPROVAL TOP BANNER
  // ========================================================
  Widget _buildApprovalBanner() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Warning Icon Box
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFC28835),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Message details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Awaiting Approval',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'This purchase order exceeds the approval threshold. Pending review from the business owner.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B6358),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Actions: Reject Order + Approve & Send
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reject Order
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() => _approvalStatus = 'Rejected');
                    _showFeedback(
                      'Purchase Order rejected and returned to requester',
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE57373)),
                    ),
                    child: Text(
                      'Reject Order',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFC0392B),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Approve & Send
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() => _approvalStatus = 'Approved');
                    _showFeedback(
                      'Purchase Order approved and transmitted to supplier',
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF382718),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E1C1A).withOpacity(0.12),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Approve & Send',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 2. BREADCRUMB & PO TITLE HEADER ROW
  // ========================================================
  Widget _buildPoHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb: Purchasing > Purchase Orders
        Row(
          children: [
            InkWell(
              onTap: widget.onBackToOverview,
              borderRadius: BorderRadius.circular(4),
              child: Text(
                'Purchasing',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6E665B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              size: 15,
              color: Color(0xFF9E958A),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: widget.onBackToOverview,
              borderRadius: BorderRadius.circular(4),
              child: Text(
                'Purchase Orders',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6E665B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Main Title Row: PO-8902 + Status Badge + Right Badges
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: PO Number + Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.poNumber,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDF5E6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0DEC0)),
                  ),
                  child: Text(
                    _approvalStatus,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94672D),
                    ),
                  ),
                ),
              ],
            ),

            // Right: Supplier, Created Date, More Actions
            Row(
              children: [
                // Supplier Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFDFD6C9)),
                  ),
                  child: Text(
                    'Supplier: Partner',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3A342C),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Created Date Tag
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFDFD6C9)),
                  ),
                  child: Text(
                    'Created: —',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF3A342C),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // [...] Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () =>
                        _showFeedback('More actions for ${widget.poNumber}'),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(6),
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
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================
  // 3. APPROVAL FLOW STATUS CARD
  // ========================================================
  Widget _buildApprovalFlowCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5DDD0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Approval Flow Status',
            style: GoogleFonts.inter(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 18),

          // Flow Row with 3 Steps and connecting lines
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 1: Created
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'by Operations Team',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Connecting Line 1 (Green)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(top: 10),
                  color: const Color(0xFF81C784),
                ),
              ),
              const SizedBox(width: 14),

              // Step 2: Submitted for Approval
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Submitted for Approval',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Automatically submitted (threshold check passed)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Connecting Line 2 (Amber)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(top: 10),
                  color: const Color(0xFFF0DEC0),
                ),
              ),
              const SizedBox(width: 14),

              // Step 3: Awaiting Owner Signature
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFC28835),
                        width: 2.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Awaiting Owner Signature',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF94672D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Business Owner notified • Pending',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 4. ORDER ITEMS (3) CARD WITH TABLE & FINANCIALS
  // ========================================================
  Widget _buildOrderItemsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5DDD0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order Items + [Edit Order] [Download PDF] [Print]
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Items (${_items.length})',
                style: GoogleFonts.inter(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              Row(
                children: [
                  // Edit Order
                  _buildOrderActionButton(
                    icon: Icons.edit_outlined,
                    label: 'Edit Order',
                    onTap: () => _showFeedback('Editing order line items...'),
                  ),
                  const SizedBox(width: 8),

                  // Download PDF
                  _buildOrderActionButton(
                    icon: Icons.description_outlined,
                    label: 'Download PDF',
                    onTap: () =>
                        _showFeedback('Downloading ${widget.poNumber} PDF...'),
                  ),
                  const SizedBox(width: 8),

                  // Print
                  _buildOrderActionButton(
                    icon: Icons.print_outlined,
                    label: 'Print',
                    onTap: () => _showFeedback(
                      'Sending ${widget.poNumber} to office printer...',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Items Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFECE4D8))),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '#',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Text(
                    'Item & Details',
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
                    'Item Code',
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
                    'Quantity',
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
                    textAlign: TextAlign.right,
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
                    'Total Price',
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
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Text(
                  'No items recorded for this purchase order.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF7A7268),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFF0E8DD)),
              itemBuilder: (context, index) {
                final item = _items[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Index
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${item.index}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),

                      // Item & Details (Thumbnail + Title + Subtitle)
                      Expanded(
                        flex: 6,
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
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.image_outlined,
                                        size: 20,
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
                                    item.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF181513),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.categoryDetails,
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

                      // Item Code
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.itemCode,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5A5248),
                          ),
                        ),
                      ),

                      // Quantity
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.quantity,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),

                      // Unit Price
                      Expanded(
                        flex: 3,
                        child: Text(
                          '₹${_formatCurrency(item.unitPrice)}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF5A5248),
                          ),
                        ),
                      ),

                      // Total Price
                      Expanded(
                        flex: 3,
                        child: Text(
                          '₹${_formatCurrency(item.totalPrice)}',
                          textAlign: TextAlign.right,
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
              },
            ),
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFE8DFD3)),
          const SizedBox(height: 18),

          // Bottom Section: Payment terms + Notes (Left) vs Financial Summary (Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Terms + Notes
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Terms: Net 30',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B6358),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shipping Method: Express Sea Cargo',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6B6358),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5DDD0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.note_alt_outlined,
                            size: 16,
                            color: Color(0xFFBA8A55),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notes',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF181513),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'No notes attached.',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF6B6358),
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
              ),
              const SizedBox(width: 32),

              // Right: Subtotal, Taxes, Total Order Value
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF6B6358),
                          ),
                        ),
                        Text(
                          '₹0.00',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Taxes & Fees',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF6B6358),
                          ),
                        ),
                        Text(
                          '₹0.00',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Total Order Value Highlighted Box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF6EF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFEDE0CF)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Order Value',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          Text(
                            '₹0.00',
                            style: GoogleFonts.inter(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF181513),
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
        ],
      ),
    );
  }

  Widget _buildOrderActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
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
              Icon(icon, size: 14, color: const Color(0xFF332D26)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF332D26),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
