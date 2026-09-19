// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SupplierDirectoryItem {
  SupplierDirectoryItem({
    required this.id,
    required this.name,
    required this.location,
    required this.initials,
    required this.category,
    required this.leadTime,
    required this.activePos,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.rating,
    this.isPreferred = false,
    this.contactName = 'Giovanni Rossi',
    this.contactRole = 'Sales Representative',
    this.email = 'contact@supplier.com',
    this.phone = '+39 02 4859 201',
    this.address = 'Industrial Zone, Milan, Italy',
    this.website = 'www.supplier.com',
    this.recentOrders = const [],
    this.isSelected = false,
  });

  final String id;
  final String name;
  final String location;
  final String initials;
  final String category;
  final String leadTime;
  final String activePos;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final int rating;
  final bool isPreferred;
  final String contactName;
  final String contactRole;
  final String email;
  final String phone;
  final String address;
  final String website;
  final List<SupplierOrderSummary> recentOrders;
  bool isSelected;
}

class SupplierOrderSummary {
  const SupplierOrderSummary({
    required this.poNumber,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.date,
  });

  final String poNumber;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final String date;
}

class PartnerDirectoryView extends StatefulWidget {
  const PartnerDirectoryView({
    super.key,
    this.onViewFullProfile,
    this.onAddSupplier,
  });

  final ValueChanged<SupplierDirectoryItem>? onViewFullProfile;
  final VoidCallback? onAddSupplier;

  @override
  State<PartnerDirectoryView> createState() => _PartnerDirectoryViewState();
}

class _PartnerDirectoryViewState extends State<PartnerDirectoryView> {
  int _selectedPillTab = 0; // 0: All, 1: Active, 2: Inactive, 3: Preferred
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All Categories';
  String _selectedStatus = 'All Status';
  String _selectedSort = 'Sort by: Name';
  int _currentPage = 1;

  late final List<SupplierDirectoryItem> _suppliers;
  late SupplierDirectoryItem _selectedPartner;

  @override
  void initState() {
    super.initState();
    _suppliers = [
      SupplierDirectoryItem(
        id: 'TS-SUPP-0421',
        name: 'Milano Tessuti',
        location: 'Milan, Italy',
        initials: 'MT',
        category: 'Fabrics',
        leadTime: '18 Days',
        activePos: '3 Active',
        status: 'Preferred',
        statusBg: const Color(0xFFDCFCE7),
        statusColor: const Color(0xFF15803D),
        rating: 5,
        isPreferred: true,
        contactName: 'Giovanni Rossi',
        contactRole: 'Sales Representative',
        email: 'giovanni.rossi@milanotessuti.it',
        phone: '+39 02 4859 201',
        address: 'Via della Spiga 12, Milan, Italy',
        website: 'www.milanotessuti.it',
        isSelected: true,
        recentOrders: const [
          SupplierOrderSummary(
            poNumber: 'PO-4091',
            status: 'Arrived',
            statusBg: Color(0xFFDCFCE7),
            statusColor: Color(0xFF15803D),
            date: 'Feb 12, 2027',
          ),
          SupplierOrderSummary(
            poNumber: 'PO-3982',
            status: 'In Transit',
            statusBg: Color(0xFFEFF6FF),
            statusColor: Color(0xFF2563EB),
            date: 'Jan 28, 2027',
          ),
          SupplierOrderSummary(
            poNumber: 'PO-3765',
            status: 'Completed',
            statusBg: Color(0xFFDCFCE7),
            statusColor: Color(0xFF15803D),
            date: 'Jan 10, 2027',
          ),
        ],
      ),
      SupplierDirectoryItem(
        id: 'TS-SUPP-0188',
        name: 'Surat Denim Ltd',
        location: 'Gujarat, India',
        initials: 'SD',
        category: 'Denim & Twill',
        leadTime: '14 Days',
        activePos: '2 Active',
        status: 'Active',
        statusBg: const Color(0xFFDCFCE7),
        statusColor: const Color(0xFF15803D),
        rating: 4,
        contactName: 'Rajesh Patel',
        contactRole: 'Head of Export Sales',
        email: 'rajesh.patel@suratdenim.in',
        phone: '+91 261 4892 110',
        address: 'Plot 42, GIDC Textile Park, Surat, India',
        website: 'www.suratdenim.in',
        recentOrders: const [
          SupplierOrderSummary(
            poNumber: 'PO-4088',
            status: 'In Transit',
            statusBg: Color(0xFFEFF6FF),
            statusColor: Color(0xFF2563EB),
            date: 'Feb 10, 2027',
          ),
          SupplierOrderSummary(
            poNumber: 'PO-3950',
            status: 'Completed',
            statusBg: Color(0xFFDCFCE7),
            statusColor: Color(0xFF15803D),
            date: 'Jan 18, 2027',
          ),
        ],
      ),
      SupplierDirectoryItem(
        id: 'TS-SUPP-0312',
        name: 'Biella Woolen Mills',
        location: 'Piedmont, Italy',
        initials: 'BW',
        category: 'Yarns & Wool',
        leadTime: '22 Days',
        activePos: '1 Active',
        status: 'Active',
        statusBg: const Color(0xFFDCFCE7),
        statusColor: const Color(0xFF15803D),
        rating: 4,
        contactName: 'Marco Bellini',
        contactRole: 'Production Director',
        email: 'm.bellini@biellawool.it',
        phone: '+39 015 849 203',
        address: 'Corso Sempione 88, Biella, Italy',
        website: 'www.biellawool.it',
      ),
      SupplierDirectoryItem(
        id: 'TS-SUPP-0094',
        name: 'Tokyo Brass & Hardware',
        location: 'Kanto, Japan',
        initials: 'TB',
        category: 'Hardware',
        leadTime: '10 Days',
        activePos: '0 Active',
        status: 'On Hold',
        statusBg: const Color(0xFFFEF3C7),
        statusColor: const Color(0xFFD97706),
        rating: 3,
        contactName: 'Kenji Sato',
        contactRole: 'Overseas Operations',
        email: 'sato@tokyobrass.jp',
        phone: '+81 3 5842 9110',
        address: 'Chiyoda-ku, Tokyo, Japan',
        website: 'www.tokyobrass.jp',
      ),
      SupplierDirectoryItem(
        id: 'TS-SUPP-0255',
        name: 'Prato Knitwear Co.',
        location: 'Prato, Italy',
        initials: 'PL',
        category: 'Knitwear',
        leadTime: '16 Days',
        activePos: '4 Active',
        status: 'Active',
        statusBg: const Color(0xFFDCFCE7),
        statusColor: const Color(0xFF15803D),
        rating: 4,
        contactName: 'Lucia Bianchi',
        contactRole: 'Client Relations',
        email: 'lucia@pratoknitwear.com',
        phone: '+39 0574 992 104',
        address: 'Via Galcianese 45, Prato, Italy',
        website: 'www.pratoknitwear.com',
      ),
      SupplierDirectoryItem(
        id: 'TS-SUPP-0142',
        name: 'Shree Textiles',
        location: 'Surat, India',
        initials: 'SH',
        category: 'Fabrics',
        leadTime: '12 Days',
        activePos: '1 Active',
        status: 'Active',
        statusBg: const Color(0xFFDCFCE7),
        statusColor: const Color(0xFF15803D),
        rating: 4,
        contactName: 'Amit Shah',
        contactRole: 'Managing Director',
        email: 'amit@shreetextiles.com',
        phone: '+91 261 2291 004',
        address: 'Ring Road Market, Surat, India',
        website: 'www.shreetextiles.com',
      ),
      SupplierDirectoryItem(
        id: 'TS-SUPP-0401',
        name: 'CottonLand',
        location: 'Izmir, Turkey',
        initials: 'CL',
        category: 'Cotton & Linen',
        leadTime: '20 Days',
        activePos: '0 Active',
        status: 'Inactive',
        statusBg: const Color(0xFFFEE2E2),
        statusColor: const Color(0xFFDC2626),
        rating: 3,
        contactName: 'Emre Yilmaz',
        contactRole: 'Export Specialist',
        email: 'emre@cottonland.tr',
        phone: '+90 232 441 8290',
        address: 'Ataturk Caddesi, Izmir, Turkey',
        website: 'www.cottonland.tr',
      ),
      SupplierDirectoryItem(
        id: 'TS-SUPP-0339',
        name: 'Global Packaging Co.',
        location: 'Barcelona, Spain',
        initials: 'GP',
        category: 'Packaging',
        leadTime: '15 Days',
        activePos: '2 Active',
        status: 'Active',
        statusBg: const Color(0xFFDCFCE7),
        statusColor: const Color(0xFF15803D),
        rating: 4,
        contactName: 'Carlos Vega',
        contactRole: 'Commercial Director',
        email: 'carlos.vega@globalpack.es',
        phone: '+34 93 481 9200',
        address: 'Poligono Industrial del Prat, Barcelona, Spain',
        website: 'www.globalpack.es',
      ),
    ];
    _selectedPartner = _suppliers.first;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SupplierDirectoryItem> get _filteredSuppliers {
    final query = _searchController.text.trim().toLowerCase();
    return _suppliers.where((item) {
      if (_selectedPillTab == 1 && item.status != 'Active' && item.status != 'Preferred') return false;
      if (_selectedPillTab == 2 && item.status != 'Inactive' && item.status != 'On Hold') return false;
      if (_selectedPillTab == 3 && !item.isPreferred) return false;

      if (_selectedCategory != 'All Categories' && item.category != _selectedCategory) {
        return false;
      }
      if (_selectedStatus != 'All Status' && item.status != _selectedStatus) {
        return false;
      }

      if (query.isNotEmpty) {
        final matches = item.name.toLowerCase().contains(query) ||
            item.location.toLowerCase().contains(query) ||
            item.category.toLowerCase().contains(query) ||
            item.contactName.toLowerCase().contains(query);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  void _showAddSupplierModal() {
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
                color: const Color(0xFFFBF4EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business_outlined, color: Color(0xFF92400E), size: 20),
            ),
            const SizedBox(width: 12),
            Text('Add New Supplier Partner', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Company / Mill Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Location (City, Country)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Primary Category',
                  hintText: 'e.g. Luxury Silks, Denim, Packaging',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
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
                const SnackBar(
                  content: Text('Supplier partner registered into directory.'),
                  backgroundColor: Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add Partner'),
          ),
        ],
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
            Text('AI Supply Chain Risk & Opportunity Radar', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ThreadStock AI continuously monitors port congestions, lead time variance, and quality indices across all 14 active vendors:',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF4B5563), height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildInsightBullet('Lead Time Volatility Alert', 'Tokyo Brass & Hardware lead time has climbed from 8 to 10 days due to regional customs re-inspections.'),
              const SizedBox(height: 12),
              _buildInsightBullet('Preferred Partner Milestone', 'Milano Tessuti delivered 99.1% of fabric rolls on schedule for 3 consecutive months.'),
              const SizedBox(height: 12),
              _buildInsightBullet('Single Source Exposure', 'Yarns & Wool is 82% concentrated in Northern Italy. Consider evaluating auxiliary suppliers in Portugal or Turkey.'),
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
              Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
              const SizedBox(height: 2),
              Text(desc, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280), height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Partners & Manufacturers + Export + Add Supplier
          _buildHeader(),
          const SizedBox(height: 16),

          // 2. Filter Pills Row
          _buildFilterPillsRow(),
          const SizedBox(height: 16),

          // 3. Search + Dropdowns Row
          _buildSearchAndFiltersRow(),
          const SizedBox(height: 20),

          // 4. Main Body: Left Table (70%) + Right Selected Partner Sidebar (30%)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1060;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Data Table & Pagination (~70%)
                    Expanded(
                      flex: 70,
                      child: Column(
                        children: [
                          _buildSuppliersTable(),
                          const SizedBox(height: 14),
                          _buildPaginationRow(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Right Selected Partner Card (~30%)
                    Expanded(
                      flex: 30,
                      child: _buildSelectedPartnerSidebar(),
                    ),
                  ],
                );
              }

              // Stacked for narrower displays
              return Column(
                children: [
                  _buildSuppliersTable(),
                  const SizedBox(height: 14),
                  _buildPaginationRow(),
                  const SizedBox(height: 24),
                  _buildSelectedPartnerSidebar(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 5. Bottom AI Supply Chain Banner
          _buildAiBanner(),
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
                'Partners & Manufacturers',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your supplier network and build stronger partnerships.',
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
            // Export Directory
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Downloading Partners & Manufacturers Directory (CSV)...'),
                    backgroundColor: Color(0xFF181513),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.file_download_outlined, size: 16),
              label: const Text('Export Directory'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 10),

            // + Add Supplier
            ElevatedButton.icon(
              onPressed: widget.onAddSupplier ?? _showAddSupplierModal,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Supplier'),
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

  // 2. Filter Pills Row
  Widget _buildFilterPillsRow() {
    return Row(
      children: [
        _buildPillTab('All Suppliers', 14, 0),
        const SizedBox(width: 10),
        _buildPillTab('Active', 10, 1),
        const SizedBox(width: 10),
        _buildPillTab('Inactive', 2, 2),
        const SizedBox(width: 10),
        _buildPillTab('Preferred Network', 3, 3),
      ],
    );
  }

  Widget _buildPillTab(String label, int count, int index) {
    final isSelected = _selectedPillTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedPillTab = index),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6B584B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF6B584B) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF866E5E) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Search and Filters Row
  Widget _buildSearchAndFiltersRow() {
    return Row(
      children: [
        // Search field
        Expanded(
          flex: 4,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search supplier name, contact, or category...',
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // All Categories dropdown
        _buildDropdownButton(
          value: _selectedCategory,
          items: const ['All Categories', 'Fabrics', 'Denim & Twill', 'Yarns & Wool', 'Hardware', 'Knitwear', 'Packaging'],
          onChanged: (val) => setState(() => _selectedCategory = val ?? 'All Categories'),
        ),
        const SizedBox(width: 10),

        // All Status dropdown
        _buildDropdownButton(
          value: _selectedStatus,
          items: const ['All Status', 'Preferred', 'Active', 'On Hold', 'Inactive'],
          onChanged: (val) => setState(() => _selectedStatus = val ?? 'All Status'),
        ),
        const SizedBox(width: 10),

        // Sort by dropdown
        _buildDropdownButton(
          value: _selectedSort,
          items: const ['Sort by: Name', 'Sort by: Lead Time', 'Sort by: Rating', 'Sort by: Active POs'],
          onChanged: (val) => setState(() => _selectedSort = val ?? 'Sort by: Name'),
        ),
      ],
    );
  }

  Widget _buildDropdownButton({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF6B7280)),
          style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF374151)),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // 4. Suppliers Table
  Widget _buildSuppliersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Checkbox(
                    value: _suppliers.every((s) => s.isSelected),
                    onChanged: (val) {
                      setState(() {
                        final v = val ?? false;
                        for (final s in _suppliers) {
                          s.isSelected = v;
                        }
                      });
                    },
                    activeColor: const Color(0xFFD97706),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 30,
                  child: Text('Supplier', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ),
                Expanded(
                  flex: 16,
                  child: Text('Category', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ),
                Expanded(
                  flex: 13,
                  child: Text('Lead Time', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ),
                Expanded(
                  flex: 13,
                  child: Text('Active POs', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ),
                Expanded(
                  flex: 12,
                  child: Text('Status', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ),
                Expanded(
                  flex: 12,
                  child: Text('Rating', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ),
                const SizedBox(
                  width: 32,
                  child: Text('Actions', textAlign: TextAlign.end, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table Rows
          for (final item in _filteredSuppliers) ...[
            _buildSupplierRow(item),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }

  Widget _buildSupplierRow(SupplierDirectoryItem item) {
    final isSelectedRow = _selectedPartner.id == item.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPartner = item;
          for (final s in _suppliers) {
            s.isSelected = (s.id == item.id);
          }
        });
      },
      hoverColor: const Color(0xFFF8FAFC),
      child: Container(
        color: isSelectedRow ? const Color(0xFFFFFBEB).withOpacity(0.35) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 24,
              child: Checkbox(
                value: item.isSelected,
                onChanged: (val) {
                  setState(() {
                    item.isSelected = val ?? false;
                    if (item.isSelected) {
                      _selectedPartner = item;
                    }
                  });
                },
                activeColor: const Color(0xFFD97706),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 12),

            // Supplier Initials + Name + Location + Preferred Crown
            Expanded(
              flex: 30,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBF4EB),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.initials,
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (item.isPreferred) ...[
                              const Text('👑', style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                item.name,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          item.location,
                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Category
            Expanded(
              flex: 16,
              child: Text(
                item.category,
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF4B5563)),
              ),
            ),

            // Lead Time
            Expanded(
              flex: 13,
              child: Text(
                item.leadTime,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: item.leadTime == '18 Days' ? const Color(0xFFB45309) : const Color(0xFF374151),
                ),
              ),
            ),

            // Active POs
            Expanded(
              flex: 13,
              child: Text(
                item.activePos,
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
              ),
            ),

            // Status Pill
            Expanded(
              flex: 12,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.statusBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: item.statusColor),
                  ),
                ),
              ),
            ),

            // Rating Stars
            Expanded(
              flex: 12,
              child: Row(
                children: List.generate(5, (starIdx) {
                  return Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: starIdx < item.rating ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB),
                  );
                }),
              ),
            ),

            // Actions Menu
            SizedBox(
              width: 32,
              child: Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF6B7280), size: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  color: Colors.white,
                  onSelected: (val) {
                    if (val == 'view_profile') {
                      widget.onViewFullProfile?.call(item);
                    } else if (val == 'new_po') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening purchase order draft for ${item.name}...'),
                          backgroundColor: const Color(0xFF181513),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(value: 'view_profile', child: Text('View Full Profile', style: GoogleFonts.inter(fontSize: 13))),
                    PopupMenuItem(value: 'new_po', child: Text('Create Purchase Order', style: GoogleFonts.inter(fontSize: 13))),
                    PopupMenuItem(value: 'email', child: Text('Send Email', style: GoogleFonts.inter(fontSize: 13))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pagination Row
  Widget _buildPaginationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing 1–8 of 14 suppliers',
          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
        ),
        Row(
          children: [
            _buildPageNavButton(icon: Icons.chevron_left_rounded, isEnabled: false),
            const SizedBox(width: 6),
            _buildPageNumberButton(1, isActive: _currentPage == 1),
            const SizedBox(width: 6),
            _buildPageNumberButton(2, isActive: _currentPage == 2),
            const SizedBox(width: 6),
            _buildPageNavButton(icon: Icons.chevron_right_rounded, isEnabled: true),
          ],
        ),
      ],
    );
  }

  Widget _buildPageNumberButton(int page, {required bool isActive}) {
    return InkWell(
      onTap: () => setState(() => _currentPage = page),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFBF4EB) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isActive ? const Color(0xFFD5C9BC) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          '$page',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFFB45309) : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildPageNavButton({required IconData icon, required bool isEnabled}) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Icon(icon, size: 18, color: isEnabled ? const Color(0xFF374151) : const Color(0xFFD1D5DB)),
    );
  }

  // 5. Right Sidebar: Selected Partner
  Widget _buildSelectedPartnerSidebar() {
    final p = _selectedPartner;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Selected Partner + More
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Partner',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                ),
                const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF6B7280)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Banner Image (Fabric Rolls)
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFD7CCC8),
                image: DecorationImage(
                  image: AssetImage('assets/mulberry_silk_fabric.jpg'),
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),

          // Partner Identity Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFBF4EB),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p.initials,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.name,
                                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Preferred',
                                  style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('ID: ${p.id}', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280))),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 12, color: Color(0xFF9CA3AF)),
                              const SizedBox(width: 3),
                              Text(p.location, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // CONTACT INFORMATION
                Text(
                  'CONTACT INFORMATION',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6B7280), letterSpacing: 0.3),
                ),
                const SizedBox(height: 12),

                // Contact Name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.contactName, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
                          Text(p.contactRole, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Email
                Row(
                  children: [
                    const Icon(Icons.mail_outline_rounded, size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.email,
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Phone
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 10),
                    Text(p.phone, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151))),
                  ],
                ),
                const SizedBox(height: 10),

                // Address
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.address,
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Website
                Row(
                  children: [
                    const Icon(Icons.language_rounded, size: 16, color: Color(0xFF9CA3AF)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.website,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF6B7280)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 14),

                // RECENT ORDER HISTORY
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'RECENT ORDER HISTORY',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF6B7280), letterSpacing: 0.3),
                    ),
                    InkWell(
                      onTap: () => widget.onViewFullProfile?.call(p),
                      child: Row(
                        children: [
                          Text('View All', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFFB45309))),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFB45309)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (p.recentOrders.isNotEmpty) ...[
                  for (final order in p.recentOrders) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(order.poNumber, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: order.statusBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  order.status,
                                  style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: order.statusColor),
                                ),
                              ),
                            ],
                          ),
                          Text(order.date, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280))),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('No active orders logged.', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF))),
                  ),
                ],
                const SizedBox(height: 16),

                // View Full Profile Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => widget.onViewFullProfile?.call(p),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF181513),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('View Full Profile'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. Bottom AI Banner
  Widget _buildAiBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stronger Supply Chains with AI',
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Get insights on supplier performance, lead time trends, and risk alerts.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: _showAiInsightsModal,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFF59E0B)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Explore AI Insights'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
