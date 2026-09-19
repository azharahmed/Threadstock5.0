// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransferOrderItemData {
  TransferOrderItemData({
    required this.name,
    required this.sku,
    required this.variant,
    required this.requestedQty,
    required this.sentQty,
    this.receivedQty,
    required this.status,
    required this.imageAsset,
    this.isSelected = false,
  });

  final String name;
  final String sku;
  final String variant;
  final int requestedQty;
  final int sentQty;
  final int? receivedQty;
  final String status;
  final String imageAsset;
  bool isSelected;
}

class TransferOrderDetailView extends StatefulWidget {
  const TransferOrderDetailView({
    super.key,
    this.transferId = 'TR-1042',
    this.status = 'In Transit',
    this.sourceName = 'Central Warehouse',
    this.sourceDetails = 'Zone A • Main Facility',
    this.destName = 'MG Road Store',
    this.destDetails = 'Bengaluru • Retail Outlet',
    this.approvalTime = '14 Jan, 10:15 AM',
    this.approvedBy = 'By Alex Morgan',
    this.dispatchTime = '16 Jan, 02:30 PM',
    this.dispatchedVia = 'Via ThreadStock Logistics',
    this.eta = '19 Jan, EOD',
    this.etaStatus = 'In Transit • On Schedule',
    this.carrier = 'ThreadStock Logistics',
    this.trackingId = 'TSL784562301',
    this.totalUnits = '48 units',
    this.variantCount = '12 variants',
    this.totalValue = '₹84,000',
    this.createdBy = 'Alex Morgan',
    this.createdOn = '14 Jan 2027, 09:42 AM',
    this.reference = 'REQ-7781',
    this.onTrackShipment,
    this.onReceiveTransfer,
    this.onPrintDocket,
    this.onCancelTransfer,
  });

  final String transferId;
  final String status;
  final String sourceName;
  final String sourceDetails;
  final String destName;
  final String destDetails;
  final String approvalTime;
  final String approvedBy;
  final String dispatchTime;
  final String dispatchedVia;
  final String eta;
  final String etaStatus;
  final String carrier;
  final String trackingId;
  final String totalUnits;
  final String variantCount;
  final String totalValue;
  final String createdBy;
  final String createdOn;
  final String reference;
  final VoidCallback? onTrackShipment;
  final VoidCallback? onReceiveTransfer;
  final VoidCallback? onPrintDocket;
  final VoidCallback? onCancelTransfer;

  @override
  State<TransferOrderDetailView> createState() => _TransferOrderDetailViewState();
}

class _TransferOrderDetailViewState extends State<TransferOrderDetailView> {
  int _activeTabIndex = 0; // 0: Items (2), 1: Shipment, 2: Activity Log
  bool _selectAll = false;

  late final List<TransferOrderItemData> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      TransferOrderItemData(
        name: 'Merino Wool Blazer',
        sku: 'MWB-20188-L',
        variant: 'Navy / L',
        requestedQty: 20,
        sentQty: 20,
        receivedQty: null,
        status: 'In Transit',
        imageAsset: 'Assets/merino_wool_blazer.jpg',
      ),
      TransferOrderItemData(
        name: 'Oxford Linen Shirt',
        sku: 'TS-10432-M',
        variant: 'Black / M',
        requestedQty: 28,
        sentQty: 28,
        receivedQty: null,
        status: 'In Transit',
        imageAsset: 'Assets/oxford_linen_shirt.jpg',
      ),
    ];
  }

  void _toggleSelectAll(bool? val) {
    setState(() {
      _selectAll = val ?? false;
      for (final item in _items) {
        item.isSelected = _selectAll;
      }
    });
  }

  void _showTrackShipmentModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.local_shipping_outlined, color: Color(0xFF2563EB), size: 22),
            const SizedBox(width: 10),
            Text(
              'Track Shipment',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF181513)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tracking ID: ${widget.trackingId}',
              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: const Color(0xFF181513)),
            ),
            const SizedBox(height: 6),
            Text(
              'Carrier: ${widget.carrier} • Status: ${widget.status}',
              style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 10, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Text('Jan 16, 02:30 PM: Dispatched from Central Warehouse',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 10, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Text('Jan 17, 11:00 AM: In Transit near Bengaluru hub',
                          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  void _showReceiveConfirmationDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Receive Transfer ${widget.transferId}',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF181513)),
        ),
        content: Text(
          'Are you sure you want to mark this transfer as received at ${widget.destName}? This will update destination inventory levels.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
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
                  content: Text('Transfer ${widget.transferId} marked as received.'),
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
            child: const Text('Confirm Receipt'),
          ),
        ],
      ),
    );
  }

  void _showCancelConfirmationDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Cancel Transfer ${widget.transferId}',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
        ),
        content: Text(
          'Are you sure you want to cancel this transfer order? The items will be returned to available stock at ${widget.sourceName}.',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Keep Active', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transfer ${widget.transferId} was cancelled.'),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Cancel Transfer'),
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
                      _buildSourceDestinationCard(),
                      const SizedBox(height: 14),
                      _buildMilestonesRow(),
                      const SizedBox(height: 24),
                      _buildTabsAndAddItemsBar(),
                      const SizedBox(height: 14),
                      _buildItemsTable(),
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
                      _buildTransferDetailsCard(),
                      const SizedBox(height: 16),
                      _buildShipmentInformationCard(),
                      const SizedBox(height: 16),
                      _buildActionButtons(),
                      const SizedBox(height: 16),
                      _buildNoteCard(),
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
              _buildSourceDestinationCard(),
              const SizedBox(height: 14),
              _buildMilestonesRow(),
              const SizedBox(height: 24),
              _buildTabsAndAddItemsBar(),
              const SizedBox(height: 14),
              _buildItemsTable(),
              const SizedBox(height: 24),
              _buildTransferDetailsCard(),
              const SizedBox(height: 16),
              _buildShipmentInformationCard(),
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 16),
              _buildNoteCard(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // 1. Header: Transfer Order, TR-1042 In Transit, and Track Shipment button
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
                'Transfer Order',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.transferId,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.status,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Movement of inventory between warehouse locations.',
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
          onTap: widget.onTrackShipment ?? _showTrackShipmentModal,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_shipping_outlined, size: 16, color: Color(0xFF181513)),
                const SizedBox(width: 7),
                Text(
                  'Track Shipment',
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
      ],
    );
  }

  // 2. Source -> Destination Card
  Widget _buildSourceDestinationCard() {
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
        children: [
          // Source
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
                        'SOURCE',
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

          // Center Arrow
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 22,
              color: const Color(0xFF64748B).withOpacity(0.8),
            ),
          ),

          // Destination
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
                        'DESTINATION',
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
    );
  }

  // 3. 3 Status Timeline / Milestone Cards (APPROVED, DISPATCHED, EXPECTED ARRIVAL)
  Widget _buildMilestonesRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        if (isNarrow) {
          return Column(
            children: [
              _buildMilestoneCard(
                icon: Icons.check_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFDCFCE7),
                label: 'APPROVED',
                title: widget.approvalTime,
                subtitle: widget.approvedBy,
              ),
              const SizedBox(height: 10),
              _buildMilestoneCard(
                icon: Icons.check_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFDCFCE7),
                label: 'DISPATCHED',
                title: widget.dispatchTime,
                subtitle: widget.dispatchedVia,
              ),
              const SizedBox(height: 10),
              _buildMilestoneCard(
                icon: Icons.local_shipping_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                label: 'EXPECTED ARRIVAL',
                title: widget.eta,
                subtitle: widget.etaStatus,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildMilestoneCard(
                icon: Icons.check_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFDCFCE7),
                label: 'APPROVED',
                title: widget.approvalTime,
                subtitle: widget.approvedBy,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMilestoneCard(
                icon: Icons.check_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFDCFCE7),
                label: 'DISPATCHED',
                title: widget.dispatchTime,
                subtitle: widget.dispatchedVia,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMilestoneCard(
                icon: Icons.local_shipping_outlined,
                iconColor: const Color(0xFF2563EB),
                iconBg: const Color(0xFFEFF6FF),
                label: 'EXPECTED ARRIVAL',
                title: widget.eta,
                subtitle: widget.etaStatus,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMilestoneCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String title,
    required String subtitle,
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
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: iconColor),
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
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
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
    );
  }

  // 4. Tabs & + Add Items Bar
  Widget _buildTabsAndAddItemsBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildUnderlineTab('Items (${_items.length})', 0),
            const SizedBox(width: 24),
            _buildUnderlineTab('Shipment', 1),
            const SizedBox(width: 24),
            _buildUnderlineTab('Activity Log', 2),
          ],
        ),
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Item selector dialog opened.'),
                duration: Duration(seconds: 1),
              ),
            );
          },
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
                const Icon(Icons.add_rounded, size: 16, color: Color(0xFFB45309)),
                const SizedBox(width: 5),
                Text(
                  'Add Items',
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
    );
  }

  Widget _buildUnderlineTab(String label, int index) {
    final isActive = _activeTabIndex == index;

    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFFD97706) : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? const Color(0xFF181513) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // 5. Items Table
  Widget _buildItemsTable() {
    return Container(
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
          // Table Header
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
                    'Sent',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Received',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
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

                  // Product thumbnail + Name + SKU
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
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ),

                  // Sent
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${item.sentQty}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ),

                  // Received
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.receivedQty != null ? '${item.receivedQty}' : '—',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),

                  // Status
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.status,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // 6. Right Column: Transfer Details Card
  Widget _buildTransferDetailsCard() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transfer Details',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Transfer ID', widget.transferId, isBold: true),
          const SizedBox(height: 10),
          _buildStatusRow('Status', widget.status),
          const SizedBox(height: 10),
          _buildDetailRow('Total Units', widget.totalUnits, isBold: true),
          const SizedBox(height: 10),
          _buildDetailRow('Variants', widget.variantCount),
          const SizedBox(height: 10),
          _buildDetailRow('Total Value', widget.totalValue, isBold: true),
          const SizedBox(height: 10),
          _buildDetailRow('Created By', widget.createdBy),
          const SizedBox(height: 10),
          _buildDetailRow('Created On', widget.createdOn),
          const SizedBox(height: 10),
          _buildDetailRow('Reference', widget.reference),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
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
            color: const Color(0xFF181513),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String status) {
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
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              status,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 7. Right Column: Shipment Information Card
  Widget _buildShipmentInformationCard() {
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
          Text(
            'Shipment Information',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 14),
          _buildDetailRow('Carrier', widget.carrier),
          const SizedBox(height: 10),
          _buildDetailRow('Tracking ID', widget.trackingId),
          const SizedBox(height: 10),
          _buildDetailRow('Dispatched On', widget.dispatchTime),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: widget.onTrackShipment ?? _showTrackShipmentModal,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Track Shipment',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 8. Right Column: Action Buttons (Receive Transfer, Print Transfer Docket, Cancel Transfer)
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary: Receive Transfer
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton(
            onPressed: widget.onReceiveTransfer ?? _showReceiveConfirmationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Receive Transfer',
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

        // Secondary: Print Transfer Docket
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            onPressed: widget.onPrintDocket ?? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Generating printable transfer docket...'),
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
                const Icon(Icons.article_outlined, size: 16, color: Color(0xFF181513)),
                const SizedBox(width: 8),
                Text(
                  'Print Transfer Docket',
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

        // Danger: Cancel Transfer
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            onPressed: widget.onCancelTransfer ?? _showCancelConfirmationDialog,
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFECACA)),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.close_rounded, size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 8),
                Text(
                  'Cancel Transfer',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 9. Right Column: Note Card
  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFB45309)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Note',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'You can receive items once they arrive at the destination location.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
