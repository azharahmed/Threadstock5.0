// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DispatchItemData {
  DispatchItemData({
    required this.name,
    required this.sku,
    required this.variant,
    required this.requestedQty,
    required this.pickedQty,
    required this.imageAsset,
    this.isSelected = false,
  });

  final String name;
  final String sku;
  final String variant;
  final int requestedQty;
  int pickedQty;
  final String imageAsset;
  bool isSelected;

  int get difference => pickedQty - requestedQty;
}

class DispatchTransferView extends StatefulWidget {
  const DispatchTransferView({
    super.key,
    this.transferId = 'TR-1042',
    this.sourceName = 'Central Warehouse',
    this.sourceDetails = 'Zone A • Main Facility',
    this.destName = 'MG Road Store',
    this.destDetails = 'Bengaluru • Retail Outlet',
    this.initialCarrier = 'Delhi Cargo Express',
    this.initialTrackingNumber = 'DCE-904128-IND',
    this.onMarkAsDispatched,
    this.onPrintDocument,
    this.onSaveDraft,
    this.onNavigateBack,
  });

  final String transferId;
  final String sourceName;
  final String sourceDetails;
  final String destName;
  final String destDetails;
  final String initialCarrier;
  final String initialTrackingNumber;
  final VoidCallback? onMarkAsDispatched;
  final VoidCallback? onPrintDocument;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onNavigateBack;

  @override
  State<DispatchTransferView> createState() => _DispatchTransferViewState();
}

class _DispatchTransferViewState extends State<DispatchTransferView> {
  bool _selectAll = false;
  late String _selectedCarrier;
  late final TextEditingController _trackingController;
  late final TextEditingController _notesController;

  late final List<DispatchItemData> _items;

  final List<String> _carrierOptions = [
    'Delhi Cargo Express',
    'ThreadStock Logistics',
    'Bluedart Surface',
    'FedEx Ground',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCarrier = widget.initialCarrier;
    _trackingController = TextEditingController(text: widget.initialTrackingNumber);
    _notesController = TextEditingController();

    _items = [
      DispatchItemData(
        name: 'Merino Wool Blazer',
        sku: 'MWB-20188-L',
        variant: 'Navy / L',
        requestedQty: 20,
        pickedQty: 19,
        imageAsset: 'Assets/merino_wool_blazer.jpg',
      ),
      DispatchItemData(
        name: 'Oxford Linen Shirt',
        sku: 'TS-10432-M',
        variant: 'Black / M',
        requestedQty: 28,
        pickedQty: 28,
        imageAsset: 'Assets/oxford_linen_shirt.jpg',
      ),
    ];
  }

  @override
  void dispose() {
    _trackingController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int get _totalPicked => _items.fold<int>(0, (sum, i) => sum + i.pickedQty);

  int get _totalDiscrepancy => _items.fold<int>(0, (sum, i) => sum + (i.difference < 0 ? i.difference.abs() : 0));

  void _toggleSelectAll(bool? val) {
    setState(() {
      _selectAll = val ?? false;
      for (final item in _items) {
        item.isSelected = _selectAll;
      }
    });
  }

  void _autoFillPicked() {
    setState(() {
      for (final item in _items) {
        item.pickedQty = item.requestedQty;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All picked quantities matched to requested quantities.'),
        backgroundColor: Color(0xFF181513),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEditPickedDialog(DispatchItemData item) {
    final controller = TextEditingController(text: '${item.pickedQty}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Edit Picked Quantity',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF181513)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${item.name} (${item.variant})',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF181513)),
            ),
            const SizedBox(height: 4),
            Text(
              'Requested Quantity: ${item.requestedQty} units',
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Picked Quantity',
                labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 0) {
                setState(() {
                  item.pickedQty = val;
                });
                Navigator.of(ctx).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showMarkDispatchedConfirmation() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.flight_takeoff_rounded, color: Color(0xFF181513), size: 22),
            const SizedBox(width: 10),
            Text(
              'Dispatch Transfer ${widget.transferId}',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF181513)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to mark this transfer as Dispatched?',
              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF181513)),
            ),
            const SizedBox(height: 8),
            Text(
              'Carrier: $_selectedCarrier\nTracking: ${_trackingController.text}\nTotal Units: $_totalPicked units',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B), height: 1.4),
            ),
            if (_totalDiscrepancy > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFD97706)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Warning: $_totalDiscrepancy unit(s) short of requested amount.',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF92400E)),
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
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transfer ${widget.transferId} dispatched successfully.'),
                  backgroundColor: const Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Confirm & Dispatch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1080;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column (~68% width)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),
                      _buildRouteInformationCard(),
                      const SizedBox(height: 24),
                      _buildItemsToDispatchSection(),
                      const SizedBox(height: 24),
                      _buildShippingCarrierCard(),
                      const SizedBox(height: 20),
                      _buildDispatchNotesCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Column (~32% width)
                SizedBox(
                  width: 350,
                  child: Column(
                    children: [
                      _buildDispatchSummaryCard(),
                      const SizedBox(height: 16),
                      if (_totalDiscrepancy > 0) ...[
                        _buildDiscrepancyCard(),
                        const SizedBox(height: 16),
                      ],
                      _buildActionButtons(),
                      const SizedBox(height: 16),
                      _buildSuccessInfoCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            );
          }

          // Stacked Layout for compact screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildRouteInformationCard(),
              const SizedBox(height: 24),
              _buildItemsToDispatchSection(),
              const SizedBox(height: 24),
              _buildShippingCarrierCard(),
              const SizedBox(height: 20),
              _buildDispatchNotesCard(),
              const SizedBox(height: 24),
              _buildDispatchSummaryCard(),
              const SizedBox(height: 16),
              if (_totalDiscrepancy > 0) ...[
                _buildDiscrepancyCard(),
                const SizedBox(height: 16),
              ],
              _buildActionButtons(),
              const SizedBox(height: 16),
              _buildSuccessInfoCard(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // 1. Header with Title, Subtitle, and "Ready to Dispatch" badge
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dispatch Transfer ${widget.transferId}',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Confirm picked quantities, enter shipping details, and dispatch the transfer.',
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFFB45309)),
              const SizedBox(width: 7),
              Text(
                'Ready to Dispatch',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 2. Route Information Card
  Widget _buildRouteInformationCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Route Information',
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181513),
          ),
        ),
        const SizedBox(height: 10),
        Container(
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
            children: [
              // FROM
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.warehouse_outlined, size: 20, color: Color(0xFFB45309)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FROM',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.sourceName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.sourceDetails,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
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

              // Arrow
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 22,
                  color: const Color(0xFF64748B).withOpacity(0.8),
                ),
              ),

              // TO
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storefront_outlined, size: 20, color: Color(0xFFB45309)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TO',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.destName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.destDetails,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
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
            ],
          ),
        ),
      ],
    );
  }

  // 3. Items to Dispatch (2) Table Section
  Widget _buildItemsToDispatchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Items to Dispatch (${_items.length})',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181513),
              ),
            ),
            InkWell(
              onTap: _autoFillPicked,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 15, color: Color(0xFFB45309)),
                    const SizedBox(width: 6),
                    Text(
                      'Auto Fill Picked',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: _selectAll,
                        onChanged: _toggleSelectAll,
                        activeColor: const Color(0xFF181513),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Product',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Variant / SKU',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Requested',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Picked',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Difference',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Checkbox(
                          value: item.isSelected,
                          onChanged: (val) {
                            setState(() {
                              item.isSelected = val ?? false;
                              _selectAll = _items.every((i) => i.isSelected);
                            });
                          },
                          activeColor: const Color(0xFF181513),
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Product Thumbnail + Name + SKU
                      Expanded(
                        flex: 5,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                width: 42,
                                height: 42,
                                color: const Color(0xFFF1F5F9),
                                child: Image.asset(
                                  item.imageAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                    Icons.image_not_supported_outlined,
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
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF181513),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.sku,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
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

                      // Variant / SKU
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.variant,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),

                      // Requested
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${item.requestedQty}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),

                      // Picked (Editable input pill)
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: InkWell(
                            onTap: () => _showEditPickedDialog(item),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 58,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${item.pickedQty}',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF181513),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Difference
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.difference == 0
                              ? '0'
                              : '${item.difference}',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: item.difference < 0 ? FontWeight.w700 : FontWeight.w500,
                            color: item.difference < 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
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

  // 4. Shipping & Carrier Information Card
  Widget _buildShippingCarrierCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shipping & Carrier Information',
          style: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181513),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // Carrier selector
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARRIER',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 18, color: Color(0xFF181513)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCarrier,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF181513),
                              ),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCarrier = val);
                              },
                              items: _carrierOptions
                                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Tracking Number
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRACKING NUMBER',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xFF181513)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _trackingController,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF181513),
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
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
      ],
    );
  }

  // 5. Dispatch Notes (Optional) Card
  Widget _buildDispatchNotesCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.description_outlined, size: 16, color: Color(0xFFB45309)),
            const SizedBox(width: 6),
            Text(
              'Dispatch Notes',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181513),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(Optional)',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181513)),
            decoration: InputDecoration(
              hintText: 'Add any special handling instructions...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8)),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  // 6. Right Column: Dispatch Summary Card
  Widget _buildDispatchSummaryCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, size: 20, color: Color(0xFFB45309)),
              const SizedBox(width: 8),
              Text(
                'Dispatch Summary',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Transfer ID', widget.transferId, isBold: true),
          const SizedBox(height: 10),
          _buildSummaryRow('Source Location', widget.sourceName, isBold: true),
          const SizedBox(height: 10),
          _buildSummaryRow('Destination', widget.destName, isBold: true),
          const SizedBox(height: 10),
          _buildSummaryRow('Active Variants', '12 variants', isBold: true),
          const SizedBox(height: 10),
          _buildSummaryRow('Ready to Ship', '$_totalPicked units', isBold: true),
          const SizedBox(height: 10),
          _buildSummaryRow(
            'Discrepancies',
            _totalDiscrepancy > 0 ? '$_totalDiscrepancy unit short' : 'None',
            isRed: _totalDiscrepancy > 0,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, bool isRed = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isRed ? const Color(0xFFDC2626) : const Color(0xFF181513),
          ),
        ),
      ],
    );
  }

  // 7. Discrepancy Alert Card
  Widget _buildDiscrepancyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFD97706)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1 unit is short',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Merino Wool Blazer (Navy / L)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'Requested: 20  |  Picked: 19',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  // 8. Action Buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary: Mark as Dispatched
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton(
            onPressed: widget.onMarkAsDispatched ?? _showMarkDispatchedConfirmation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Mark as Dispatched',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Secondary: Print Transfer Document
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            onPressed: widget.onPrintDocument ?? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Generating printable transfer document...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF181513),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.description_outlined, size: 16, color: Color(0xFF181513)),
                const SizedBox(width: 8),
                Text(
                  'Print Transfer Document',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Tertiary: Save as Draft
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            onPressed: widget.onSaveDraft ?? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Draft saved successfully.'),
                  backgroundColor: Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF181513),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Save as Draft',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 9. Success Info Box
  Widget _buildSuccessInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF16A34A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Once dispatched, the receiving store will be notified and items will be marked as in transit.',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF166534),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
