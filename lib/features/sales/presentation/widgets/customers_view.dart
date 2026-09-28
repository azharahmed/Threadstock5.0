// ignore_for_file: deprecated_member_use
// ignore_for_file: unused_field, unused_element_parameter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/business/current_business_service.dart';
import '../../data/sales_repository.dart';
import '../../domain/models/customer.dart';

/// Customers — Sales sub-section showing the full customer list + profile panel.
/// Data comes from public.customers via SalesRepository, scoped to the current business.
class CustomersView extends StatefulWidget {
  const CustomersView({super.key});

  @override
  State<CustomersView> createState() => _CustomersViewState();
}

class _CustomersViewState extends State<CustomersView> {
  // Search / filter
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Data state
  List<Customer> _customers = [];
  bool _isLoading = true;
  String? _error;

  // Selected row for profile panel
  Customer? _selected;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    CustomerChangeNotifier.instance.addListener(_onCustomerChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    CustomerChangeNotifier.instance.removeListener(_onCustomerChanged);
    super.dispose();
  }

  void _onCustomerChanged() {
    if (mounted) _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final businessId = CurrentBusinessService.instance.currentBusinessId;
      if (businessId == null || businessId.isEmpty || businessId.startsWith('biz_')) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final list = await SalesRepository.instance.getCustomers(businessId: businessId);
      if (mounted) {
        setState(() {
          _customers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<Customer> get _filtered {
    if (_searchQuery.isEmpty) return _customers;
    final q = _searchQuery.toLowerCase();
    return _customers.where((c) {
      final nameMatch = c.name.toLowerCase().contains(q);
      final emailMatch = c.email != null && c.email!.toLowerCase().contains(q);
      final phoneMatch = c.phone != null && c.phone!.contains(q);
      return nameMatch || emailMatch || phoneMatch;
    }).toList();
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

          // Main layout
          LayoutBuilder(
            builder: (context, constraints) {
              // When no customer is selected, do NOT reserve space for the profile panel.
              if (_selected == null) {
                return _buildTableSection();
              }

              // At wide widths (>= 1080), display side-by-side with an inspector panel (~320px).
              final canDisplaySideBySide = constraints.maxWidth >= 1080;
              if (canDisplaySideBySide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTableSection()),
                    const SizedBox(width: 20),
                    SizedBox(width: 320, child: _buildProfilePanel()),
                  ],
                );
              }

              return Column(
                children: [
                  _buildTableSection(),
                  const SizedBox(height: 20),
                  _buildProfilePanel(),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Header
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        final titleSection = Column(
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
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            // Refresh
            InkWell(
              onTap: _loadCustomers,
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
                    const Icon(Icons.refresh_rounded, size: 15, color: Color(0xFF5C4F44)),
                    const SizedBox(width: 7),
                    Text(
                      'Refresh',
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
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [titleSection, const SizedBox(height: 14), actionButtons],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: titleSection),
            const SizedBox(width: 16),
            actionButtons,
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Metrics Strip
  // ---------------------------------------------------------------------------

  Widget _buildMetricsStrip() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 840;
        final card1 = _buildMetricCard(
          icon: Icons.people_outline_rounded,
          label: 'Total Customers',
          value: '${_customers.length}',
          trend: '—',
          trendColor: const Color(0xFF7E766B),
        );
        final card2 = _buildMetricCard(
          icon: Icons.shopping_cart_outlined,
          label: 'Repeat Purchase Rate',
          value: '—',
          trend: '—',
          trendColor: const Color(0xFF7E766B),
        );
        final card3 = _buildMetricCard(
          icon: Icons.payments_outlined,
          label: 'Avg. Lifetime Spend',
          value: '—',
          trend: '—',
          trendColor: const Color(0xFF7E766B),
        );
        final card4 = _buildMetricCard(
          icon: Icons.inventory_2_outlined,
          label: 'Total Orders',
          value: '—',
          trend: '—',
          trendColor: const Color(0xFF7E766B),
        );

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 12),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 12),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 12),
            Expanded(child: card2),
            const SizedBox(width: 12),
            Expanded(child: card3),
            const SizedBox(width: 12),
            Expanded(child: card4),
          ],
        );
      },
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1816),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          height: 40,
          child: Container(
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
      ],
    );
  }

  Widget _buildTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidget = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8DFD3)),
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 32, color: Color(0xFFEF4444)),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load customers',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1C1A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextButton(onPressed: _loadCustomers, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              else if (_filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5EDE1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.people_outline_rounded,
                            size: 24,
                            color: Color(0xFFBA8A55),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isEmpty ? 'No customers yet' : 'No customers found',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E1C1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Customers created during sales will appear here.'
                              : 'Try a different name, email or phone.',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF7E766B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._filtered.asMap().entries.map((entry) {
                  return _buildTableRow(
                    entry.value,
                    isLast: entry.key == _filtered.length - 1,
                  );
                }),
            ],
          ),
        );

        if (constraints.maxWidth < 800) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 800),
              child: tableWidget,
            ),
          );
        }
        return tableWidget;
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF7F2),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(11),
          topRight: Radius.circular(11),
        ),
        border: Border(bottom: BorderSide(color: Color(0xFFEEE5D8))),
      ),
      child: Row(
        children: [
          // Customer Name (flex 30)
          const Expanded(
            flex: 30,
            child: Padding(
              padding: EdgeInsets.only(right: 12),
              child: Text(
                'CUSTOMER',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E7F72),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // Phone (flex 18)
          const Expanded(
            flex: 18,
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text(
                'PHONE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E7F72),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // Email (flex 24)
          const Expanded(
            flex: 24,
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text(
                'EMAIL',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E7F72),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),

          // Member Since (flex 14)
          const Expanded(
            flex: 14,
            child: Text(
              'MEMBER SINCE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E7F72),
                letterSpacing: 0.3,
              ),
            ),
          ),

          // Actions spacer (width: 32)
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildTableRow(Customer c, {bool isLast = false}) {
    final isSelected = _selected?.id == c.id;
    return InkWell(
      onTap: () => setState(() => _selected = c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF8EF) : Colors.white,
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: Color(0xFFF4EDE5), width: 0.8),
                ),
        ),
        child: Row(
          children: [
            // Avatar + Name (flex 30)
            Expanded(
              flex: 30,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1816),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Phone (flex 18)
            Expanded(
              flex: 18,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  c.phone ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5C5047)),
                ),
              ),
            ),

            // Email (flex 24)
            Expanded(
              flex: 24,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  c.email ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF5C5047)),
                ),
              ),
            ),

            // Member Since (flex 14)
            Expanded(
              flex: 14,
              child: Text(
                _formatDate(c.createdAt),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF7E766B)),
              ),
            ),

            // Actions (width: 32)
            SizedBox(
              width: 32,
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

  Widget _buildAvatar(Customer c) {
    final initials = _initials(c.name);
    final color = _colorForName(c.name);
    return CircleAvatar(
      radius: 18,
      backgroundColor: color,
      child: Text(
        initials,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_customers.isEmpty && !_isLoading) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          _isLoading
              ? 'Loading...'
              : 'Showing ${_filtered.length} of ${_customers.length} customer${_customers.length == 1 ? '' : 's'}',
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF7E766B)),
        ),
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

    final initials = _initials(c.name);
    final color = _colorForName(c.name);

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
                  onTap: () => setState(() => _selected = null),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 17, color: Color(0xFF9E8E7E)),
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
                  backgroundColor: color,
                  child: Text(
                    initials,
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
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Active Customer',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Member since ${_formatDate(c.createdAt)}',
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
                _buildContactRow(Icons.email_outlined, c.email ?? '—'),
                const SizedBox(height: 8),
                _buildContactRow(Icons.phone_outlined, c.phone ?? '—'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // CTA buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
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
                        'View Purchase History',
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

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Color _colorForName(String name) {
    const colors = [
      Color(0xFF8C5E33),
      Color(0xFF5B6FBB),
      Color(0xFF1A8B6F),
      Color(0xFF9B3A5A),
      Color(0xFF6B47DC),
      Color(0xFF2E7D9E),
      Color(0xFF7A5C28),
      Color(0xFF4A7C5B),
    ];
    final idx = name.codeUnits.fold(0, (sum, c) => sum + c) % colors.length;
    return colors[idx];
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
