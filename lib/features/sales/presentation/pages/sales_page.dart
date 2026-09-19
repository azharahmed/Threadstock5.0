// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';
import '../widgets/customers_view.dart';
import '../widgets/held_sales_view.dart';
import '../widgets/new_sale_view.dart';
import '../widgets/return_exchange_view.dart';
import '../widgets/sale_detail_view.dart';
import '../widgets/sale_invoice_view.dart';
import '../widgets/sales_analytics_view.dart';

enum SalesPageMode {
  analytics,
  overview,
  newSale,
  saleDetail,
  heldSales,
  invoice,
  customers,
  returnExchange,
}

class SalesPage extends StatefulWidget {
  const SalesPage({
    super.key,
    this.initialMode = SalesPageMode.analytics,
    this.initialSaleId = '#TS-10482',
    this.onTitleChanged,
  });

  final SalesPageMode initialMode;
  final String initialSaleId;
  final ValueChanged<String>? onTitleChanged;

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SaleItem {
  const _SaleItem({
    required this.title,
    required this.variantInfo,
    required this.price,
    required this.imageAsset,
  });

  final String title;
  final String variantInfo;
  final String price;
  final String imageAsset;
}

class _SalesTransaction {
  const _SalesTransaction({
    required this.id,
    required this.customerName,
    required this.itemsSummary,
    required this.location,
    required this.paymentMethod,
    required this.totalAmount,
    required this.status,
    required this.time,
    required this.cashier,
    required this.paymentDetails,
    required this.dateTime,
    required this.subtotal,
    required this.cgst,
    required this.sgst,
    required this.totalWithTax,
    required this.items,
  });

  final String id;
  final String customerName;
  final String itemsSummary;
  final String location;
  final String paymentMethod;
  final String totalAmount;
  final String status;
  final String time;
  final String cashier;
  final String paymentDetails;
  final String dateTime;
  final String subtotal;
  final String cgst;
  final String sgst;
  final String totalWithTax;
  final List<_SaleItem> items;
}

class _SalesPageState extends State<SalesPage> {
  late SalesPageMode _mode;
  int _selectedTab = 0; // 0: All Sales, 1: Returns, 2: Exchanges
  late String _selectedSaleId;
  final Set<String> _selectedRowIds = {};
  final _searchController = TextEditingController();

  final List<_SalesTransaction> _transactions = const [
    _SalesTransaction(
      id: '#TS-10482',
      customerName: 'Emma\nCarter',
      itemsSummary: '2 items',
      location: 'Central Store',
      paymentMethod: 'Card\n(Visa 4292)',
      totalAmount: '₹8,420',
      status: 'Completed',
      time: '10:42 AM',
      cashier: 'Priya S.',
      paymentDetails: 'Visa Ending 4292',
      dateTime: 'Feb 18, 2027, 10:42 AM',
      subtotal: '₹8,420',
      cgst: '₹757.80',
      sgst: '₹757.80',
      totalWithTax: '₹9,935.60',
      items: [
        _SaleItem(
          title: 'Oxford Linen Shirt',
          variantInfo: 'Black • M • QTY: 2',
          price: '₹4,980',
          imageAsset: 'Assets/oxford_linen_shirt.jpg',
        ),
        _SaleItem(
          title: 'Raw Denim Jeans',
          variantInfo: 'Indigo • L • QTY: 1',
          price: '₹3,440',
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
      ],
    ),
    _SalesTransaction(
      id: '#TS-10481',
      customerName: 'Aarav\nSharma',
      itemsSummary: '1 item',
      location: 'Delhi Flagship',
      paymentMethod: 'UPI',
      totalAmount: '₹2,490',
      status: 'Completed',
      time: '10:15 AM',
      cashier: 'Rohit M.',
      paymentDetails: 'Google Pay (UPI)',
      dateTime: 'Feb 18, 2027, 10:15 AM',
      subtotal: '₹2,490',
      cgst: '₹224.10',
      sgst: '₹224.10',
      totalWithTax: '₹2,938.20',
      items: [
        _SaleItem(
          title: 'Oxford Linen Shirt',
          variantInfo: 'Blue • L • QTY: 1',
          price: '₹2,490',
          imageAsset: 'Assets/oxford_linen_shirt_blue.jpg',
        ),
      ],
    ),
    _SalesTransaction(
      id: '#TS-10480',
      customerName: 'Riya\nSen',
      itemsSummary: '3 items',
      location: 'Central Store',
      paymentMethod: 'Card',
      totalAmount: '₹11,890',
      status: 'Completed',
      time: '09:58 AM',
      cashier: 'Priya S.',
      paymentDetails: 'Mastercard Ending 8812',
      dateTime: 'Feb 18, 2027, 09:58 AM',
      subtotal: '₹11,890',
      cgst: '₹1,070.10',
      sgst: '₹1,070.10',
      totalWithTax: '₹14,030.20',
      items: [
        _SaleItem(
          title: 'Silk Evening Dress',
          variantInfo: 'Bronze • S • QTY: 1',
          price: '₹11,890',
          imageAsset: 'Assets/silk_evening_dress.jpg',
        ),
      ],
    ),
    _SalesTransaction(
      id: '#TS-10479',
      customerName: 'Kavya\nMehta',
      itemsSummary: '4 items',
      location: 'Central Store',
      paymentMethod: 'Card',
      totalAmount: '₹14,320',
      status: 'Completed',
      time: '09:21 AM',
      cashier: 'Priya S.',
      paymentDetails: 'Amex Ending 1004',
      dateTime: 'Feb 18, 2027, 09:21 AM',
      subtotal: '₹14,320',
      cgst: '₹1,288.80',
      sgst: '₹1,288.80',
      totalWithTax: '₹16,897.60',
      items: [
        _SaleItem(
          title: 'Merino Wool Blazer',
          variantInfo: 'Charcoal • 40R • QTY: 1',
          price: '₹14,320',
          imageAsset: 'Assets/merino_wool_blazer.jpg',
        ),
      ],
    ),
    _SalesTransaction(
      id: '#TS-10478',
      customerName: 'Arjun\nNair',
      itemsSummary: '1 item',
      location: 'Mumbai Hub',
      paymentMethod: 'UPI',
      totalAmount: '₹3,280',
      status: 'Completed',
      time: '09:05 AM',
      cashier: 'Deepak K.',
      paymentDetails: 'Paytm UPI',
      dateTime: 'Feb 18, 2027, 09:05 AM',
      subtotal: '₹3,280',
      cgst: '₹295.20',
      sgst: '₹295.20',
      totalWithTax: '₹3,870.40',
      items: [
        _SaleItem(
          title: 'Raw Denim Jeans',
          variantInfo: 'Black • 32 • QTY: 1',
          price: '₹3,280',
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
      ],
    ),
    _SalesTransaction(
      id: '#TS-10477',
      customerName: 'Neha\nKapoor',
      itemsSummary: '2 items',
      location: 'Central Store',
      paymentMethod: 'Card',
      totalAmount: '₹6,760',
      status: 'Completed',
      time: '08:47 AM',
      cashier: 'Priya S.',
      paymentDetails: 'Visa Ending 7721',
      dateTime: 'Feb 18, 2027, 08:47 AM',
      subtotal: '₹6,760',
      cgst: '₹608.40',
      sgst: '₹608.40',
      totalWithTax: '₹7,976.80',
      items: [
        _SaleItem(
          title: 'Oxford Linen Shirt',
          variantInfo: 'White • S • QTY: 2',
          price: '₹6,760',
          imageAsset: 'Assets/oxford_linen_shirt_blue.jpg',
        ),
      ],
    ),
    _SalesTransaction(
      id: '#TS-10476',
      customerName: 'Vikram\nJoshi',
      itemsSummary: '5 items',
      location: 'Delhi Flagship',
      paymentMethod: 'Card',
      totalAmount: '₹18,450',
      status: 'Completed',
      time: '08:32 AM',
      cashier: 'Rohit M.',
      paymentDetails: 'Visa Ending 3319',
      dateTime: 'Feb 18, 2027, 08:32 AM',
      subtotal: '₹18,450',
      cgst: '₹1,660.50',
      sgst: '₹1,660.50',
      totalWithTax: '₹21,771.00',
      items: [
        _SaleItem(
          title: 'Gabardine Trench',
          variantInfo: 'Camel • 42 • QTY: 1',
          price: '₹18,450',
          imageAsset: 'Assets/gabardine_trench.jpg',
        ),
      ],
    ),
    _SalesTransaction(
      id: '#TS-10475',
      customerName: 'Sara\nKhan',
      itemsSummary: '2 items',
      location: 'Central Store',
      paymentMethod: 'UPI',
      totalAmount: '₹5,980',
      status: 'Completed',
      time: '08:15 AM',
      cashier: 'Priya S.',
      paymentDetails: 'PhonePe UPI',
      dateTime: 'Feb 18, 2027, 08:15 AM',
      subtotal: '₹5,980',
      cgst: '₹538.20',
      sgst: '₹538.20',
      totalWithTax: '₹7,056.40',
      items: [
        _SaleItem(
          title: 'Raw Denim Jeans',
          variantInfo: 'Indigo • M • QTY: 1',
          price: '₹3,490',
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
        _SaleItem(
          title: 'Oxford Linen Shirt',
          variantInfo: 'Blue • M • QTY: 1',
          price: '₹2,490',
          imageAsset: 'Assets/oxford_linen_shirt_blue.jpg',
        ),
      ],
    ),
  ];

  _SalesTransaction? get _selectedTransaction {
    try {
      return _transactions.firstWhere((t) => t.id == _selectedSaleId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _selectedSaleId = widget.initialSaleId;
    _searchController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mode == SalesPageMode.analytics) {
        widget.onTitleChanged?.call('Sales Analytics');
      } else if (_mode == SalesPageMode.saleDetail) {
        widget.onTitleChanged?.call('Sale $_selectedSaleId');
      } else if (_mode == SalesPageMode.newSale) {
        widget.onTitleChanged?.call('New Sale');
      } else if (_mode == SalesPageMode.heldSales) {
        widget.onTitleChanged?.call('Held Sales');
      } else if (_mode == SalesPageMode.invoice) {
        widget.onTitleChanged?.call('PO-10482 Invoice');
      } else if (_mode == SalesPageMode.customers) {
        widget.onTitleChanged?.call('Customers');
      } else if (_mode == SalesPageMode.returnExchange) {
        widget.onTitleChanged?.call('Return / Exchange');
      } else {
        widget.onTitleChanged?.call('Sales');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SalesTransaction> get _filteredTransactions {
    final query = _searchController.text.trim().toLowerCase();

    return _transactions.where((t) {
      if (query.isNotEmpty) {
        final matches = t.id.toLowerCase().contains(query) ||
            t.customerName.toLowerCase().contains(query) ||
            t.location.toLowerCase().contains(query) ||
            t.paymentMethod.toLowerCase().contains(query);
        if (!matches) return false;
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
    if (_mode == SalesPageMode.analytics) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 24,
          child: SingleChildScrollView(
            child: SalesAnalyticsView(
              onNavigateToOverview: () {
                setState(() {
                  _mode = SalesPageMode.overview;
                  widget.onTitleChanged?.call('Sales');
                });
              },
              onNavigateToNewSale: () {
                setState(() {
                  _mode = SalesPageMode.newSale;
                  widget.onTitleChanged?.call('New Sale');
                });
              },
              onNavigateToSaleDetail: (saleId) {
                setState(() {
                  _selectedSaleId = saleId;
                  _mode = SalesPageMode.saleDetail;
                  widget.onTitleChanged?.call('Sale $saleId');
                });
              },
            ),
          ),
        ),
      );
    }

    if (_mode == SalesPageMode.saleDetail) {
      return SaleDetailView(
        saleId: _selectedSaleId,
        onBackToOverview: () {
          setState(() {
            _mode = SalesPageMode.overview;
          });
          widget.onTitleChanged?.call('Sales');
        },
      );
    }

    if (_mode == SalesPageMode.newSale) {
      return NewSaleView(
        onBackToOverview: () {
          setState(() {
            _mode = SalesPageMode.overview;
          });
          widget.onTitleChanged?.call('Sales');
        },
      );
    }

    if (_mode == SalesPageMode.heldSales) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          maxWidth: 1320,
          child: const HeldSalesView(),
        ),
      );
    }

    if (_mode == SalesPageMode.invoice) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          maxWidth: 1200,
          child: const SaleInvoiceView(),
        ),
      );
    }

    if (_mode == SalesPageMode.customers) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          maxWidth: 1400,
          child: const CustomersView(),
        ),
      );
    }

    if (_mode == SalesPageMode.returnExchange) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          maxWidth: 1400,
          child: ReturnExchangeView(
            onBackToSales: () {
              setState(() {
                _mode = SalesPageMode.overview;
              });
              widget.onTitleChanged?.call('Sales');
            },
          ),
        ),
      );
    }

    final selectedTx = _selectedTransaction;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 24,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Responsive Split Layout: Left Table vs Right Selected Transaction
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1050 && selectedTx != null;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Sales Overview & Table
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 20),
                              _buildKpiMetricsRow(),
                              const SizedBox(height: 20),
                              _buildTableCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),

                        // Right: Selected Transaction Panel (approx 360px width)
                        SizedBox(
                          width: 360,
                          child: _buildSelectedTransactionPanel(selectedTx),
                        ),
                      ],
                    );
                  }

                  // Compact / Stacked Layout
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 20),
                      _buildKpiMetricsRow(),
                      const SizedBox(height: 20),
                      _buildTableCard(),
                      if (selectedTx != null) ...[
                        const SizedBox(height: 24),
                        _buildSelectedTransactionPanel(selectedTx),
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
  // 1. HEADER ROW: Sales Overview + Export & New Sale CTAs
  // ========================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Title & Description
        Row(
          children: [
            Text(
              'Sales Overview',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Track transactions, returns and customer activity',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B6358),
              ),
            ),
          ],
        ),

        // Action Buttons: Export + New Sale
        Row(
          children: [
            // Export
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDFD4C5)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showFeedback('Exporting sales activity log...'),
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
                          'Export',
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

            // New Sale
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
                  onTap: () {
                    setState(() {
                      _mode = SalesPageMode.newSale;
                    });
                    widget.onTitleChanged?.call('New Sale');
                  },
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
                          'New Sale',
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
        ),
      ],
    );
  }

  // ========================================================
  // 2. TOP 4 KPI CARDS
  // ========================================================
  Widget _buildKpiMetricsRow() {
    return Row(
      children: [
        // 1. Today's Sales
        Expanded(
          child: _buildTopKpiBox(
            icon: Icons.currency_rupee_rounded,
            iconBg: const Color(0xFFFAF4EA),
            iconColor: const Color(0xFF9E6516),
            label: 'Today\'s Sales',
            value: '₹1,48,200',
            trendText: '↑ 12%',
            trendSubtext: 'vs yesterday',
            isPositive: true,
          ),
        ),
        const SizedBox(width: 14),

        // 2. Orders
        Expanded(
          child: _buildTopKpiBox(
            icon: Icons.shopping_cart_outlined,
            iconBg: const Color(0xFFFAF4EA),
            iconColor: const Color(0xFF9E6516),
            label: 'Orders',
            value: '24',
            trendText: '↑ 8%',
            trendSubtext: 'vs yesterday',
            isPositive: true,
          ),
        ),
        const SizedBox(width: 14),

        // 3. Average Order Value
        Expanded(
          child: _buildAovKpiBox(),
        ),
        const SizedBox(width: 14),

        // 4. Returns Today
        Expanded(
          child: _buildReturnsKpiBox(),
        ),
      ],
    );
  }

  Widget _buildTopKpiBox({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String trendText,
    required String trendSubtext,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEADBCA)),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6358),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E1C1A),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trendText,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isPositive
                          ? const Color(0xFF1F7A46)
                          : const Color(0xFFB83A28),
                    ),
                  ),
                  Text(
                    trendSubtext,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8A8275),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAovKpiBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF4EA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEADBCA)),
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 14,
                  color: Color(0xFF9E6516),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Average Order Value',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6358),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹6,175',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F6EE),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Healthy',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F7A46),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReturnsKpiBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DFD3), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF4EA),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFEADBCA)),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 14,
                  color: Color(0xFF9E6516),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Returns Today',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6358),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '3',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF3E8),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Attention',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9E6516),
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
  // 3. MAIN SALES TRANSACTIONS TABLE CARD
  // ========================================================
  Widget _buildTableCard() {
    final transactions = _filteredTransactions;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
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
          // Filter Toolbar Row: Tabs + Search + Filter Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Tabs: All Sales, Returns, Exchanges
                Row(
                  children: [
                    _buildTabButton('All Sales', 0),
                    const SizedBox(width: 8),
                    _buildTabButton('Returns', 1),
                    const SizedBox(width: 8),
                    _buildTabButton('Exchanges', 2),
                  ],
                ),
                const Spacer(),

                // Search Input Field
                Container(
                  width: 220,
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFDFD4C5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 15,
                        color: Color(0xFF8A8275),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search by sale ID, customer, item...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 11.5,
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

                // Filter Button
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFDFD4C5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.filter_list_rounded,
                        size: 15,
                        color: Color(0xFF5E574E),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Filter',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E1C1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFEDE5DA), height: 1),

          // Enclose Table in horizontal scroll with fixed 760px min width for safety
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 760,
              child: Column(
                children: [
                  // Table Header Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFEDE5DA), width: 1.0),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildCheckbox(
                          value: _selectedRowIds.length == transactions.length && transactions.isNotEmpty,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedRowIds.addAll(transactions.map((t) => t.id));
                              } else {
                                _selectedRowIds.clear();
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 14),
                        _buildTh('Sale ID', flex: 2),
                        _buildTh('Customer', flex: 2),
                        _buildTh('Items', flex: 2),
                        _buildTh('Location', flex: 2),
                        _buildTh('Payment', flex: 2),
                        _buildTh('Total', flex: 2),
                        _buildTh('Status', flex: 2),
                        _buildTh('Time', flex: 2),
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
                  if (transactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: Center(
                        child: Text(
                          'No sales transactions found matching query.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF7E766B),
                          ),
                        ),
                      ),
                    )
                  else
                    ...transactions.map((tx) {
                      final isRowSelected = _selectedSaleId == tx.id;
                      final isChecked = _selectedRowIds.contains(tx.id);

                      return InkWell(
                        onTap: () => setState(() => _selectedSaleId = tx.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                      _selectedRowIds.add(tx.id);
                                    } else {
                                      _selectedRowIds.remove(tx.id);
                                    }
                                  });
                                },
                              ),
                              const SizedBox(width: 14),

                              // Sale ID
                              Expanded(
                                flex: 2,
                                child: Text(
                                  tx.id,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E1C1A),
                                  ),
                                ),
                              ),

                              // Customer Name
                              Expanded(
                                flex: 2,
                                child: Text(
                                  tx.customerName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF2A2520),
                                    height: 1.2,
                                  ),
                                ),
                              ),

                              // Items
                              Expanded(
                                flex: 2,
                                child: Text(
                                  tx.itemsSummary,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF5E574E),
                                  ),
                                ),
                              ),

                              // Location
                              Expanded(
                                flex: 2,
                                child: Text(
                                  tx.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF5E574E),
                                  ),
                                ),
                              ),

                              // Payment Method
                              Expanded(
                                flex: 2,
                                child: Text(
                                  tx.paymentMethod,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF5E574E),
                                    height: 1.2,
                                  ),
                                ),
                              ),

                              // Total
                              Expanded(
                                flex: 2,
                                child: Text(
                                  tx.totalAmount,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E1C1A),
                                  ),
                                ),
                              ),

                              // Status Pill
                              Expanded(
                                flex: 2,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE9F6EE),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      tx.status,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1F7A46),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Time
                              Expanded(
                                flex: 2,
                                child: Text(
                                  tx.time,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF7E766B),
                                  ),
                                ),
                              ),

                              // Chevron Right
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
                  'Showing 1–${transactions.length} of 24 sales',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7E766B),
                  ),
                ),
                Row(
                  children: [
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
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFDFD4C5)),
                      ),
                      child: Center(
                        child: Text(
                          '2',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5E574E),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFDFD4C5)),
                      ),
                      child: Center(
                        child: Text(
                          '3',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5E574E),
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
                    const SizedBox(width: 12),

                    // Dropdown: 10 per page
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
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;

    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E1C1A) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6B6358),
          ),
        ),
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
          fontSize: 11.5,
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
  // 4. RIGHT PANEL: SELECTED TRANSACTION DETAILS
  // ========================================================
  Widget _buildSelectedTransactionPanel(_SalesTransaction tx) {
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
          // Header: Selected Transaction + Close Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Transaction',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: const Color(0xFF7E766B),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _selectedSaleId = ''),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sale Title + Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sale ${tx.id}',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F6EE),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  tx.status,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F7A46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Key-Values
          _buildTxDetailRow('Customer', tx.customerName.replaceAll('\n', ' ')),
          const SizedBox(height: 10),
          _buildTxDetailRow('Location', tx.location),
          const SizedBox(height: 10),
          _buildTxDetailRow('Cashier', tx.cashier),
          const SizedBox(height: 10),
          _buildTxDetailRow('Payment', tx.paymentDetails),
          const SizedBox(height: 10),
          _buildTxDetailRow('Date & Time', tx.dateTime),
          const SizedBox(height: 20),

          // Products Purchased (2)
          Text(
            'Products Purchased (${tx.items.length})',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1C1A),
            ),
          ),
          const SizedBox(height: 12),

          // Product items list
          ...tx.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: 40,
                      height: 40,
                      color: const Color(0xFF1E1C1A),
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
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1C1A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.variantInfo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF7E766B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.price,
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
          const SizedBox(height: 8),
          const Divider(color: Color(0xFFEDE5DA), height: 1),
          const SizedBox(height: 12),

          // Financial breakdown
          _buildBreakdownRow('Subtotal', tx.subtotal),
          const SizedBox(height: 6),
          _buildBreakdownRow('CGST (9%)', tx.cgst),
          const SizedBox(height: 6),
          _buildBreakdownRow('SGST (9%)', tx.sgst),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFEDE5DA), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
              Text(
                tx.totalWithTax,
                style: GoogleFonts.inter(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Primary CTA: View Sale Details
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
                onTap: () {
                  setState(() {
                    _selectedSaleId = tx.id;
                    _mode = SalesPageMode.saleDetail;
                  });
                  widget.onTitleChanged?.call('Sale ${tx.id}');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'View Sale Details',
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
          const SizedBox(height: 10),

          // Secondary CTA: Print Receipt
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
                onTap: () => _showFeedback('Printing thermal POS receipt for ${tx.id}...'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.print_outlined,
                        size: 16,
                        color: Color(0xFF1E1C1A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Print Receipt',
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
          const SizedBox(height: 10),

          // Tertiary CTA: Return / Exchange
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF3C8C2)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _showFeedback('Return/Exchange workflow initiated for ${tx.id}.'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.sync_rounded,
                        size: 16,
                        color: Color(0xFFC2410C),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Return / Exchange',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFC2410C),
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

  Widget _buildTxDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF7E766B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E1C1A),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF7E766B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E1C1A),
          ),
        ),
      ],
    );
  }
}
