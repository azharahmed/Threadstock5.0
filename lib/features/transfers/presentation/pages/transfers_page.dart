// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

import '../widgets/dispatch_transfer_view.dart';
import '../widgets/new_stock_transfer_view.dart';
import '../widgets/receive_transfer_view.dart';
import '../widgets/receiving_queue_view.dart';
import '../widgets/transfer_order_detail_view.dart';

enum TransfersViewMode {
  overview,
  orderDetail,
  dispatchTransfer,
  receiveTransfer,
  receivingQueue,
  newTransfer,
}

class TransfersPage extends StatefulWidget {
  const TransfersPage({
    super.key,
    this.initialMode = TransfersViewMode.receivingQueue,
    this.initialTransferId = 'PO-2024-0847',
    this.onTitleChanged,
    this.onNavigateToOverview,
  });

  final TransfersViewMode initialMode;
  final String initialTransferId;
  final ValueChanged<String>? onTitleChanged;
  final VoidCallback? onNavigateToOverview;

  @override
  State<TransfersPage> createState() => _TransfersPageState();
}

class _StockTransfer {
  const _StockTransfer({
    required this.id,
    required this.fromLocation,
    required this.toLocation,
    required this.itemsSummary,
    required this.createdDate,
    required this.createdTimestamp,
    required this.eta,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.items,
  });

  final String id;
  final String fromLocation;
  final String toLocation;
  final String itemsSummary;
  final String createdDate;
  final String createdTimestamp;
  final String eta;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final List<_TransferItem> items;
}

class _TransferItem {
  const _TransferItem({
    required this.name,
    required this.variant,
    required this.quantity,
    required this.imageAsset,
  });

  final String name;
  final String variant;
  final String quantity;
  final String imageAsset;
}

class _TransfersPageState extends State<TransfersPage> {
  late TransfersViewMode _mode;
  late String _transferId;
  int _selectedTab = 0; // 0: All, 1: In Transit, 2: Pending, 3: Completed, 4: Draft
  String _selectedTransferId = 'TR-1022';
  final Set<String> _selectedRowIds = {};
  final _searchController = TextEditingController();
  bool _isAiCardDismissed = false;

  final List<_StockTransfer> _transfers = const [
    _StockTransfer(
      id: 'TR-1022',
      fromLocation: 'Central Warehouse',
      toLocation: 'Delhi Flagship Store',
      itemsSummary: '180 units',
      createdDate: 'Feb 10, 2027',
      createdTimestamp: 'Feb 10, 2027, 10:24 AM',
      eta: '1 Day',
      status: 'In Transit',
      statusBg: Color(0xFFEAF1FB),
      statusColor: Color(0xFF2662BA),
      items: [
        _TransferItem(
          name: 'Oxford Linen Shirt',
          variant: 'Black / M',
          quantity: '180 pcs',
          imageAsset: 'Assets/oxford_linen_shirt.jpg',
        ),
      ],
    ),
    _StockTransfer(
      id: 'TR-1025',
      fromLocation: 'Zone B Warehouse',
      toLocation: 'Central Warehouse',
      itemsSummary: '300 units',
      createdDate: 'Feb 12, 2027',
      createdTimestamp: 'Feb 12, 2027, 03:40 PM',
      eta: '—',
      status: 'Pending',
      statusBg: Color(0xFFFBF0DF),
      statusColor: Color(0xFF9E6516),
      items: [
        _TransferItem(
          name: 'Raw Denim Jeans',
          variant: 'Indigo / L',
          quantity: '300 pcs',
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
      ],
    ),
    _StockTransfer(
      id: 'TR-1029',
      fromLocation: 'Surat Hub',
      toLocation: 'Central Warehouse',
      itemsSummary: '120 units',
      createdDate: 'Feb 08, 2027',
      createdTimestamp: 'Feb 08, 2027, 11:15 AM',
      eta: '—',
      status: 'Completed',
      statusBg: Color(0xFFE9F6EE),
      statusColor: Color(0xFF1F7A46),
      items: [
        _TransferItem(
          name: 'Combed Cotton Jersey',
          variant: 'Natural / 280gsm',
          quantity: '120 pcs',
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
      ],
    ),
  ];

  _StockTransfer? get _selectedTransfer {
    try {
      return _transfers.firstWhere((t) => t.id == _selectedTransferId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _transferId = widget.initialTransferId;
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_StockTransfer> get _filteredTransfers {
    final query = _searchController.text.trim().toLowerCase();

    return _transfers.where((transfer) {
      // 1. Tab Filter
      if (_selectedTab == 1 && transfer.status != 'In Transit') return false;
      if (_selectedTab == 2 && transfer.status != 'Pending') return false;
      if (_selectedTab == 3 && transfer.status != 'Completed') return false;
      if (_selectedTab == 4 && transfer.status != 'Draft') return false;

      // 2. Search Query Filter
      if (query.isNotEmpty) {
        final matchesQuery = transfer.id.toLowerCase().contains(query) ||
            transfer.fromLocation.toLowerCase().contains(query) ||
            transfer.toLocation.toLowerCase().contains(query) ||
            transfer.itemsSummary.toLowerCase().contains(query) ||
            transfer.status.toLowerCase().contains(query);
        if (!matchesQuery) return false;
      }

      return true;
    }).toList();
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Color(0xFFBA8A55), size: 18),
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

  @override
  Widget build(BuildContext context) {
    if (_mode == TransfersViewMode.receivingQueue) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 16,
          child: ReceivingQueueView(
            onSelectPo: (poId) {
              setState(() {
                _transferId = poId;
                _mode = TransfersViewMode.receiveTransfer;
                widget.onTitleChanged?.call('Receiving Workflow');
              });
            },
            onLogReceipt: () {
              setState(() {
                _transferId = 'PO-2024-0847';
                _mode = TransfersViewMode.receiveTransfer;
                widget.onTitleChanged?.call('Receiving Workflow');
              });
            },
          ),
        ),
      );
    }

    if (_mode == TransfersViewMode.receiveTransfer) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 16,
          child: ReceiveTransferView(
            transferId: _transferId,
            onViewTransfer: () {
              setState(() {
                _mode = TransfersViewMode.receivingQueue;
                widget.onTitleChanged?.call('Receiving');
              });
            },
            onCompleteReceiving: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Receipt $_transferId completed and posted to inventory.'),
                  backgroundColor: const Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              setState(() {
                _mode = TransfersViewMode.receivingQueue;
                widget.onTitleChanged?.call('Receiving');
              });
            },
          ),
        ),
      );
    }

    if (_mode == TransfersViewMode.dispatchTransfer) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 16,
          child: DispatchTransferView(
            transferId: _transferId,
            onNavigateBack: () {
              setState(() {
                _mode = TransfersViewMode.orderDetail;
                widget.onTitleChanged?.call('TR-1042');
              });
            },
          ),
        ),
      );
    }

    if (_mode == TransfersViewMode.orderDetail) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 16,
          child: TransferOrderDetailView(
            transferId: _transferId,
            onCancelTransfer: () {
              setState(() {
                _mode = TransfersViewMode.overview;
                widget.onTitleChanged?.call('Stock Transfers');
              });
            },
          ),
        ),
      );
    }

    if (_mode == TransfersViewMode.newTransfer) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          maxWidth: 1360,
          child: NewStockTransferView(),
        ),
      );
    }

    final selectedTransfer = _selectedTransfer;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 24,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Responsive Split Layout: Left Table vs Right Intelligence & Details
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1050;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Stock Transfers Main Section (Header + Tabs + Filters + Table)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 20),
                              _buildTabsRow(),
                              const SizedBox(height: 18),
                              _buildFilterToolbar(),
                              const SizedBox(height: 16),
                              _buildTableCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Right: AI Auto-Replenishment + Transfer Details
                        SizedBox(
                          width: 360,
                          child: Column(
                            children: [
                              if (!_isAiCardDismissed) ...[
                                _buildAiAutoReplenishmentCard(),
                                const SizedBox(height: 20),
                              ],
                              if (selectedTransfer != null)
                                _buildTransferDetailsCard(selectedTransfer),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Compact Layout
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildTabsRow(),
                      const SizedBox(height: 18),
                      _buildFilterToolbar(),
                      const SizedBox(height: 16),
                      _buildTableCard(),
                      const SizedBox(height: 24),
                      if (!_isAiCardDismissed) ...[
                        _buildAiAutoReplenishmentCard(),
                        const SizedBox(height: 20),
                      ],
                      if (selectedTransfer != null)
                        _buildTransferDetailsCard(selectedTransfer),
                    ],
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // 1. HEADER ROW: Stock Transfers + 3 transfers active + Create Transfer
  // ========================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title & Active Count
        Row(
          children: [
            Text(
              'Stock Transfers',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 32,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '3 transfers active',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B6358),
              ),
            ),
          ],
        ),

        // Create Transfer CTA Button
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1C1A),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E1C1A).withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _showFeedback('Create stock transfer workflow initialized.'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Create Transfer',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // 2. STATUS TABS ROW
  // ========================================================
  Widget _buildTabsRow() {
    final tabs = [
      {'label': 'All', 'count': '3'},
      {'label': 'In Transit', 'count': '1'},
      {'label': 'Pending', 'count': '1'},
      {'label': 'Completed', 'count': '1'},
      {'label': 'Draft', 'count': '0'},
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8DFD3), width: 1.0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isSelected = _selectedTab == index;

            return InkWell(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? const Color(0xFFBA8A55)
                          : Colors.transparent,
                      width: 2.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tab['label']!,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF1E1C1A)
                            : const Color(0xFF7E766B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFAF3E6)
                            : const Color(0xFFF3ECE1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        tab['count']!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFF9E6516)
                              : const Color(0xFF7E766B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ========================================================
  // 3. FILTER TOOLBAR
  // ========================================================
  Widget _buildFilterToolbar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Search Input
          Container(
            width: 290,
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 17,
                  color: Color(0xFF8A8275),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search transfer ID, warehouse or items...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF9E958A),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Dropdown: From
          _buildDropdownFilter('From'),
          const SizedBox(width: 10),

          // Dropdown: To
          _buildDropdownFilter('To'),
          const SizedBox(width: 10),

          // Dropdown: Status
          _buildDropdownFilter('Status'),
          const SizedBox(width: 10),

          // Date Range Button
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF5E574E),
                ),
                const SizedBox(width: 6),
                Text(
                  'Date Range',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // More Filters Button
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.filter_list_rounded,
                  size: 16,
                  color: Color(0xFF5E574E),
                ),
                const SizedBox(width: 6),
                Text(
                  'More Filters',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFilter(String label) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDFD4C5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E1C1A),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: Color(0xFF8A8275),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 4. MAIN TRANSFERS TABLE CARD
  // ========================================================
  Widget _buildTableCard() {
    final transfers = _filteredTransfers;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Enclose table in horizontal scroll with fixed 760px minimum width for safety
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 760,
              child: Column(
                children: [
                  // Table Header Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEDE5DA), width: 1.0),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildCheckbox(
                          value: _selectedRowIds.length == transfers.length && transfers.isNotEmpty,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedRowIds.addAll(transfers.map((t) => t.id));
                              } else {
                                _selectedRowIds.clear();
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 14),
                        _buildTh('Transfer ID', flex: 2),
                        _buildTh('From', flex: 3),
                        _buildTh('To', flex: 3),
                        _buildTh('Items', flex: 2),
                        _buildTh('Created', flex: 2),
                        _buildTh('ETA', flex: 2),
                        _buildTh('Status', flex: 2),
                        const SizedBox(
                          width: 24,
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 16,
                            color: Color(0xFF8A8275),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Table Rows
                  if (transfers.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No stock transfers found matching criteria.',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: const Color(0xFF7E766B),
                          ),
                        ),
                      ),
                    )
                  else
                    ...transfers.map((transfer) {
                      final isRowSelected = _selectedTransferId == transfer.id;
                      final isChecked = _selectedRowIds.contains(transfer.id);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTransferId = transfer.id;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isRowSelected
                                ? const Color(0xFFFDF7EE)
                                : Colors.transparent,
                            border: const Border(
                              bottom: BorderSide(
                                color: Color(0xFFF1EAE0),
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildCheckbox(
                                value: isChecked,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedRowIds.add(transfer.id);
                                    } else {
                                      _selectedRowIds.remove(transfer.id);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 14),

                              // Transfer ID
                              Expanded(
                                flex: 2,
                                child: Text(
                                  transfer.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E1C1A),
                                  ),
                                ),
                              ),

                              // From
                              Expanded(
                                flex: 3,
                                child: Text(
                                  transfer.fromLocation,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF2A2520),
                                  ),
                                ),
                              ),

                              // To
                              Expanded(
                                flex: 3,
                                child: Text(
                                  transfer.toLocation,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF5E574E),
                                  ),
                                ),
                              ),

                              // Items
                              Expanded(
                                flex: 2,
                                child: Text(
                                  transfer.itemsSummary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF5E574E),
                                  ),
                                ),
                              ),

                              // Created
                              Expanded(
                                flex: 2,
                                child: Text(
                                  transfer.createdDate,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF5E574E),
                                  ),
                                ),
                              ),

                              // ETA
                              Expanded(
                                flex: 2,
                                child: Text(
                                  transfer.eta,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF5E574E),
                                  ),
                                ),
                              ),

                              // Status Badge
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: transfer.statusBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      transfer.status,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: transfer.statusColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Chevron Trailing
                              const SizedBox(
                                width: 24,
                                child: Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: Color(0xFF8A8275),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),

          // Pagination Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transfers.isEmpty
                      ? 'No transfers found'
                      : 'Showing 1–${transfers.length} of ${transfers.length} transfers',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7E766B),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFDFD4C5)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '10 per page',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1E1C1A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: Color(0xFF8A8275),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.chevron_left_rounded,
                      size: 18,
                      color: Color(0xFF8A8275),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFBA8A55)),
                      ),
                      child: Center(
                        child: Text(
                          '1',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFBA8A55),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFF8A8275),
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

  Widget _buildTh(String title, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF7E766B),
        ),
      ),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Checkbox(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1E1C1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: Color(0xFFCDC2B4), width: 1.2),
      ),
    );
  }

  // ========================================================
  // 5. RIGHT PANEL - CARD 1: AI AUTO-REPLENISHMENT
  // ========================================================
  Widget _buildAiAutoReplenishmentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBCA), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: AI Auto-Replenishment + More options
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_outlined,
                    size: 18,
                    color: Color(0xFFBA8A55),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI Auto-Replenishment',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF946A36),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded, size: 18),
                color: const Color(0xFF7E766B),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showFeedback('AI replenishment settings'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Inset Recommendation Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 48,
                    height: 48,
                    color: const Color(0xFF1E1C1A),
                    child: Image.asset(
                      'Assets/oxford_linen_shirt.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.checkroom_rounded,
                        color: Color(0xFFBA8A55),
                        size: 24,
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
                        'Oxford Linen Shirt — Black/M',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1C1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF5E574E),
                            height: 1.4,
                          ),
                          children: const [
                            TextSpan(
                              text:
                                  'Indira Nagar Store is projected to stock out in ',
                            ),
                            TextSpan(
                              text: '5 days',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E1C1A),
                              ),
                            ),
                            TextSpan(
                              text:
                                  ' due to high velocity. Central Warehouse has 42 units of excess stock.',
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
          const SizedBox(height: 16),

          // Metrics Rows
          _buildMetricsRow('Proposed Transfer', '18 units'),
          const SizedBox(height: 8),
          _buildMetricsRow('Estimated Transit', '2 Days'),
          const SizedBox(height: 18),

          // Primary CTA: Prepare Transfer
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF322316), Color(0xFF1C1814)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E2014).withOpacity(0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showFeedback(
                    'Transfer proposal for 18 units prepared and sent to dispatch queue.'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.near_me_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prepare Transfer',
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
            ),
          ),
          const SizedBox(height: 10),

          // Secondary CTA: Dismiss Recommendation
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() => _isAiCardDismissed = true);
                  _showFeedback('Recommendation dismissed.');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Center(
                    child: Text(
                      'Dismiss Recommendation',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1E1C1A),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 6. RIGHT PANEL - CARD 2: TRANSFER DETAILS
  // ========================================================
  Widget _buildTransferDetailsCard(_StockTransfer transfer) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Transfer Details + More
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transfer Details',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz_rounded, size: 18),
                color: const Color(0xFF7E766B),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showFeedback('Transfer actions menu'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Transfer ID
          _buildDetailRow('Transfer ID', transfer.id, isBold: true),
          const SizedBox(height: 10),

          // From
          _buildDetailRow('From', transfer.fromLocation),
          const SizedBox(height: 10),

          // To
          _buildDetailRow('To', transfer.toLocation),
          const SizedBox(height: 10),

          // Created On
          _buildDetailRow('Created On', transfer.createdTimestamp),
          const SizedBox(height: 10),

          // ETA
          _buildDetailRow('ETA', transfer.eta),
          const SizedBox(height: 10),

          // Status Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7E766B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: transfer.statusBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  transfer.status,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: transfer.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Items (1)
          Text(
            'Items (${transfer.items.length})',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1C1A),
            ),
          ),
          const SizedBox(height: 12),
          ...transfer.items.map((item) {
            return Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 42,
                    height: 42,
                    color: const Color(0xFF1A2740),
                    child: Image.asset(
                      item.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.checkroom_rounded,
                        color: Color(0xFFBA8A55),
                        size: 20,
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1C1A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.variant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  item.quantity,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 14),

          // View all items link
          InkWell(
            onTap: () => _showFeedback('View all items manifest modal'),
            child: Row(
              children: [
                Text(
                  'View all items',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFBA8A55),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Color(0xFFBA8A55),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // View Transfer History Outlined Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showFeedback('Transfer audit history opened.'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Color(0xFF1E1C1A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'View Transfer History',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E1C1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF7E766B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1C1A),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF7E766B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isBold ? 13.5 : 12.5,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
            color: const Color(0xFF1E1C1A),
          ),
        ),
      ],
    );
  }
}
