// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReceiveItemData {
  ReceiveItemData({
    required this.name,
    required this.sku,
    required this.category,
    required this.unit,
    required this.expectedQty,
    required this.receivedQty,
    required this.conditionStatus,
    required this.imageAsset,
    this.isSelected = false,
  });

  final String name;
  final String sku;
  final String category;
  final String unit;
  final int expectedQty;
  int receivedQty;
  String conditionStatus;
  final String imageAsset;
  bool isSelected;

  int get variance => receivedQty - expectedQty;
  double get variancePercent =>
      expectedQty > 0 ? ((receivedQty - expectedQty) / expectedQty) * 100 : 0.0;
}

class ReceiveTransferView extends StatefulWidget {
  const ReceiveTransferView({
    super.key,
    this.transferId = 'TR-NEW',
    this.supplier = 'Primary Supplier',
    this.categoriesCount = '0 Categories',
    this.expectedDelivery = 'Feb 15, 2027',
    this.receivedBy = 'Store Manager (Admin)',
    this.logTimestamp = 'Feb 15, 2027  10:32 AM',
    this.status = 'In Receiving',
    this.sourceName = 'Main Facility',
    this.sourceDetails = 'Zone A • Main Facility',
    this.destName = 'Storage Facility',
    this.destDetails = 'Zone A',
    this.createdBy = 'Store Manager',
    this.createdOn = '15 Feb 2027, 10:32 AM',
    this.overallStatus = 'In Receiving',
    this.onViewTransfer,
    this.onCompleteReceiving,
    this.onPrintReport,
    this.onSaveDraft,
  });

  final String transferId;
  final String supplier;
  final String categoriesCount;
  final String expectedDelivery;
  final String receivedBy;
  final String logTimestamp;
  final String status;
  final String sourceName;
  final String sourceDetails;
  final String destName;
  final String destDetails;
  final String createdBy;
  final String createdOn;
  final String overallStatus;
  final VoidCallback? onViewTransfer;
  final VoidCallback? onCompleteReceiving;
  final VoidCallback? onPrintReport;
  final VoidCallback? onSaveDraft;

  @override
  State<ReceiveTransferView> createState() => _ReceiveTransferViewState();
}

class _ReceiveTransferViewState extends State<ReceiveTransferView> {
  bool _selectAll = false;
  bool _aiAutoMatchActive = true;
  late final TextEditingController _discrepancyNotesController;
  late final List<ReceiveItemData> _items;
  final Map<int, TextEditingController> _qtyControllers = {};

  final List<String> _conditionOptions = [
    'Good Condition',
    '8 Missing',
    'Missing',
    'Damaged',
    'Wrong Item',
  ];

  @override
  void initState() {
    super.initState();
    _discrepancyNotesController = TextEditingController();

    _items = [];

    for (int i = 0; i < _items.length; i++) {
      _qtyControllers[i] = TextEditingController(
        text: '${_items[i].receivedQty}',
      );
    }
  }

  @override
  void dispose() {
    _discrepancyNotesController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  int get _totalExpected =>
      _items.fold<int>(0, (sum, i) => sum + i.expectedQty);

  int get _totalReceived =>
      _items.fold<int>(0, (sum, i) => sum + i.receivedQty);

  int get _totalVariance => _totalReceived - _totalExpected;

  int get _verifiedCount =>
      _items.where((i) => i.isSelected || i.receivedQty > 0).length;

  void _toggleSelectAll(bool? val) {
    setState(() {
      _selectAll = val ?? false;
      for (final item in _items) {
        item.isSelected = _selectAll;
      }
    });
  }

  void _showScanItemsModal() {
    final skuController = TextEditingController();
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
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFFB45309),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Barcode & SKU Scanner',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                Text(
                  'Main Facility (Zone A)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.barcode_reader,
                    size: 46,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Point scanner at item barcode or label',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Camera active • Auto-detecting code format',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: skuController,
              decoration: InputDecoration(
                hintText: 'Enter SKU manually (e.g. SLK-PL-M85)',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
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
              'Close',
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
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
                        'Barcode verified and matched with purchase order item.',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Verify SKU'),
          ),
        ],
      ),
    );
  }

  void _showAddItemModal() {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final expectedCtrl = TextEditingController(text: '100');
    final unitCtrl = TextEditingController(text: 'Meters');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Add Incoming Item to PO',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g. Mulberry Crepe Silk',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: skuCtrl,
              decoration: InputDecoration(
                labelText: 'SKU',
                hintText: 'e.g. SLK-CRP-01',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: expectedCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Expected Qty',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: unitCtrl,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
              ],
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
              final exp = int.tryParse(expectedCtrl.text) ?? 100;
              final name = nameCtrl.text.trim().isEmpty
                  ? 'Italian Linen Blend'
                  : nameCtrl.text.trim();
              final sku = skuCtrl.text.trim().isEmpty
                  ? 'SKU: LIN-IT-12'
                  : 'SKU: ${skuCtrl.text.trim()}';

              setState(() {
                final newItem = ReceiveItemData(
                  name: name,
                  sku: sku,
                  category: 'Category: Linen Textiles',
                  unit: unitCtrl.text.trim().isEmpty
                      ? 'Meters'
                      : unitCtrl.text.trim(),
                  expectedQty: exp,
                  receivedQty: exp,
                  conditionStatus: 'Good Condition',
                  imageAsset: '',
                  isSelected: true,
                );
                _items.add(newItem);
                final newIdx = _items.length - 1;
                _qtyControllers[newIdx] = TextEditingController(
                  text: '${newItem.receivedQty}',
                );
              });
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  void _showAiSuggestionsModal() {
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
                border: Border.all(color: const Color(0xFFFDE68A)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'ThreadStock AI Receiving Insights',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFFB45309),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'AI Auto-Match analyzed purchase order PO-0847 against supplier advance shipping notice.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF78350F),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSuggestionRow(
                icon: Icons.check_circle_outline_rounded,
                iconColor: const Color(0xFF16A34A),
                title: 'Silk Fabric Match: 100%',
                description:
                    '500 Meters of Premium Raw Silk Blend matches Lot #IT-8841 exactly with no dimensional variance.',
              ),
              const SizedBox(height: 12),
              _buildSuggestionRow(
                icon: Icons.warning_amber_rounded,
                iconColor: const Color(0xFFD97706),
                title: 'Worsted Wool Discrepancy: -8 Kgs',
                description:
                    'Expected 350 Kgs, scanned 342 Kgs. Freight carrier noted Box 4 seal damage at customs checkpoint.',
              ),
              const SizedBox(height: 12),
              _buildSuggestionRow(
                icon: Icons.lightbulb_outline_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'Recommended Action',
                description:
                    'Accept 342 Kgs as Partial, generate Carrier Damage Claim #CC-842, and auto-credit vendor invoice by €360.00.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Dismiss',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'AI recommendations applied to receipt ledger.',
                  ),
                  backgroundColor: Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Apply AI Actions'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF4B5563),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCompleteReceivingModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF16A34A),
              size: 24,
            ),
            const SizedBox(width: 10),
            Text(
              'Complete Receipt for ${widget.transferId}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Completing this receipt will post $_totalReceived units to ${widget.destName} available inventory and generate stock intake ledger entries.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),
            if (_totalVariance < 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 18,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Variance Notice: ${_totalVariance.abs()} unit(s) recorded as discrepancy under receiving manifest.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Receipt for ${widget.transferId} completed successfully.',
                  ),
                  backgroundColor: const Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Confirm Receipt'),
          ),
        ],
      ),
    );
  }

  void _showPrintReportModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(
              Icons.print_outlined,
              color: Color(0xFF181513),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Receiving Report Preview',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'THREADSTOCK RECEIVING MANIFEST',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'PO: ${widget.transferId} • Supplier: ${widget.supplier}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      'Location: ${widget.destName} (${widget.destDetails})',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      'Logged By: ${widget.receivedBy} on ${widget.logTimestamp}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const Divider(height: 20),
                    for (final item in _items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${item.receivedQty}/${item.expectedQty} ${item.unit} (${item.conditionStatus})',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Units Received:',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$_totalReceived / $_totalExpected Units',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Print job sent to thermal warehouse printer.'),
                  backgroundColor: Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print Manifest'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
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
          // 1. Top Page Header: Title + Subtitle + AI Auto-Match Button
          _buildTopHeader(),
          const SizedBox(height: 20),

          // 2. Info Cards Row (4 cards in a row)
          _buildInfoCardsRow(),
          const SizedBox(height: 24),

          // 3. Responsive 2-column layout (Table + AI Helper on Left, Receipt Summary on Right)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1060;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column (Wide)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScanAndVerifyCard(),
                          const SizedBox(height: 20),
                          _buildAiHelperCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),

                    // Right Column (Sidebar ~350px width)
                    SizedBox(
                      width: 350,
                      child: Column(
                        children: [
                          _buildReceiptSummaryCard(),
                          const SizedBox(height: 16),
                          _buildDiscrepancyNotesCard(),
                          const SizedBox(height: 16),
                          _buildLogReceivedByCard(),
                          const SizedBox(height: 16),
                          _buildActionButtons(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Stacked for narrow/mobile
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildScanAndVerifyCard(),
                  const SizedBox(height: 20),
                  _buildAiHelperCard(),
                  const SizedBox(height: 24),
                  _buildReceiptSummaryCard(),
                  const SizedBox(height: 16),
                  _buildDiscrepancyNotesCard(),
                  const SizedBox(height: 16),
                  _buildLogReceivedByCard(),
                  const SizedBox(height: 16),
                  _buildActionButtons(),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 1. Top Page Header
  Widget _buildTopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Receiving Workflow',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Scan, verify and record incoming items against the purchase order.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // AI Auto-Match Active Badge / Button
        InkWell(
          onTap: () {
            setState(() {
              _aiAutoMatchActive = !_aiAutoMatchActive;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _aiAutoMatchActive
                      ? 'AI Auto-Match enabled for PO items.'
                      : 'AI Auto-Match paused. Manual entry active.',
                ),
                backgroundColor: const Color(0xFF181513),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: _aiAutoMatchActive
                  ? const Color(0xFFFFFBEB)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _aiAutoMatchActive
                    ? const Color(0xFFFDE68A)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: _aiAutoMatchActive
                      ? const Color(0xFFD97706)
                      : const Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 8),
                Text(
                  _aiAutoMatchActive
                      ? 'AI Auto-Match Active'
                      : 'AI Auto-Match Inactive',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _aiAutoMatchActive
                        ? const Color(0xFFB45309)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 2. Info Cards Row
  Widget _buildInfoCardsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final card1 = _buildInfoCardItem(
          icon: Icons.receipt_long_outlined,
          title: widget.transferId,
          subtitle: 'Purchase Order',
        );
        final card2 = _buildInfoCardItem(
          icon: Icons.storefront_outlined,
          title: widget.supplier,
          subtitle: 'Supplier',
        );
        final card3 = _buildInfoCardItem(
          icon: Icons.inventory_2_outlined,
          title: widget.categoriesCount,
          subtitle: 'Expected Items',
        );
        final card4 = _buildInfoCardItem(
          icon: Icons.calendar_today_outlined,
          title: widget.expectedDelivery,
          subtitle: 'Expected Delivery',
        );

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 14),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 14),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 16),
            Expanded(child: card2),
            const SizedBox(width: 16),
            Expanded(child: card3),
            const SizedBox(width: 16),
            Expanded(child: card4),
          ],
        );
      },
    );
  }

  Widget _buildInfoCardItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFBF4EB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF92400E)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Scan and Verify Items Card
  Widget _buildScanAndVerifyCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header inside card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan and Verify Items',
                        style: GoogleFonts.inter(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Scan barcodes or manually enter quantities to verify received items.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    // Scan Barcode Button
                    OutlinedButton.icon(
                      onPressed: _showScanItemsModal,
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                      label: const Text('Scan Barcode'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1F2937),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Add Item + Button
                    ElevatedButton(
                      onPressed: _showAddItemModal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFFBEB),
                        foregroundColor: const Color(0xFFB45309),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFFFDE68A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Add Item +'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Divider before table
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Checkbox(
                    value: _selectAll,
                    onChanged: _toggleSelectAll,
                    activeColor: const Color(0xFFD97706),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  child: Text(
                    '#',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: Text(
                    'Item Details',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Expected',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Received',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    'Variance',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  child: Text(
                    'Condition Status',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 50,
                  child: Text(
                    'Actions',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table Rows
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
                    'No items to receive',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Incoming items from approved purchase orders or transfer orders will appear here.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            )
          else
            for (int i = 0; i < _items.length; i++) ...[
              _buildTableRow(i),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ],

          // Dashed Scan Container
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildDashedScanButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(int index) {
    final item = _items[index];
    final isGood = item.conditionStatus == 'Good Condition';
    final hasVariance = item.variance != 0;

    return Container(
      color: item.isSelected
          ? const Color(0xFFFFFBEB).withOpacity(0.3)
          : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  _selectAll = _items.every((it) => it.isSelected);
                });
              },
              activeColor: const Color(0xFFD97706),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Index #
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Item Details: Thumbnail + Name + SKU + Category
          Expanded(
            flex: 5,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 44,
                    height: 44,
                    color: const Color(0xFFF3F4F6),
                    child: Image.asset(
                      item.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.image, color: Color(0xFF94A3B8)),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            item.sku,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.category,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Expected
          SizedBox(
            width: 100,
            child: Text(
              '${item.expectedQty} ${item.unit}',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111827),
              ),
            ),
          ),

          // Received (Editable Field)
          SizedBox(
            width: 80,
            child: Container(
              height: 36,
              width: 58,
              alignment: Alignment.centerLeft,
              child: TextFormField(
                controller: _qtyControllers[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 6,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                      color: Color(0xFFD97706),
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null && parsed >= 0) {
                    setState(() {
                      item.receivedQty = parsed;
                      if (item.variance < 0) {
                        item.conditionStatus = '${item.variance.abs()} Missing';
                      } else {
                        item.conditionStatus = 'Good Condition';
                      }
                    });
                  }
                },
              ),
            ),
          ),

          // Variance
          SizedBox(
            width: 90,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hasVariance ? '${item.variance}' : '0',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: item.variance < 0
                        ? const Color(0xFFDC2626)
                        : (item.variance > 0
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF16A34A)),
                  ),
                ),
                Text(
                  item.variance < 0
                      ? '(${item.variancePercent.toStringAsFixed(1)}%)'
                      : (item.variance > 0
                            ? '(+${item.variancePercent.toStringAsFixed(1)}%)'
                            : '(0%)'),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: item.variance < 0
                        ? const Color(0xFFDC2626)
                        : (item.variance > 0
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF16A34A)),
                  ),
                ),
              ],
            ),
          ),

          // Condition Status (Dropdown Pill Badge)
          SizedBox(
            width: 140,
            child: PopupMenuButton<String>(
              onSelected: (status) {
                setState(() {
                  item.conditionStatus = status;
                });
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              color: Colors.white,
              itemBuilder: (ctx) => _conditionOptions.map((st) {
                return PopupMenuItem<String>(
                  value: st,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: st == 'Good Condition'
                              ? const Color(0xFF16A34A)
                              : (st.contains('Missing')
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFFDC2626)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        st,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isGood
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isGood
                        ? const Color(0xFFBBF7D0)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isGood
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.conditionStatus,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isGood
                              ? const Color(0xFF15803D)
                              : const Color(0xFFB45309),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 15,
                      color: isGood
                          ? const Color(0xFF15803D)
                          : const Color(0xFFB45309),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Actions (...)
          SizedBox(
            width: 50,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  color: Color(0xFF6B7280),
                  size: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: Colors.white,
                onSelected: (val) {
                  if (val == 'match_full') {
                    setState(() {
                      item.receivedQty = item.expectedQty;
                      _qtyControllers[index]?.text = '${item.receivedQty}';
                      item.conditionStatus = 'Good Condition';
                    });
                  } else if (val == 'report_damaged') {
                    setState(() {
                      item.conditionStatus = 'Damaged';
                    });
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'match_full',
                    child: Text(
                      'Match Full Expected Qty',
                      style: GoogleFonts.inter(fontSize: 13),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'report_damaged',
                    child: Text(
                      'Mark Item Damaged',
                      style: GoogleFonts.inter(fontSize: 13),
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

  // Dashed Scan Container
  Widget _buildDashedScanButton() {
    return InkWell(
      onTap: _showScanItemsModal,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB).withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFFDE68A),
            style: BorderStyle.solid,
            width: 1.2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_box_outlined,
              size: 18,
              color: Color(0xFFB45309),
            ),
            const SizedBox(width: 8),
            Text(
              'Scan next item or click to add another item',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF92400E),
              ),
            ),
            const SizedBox(width: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Text(
                '⌘ + Enter',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB45309),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. AI Helper Card
  Widget _buildAiHelperCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sparkle icon
          const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Helper',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 8),
                _buildAiCheckItem('Auto-matched 2 of 2 items from PO'),
                const SizedBox(height: 6),
                _buildAiCheckItem('Detected 1 discrepancy (8 Kgs short)'),
                const SizedBox(height: 6),
                _buildAiCheckItem('Verified item conditions'),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // View AI Suggestions Button
          OutlinedButton(
            onPressed: _showAiSuggestionsModal,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFF59E0B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              textStyle: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('View AI Suggestions'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiCheckItem(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: const Icon(
            Icons.check_rounded,
            size: 11,
            color: Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  // 5. Right Sidebar: Receipt Summary Card
  Widget _buildReceiptSummaryCard() {
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
          Row(
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                color: Color(0xFFD97706),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Receipt Summary',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Verify Rate
          _buildSummaryRow(
            label: 'Verify Rate',
            value: '$_verifiedCount / ${_items.length} Verified',
          ),
          const SizedBox(height: 12),

          // Total Expected Units
          _buildSummaryRow(
            label: 'Total Expected Units',
            value: '$_totalExpected Units',
          ),
          const SizedBox(height: 12),

          // Total Received
          _buildSummaryRow(
            label: 'Total Received',
            value: '$_totalReceived Units',
            valueColor: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 12),

          // Variance
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Variance',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _totalVariance < 0
                      ? const Color(0xFFFEE2E2)
                      : (_totalVariance > 0
                            ? const Color(0xFFE0E7FF)
                            : const Color(0xFFDCFCE7)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _totalVariance == 0 ? '0 Units' : '$_totalVariance Units',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _totalVariance < 0
                        ? const Color(0xFFDC2626)
                        : (_totalVariance > 0
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF16A34A)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
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
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  // 6. Right Sidebar: Discrepancy Notes Card
  Widget _buildDiscrepancyNotesCard() {
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
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFFD97706),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Discrepancy Notes',
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: TextField(
              controller: _discrepancyNotesController,
              maxLines: 3,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
              decoration: const InputDecoration.collapsed(
                hintText: 'Enter any notes or comments about received items...',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Right Sidebar: Log Received By Card
  Widget _buildLogReceivedByCard() {
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
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFFD97706),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Log Received By',
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // User Selector Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 20,
                  color: Color(0xFF4B5563),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.receivedBy,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Timestamp Row
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                widget.logTimestamp,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 8. Action Buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Complete Receipt
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed:
                widget.onCompleteReceiving ?? _showCompleteReceivingModal,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Complete Receipt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Save as Partial
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              widget.onSaveDraft?.call();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Draft saved: Partial receiving saved to system.',
                  ),
                  backgroundColor: Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
            label: const Text('Save as Partial'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF111827),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Print Receiving Report
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: widget.onPrintReport ?? _showPrintReportModal,
            icon: const Icon(Icons.print_outlined, size: 18),
            label: const Text('Print Receiving Report'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF111827),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
