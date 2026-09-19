// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InboundShipmentItem {
  InboundShipmentItem({
    required this.poNumber,
    required this.supplierCode,
    required this.supplierName,
    required this.expectedDatePrimary,
    required this.expectedDateSecondary,
    required this.itemsCount,
    required this.status,
    required this.trackingId,
    this.isSelected = false,
  });

  final String poNumber;
  final String supplierCode;
  final String supplierName;
  final String expectedDatePrimary;
  final String expectedDateSecondary;
  final String itemsCount;
  final String status;
  final String trackingId;
  bool isSelected;
}

class ReceivingQueueView extends StatefulWidget {
  const ReceivingQueueView({
    super.key,
    this.onSelectPo,
    this.onLogReceipt,
    this.onDateRangeSelected,
  });

  final ValueChanged<String>? onSelectPo;
  final VoidCallback? onLogReceipt;
  final ValueChanged<String>? onDateRangeSelected;

  @override
  State<ReceivingQueueView> createState() => _ReceivingQueueViewState();
}

class _ReceivingQueueViewState extends State<ReceivingQueueView> {
  int _selectedTab = 0; // 0: Expected Today, 1: In Transit, 2: Received This Week, 3: All Open POs
  final TextEditingController _searchController = TextEditingController();
  bool _selectAll = false;
  String _selectedDateRange = 'Feb 01, 2027 – Feb 28, 2027';

  late final List<InboundShipmentItem> _shipments;

  @override
  void initState() {
    super.initState();
    _shipments = [
      InboundShipmentItem(
        poNumber: 'PO-2024-0847',
        supplierCode: 'MT',
        supplierName: 'Milano Tessuti',
        expectedDatePrimary: 'Today, 4:00 PM',
        expectedDateSecondary: 'Feb 15, 2027',
        itemsCount: '850 Units',
        status: 'Expected Today',
        trackingId: 'TRK-7492193',
      ),
      InboundShipmentItem(
        poNumber: 'PO-2024-0810',
        supplierCode: 'PK',
        supplierName: 'Prato Knitwear Co.',
        expectedDatePrimary: 'Feb 18, 2027',
        expectedDateSecondary: '10:00 AM',
        itemsCount: '320 Units',
        status: 'In Transit',
        trackingId: 'TRK-0194821',
      ),
      InboundShipmentItem(
        poNumber: 'PO-2024-0792',
        supplierCode: 'SD',
        supplierName: 'Surat Denim Ltd',
        expectedDatePrimary: 'Received Yesterday',
        expectedDateSecondary: 'Feb 14, 2027, 03:20 PM',
        itemsCount: '1,200 Units',
        status: 'Received',
        trackingId: 'TRK-2948201',
      ),
      InboundShipmentItem(
        poNumber: 'PO-2024-0732',
        supplierCode: 'TB',
        supplierName: 'Tokyo Brass & Hardware',
        expectedDatePrimary: 'Received Feb 10',
        expectedDateSecondary: 'Feb 10, 2027, 11:45 AM',
        itemsCount: '450 Units',
        status: 'Partial Receipt',
        trackingId: 'TRK-3928194',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<InboundShipmentItem> get _filteredShipments {
    final query = _searchController.text.trim().toLowerCase();
    return _shipments.where((item) {
      if (_selectedTab == 0 && item.status != 'Expected Today') return false;
      if (_selectedTab == 1 && item.status != 'In Transit') return false;
      if (_selectedTab == 2 && item.status != 'Received' && item.status != 'Partial Receipt') return false;

      if (query.isNotEmpty) {
        final matches = item.poNumber.toLowerCase().contains(query) ||
            item.supplierName.toLowerCase().contains(query) ||
            item.trackingId.toLowerCase().contains(query) ||
            item.status.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  void _toggleSelectAll(bool? val) {
    setState(() {
      _selectAll = val ?? false;
      for (final s in _shipments) {
        s.isSelected = _selectAll;
      }
    });
  }

  void _showDatePickerModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Select Receiving Window',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('February 2027 (Current Month)'),
              subtitle: const Text('Feb 01, 2027 – Feb 28, 2027'),
              leading: const Icon(Icons.calendar_month, color: Color(0xFFB45309)),
              onTap: () {
                setState(() => _selectedDateRange = 'Feb 01, 2027 – Feb 28, 2027');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: const Text('Next 14 Days'),
              subtitle: const Text('Feb 15, 2027 – Mar 01, 2027'),
              leading: const Icon(Icons.date_range, color: Color(0xFF64748B)),
              onTap: () {
                setState(() => _selectedDateRange = 'Feb 15, 2027 – Mar 01, 2027');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: const Text('Q1 2027'),
              subtitle: const Text('Jan 01, 2027 – Mar 31, 2027'),
              leading: const Icon(Icons.timelapse, color: Color(0xFF64748B)),
              onTap: () {
                setState(() => _selectedDateRange = 'Jan 01, 2027 – Mar 31, 2027');
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAiInsightsModal() {
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
              child: const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Receiving Intelligence Guide',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ThreadStock AI continuously syncs your inbound supply chain with real-time delivery telemetry:',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4B5563), height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildInsightBullet(
                'Auto-Match POs',
                'Advanced Optical Character Recognition (OCR) and barcode reading cross-reference packing lists with purchase orders automatically.',
              ),
              const SizedBox(height: 12),
              _buildInsightBullet(
                'Discrepancy Resolution',
                'Instantly flags quantity shortages, lot misallocations, or fabric flaws before merchandise enters sellable stock.',
              ),
              const SizedBox(height: 12),
              _buildInsightBullet(
                'Automated Ledger Entries',
                'Double-entry inventory events are drafted in real time, pending warehouse floor manager sign-off.',
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

  Widget _buildInsightBullet(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header
          _buildHeader(),
          const SizedBox(height: 20),

          // 2. Metrics Cards Row
          _buildMetricsRow(),
          const SizedBox(height: 28),

          // 3. Inbound Inventory Queue Section
          _buildQueueSection(),
          const SizedBox(height: 24),

          // 4. AI Receiving Insights Bottom Banner
          _buildAiInsightsBanner(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 1. Header
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
                'Receiving',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track and manage inbound shipments, receipts and inventory availability.',
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
        Row(
          children: [
            // Date Picker Dropdown Pill
            InkWell(
              onTap: _showDatePickerModal,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF4B5563)),
                    const SizedBox(width: 8),
                    Text(
                      _selectedDateRange,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF6B7280)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // + Log Receipt Primary Button
            ElevatedButton.icon(
              onPressed: widget.onLogReceipt ?? () => widget.onSelectPo?.call('PO-2024-0847'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Log Receipt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Metrics Cards Row
  Widget _buildMetricsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final card1 = _buildMetricCard(
          icon: Icons.local_shipping_outlined,
          iconBg: const Color(0xFFFBF4EB),
          iconColor: const Color(0xFF92400E),
          label: 'Expected Today',
          value: '3 Shipments',
          badgeText: 'Awaiting Arrival',
          badgeBg: const Color(0xFFFEF3C7),
          badgeColor: const Color(0xFFB45309),
        );
        final card2 = _buildMetricCard(
          icon: Icons.inventory_2_outlined,
          iconBg: const Color(0xFFFBF4EB),
          iconColor: const Color(0xFF92400E),
          label: 'In Transit',
          value: '8 Shipments',
          badgeText: 'Trackable',
          badgeBg: const Color(0xFFEFF6FF),
          badgeColor: const Color(0xFF2563EB),
        );
        final card3 = _buildMetricCard(
          icon: Icons.check_circle_outline_rounded,
          iconBg: const Color(0xFFDCFCE7),
          iconColor: const Color(0xFF16A34A),
          label: 'Received This Week',
          value: '12 Shipments',
          badgeText: 'Completed',
          badgeBg: const Color(0xFFDCFCE7),
          badgeColor: const Color(0xFF15803D),
        );
        final card4 = _buildMetricCard(
          icon: Icons.warning_amber_rounded,
          iconBg: const Color(0xFFFEF3C7),
          iconColor: const Color(0xFFD97706),
          label: 'Partial / Issues',
          value: '1 Shipment',
          badgeText: 'Requires Review',
          badgeBg: const Color(0xFFFEE2E2),
          badgeColor: const Color(0xFFDC2626),
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

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w400, color: const Color(0xFF6B7280)),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Queue Section
  Widget _buildQueueSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + Search + Filter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Inbound Inventory Queue',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            Row(
              children: [
                // Search field
                Container(
                  width: 280,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Search PO, supplier, or tracking ID...',
                            hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Filter button
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Filter options: All locations and suppliers active.'),
                        backgroundColor: Color(0xFF181513),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.filter_list_rounded, size: 16),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Filter Tabs
        Row(
          children: [
            _buildFilterPill(label: 'Expected Today', count: 3, index: 0),
            const SizedBox(width: 10),
            _buildFilterPill(label: 'In Transit', count: 8, index: 1),
            const SizedBox(width: 10),
            _buildFilterPill(label: 'Received This Week', count: 12, index: 2),
            const SizedBox(width: 10),
            _buildFilterPill(label: 'All Open POs', count: 24, index: 3),
          ],
        ),
        const SizedBox(height: 16),

        // Queue Table Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              // Header
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'PO NUMBER',
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'SUPPLIER',
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Text(
                            'EXPECTED DATE & TIME',
                            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_downward_rounded, size: 13, color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'ITEMS COUNT',
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'STATUS',
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'TRACKING ID',
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                      ),
                    ),
                    const SizedBox(
                      width: 40,
                      child: Text(
                        'ACTIONS',
                        textAlign: TextAlign.end,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Rows
              for (final item in _filteredShipments) ...[
                _buildQueueRow(item),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill({required String label, required int count, required int index}) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF181513) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF181513) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          '$label  ($count)',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueRow(InboundShipmentItem item) {
    return InkWell(
      onTap: () => widget.onSelectPo?.call(item.poNumber),
      hoverColor: const Color(0xFFF8FAFC),
      child: Padding(
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
                    _selectAll = _shipments.every((s) => s.isSelected);
                  });
                },
                activeColor: const Color(0xFFD97706),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 12),

            // PO Number
            Expanded(
              flex: 3,
              child: Text(
                item.poNumber,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ),

            // Supplier
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBF4EB),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.supplierCode,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.supplierName,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500, color: const Color(0xFF1F2937)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Expected Date & Time
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.expectedDatePrimary,
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.expectedDateSecondary,
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),

            // Items Count
            Expanded(
              flex: 3,
              child: Text(
                item.itemsCount,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF374151)),
              ),
            ),

            // Status Pill
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildStatusPill(item.status),
              ),
            ),

            // Tracking ID
            Expanded(
              flex: 3,
              child: Text(
                item.trackingId,
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF4B5563)),
              ),
            ),

            // Actions Menu (...)
            SizedBox(
              width: 40,
              child: Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF6B7280), size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  color: Colors.white,
                  onSelected: (val) {
                    if (val == 'receive') {
                      widget.onSelectPo?.call(item.poNumber);
                    } else if (val == 'track') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Tracking ${item.trackingId} via Freight Carrier API...'),
                          backgroundColor: const Color(0xFF181513),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'receive',
                      child: Text('Process Receipt', style: GoogleFonts.inter(fontSize: 13)),
                    ),
                    PopupMenuItem(
                      value: 'track',
                      child: Text('Track Carrier Live', style: GoogleFonts.inter(fontSize: 13)),
                    ),
                    PopupMenuItem(
                      value: 'packing_list',
                      child: Text('View Packing Manifest', style: GoogleFonts.inter(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    if (status == 'Expected Today') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFFB45309)),
            const SizedBox(width: 5),
            Text(
              'Expected Today',
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFB45309)),
            ),
          ],
        ),
      );
    }

    if (status == 'In Transit') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.local_shipping_outlined, size: 13, color: Color(0xFF2563EB)),
            const SizedBox(width: 5),
            Text(
              'In Transit',
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
            ),
          ],
        ),
      );
    }

    if (status == 'Received') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
            const SizedBox(width: 5),
            Text(
              'Received',
              style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
            ),
          ],
        ),
      );
    }

    // Partial Receipt
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 13, color: Color(0xFFDC2626)),
          const SizedBox(width: 5),
          Text(
            'Partial Receipt',
            style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }

  // 4. AI Receiving Insights Banner
  Widget _buildAiInsightsBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Top Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 22),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Receiving Insights',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Get intelligent recommendations to process receipts faster and accurately.',
                        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: _showAiInsightsModal,
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Learn More'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB45309),
                  side: const BorderSide(color: Color(0xFFF59E0B)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 3 Feature Columns
          Row(
            children: [
              Expanded(
                child: _buildBannerFeatureItem(
                  icon: Icons.description_outlined,
                  title: 'Auto-match POs',
                  subtitle: 'Automatically match incoming items with purchase orders.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBannerFeatureItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Detect discrepancies',
                  subtitle: 'Identify quantity, variant or damaged item mismatches.',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBannerFeatureItem(
                  icon: Icons.access_time_rounded,
                  title: 'Speed up processing',
                  subtitle: 'Reduce manual work with AI-assisted verification.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Color(0xFFFBF4EB),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 19, color: const Color(0xFF92400E)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
