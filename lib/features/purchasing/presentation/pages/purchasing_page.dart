// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';
import '../widgets/access_restricted_view.dart';
import '../widgets/create_purchase_order_view.dart';
import '../widgets/po_10482_detail_view.dart';
import '../widgets/po_detail_view.dart';
import '../widgets/return_to_supplier_view.dart';

enum PurchasingViewMode {
  overview,
  poDetail,
  accessRestricted,
  returnToSupplier,
  createPo,
  poDetail10482,
}

class PurchasingPage extends StatefulWidget {
  const PurchasingPage({
    super.key,
    this.initialMode = PurchasingViewMode.accessRestricted,
    this.initialPoNumber = 'PO-2024-8902',
    this.onTitleChanged,
    this.onNavigateToDashboard,
  });

  final PurchasingViewMode initialMode;
  final String initialPoNumber;
  final ValueChanged<String>? onTitleChanged;
  final VoidCallback? onNavigateToDashboard;

  @override
  State<PurchasingPage> createState() => _PurchasingPageState();
}

class _PurchaseOrder {
  const _PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.supplier,
    required this.destination,
    required this.itemsSummary,
    required this.totalValue,
    required this.eta,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.createdOn,
    required this.createdBy,
    required this.notes,
    required this.items,
  });

  final String id;
  final String poNumber;
  final String supplier;
  final String destination;
  final String itemsSummary;
  final String totalValue;
  final String eta;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final String createdOn;
  final String createdBy;
  final String notes;
  final List<_PoItem> items;
}

class _PoItem {
  const _PoItem({
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

class _PurchasingPageState extends State<PurchasingPage> {
  late PurchasingViewMode _mode;
  late String _selectedPoNumber;
  int _selectedTab = 2; // Default to 'Awaiting Approval' tab as in screenshot
  String _selectedPoId = 'PO-4098'; // Selected PO in screenshot
  final Set<String> _selectedRowIds = {};
  final _searchController = TextEditingController();

  final List<_PurchaseOrder> _orders = const [
    _PurchaseOrder(
      id: 'PO-4098',
      poNumber: 'PO-4098',
      supplier: 'Surat Denim Ltd',
      destination: 'Delhi Store Hub',
      itemsSummary: '1,200 units',
      totalValue: '₹15,20,000',
      eta: 'Feb 18, 2027',
      status: 'Awaiting Approval',
      statusBg: Color(0xFFFBF0DF),
      statusColor: Color(0xFF9E6516),
      createdOn: 'Oct 15, 2024, 10:24 AM',
      createdBy: 'Alex Mercer',
      notes: 'Urgent stock for new collection.\nPlease review and approve.',
      items: [
        _PoItem(
          name: 'Raw Denim Jeans',
          variant: 'Indigo / L',
          quantity: '800 pcs',
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
        _PoItem(
          name: 'Raw Denim Jeans',
          variant: 'Black / M',
          quantity: '400 pcs',
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
      ],
    ),
    _PurchaseOrder(
      id: 'PO-4091',
      poNumber: 'PO-4091',
      supplier: 'Bialla Mills',
      destination: 'Central Warehouse',
      itemsSummary: '850 units',
      totalValue: '₹24,50,000',
      eta: 'Today',
      status: 'Arrived',
      statusBg: Color(0xFFE9F6EE),
      statusColor: Color(0xFF1F7A46),
      createdOn: 'Oct 12, 2024, 02:15 PM',
      createdBy: 'Elena Rostova',
      notes: 'Cotton jersey fabric rolls for Atelier production run.',
      items: [
        _PoItem(
          name: 'Combed Cotton Jersey',
          variant: 'Natural / 280gsm',
          quantity: '550 pcs',
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
        _PoItem(
          name: 'Ribbed Collar Trim',
          variant: 'Oatmeal / 120m',
          quantity: '300 pcs',
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
      ],
    ),
    _PurchaseOrder(
      id: 'PO-4094',
      poNumber: 'PO-4094',
      supplier: 'Prato Knitwear Co.',
      destination: 'Central Warehouse',
      itemsSummary: '400 units',
      totalValue: '₹8,40,000',
      eta: 'Today',
      status: 'In Transit',
      statusBg: Color(0xFFEAF1FB),
      statusColor: Color(0xFF2662BA),
      createdOn: 'Oct 14, 2024, 11:30 AM',
      createdBy: 'Marcus Vance',
      notes: 'Merino wool cardigans shipment dispatched via express freight.',
      items: [
        _PoItem(
          name: 'Fine Merino Cardigan',
          variant: 'Camel / S-M',
          quantity: '250 pcs',
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
        _PoItem(
          name: 'Fine Merino Cardigan',
          variant: 'Charcoal / L-XL',
          quantity: '150 pcs',
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
      ],
    ),
    _PurchaseOrder(
      id: 'PO-4102',
      poNumber: 'PO-4102',
      supplier: 'Bialla Mills',
      destination: 'Central Warehouse',
      itemsSummary: '300 units',
      totalValue: '₹11,80,000',
      eta: 'Feb 24, 2027',
      status: 'Draft',
      statusBg: Color(0xFFF0EBE3),
      statusColor: Color(0xFF6B6358),
      createdOn: 'Oct 17, 2024, 04:45 PM',
      createdBy: 'Alex Mercer',
      notes: 'Draft PO under review for Spring/Summer initial batch.',
      items: [
        _PoItem(
          name: 'Mulberry Silk Blend',
          variant: 'Ivory / 140cm',
          quantity: '300 pcs',
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
      ],
    ),
  ];

  _PurchaseOrder? get _selectedOrder {
    try {
      return _orders.firstWhere((po) => po.id == _selectedPoId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _selectedPoNumber = widget.initialPoNumber;
    _searchController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mode == PurchasingViewMode.accessRestricted) {
        widget.onTitleChanged?.call('Purchasing Settings');
      } else if (_mode == PurchasingViewMode.poDetail) {
        widget.onTitleChanged?.call('PO $_selectedPoNumber');
      } else if (_mode == PurchasingViewMode.returnToSupplier) {
        widget.onTitleChanged?.call('Return to Supplier');
      } else if (_mode == PurchasingViewMode.createPo) {
        widget.onTitleChanged?.call('Create Purchase Order');
      } else if (_mode == PurchasingViewMode.poDetail10482) {
        widget.onTitleChanged?.call('PO #10482');
      } else {
        widget.onTitleChanged?.call('Purchase Orders');
      }
    });
  }

  List<_PurchaseOrder> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _orders;
    return _orders.where((order) {
      return order.poNumber.toLowerCase().contains(query) ||
          order.supplier.toLowerCase().contains(query) ||
          order.destination.toLowerCase().contains(query) ||
          order.status.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    if (_mode == PurchasingViewMode.returnToSupplier) {
      return ReturnToSupplierView(
        poNumber: 'PO #10482',
        supplier: 'Milano Tessuti',
        poDate: '12 Jan 2027',
        receivedDate: '18 Jan 2027',
        onViewOriginalPo: () {
          setState(() {
            _mode = PurchasingViewMode.poDetail;
            _selectedPoNumber = 'PO #10482';
            widget.onTitleChanged?.call('PO #10482');
          });
        },
        onCreatePurchaseReturn: () {
          _showFeedback('Purchase return created successfully for Milano Tessuti.');
        },
        onSaveDraft: () {
          _showFeedback('Return draft saved.');
        },
      );
    }

    if (_mode == PurchasingViewMode.createPo) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          maxWidth: 1320,
          child: CreatePurchaseOrderView(
            onCreateOrder: () {
              _showFeedback('Purchase Order created successfully.');
              setState(() {
                _mode = PurchasingViewMode.poDetail10482;
                widget.onTitleChanged?.call('PO #10482');
              });
            },
            onSaveDraft: () => _showFeedback('Draft saved.'),
          ),
        ),
      );
    }

    if (_mode == PurchasingViewMode.poDetail10482) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          maxWidth: 1320,
          child: PO10482DetailView(
            onBackToOverview: () {
              setState(() {
                _mode = PurchasingViewMode.overview;
                widget.onTitleChanged?.call('Purchase Orders');
              });
            },
            onNavigateToInvoice: () {
              _showFeedback('Opening PO #10482 invoice...');
            },
          ),
        ),
      );
    }

    if (_mode == PurchasingViewMode.accessRestricted) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          maxWidth: 1320,
          child: AccessRestrictedView(
            resourceName: 'Purchasing settings',
            roleName: 'Cashier',
            onGoToDashboard: widget.onNavigateToDashboard,
            onSwitchToAdmin: () {
              setState(() {
                _mode = PurchasingViewMode.overview;
                widget.onTitleChanged?.call('Purchase Orders');
              });
            },
          ),
        ),
      );
    }

    if (_mode == PurchasingViewMode.poDetail) {
      return PoDetailView(
        poNumber: _selectedPoNumber,
        onBackToOverview: () {
          setState(() {
            _mode = PurchasingViewMode.overview;
          });
          widget.onTitleChanged?.call('Purchasing');
        },
      );
    }

    final selectedPo = _selectedOrder;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 24,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header: Purchase Orders + 4 active orders + Import / Create PO
              _buildHeader(),
              const SizedBox(height: 20),

              // 2. Tabs Row: All (12), Draft (3), Awaiting Approval (1), etc.
              _buildTabsRow(),
              const SizedBox(height: 18),

              // 3. Filter Toolbar
              _buildFilterToolbar(),
              const SizedBox(height: 16),

              // 4. Main Content: Table + Optional Detail Panel
              LayoutBuilder(
                builder: (context, constraints) {
                  final showSideBySide =
                      constraints.maxWidth >= 1050 && selectedPo != null;

                  if (showSideBySide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Table Card
                        Expanded(
                          child: _buildTableCard(),
                        ),
                        const SizedBox(width: 18),

                        // Right: PO Detail Panel (360 px width)
                        SizedBox(
                          width: 360,
                          child: _buildDetailPanel(selectedPo),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _buildTableCard(),
                      if (selectedPo != null) ...[
                        const SizedBox(height: 20),
                        _buildDetailPanel(selectedPo),
                      ],
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
  // 1. HEADER ROW
  // ========================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title & Active Count
        Row(
          children: [
            Text(
              'Purchase Orders',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 32,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '4 active orders',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B6358),
              ),
            ),
          ],
        ),

        // Actions: Import & Create PO
        Row(
          children: [
            // Import Button
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDFD4C5)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showFeedback('Import purchase orders modal'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.file_upload_outlined,
                          size: 16,
                          color: Color(0xFF1E1C1A),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Import',
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
            const SizedBox(width: 10),

            // Create PO Button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1C1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showFeedback('Create Purchase Order workflow'),
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
                          'Create PO',
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
            const SizedBox(width: 10),

            // Cashier / Restricted View Preview Button
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF3E8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEADBCA)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      _mode = PurchasingViewMode.accessRestricted;
                      widget.onTitleChanged?.call('Purchasing Settings');
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 15,
                          color: Color(0xFF8D6433),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Simulate Cashier Role',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8D6433),
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
      ],
    );
  }

  // ========================================================
  // 2. TABS ROW
  // ========================================================
  Widget _buildTabsRow() {
    final tabs = [
      {'label': 'All', 'count': '12'},
      {'label': 'Draft', 'count': '3'},
      {'label': 'Awaiting Approval', 'count': '1'},
      {'label': 'Ordered', 'count': '5'},
      {'label': 'Received', 'count': '3'},
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
            width: 280,
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
                      hintText: 'Search PO number, supplier or items...',
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

          // Dropdown: Supplier
          _buildDropdownFilter('Supplier'),
          const SizedBox(width: 10),

          // Dropdown: Status
          _buildDropdownFilter('Status'),
          const SizedBox(width: 10),

          // Dropdown: Date Range
          _buildDropdownFilter('Date Range'),
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
          const SizedBox(width: 10),

          // View Switcher (List View Icon)
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: const Center(
              child: Icon(
                Icons.view_headline_rounded,
                size: 18,
                color: Color(0xFF5E574E),
              ),
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
  // 4. MAIN PURCHASE ORDERS TABLE CARD
  // ========================================================
  Widget _buildTableCard() {
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
          // Table Headers & Rows inside horizontal scroll for zero-overflow safety
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 780,
              child: Column(
                children: [
                  // Table Header
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
                          value: _selectedRowIds.length == _orders.length,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedRowIds.addAll(_orders.map((o) => o.id));
                              } else {
                                _selectedRowIds.clear();
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 14),
                        _buildTh('PO Number', flex: 2),
                        _buildTh('Supplier', flex: 3),
                        _buildTh('Destination', flex: 3),
                        _buildTh('Items', flex: 2),
                        _buildTh('Total Value', flex: 3),
                        _buildTh('ETA', flex: 2),
                        _buildTh(
                          'Status',
                          flex: 3,
                          trailing: const Icon(
                            Icons.unfold_more_rounded,
                            size: 14,
                            color: Color(0xFF8A8275),
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),
                  ),

                  // Table Rows
                  ..._filteredOrders.map((order) {
                    final isRowSelected = _selectedPoId == order.id;
                    final isChecked = _selectedRowIds.contains(order.id);

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPoId = order.id;
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
                                    _selectedRowIds.add(order.id);
                                  } else {
                                    _selectedRowIds.remove(order.id);
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 14),

                            // PO Number
                            Expanded(
                              flex: 2,
                              child: Text(
                                order.poNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1C1A),
                                ),
                              ),
                            ),

                            // Supplier
                            Expanded(
                              flex: 3,
                              child: Text(
                                order.supplier,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF2A2520),
                                ),
                              ),
                            ),

                            // Destination
                            Expanded(
                              flex: 3,
                              child: Text(
                                order.destination,
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
                                order.itemsSummary,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF5E574E),
                                ),
                              ),
                            ),

                            // Total Value
                            Expanded(
                              flex: 3,
                              child: Text(
                                order.totalValue,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E1C1A),
                                ),
                              ),
                            ),

                            // ETA
                            Expanded(
                              flex: 2,
                              child: Text(
                                order.eta,
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
                              flex: 3,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: order.statusBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    order.status,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: order.statusColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Trailing Arrow
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Color(0xFF8A8275),
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
                  _filteredOrders.isEmpty
                      ? 'No orders found matching search'
                      : 'Showing 1–${_filteredOrders.length} of ${_filteredOrders.length} orders',
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

  Widget _buildTh(String title, {required int flex, Widget? trailing}) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Flexible(
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
          ),
          if (trailing != null) ...[
            const SizedBox(width: 4),
            trailing,
          ],
        ],
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
  // 5. RIGHT PO DETAIL PANEL
  // ========================================================
  Widget _buildDetailPanel(_PurchaseOrder po) {
    return Container(
      padding: const EdgeInsets.all(22),
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
          // Header: PO-4098 Details + More / Close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${po.poNumber} Details',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.more_horiz_rounded, size: 18),
                    color: const Color(0xFF7E766B),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showFeedback('More actions menu'),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: const Color(0xFF7E766B),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() => _selectedPoId = ''),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Supplier
          Text(
            'Supplier',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                po.supplier,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
              InkWell(
                onTap: () => _showFeedback('Navigating to supplier details'),
                child: Row(
                  children: [
                    Text(
                      'View Supplier',
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
            ],
          ),
          const SizedBox(height: 14),

          // Destination
          Text(
            'Destination',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            po.destination,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1C1A),
            ),
          ),
          const SizedBox(height: 14),

          // Expected Date
          Text(
            'Expected Date',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                po.eta,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: Color(0xFF6B6358),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Items (2)
          Text(
            'Items (${po.items.length})',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1C1A),
            ),
          ),
          const SizedBox(height: 10),
          ...po.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 40,
                      height: 40,
                      color: const Color(0xFF1A2740),
                      child: Image.asset(
                        item.imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
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
              ),
            );
          }),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFEADBCA), height: 1),
          const SizedBox(height: 14),

          // Total Items
          _buildSummaryRow('Total Items', po.itemsSummary),
          const SizedBox(height: 8),

          // Total Value
          _buildSummaryRow(
            'Total Value',
            po.totalValue,
            isBold: true,
          ),
          const SizedBox(height: 8),

          // Status
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
                  color: po.statusBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  po.status,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: po.statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Created By
          _buildSummaryRow('Created By', po.createdBy),
          const SizedBox(height: 8),

          // Created On
          _buildSummaryRow('Created On', po.createdOn),
          const SizedBox(height: 14),

          // Notes
          Text(
            'Notes',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF7F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Text(
              po.notes,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF423B33),
                height: 1.45,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Approve Purchase Order Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF241E18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  setState(() {
                    _selectedPoNumber = po.poNumber;
                    _mode = PurchasingViewMode.poDetail;
                  });
                  widget.onTitleChanged?.call('Purchasing Operations');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 17,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Approve Purchase Order',
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

          // Reject PO Button
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
                onTap: () => _showFeedback(
                    'Purchase Order ${po.poNumber} rejected.'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        size: 17,
                        color: Color(0xFFB83A28),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Reject PO',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB83A28),
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

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
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
