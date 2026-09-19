// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Customers — Sales sub-section showing the full customer list + profile panel.
class CustomersView extends StatefulWidget {
  const CustomersView({super.key});

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  // Search / filter
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Selected row for profile panel
  _CustomerItem? _selected;

  // Customer data
  late List<_CustomerItem> _customers;

  @override
  void initState() {
    super.initState();
    _customers = _buildCustomers();
    _selected = _customers.first;
  }

  List<_CustomerItem> _buildCustomers() => [
        _CustomerItem(
          initials: 'EC',
          color: const Color(0xFF6E9DC8),
          name: 'Emma Carter',
          email: 'emma.c@gmail.com',
          orders: 12,
          lifetimeSpend: '₹84,290',
          lifetimeSpendNum: 84290,
          avgOrderValue: '₹7,024',
          returns: 1,
          lastPurchaseRelative: 'Yesterday',
          lastPurchaseDate: '14 Feb 2027',
          storeLocation: 'Central Store',
          status: _CustomerStatus.active,
          memberSince: 'Mar 2024',
          phone: '+91 98402 10492',
          tags: ['VIP', 'Regular', "Women's Wear"],
          hasPhoto: true,
        ),
        _CustomerItem(
          initials: 'DP',
          color: const Color(0xFF8BC4A0),
          name: 'Dev Patel',
          email: 'dev.patel@domain.com',
          orders: 8,
          lifetimeSpend: '₹52,800',
          lifetimeSpendNum: 52800,
          avgOrderValue: '₹6,600',
          returns: 0,
          lastPurchaseRelative: '3 days ago',
          lastPurchaseDate: '11 Feb 2027',
          storeLocation: 'Mumbai Flagship',
          status: _CustomerStatus.active,
          memberSince: 'Jun 2024',
          phone: '+91 98765 43210',
          tags: ['Regular', "Men's Wear"],
        ),
        _CustomerItem(
          initials: 'PN',
          color: const Color(0xFFD4A5C0),
          name: 'Priya Nair',
          email: 'priya.nair@domain.com',
          orders: 15,
          lifetimeSpend: '₹1,12,400',
          lifetimeSpendNum: 112400,
          avgOrderValue: '₹7,493',
          returns: 2,
          lastPurchaseRelative: '1 week ago',
          lastPurchaseDate: '07 Feb 2027',
          storeLocation: 'Bangalore Hub',
          status: _CustomerStatus.active,
          memberSince: 'Jan 2024',
          phone: '+91 91234 56789',
          tags: ['VIP', "Women's Wear", 'Loyalty Plus'],
        ),
        _CustomerItem(
          initials: 'AM',
          color: const Color(0xFFB3A9C4),
          name: 'Arjun Mehta',
          email: 'arjun.mehta@domain.com',
          orders: 3,
          lifetimeSpend: '₹18,200',
          lifetimeSpendNum: 18200,
          avgOrderValue: '₹6,067',
          returns: 0,
          lastPurchaseRelative: 'Feb 10, 2027',
          lastPurchaseDate: 'Feb 10, 2027',
          storeLocation: 'Central Store',
          status: _CustomerStatus.inactive,
          memberSince: 'Oct 2024',
          phone: '+91 70987 65432',
          tags: ["Men's Wear"],
        ),
        _CustomerItem(
          initials: 'SR',
          color: const Color(0xFFE8A87C),
          name: 'Siddharth Rao',
          email: 'siddharth.rao@domain.com',
          orders: 20,
          lifetimeSpend: '₹1,84,600',
          lifetimeSpendNum: 184600,
          avgOrderValue: '₹9,230',
          returns: 4,
          lastPurchaseRelative: 'Jan 28, 2027',
          lastPurchaseDate: 'Jan 28, 2027',
          storeLocation: 'Delhi Boutique',
          status: _CustomerStatus.active,
          memberSince: 'Nov 2023',
          phone: '+91 98001 23456',
          tags: ['VIP', 'High Spender', "Men's Wear"],
        ),
        _CustomerItem(
          initials: 'KS',
          color: const Color(0xFF82C4B8),
          name: 'Kirti Sen',
          email: 'kirti.sen@domain.com',
          orders: 5,
          lifetimeSpend: '₹34,500',
          lifetimeSpendNum: 34500,
          avgOrderValue: '₹6,900',
          returns: 1,
          lastPurchaseRelative: 'Jan 15, 2027',
          lastPurchaseDate: 'Jan 15, 2027',
          storeLocation: 'Mumbai Flagship',
          status: _CustomerStatus.active,
          memberSince: 'May 2024',
          phone: '+91 77889 90011',
          tags: ['Regular', "Women's Wear"],
        ),
      ];

  List<_CustomerItem> get _filtered {
    if (_searchQuery.isEmpty) return _customers;
    final q = _searchQuery.toLowerCase();
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q) ||
            c.storeLocation.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildMetricsStrip(),
          const SizedBox(height: 20),

          // Main split layout
          LayoutBuilder(builder: (context, constraints) {
            final showPanel = constraints.maxWidth >= 900;
            if (showPanel) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTableSection()),
                  const SizedBox(width: 20),
                  SizedBox(width: 290, child: _buildProfilePanel()),
                ],
              );
            }
            return Column(
              children: [
                _buildTableSection(),
                if (_selected != null) ...[
                  const SizedBox(height: 20),
                  _buildProfilePanel(),
                ],
              ],
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customers',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181614),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Manage your customers, purchase history and relationships.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF6B6358),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Export
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD5C9BC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.download_outlined, size: 15, color: Color(0xFF5C4F44)),
                const SizedBox(width: 7),
                Text(
                  'Export Customers',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF5C4F44),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Add Customer
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1816),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, size: 15, color: Colors.white),
                const SizedBox(width: 7),
                Text(
                  'Add Customer',
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
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Metrics Strip
  // ---------------------------------------------------------------------------

  Widget _buildMetricsStrip() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.people_outline_rounded,
            label: 'Active Customers',
            value: '3,842',
            trend: '↑ 12% MoM',
            trendColor: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.shopping_cart_outlined,
            label: 'Repeat Purchase Rate',
            value: '68.2%',
            trend: '↑ 6% MoM',
            trendColor: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.currency_rupee_rounded,
            label: 'Avg. Lifetime Spend',
            value: '₹18,450',
            trend: '↑ 450 growth avg',
            trendColor: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.inventory_2_outlined,
            label: 'Total Orders',
            value: '24,120',
            trend: '↑ 18% MoM',
            trendColor: const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String trend,
    required Color trendColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8DFD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EDE0),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: const Color(0xFF8C5E33)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF7E766B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1816),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: trendColor,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Table Section
  // ---------------------------------------------------------------------------

  Widget _buildTableSection() {
    return Column(
      children: [
        _buildSearchAndFilters(),
        const SizedBox(height: 12),
        _buildTable(),
        const SizedBox(height: 12),
        _buildPagination(),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        // Search
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD5C9BC)),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF1A1816)),
              decoration: InputDecoration(
                hintText: 'Search by customer name, email or phone...',
                hintStyle: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF9E8E7E)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9E8E7E)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _buildFilterChip('Preferred Location'),
        const SizedBox(width: 8),
        _buildFilterChip('Spend Tier'),
        const SizedBox(width: 8),
        _buildFilterChip('Returns Logged'),
        const SizedBox(width: 8),
        // More Filters
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD5C9BC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tune_rounded, size: 14, color: Color(0xFF5C4F44)),
                const SizedBox(width: 5),
                Text(
                  'More Filters',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF5C4F44)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD5C9BC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: const Color(0xFF3D3530))),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 15, color: Color(0xFF7E766B)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    final rows = _filtered;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DFD3)),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          ...rows.asMap().entries.map((entry) {
            return _buildTableRow(entry.value, isLast: entry.key == rows.length - 1);
          }),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(11), topRight: Radius.circular(11)),
        border: Border(bottom: BorderSide(color: Color(0xFFEEE5D8))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Checkbox(
              value: false,
              onChanged: (_) {},
              side: const BorderSide(color: Color(0xFFD5C9BC), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const Expanded(flex: 26, child: Text('CUSTOMER NAME', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF8E7F72), letterSpacing: 0.3))),
          Expanded(flex: 10, child: Row(children: [
            const Text('ORDERS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF8E7F72), letterSpacing: 0.3)),
            const SizedBox(width: 3),
            const Icon(Icons.unfold_more_rounded, size: 13, color: Color(0xFF9E8E7E)),
          ])),
          const Expanded(flex: 14, child: Text('LIFETIME SPEND', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF8E7F72), letterSpacing: 0.3))),
          const Expanded(flex: 9, child: Text('RETURNS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF8E7F72), letterSpacing: 0.3))),
          const Expanded(flex: 16, child: Text('LAST PURCHASE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF8E7F72), letterSpacing: 0.3))),
          const Expanded(flex: 16, child: Text('STORE LOCATION', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF8E7F72), letterSpacing: 0.3))),
          const Expanded(flex: 10, child: Text('STATUS', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF8E7F72), letterSpacing: 0.3))),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTableRow(_CustomerItem c, {bool isLast = false}) {
    final isSelected = _selected?.email == c.email;
    return InkWell(
      onTap: () => setState(() => _selected = c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8EF) : Colors.white,
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFF4EDE5), width: 0.8)),
        ),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 36,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => setState(() => _selected = c),
                side: const BorderSide(color: Color(0xFFD5C9BC), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                activeColor: const Color(0xFF8C5E33),
              ),
            ),

            // Avatar + Name
            Expanded(
              flex: 26,
              child: Row(
                children: [
                  _buildAvatar(c),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1816),
                          ),
                        ),
                        Text(
                          c.email,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7E766B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Orders
            Expanded(
              flex: 10,
              child: Text(
                '${c.orders}',
                style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF1A1816)),
              ),
            ),

            // Lifetime Spend
            Expanded(
              flex: 14,
              child: Text(
                c.lifetimeSpend,
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500, color: const Color(0xFF1A1816)),
              ),
            ),

            // Returns
            Expanded(
              flex: 9,
              child: Text(
                '${c.returns}',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: c.returns > 0 ? FontWeight.w600 : FontWeight.w400,
                  color: c.returns > 0 ? const Color(0xFFEF4444) : const Color(0xFF7E766B),
                ),
              ),
            ),

            // Last Purchase
            Expanded(
              flex: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.lastPurchaseRelative,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1A1816)),
                  ),
                  if (c.lastPurchaseDate != c.lastPurchaseRelative)
                    Text(
                      c.lastPurchaseDate,
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF9E8E7E)),
                    ),
                ],
              ),
            ),

            // Store Location
            Expanded(
              flex: 16,
              child: Text(
                c.storeLocation,
                style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF5C5047)),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Status
            Expanded(
              flex: 10,
              child: _buildStatusBadge(c.status),
            ),

            // Actions
            SizedBox(
              width: 40,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.more_horiz_rounded, size: 17, color: Color(0xFF9E8E7E)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(_CustomerItem c) {
    if (c.hasPhoto) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: c.color,
        child: ClipOval(
          child: Container(
            width: 36,
            height: 36,
            color: c.color,
            alignment: Alignment.center,
            child: Text(
              c.initials,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: c.color,
      child: Text(
        c.initials,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusBadge(_CustomerStatus status) {
    final isActive = status == _CustomerStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F0EE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: isActive ? const Color(0xFF16A34A) : const Color(0xFF6B6358),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Row(
      children: [
        Text(
          'Showing 1–6 of 3,842 customers',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF7E766B)),
        ),
        const Spacer(),
        // Prev
        _pageBtn(Icons.chevron_left_rounded, enabled: false, onTap: () {}),
        const SizedBox(width: 4),
        ...[1, 2, 3, 4, 5].map((p) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p == 1 ? const Color(0xFF1A1816) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: p == 1 ? const Color(0xFF1A1816) : const Color(0xFFD5C9BC)),
                  ),
                  child: Text(
                    '$p',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: p == 1 ? FontWeight.w600 : FontWeight.w400,
                      color: p == 1 ? Colors.white : const Color(0xFF5C4F44),
                    ),
                  ),
                ),
              ),
            )),
        _pageBtn(Icons.chevron_right_rounded, enabled: true, onTap: () {}),
        const SizedBox(width: 16),
        // Show dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: const Color(0xFFD5C9BC)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Show  10', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF3D3530))),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF7E766B)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pageBtn(IconData icon, {required bool enabled, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD5C9BC)),
          color: enabled ? Colors.white : const Color(0xFFF4EDE4),
        ),
        child: Icon(icon, size: 17, color: enabled ? const Color(0xFF5C4F44) : const Color(0xFFB0A89E)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Profile Panel (right)
  // ---------------------------------------------------------------------------

  Widget _buildProfilePanel() {
    final c = _selected;
    if (c == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8DFD3)),
        ),
        child: Center(
          child: Text(
            'Select a customer to view their profile.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9E8E7E)),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DFD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
            child: Row(
              children: [
                Text(
                  'Customer Profile',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1816),
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.more_horiz_rounded, size: 17, color: Color(0xFF9E8E7E)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Avatar + Name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: c.color,
                  child: Text(
                    c.initials,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  c.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1816),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: c.status == _CustomerStatus.active
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F0EE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    c.status == _CustomerStatus.active ? 'Active Customer' : 'Inactive Customer',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: c.status == _CustomerStatus.active
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF6B6358),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Member since ${c.memberSince}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9E8E7E)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF0E8DF), height: 1),
          const SizedBox(height: 14),

          // Contact details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildContactRow(Icons.email_outlined, c.email),
                const SizedBox(height: 8),
                _buildContactRow(Icons.phone_outlined, c.phone),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF8E7F72)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD5C9BC)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(c.storeLocation, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF3D3530))),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: Color(0xFF7E766B)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0xFFF0E8DF), height: 1),
          const SizedBox(height: 12),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildStatRow('Total Orders', '${c.orders} Orders'),
                const SizedBox(height: 8),
                _buildStatRow('Avg. Order Value', c.avgOrderValue),
                const SizedBox(height: 8),
                _buildStatRow('Lifetime Spend', c.lifetimeSpend, valueColor: const Color(0xFF16A34A)),
              ],
            ),
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF0E8DF), height: 1),
          const SizedBox(height: 12),

          // Tags
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tags',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF7E766B)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: c.tags.map((tag) => _buildTag(tag)).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // CTA buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF1A1816)),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history_rounded, size: 15, color: Color(0xFF1A1816)),
                          const SizedBox(width: 7),
                          Text(
                            'View Detailed History',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1816),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD5C9BC)),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shopping_cart_outlined, size: 15, color: Color(0xFF5C4F44)),
                          const SizedBox(width: 7),
                          Text(
                            'New Quick Sale',
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5C4F44),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF8E7F72)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF3D3530)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF7E766B)),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF1A1816),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label) {
    Color bg;
    Color fg;
    if (label == 'VIP') {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFD97706);
    } else if (label == 'High Spender') {
      bg = const Color(0xFFFFEDE5);
      fg = const Color(0xFFEA580C);
    } else if (label == 'Loyalty Plus') {
      bg = const Color(0xFFEDE9FE);
      fg = const Color(0xFF7C3AED);
    } else {
      bg = const Color(0xFFF1EBE3);
      fg = const Color(0xFF5C4F44);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: fg)),
    );
  }
}

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

enum _CustomerStatus { active, inactive }

class _CustomerItem {
  final String initials;
  final Color color;
  final String name;
  final String email;
  final int orders;
  final String lifetimeSpend;
  final int lifetimeSpendNum;
  final String avgOrderValue;
  final int returns;
  final String lastPurchaseRelative;
  final String lastPurchaseDate;
  final String storeLocation;
  final _CustomerStatus status;
  final String memberSince;
  final String phone;
  final List<String> tags;
  final bool hasPhoto;

  const _CustomerItem({
    required this.initials,
    required this.color,
    required this.name,
    required this.email,
    required this.orders,
    required this.lifetimeSpend,
    required this.lifetimeSpendNum,
    required this.avgOrderValue,
    required this.returns,
    required this.lastPurchaseRelative,
    required this.lastPurchaseDate,
    required this.storeLocation,
    required this.status,
    required this.memberSince,
    required this.phone,
    required this.tags,
    this.hasPhoto = false,
  });
}
