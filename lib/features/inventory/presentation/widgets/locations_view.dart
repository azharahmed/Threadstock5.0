// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/business/current_business_service.dart';
import '../../data/location_repository.dart';

class LocationItem {
  const LocationItem({
    required this.id,
    required this.name,
    required this.type,
    required this.typeBg,
    required this.typeColor,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.address,
    required this.city,
    required this.totalStock,
    required this.activeTransfers,
    required this.activeTransfersColor,
    required this.imageAsset,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String type;
  final Color typeBg;
  final Color typeColor;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final String address;
  final String city;
  final String totalStock;
  final String activeTransfers;
  final Color activeTransfersColor;
  final String imageAsset;
  final bool isActive;
}

class LocationsView extends StatefulWidget {
  const LocationsView({
    super.key,
    this.onAddLocation,
    this.onManageStock,
    this.onViewDetails,
    this.onGetAiInsights,
  });

  final VoidCallback? onAddLocation;
  final ValueChanged<LocationItem>? onManageStock;
  final ValueChanged<LocationItem>? onViewDetails;
  final VoidCallback? onGetAiInsights;

  @override
  State<LocationsView> createState() => _LocationsViewState();
}

class _LocationsViewState extends State<LocationsView> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'All Types';
  String _selectedStatus = 'All Status';
  String _selectedZone = 'All Zones';
  String _selectedSort = 'Sort by: Name';
  bool _isGridView = true;
  bool _isLoading = true;
  int _totalStockUnits = 0;

  List<LocationItem> _locations = const [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final repo = LocationRepository();
      final locations = await repo.getLocations(onlyActive: false);

      // Query inventory_balances for per-location stock counts
      final Map<String, int> stockByLocation = {};
      int totalUnits = 0;
      try {
        final sb = Supabase.instance.client;
        final businessId = CurrentBusinessService.instance.currentBusinessId;
        if (businessId != null && businessId.isNotEmpty) {
          final balances = await sb
              .from('inventory_balances')
              .select('location_id, available_qty')
              .eq('business_id', businessId);
          for (final b in (balances as List)) {
            final locId = b['location_id'] as String?;
            final qty = (b['available_qty'] as num?)?.toInt() ?? 0;
            if (locId != null && qty > 0) {
              stockByLocation[locId] = (stockByLocation[locId] ?? 0) + qty;
              totalUnits += qty;
            }
          }
        }
      } catch (_) {}

      final items = locations.map((loc) {
        final stockQty = stockByLocation[loc.id] ?? 0;
        return LocationItem(
          id: loc.id,
          name: loc.name,
          type: _typeDisplayName(loc.locationType),
          typeBg: _typeBg(loc.locationType),
          typeColor: _typeColor(loc.locationType),
          status: loc.status == 'active' ? 'Active' : 'Inactive',
          statusBg: loc.status == 'active'
              ? const Color(0xFFDCFCE7)
              : const Color(0xFFFEE2E2),
          statusColor: loc.status == 'active'
              ? const Color(0xFF15803D)
              : const Color(0xFFDC2626),
          address: [
            loc.streetAddress,
            loc.city,
            loc.postalCode,
          ].where((s) => s != null && s.isNotEmpty).join(', '),
          city: loc.city ?? '',
          totalStock: _formatQty(stockQty),
          activeTransfers: '0 Active',
          activeTransfersColor: const Color(0xFF6B7280),
          imageAsset: '',
          isActive: loc.status == 'active',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _locations = items;
          _totalStockUnits = totalUnits;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locations = const [];
          _isLoading = false;
        });
      }
    }
  }

  static String _typeDisplayName(String t) {
    switch (t.toLowerCase()) {
      case 'retail':
      case 'retail_store':
        return 'Retail Store';
      case 'popup':
      case 'pop_up':
        return 'Pop-up';
      case 'distribution_center':
        return 'Distribution Centre';
      default:
        return 'Warehouse';
    }
  }

  static Color _typeBg(String t) {
    switch (t.toLowerCase()) {
      case 'retail':
      case 'retail_store':
        return const Color(0xFFEFF6FF);
      case 'popup':
      case 'pop_up':
        return const Color(0xFFFEF3C7);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  static Color _typeColor(String t) {
    switch (t.toLowerCase()) {
      case 'retail':
      case 'retail_store':
        return const Color(0xFF2563EB);
      case 'popup':
      case 'pop_up':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF475569);
    }
  }

  static String _formatQty(int n) {
    if (n == 0) return '0';
    return n.toString().replaceAllMapped(
      RegExp(r'(\d+?)(?=(\d\d)+(\d)(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LocationItem> get _filteredLocations {
    final q = _searchController.text.trim().toLowerCase();
    return _locations.where((loc) {
      if (_selectedType != 'All Types' && loc.type != _selectedType)
        return false;
      if (_selectedStatus != 'All Status' && loc.status != _selectedStatus)
        return false;
      if (q.isNotEmpty) {
        final matches =
            loc.name.toLowerCase().contains(q) ||
            loc.address.toLowerCase().contains(q) ||
            loc.city.toLowerCase().contains(q);
        if (!matches) return false;
      }
      return true;
    }).toList();
  }

  void _showAddLocationModal() {
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
              child: const Icon(
                Icons.add_business_rounded,
                color: Color(0xFF92400E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Add Inventory Node / Store',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Location / Branch Name',
                  hintText: 'e.g. London Regent St Store',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Street Address & Postal Code',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Node Type (Warehouse, Retail Store, Pop-up)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
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
                const SnackBar(
                  content: Text(
                    'New inventory node registered across network.',
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
            child: const Text('Add Location'),
          ),
        ],
      ),
    );
  }

  void _showAiLocationInsightsModal() {
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
              child: const Icon(
                Icons.auto_awesome,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Network Balancing Recommendations',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: _locations.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Add inventory locations to receive AI-powered network balancing insights.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add inventory data to unlock AI-powered cross-location rebalancing and transfer recommendations.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildInsightBullet(
                      'Stock Velocity Analysis',
                      'AI will compare sell-through rates across ${_locations.length} registered location(s) to identify rebalancing opportunities.',
                    ),
                    const SizedBox(height: 10),
                    _buildInsightBullet(
                      'Transfer Scheduling',
                      'Once inventory data is recorded, automated transfer scheduling will prevent stockouts and reduce excess holding.',
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
        ],
      ),
    );
  }

  Widget _buildInsightBullet(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: Color(0xFF16A34A),
          size: 18,
        ),
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
                desc,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 80),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF8C5E33),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Locations + Subtitle + [+ Add Location]
          _buildHeader(),
          const SizedBox(height: 20),

          // 2. Top 4 Metric KPI Cards
          _buildKpiCardsRow(),
          const SizedBox(height: 20),

          // 3. Search & Filter & View Controls
          _buildControlsRow(),
          const SizedBox(height: 20),

          // 4. Location Cards Grid
          if (_isGridView)
            _buildLocationCardsGrid()
          else
            _buildLocationSummaryCard(),
          const SizedBox(height: 24),

          // 5. Bottom Row: Network Map + Location Summary
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1060;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Network Map (~38%)
                    Expanded(flex: 38, child: _buildNetworkMapCard()),
                    const SizedBox(width: 20),

                    // Location Summary Table (~62%)
                    Expanded(flex: 62, child: _buildLocationSummaryCard()),
                  ],
                );
              }

              return Column(
                children: [
                  _buildNetworkMapCard(),
                  const SizedBox(height: 20),
                  _buildLocationSummaryCard(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // 6. Bottom AI Location Insights Banner
          _buildAiLocationBanner(),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Locations',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your inventory across all stores, warehouses and distribution points.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: widget.onAddLocation ?? _showAddLocationModal,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Location'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF181513),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            textStyle: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // 2. Top 4 Metric KPI Cards
  Widget _buildKpiCardsRow() {
    final activeCount = _locations.where((l) => l.isActive).length;
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            icon: Icons.location_on_outlined,
            title: 'Total Registered Locations',
            value:
                '${_locations.length} node${_locations.length == 1 ? '' : 's'}',
            trend: '$activeCount active',
            isTrendPositive: activeCount > 0,
            sparklineColor: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            icon: Icons.inventory_2_outlined,
            title: 'Total Units Across Network',
            value: _totalStockUnits > 0
                ? '${_formatQty(_totalStockUnits)} units'
                : '—',
            trend: _totalStockUnits > 0 ? 'In stock' : 'No stock recorded',
            isTrendPositive: _totalStockUnits > 0,
            sparklineColor: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            icon: Icons.sync_alt_rounded,
            title: 'Pending Network Transfers',
            value: '—',
            trend: 'No data yet',
            isTrendPositive: false,
            trendColor: const Color(0xFF6B7280),
            sparklineColor: const Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildKpiCard(
            icon: Icons.storefront_outlined,
            title: 'Total Stock Value',
            value: '—',
            trend: 'No valuation data',
            isTrendPositive: false,
            trendColor: const Color(0xFF6B7280),
            sparklineColor: const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required String title,
    required String value,
    required String trend,
    required bool isTrendPositive,
    Color? trendColor,
    required Color sparklineColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBF4EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: const Color(0xFF92400E)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF6B7280),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    trend,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color:
                          trendColor ??
                          (isTrendPositive
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
              // Mini Sparkline
              SizedBox(
                width: 54,
                height: 22,
                child: CustomPaint(
                  painter: _MiniSparklinePainter(color: sparklineColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Search & Filter & View Controls
  Widget _buildControlsRow() {
    return Row(
      children: [
        // Search
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
                const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Search location, city or address...',
                      hintStyle: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
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
        const SizedBox(width: 10),

        // Type dropdown
        _buildDropdown(
          value: _selectedType,
          items: const ['All Types', 'Retail Store', 'Warehouse', 'Pop-up'],
          onChanged: (val) =>
              setState(() => _selectedType = val ?? 'All Types'),
        ),
        const SizedBox(width: 8),

        // Status dropdown
        _buildDropdown(
          value: _selectedStatus,
          items: const ['All Status', 'Active', 'Inactive'],
          onChanged: (val) =>
              setState(() => _selectedStatus = val ?? 'All Status'),
        ),
        const SizedBox(width: 8),

        // Zone dropdown
        _buildDropdown(
          value: _selectedZone,
          items: const ['All Zones', 'Zone A', 'Zone B'],
          onChanged: (val) =>
              setState(() => _selectedZone = val ?? 'All Zones'),
        ),
        const SizedBox(width: 10),

        // View Map button
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.map_outlined, size: 16),
          label: const Text('View Map'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF374151),
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            textStyle: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Sort by dropdown
        _buildDropdown(
          value: _selectedSort,
          items: const [
            'Sort by: Name',
            'Sort by: Stock',
            'Sort by: Transfers',
          ],
          onChanged: (val) =>
              setState(() => _selectedSort = val ?? 'Sort by: Name'),
        ),
        const SizedBox(width: 10),

        // View Switcher (Grid / List)
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () => setState(() => _isGridView = true),
                child: Container(
                  width: 38,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isGridView
                        ? const Color(0xFFFBF4EB)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(7),
                    ),
                  ),
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 17,
                    color: _isGridView
                        ? const Color(0xFFB45309)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
              Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
              InkWell(
                onTap: () => setState(() => _isGridView = false),
                child: Container(
                  width: 38,
                  height: 40,
                  decoration: BoxDecoration(
                    color: !_isGridView
                        ? const Color(0xFFFBF4EB)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(7),
                    ),
                  ),
                  child: Icon(
                    Icons.format_list_bulleted_rounded,
                    size: 18,
                    color: !_isGridView
                        ? const Color(0xFFB45309)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: Color(0xFF6B7280),
          ),
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // 4. Location Cards Grid
  Widget _buildLocationCardsGrid() {
    final filtered = _filteredLocations;
    if (filtered.isEmpty) {
      return _buildEmptyLocationsCard();
    }
    return Row(
      children: [
        for (int i = 0; i < filtered.length; i++) ...[
          Expanded(child: _buildLocationCard(filtered[i])),
          if (i < filtered.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildEmptyLocationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Color(0xFFFBF4EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_outlined,
              size: 26,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No locations yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your first store, warehouse, or distribution node to get started.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: widget.onAddLocation ?? _showAddLocationModal,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add First Location'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(LocationItem loc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image with Badges
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(11),
                ),
                child: SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: Image.asset(
                    loc.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFF1F5F9),
                      child: const Icon(
                        Icons.storefront_outlined,
                        color: Color(0xFF94A3B8),
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Body Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: loc.typeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        loc.type,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: loc.typeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: loc.statusBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        loc.status,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: loc.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Text(
                  loc.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        loc.address,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF6B7280),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Metrics: Total Stock + Active Transfers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Stock',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${loc.totalStock} items',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Active Transfers',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          loc.activeTransfers,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: loc.activeTransfersColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action buttons: [View Details] [Manage Stock]
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => widget.onViewDetails?.call(loc),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF374151),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => widget.onManageStock?.call(loc),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: loc.isActive
                              ? const Color(0xFF181513)
                              : Colors.white,
                          foregroundColor: loc.isActive
                              ? Colors.white
                              : const Color(0xFF374151),
                          side: loc.isActive
                              ? null
                              : const BorderSide(color: Color(0xFFD1D5DB)),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(loc.isActive ? 'Manage Stock' : 'Activate'),
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

  // 5. Left: Network Map Card
  Widget _buildNetworkMapCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Network Map',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              Row(
                children: [
                  _buildMapLegendItem('Active', const Color(0xFF16A34A)),
                  const SizedBox(width: 10),
                  _buildMapLegendItem('Limited', const Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  _buildMapLegendItem('Inactive', const Color(0xFFDC2626)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Map Canvas with zoom controls
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _NetworkTopologyMapPainter(
                      locationNames: _locations.map((l) => l.name).toList(),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Icon(
                            Icons.add,
                            size: 14,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 1,
                        color: const Color(0xFFE2E8F0),
                      ),
                      InkWell(
                        onTap: () {},
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 14,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMapLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // 5. Right: Location Summary Table Card
  Widget _buildLocationSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Location Summary',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                InkWell(
                  onTap: _showAiLocationInsightsModal,
                  child: Row(
                    children: [
                      Text(
                        'View AI Locations',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: Color(0xFFB45309),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 30,
                  child: Text(
                    'LOCATION',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  flex: 18,
                  child: Text(
                    'TYPE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: Text(
                    'CITY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: Text(
                    'TOTAL STOCK',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: Text(
                    'ACTIVE TRANSFERS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  flex: 14,
                  child: Text(
                    'STATUS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 24,
                  child: Text(
                    'ACTIONS',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 10,
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
          if (_locations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No locations registered yet.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          for (final loc in _locations) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 30,
                    child: Text(
                      loc.name,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 18,
                    child: loc.type == 'Pop-up'
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: loc.typeBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                loc.type,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: loc.typeColor,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            loc.type,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF4B5563),
                            ),
                          ),
                  ),
                  Expanded(
                    flex: 16,
                    child: Text(
                      loc.city,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 16,
                    child: Text(
                      loc.totalStock,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 20,
                    child: Text(
                      loc.activeTransfers,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: loc.activeTransfersColor,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 14,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: loc.statusBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          loc.status,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: loc.statusColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        onSelected: (val) {
                          if (val == 'manage') widget.onManageStock?.call(loc);
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: 'manage',
                            child: Text(
                              'Manage Stock',
                              style: GoogleFonts.inter(fontSize: 12.5),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'view',
                            child: Text(
                              'View Details',
                              style: GoogleFonts.inter(fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }

  // 6. Bottom AI Location Insights Banner
  Widget _buildAiLocationBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Location Insights',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Optimize stock distribution, reduce transfer time, and prevent stockouts with AI-powered insights.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: widget.onGetAiInsights ?? _showAiLocationInsightsModal,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFF59E0B)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Get AI Insights'),
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

// Mini Sparkline Painter
class _MiniSparklinePainter extends CustomPainter {
  const _MiniSparklinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.85,
        size.width * 0.6,
        size.height * 0.2,
        size.width,
        size.height * 0.1,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Network Topology Map Painter (dynamic – uses real location names)
class _NetworkTopologyMapPainter extends CustomPainter {
  const _NetworkTopologyMapPainter({this.locationNames = const []});
  final List<String> locationNames;

  // Fixed node positions (up to 6 locations)
  static const _nodeOffsets = [
    [0.55, 0.32],
    [0.51, 0.65],
    [0.80, 0.55],
    [0.25, 0.55],
    [0.70, 0.28],
    [0.32, 0.28],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    final bgPaint = Paint()..color = const Color(0xFFF5F3EF);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Land masses
    final landPaint = Paint()..color = const Color(0xFFEBE6DC);
    final land1 = Path()
      ..moveTo(size.width * 0.1, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.1,
        size.width * 0.45,
        size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.7,
        size.width * 0.2,
        size.height * 0.75,
      )
      ..close();
    canvas.drawPath(land1, landPaint);
    final land2 = Path()
      ..moveTo(size.width * 0.48, size.height * 0.2)
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.15,
        size.width * 0.85,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.85,
        size.width * 0.5,
        size.height * 0.7,
      )
      ..close();
    canvas.drawPath(land2, landPaint);

    if (locationNames.isEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: 'Add locations to see network map',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: const Color(0xFF9CA3AF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width);
      tp.paint(
        canvas,
        Offset((size.width - tp.width) / 2, size.height / 2 - tp.height / 2),
      );
      return;
    }

    final count = locationNames.length.clamp(0, _nodeOffsets.length);
    final pts = List.generate(
      count,
      (i) => Offset(
        size.width * _nodeOffsets[i][0],
        size.height * _nodeOffsets[i][1],
      ),
    );

    // Draw connections from hub (index 0) to all others
    if (pts.length > 1) {
      final curvePaint = Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      for (int i = 1; i < pts.length; i++) {
        final from = pts[0];
        final to = pts[i];
        final path = Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(
            (from.dx + to.dx) / 2,
            (from.dy + to.dy) / 2 - 20,
            to.dx,
            to.dy,
          );
        canvas.drawPath(path, curvePaint);
      }
    }

    // Draw nodes
    for (int i = 0; i < pts.length; i++) {
      _drawNode(canvas, pts[i], locationNames[i], const Color(0xFF16A34A));
    }
  }

  void _drawNode(Canvas canvas, Offset pt, String label, Color color) {
    final fillPaint = Paint()..color = color;
    final ringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(pt, 5.5, fillPaint);
    canvas.drawCircle(pt, 5.5, ringPaint);
    final display = label.length > 14 ? '${label.substring(0, 12)}…' : label;
    final tp = TextPainter(
      text: TextSpan(
        text: '  $display',
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(pt.dx + 4, pt.dy - 6));
  }

  @override
  bool shouldRepaint(covariant _NetworkTopologyMapPainter old) =>
      old.locationNames != locationNames;
}
