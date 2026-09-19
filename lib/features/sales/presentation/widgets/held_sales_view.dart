// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Data model ──────────────────────────────────────────────────────────────
class _HeldCartItem {
  const _HeldCartItem({
    required this.name,
    required this.variant,
    required this.sku,
    required this.qty,
    required this.price,
    required this.imageAsset,
  });
  final String name;
  final String variant;
  final String sku;
  final int qty;
  final int price;
  final String imageAsset;
}

class _HeldCart {
  const _HeldCart({
    required this.holdId,
    required this.customerName,
    required this.customerEmail,
    required this.avatarLabel,
    required this.avatarColor,
    required this.value,
    required this.location,
    required this.cashier,
    required this.heldAt,
    required this.heldAtDate,
    required this.expires,
    required this.expiresDate,
    required this.isExpired,
    required this.isExpiringSoon,
    required this.itemCount,
    required this.items,
    required this.notes,
    required this.subtotal,
    required this.tax,
    required this.estimatedTotal,
  });

  final String holdId;
  final String customerName;
  final String customerEmail;
  final String avatarLabel;
  final Color avatarColor;
  final String value;
  final String location;
  final String cashier;
  final String heldAt;
  final String heldAtDate;
  final String expires;
  final String expiresDate;
  final bool isExpired;
  final bool isExpiringSoon;
  final int itemCount;
  final List<_HeldCartItem> items;
  final String notes;
  final int subtotal;
  final int tax;
  final int estimatedTotal;
}

// ─── Widget ───────────────────────────────────────────────────────────────────
class HeldSalesView extends StatefulWidget {
  const HeldSalesView({super.key});

  @override
  State<HeldSalesView> createState() => _HeldSalesViewState();
}

class _HeldSalesViewState extends State<HeldSalesView> {
  String? _selectedHoldId = 'HLD-402';

  final List<_HeldCart> _carts = const [
    _HeldCart(
      holdId: 'HLD-402',
      customerName: 'Kiran Sharma',
      customerEmail: 'kiran.sharma@example.com',
      avatarLabel: 'KS',
      avatarColor: Color(0xFFF59E0B),
      value: '₹18,600',
      location: 'Central Store',
      cashier: 'Rahul S.',
      heldAt: '10:15 AM',
      heldAtDate: '14 Jan 2027',
      expires: '2h left',
      expiresDate: 'Today, 12:15 PM',
      isExpired: false,
      isExpiringSoon: true,
      itemCount: 3,
      items: [
        _HeldCartItem(
          name: 'Oxford Linen Shirt',
          variant: 'Black / M',
          sku: 'TS-10432-B-M',
          qty: 1,
          price: 6900,
          imageAsset: 'Assets/oxford_linen_shirt.jpg',
        ),
        _HeldCartItem(
          name: 'Merino Wool Blazer',
          variant: 'Navy / L',
          sku: 'MWB-20188-N-L',
          qty: 1,
          price: 11500,
          imageAsset: 'Assets/merino_wool_blazer.jpg',
        ),
        _HeldCartItem(
          name: 'Raw Denim Jeans',
          variant: 'Indigo / L',
          sku: 'RDJ-22011-IND-L',
          qty: 1,
          price: 2200,
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
      ],
      notes: 'Customer requested to keep order on hold while they try another size in the changing room.',
      subtotal: 18600,
      tax: 2232,
      estimatedTotal: 20808,
    ),
    _HeldCart(
      holdId: 'HLD-389',
      customerName: 'Ananya Singh',
      customerEmail: 'ananya.singh@example.com',
      avatarLabel: 'AS',
      avatarColor: Color(0xFF8B5CF6),
      value: '₹42,160',
      location: 'Delhi Hub',
      cashier: 'Meera J.',
      heldAt: 'Yesterday',
      heldAtDate: '13 Jan 2027, 04:20 PM',
      expires: '24h',
      expiresDate: '14 Jan 2027, 04:20 PM',
      isExpired: false,
      isExpiringSoon: false,
      itemCount: 5,
      items: [
        _HeldCartItem(
          name: 'Merino Wool Blazer',
          variant: 'Grey / M',
          sku: 'MWB-20188-G-M',
          qty: 2,
          price: 23000,
          imageAsset: 'Assets/merino_wool_blazer.jpg',
        ),
        _HeldCartItem(
          name: 'Oxford Linen Shirt',
          variant: 'White / L',
          sku: 'TS-10432-W-L',
          qty: 3,
          price: 19160,
          imageAsset: 'Assets/oxford_linen_shirt.jpg',
        ),
      ],
      notes: '',
      subtotal: 42160,
      tax: 5059,
      estimatedTotal: 47219,
    ),
    _HeldCart(
      holdId: 'HLD-395',
      customerName: 'Priya Kapoor',
      customerEmail: 'priya.kapoor@example.com',
      avatarLabel: 'PK',
      avatarColor: Color(0xFF10B981),
      value: '₹23,820',
      location: 'Central Store',
      cashier: 'Rahul S.',
      heldAt: 'Yesterday',
      heldAtDate: '13 Jan 2027, 11:05 AM',
      expires: '48h',
      expiresDate: '15 Jan 2027, 11:05 AM',
      isExpired: false,
      isExpiringSoon: false,
      itemCount: 2,
      items: [
        _HeldCartItem(
          name: 'Raw Denim Jeans',
          variant: 'Black / 32',
          sku: 'RDJ-22011-BLK-32',
          qty: 2,
          price: 23820,
          imageAsset: 'Assets/raw_denim_jeans.jpg',
        ),
      ],
      notes: '',
      subtotal: 23820,
      tax: 2858,
      estimatedTotal: 26678,
    ),
    _HeldCart(
      holdId: 'HLD-398',
      customerName: 'Rohit Taunk',
      customerEmail: 'rohit.taunk@example.com',
      avatarLabel: 'RT',
      avatarColor: Color(0xFFEC4899),
      value: '₹19,740',
      location: 'MG Road Store',
      cashier: 'Sneha K.',
      heldAt: '11 Jan 2027',
      heldAtDate: '03:30 PM',
      expires: 'Expired',
      expiresDate: '12 Jan 2027, 03:30 PM',
      isExpired: true,
      isExpiringSoon: false,
      itemCount: 4,
      items: [
        _HeldCartItem(
          name: 'Merino Wool Blazer',
          variant: 'Navy / L',
          sku: 'MWB-20188-N-L',
          qty: 1,
          price: 11500,
          imageAsset: 'Assets/merino_wool_blazer.jpg',
        ),
        _HeldCartItem(
          name: 'Oxford Linen Shirt',
          variant: 'Black / M',
          sku: 'TS-10432-B-M',
          qty: 3,
          price: 8240,
          imageAsset: 'Assets/oxford_linen_shirt.jpg',
        ),
      ],
      notes: '',
      subtotal: 19740,
      tax: 2369,
      estimatedTotal: 22109,
    ),
  ];

  _HeldCart? get _selected =>
      _carts.where((c) => c.holdId == _selectedHoldId).isNotEmpty
          ? _carts.firstWhere((c) => c.holdId == _selectedHoldId)
          : null;

  int get _expiringSoon =>
      _carts.where((c) => c.isExpiringSoon && !c.isExpired).length;

  int get _totalRevenue =>
      _carts.fold(0, (sum, c) => sum + c.subtotal);

  void _showCancelHoldDialog(_HeldCart cart) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Cancel Hold ${cart.holdId}?',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF181513)),
        ),
        content: Text(
          'This will remove the cart hold for ${cart.customerName}. The cart items will be released back to inventory.',
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Keep Hold', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hold ${cart.holdId} cancelled.'),
                  backgroundColor: const Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Cancel Hold'),
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
          _buildHeader(),
          const SizedBox(height: 18),
          _buildStatCards(),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 960;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTable()),
                  const SizedBox(width: 20),
                  SizedBox(width: 320, child: _buildSidePanel()),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTable(),
                const SizedBox(height: 20),
                _buildSidePanel(),
              ],
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Held Sales',
          style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF181513), letterSpacing: -0.4),
        ),
        const SizedBox(height: 4),
        Text(
          'Review and manage held carts and blocked transactions.',
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.shopping_cart_outlined,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            label: 'TOTAL HELD TRANSACTIONS',
            value: '${_carts.length} Sales On Hold',
            valueColor: const Color(0xFF181513),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.access_time_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            label: 'EXPIRING IN 24H',
            value: '$_expiringSoon Transactions',
            valueColor: const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.currency_rupee_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            label: 'HELD REVENUE BLOCKED',
            value: '₹${_totalRevenue.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
            valueColor: const Color(0xFF181513),
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(
              children: [
                _ColHeader('Hold ID', flex: 2),
                _ColHeader('Customer', flex: 4),
                _ColHeader('Value', flex: 2),
                _ColHeader('Location', flex: 3),
                _ColHeader('Cashier', flex: 2),
                _ColHeader('Held At', flex: 3),
                _ColHeader('Expires', flex: 3),
              ],
            ),
          ),

          // Rows
          ..._carts.map((cart) {
            final isSelected = cart.holdId == _selectedHoldId;
            return InkWell(
              onTap: () => setState(() => _selectedHoldId = cart.holdId),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFFBF0) : Colors.white,
                  border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    // Hold ID
                    Expanded(
                      flex: 2,
                      child: Text(
                        cart.holdId,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF181513)),
                      ),
                    ),

                    // Customer
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(color: cart.avatarColor.withOpacity(0.18), shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(
                              cart.avatarLabel,
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: cart.avatarColor),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cart.customerName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF181513))),
                                Text(cart.customerEmail, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                                Text('${cart.itemCount} items', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Value
                    Expanded(
                      flex: 2,
                      child: Text(cart.value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF181513))),
                    ),

                    // Location
                    Expanded(
                      flex: 3,
                      child: Text(cart.location, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
                    ),

                    // Cashier
                    Expanded(
                      flex: 2,
                      child: Text(cart.cashier, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF475569))),
                    ),

                    // Held At
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cart.heldAt, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF181513))),
                          Text(cart.heldAtDate, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),

                    // Expires
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cart.expires,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: cart.isExpired
                                  ? const Color(0xFFDC2626)
                                  : (cart.isExpiringSoon ? const Color(0xFFD97706) : const Color(0xFF475569)),
                            ),
                          ),
                          Text(cart.expiresDate, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Empty footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                const Icon(Icons.inventory_2_outlined, size: 36, color: Color(0xFFCBD5E1)),
                const SizedBox(height: 8),
                Text('No other held sales in session', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    final cart = _selected;
    if (cart == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: Text('Select a held cart to preview', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF94A3B8))),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Held Cart ${cart.holdId}',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF181513)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Text('SELECTED', style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: const Color(0xFFB45309), letterSpacing: 0.5)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer section
                Text('CUSTOMER', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: const Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: cart.avatarColor.withOpacity(0.18), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(cart.avatarLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: cart.avatarColor)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cart.customerName, style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF181513))),
                          Text(cart.customerEmail, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 12),

                // Products in cart
                Text('PRODUCTS IN CART (${cart.items.length})', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: const Color(0xFF94A3B8))),
                const SizedBox(height: 10),
                ...cart.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 38,
                          height: 38,
                          color: const Color(0xFFF1F5F9),
                          child: Image.asset(
                            item.imageAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, size: 18, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF181513))),
                            Text('${item.variant} · ${item.sku}', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Text(
                        '${item.qty} × ₹${item.price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF181513)),
                      ),
                    ],
                  ),
                )),

                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 12),

                // Totals
                _TotalRow('Subtotal', '₹${cart.subtotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'),
                const SizedBox(height: 4),
                _TotalRow('Tax (IGST 12%)', '₹${cart.tax.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Estimated Total', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF181513))),
                    Text(
                      '₹${cart.estimatedTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF181513)),
                    ),
                  ],
                ),

                if (cart.notes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 12),
                  Text('NOTES', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5, color: const Color(0xFF94A3B8))),
                  const SizedBox(height: 6),
                  Text(cart.notes, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B), height: 1.4)),
                ],

                const SizedBox(height: 16),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: ElevatedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Resuming ${cart.holdId} for ${cart.customerName}...'), backgroundColor: const Color(0xFF181513), behavior: SnackBarBehavior.floating),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF181513),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: Text('Resume Sale', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Opening cart editor...'), duration: Duration(seconds: 1)),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF181513)),
                          label: Text('Edit Cart', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF181513))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 38,
                        child: OutlinedButton.icon(
                          onPressed: () => _showCancelHoldDialog(cart),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFFECACA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFDC2626)),
                          label: Text('Cancel Hold', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFFDC2626))),
                        ),
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
}

// ─── Helper widgets ───────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: const Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: valueColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.text, {required this.flex});
  final String text;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B))),
        Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF181513))),
      ],
    );
  }
}
