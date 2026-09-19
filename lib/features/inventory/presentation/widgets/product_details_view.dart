// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductDetailsView extends StatefulWidget {
  const ProductDetailsView({
    super.key,
    this.onBackToInventory,
    this.onEditProduct,
  });

  final VoidCallback? onBackToInventory;
  final VoidCallback? onEditProduct;

  @override
  State<ProductDetailsView> createState() => _ProductDetailsViewState();
}

class _ProductDetailsViewState extends State<ProductDetailsView> {
  int _selectedTabIndex = 1; // 0: Overview, 1: Variants, 2: Inventory, 3: Purchasing, 4: Sales, 5: Activity
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Product Header Card
          _buildProductHeaderCard(),
          const SizedBox(height: 20),

          // 2. Horizontal Navigation Tabs
          _buildNavigationTabs(),
          const SizedBox(height: 20),

          // 3. Color × Size Inventory Matrix Card
          _buildMatrixCard(),
          const SizedBox(height: 16),

          // 4. Bottom Legend & Real-time Info Bar
          _buildLegendBar(),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // 1. Top Product Header Card
  Widget _buildProductHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Large Photo (Square ~130x130)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/oxford_linen_shirt.jpg',
              width: 130,
              height: 130,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 130,
                height: 130,
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.checkroom_rounded, size: 48, color: Color(0xFF94A3B8)),
              ),
            ),
          ),
          const SizedBox(width: 22),

          // Details & KPI Cards
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title, Active Badge, and Action Buttons
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Oxford Linen Shirt',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF15803D),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Active',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: widget.onEditProduct,
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Edit Product'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        minimumSize: Size.zero,
                      ),
                      child: const Icon(Icons.more_horiz_rounded, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  'SKU: TS-10492   •   Summer 2027   •   Category: Shirts',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 14),

                // Two Summary Stat Cards
                Row(
                  children: [
                    // Card 1: Total Stock Available
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.all_inbox_rounded, size: 20, color: Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Stock Available',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '245 units',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              Text(
                                'across 4 locations',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Card 2: Gross Value
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3E8FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.circle_outlined, size: 20, color: Color(0xFF8B5CF6)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Gross Value',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF9CA3AF)),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '₹14.8L',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 14), // Balances height with Card 1
                            ],
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

  // 2. Horizontal Navigation Tabs
  Widget _buildNavigationTabs() {
    final tabs = [
      {'title': 'Overview', 'icon': Icons.description_outlined},
      {'title': 'Variants', 'icon': Icons.inventory_2_outlined},
      {'title': 'Inventory', 'icon': Icons.storefront_outlined},
      {'title': 'Purchasing', 'icon': Icons.shopping_cart_outlined},
      {'title': 'Sales', 'icon': Icons.bar_chart_rounded},
      {'title': 'Activity', 'icon': Icons.history_rounded},
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            _buildTabItem(
              title: tabs[i]['title'] as String,
              icon: tabs[i]['icon'] as IconData,
              index: i,
            ),
            if (i < tabs.length - 1) const SizedBox(width: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required String title,
    required IconData icon,
    required int index,
  }) {
    final isActive = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFFD97706) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isActive ? const Color(0xFFB45309) : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? const Color(0xFF111827) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. Color × Size Inventory Matrix Card
  Widget _buildMatrixCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Matrix Toolbar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.all_inbox_rounded, size: 20, color: Color(0xFF1E293B)),
                    const SizedBox(width: 8),
                    Text(
                      'Color × Size Inventory Matrix',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 210,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, size: 15, color: Color(0xFF9CA3AF)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF1E293B)),
                              decoration: InputDecoration(
                                hintText: 'Search color, size...',
                                hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list_rounded, size: 14),
                      label: const Text('Filters'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: const Size(0, 34),
                        textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 30,
                  child: Text('Color', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ),
                Expanded(flex: 12, child: Text('S', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 12, child: Text('M', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 12, child: Text('L', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 12, child: Text('XL', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 12, child: Text('XXL', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                const SizedBox(width: 24),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Row 1: Black
          _buildMatrixRow(
            colorName: 'Black',
            colorDot: const Color(0xFF18181B),
            s: '12',
            m: '24',
            l: '18',
            xl: '7',
            xxl: '3',
            xxlIsLow: true,
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Row 2: Sand
          _buildMatrixRow(
            colorName: 'Sand',
            colorDot: const Color(0xFFD4C4B5),
            s: '8',
            m: '14',
            l: '21',
            xl: '4',
            xxl: '2',
            xlIsLow: true,
            xxlIsLow: true,
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Row 3: White
          _buildMatrixRow(
            colorName: 'White',
            colorDot: Colors.white,
            hasBorder: true,
            s: '17',
            m: '31',
            l: '26',
            xl: '9',
            xxl: '5',
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Row 4: Navy
          _buildMatrixRow(
            colorName: 'Navy',
            colorDot: const Color(0xFF1E3A8A),
            s: '6',
            m: '18',
            l: '14',
            xl: '8',
            xxl: '1',
            xxlIsOut: true,
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Pagination Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing 1–4 of 4 colors',
                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
                ),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.chevron_left_rounded, size: 15, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFD97706)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '1',
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.chevron_right_rounded, size: 15, color: Color(0xFF94A3B8)),
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

  Widget _buildMatrixRow({
    required String colorName,
    required Color colorDot,
    bool hasBorder = false,
    required String s,
    required String m,
    required String l,
    required String xl,
    required String xxl,
    bool xlIsLow = false,
    bool xxlIsLow = false,
    bool xxlIsOut = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Color Circle + Label
          Expanded(
            flex: 30,
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: colorDot,
                    shape: BoxShape.circle,
                    border: hasBorder ? Border.all(color: const Color(0xFFCBD5E1), width: 1.5) : null,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  colorName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),

          // S
          Expanded(
            flex: 12,
            child: Text(s, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B))),
          ),

          // M
          Expanded(
            flex: 12,
            child: Text(m, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B))),
          ),

          // L
          Expanded(
            flex: 12,
            child: Text(l, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B))),
          ),

          // XL
          Expanded(
            flex: 12,
            child: xlIsLow ? _buildPill(xl, isOut: false) : Text(xl, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B))),
          ),

          // XXL
          Expanded(
            flex: 12,
            child: (xxlIsLow || xxlIsOut)
                ? _buildPill(xxl, isOut: xxlIsOut)
                : Text(xxl, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B))),
          ),

          // Actions
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFF9CA3AF)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String val, {required bool isOut}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: isOut ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          val,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isOut ? const Color(0xFFDC2626) : const Color(0xFFD97706),
          ),
        ),
      ),
    );
  }

  // 4. Bottom Legend & Real-time Info Bar
  Widget _buildLegendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildLegendItem(const Color(0xFF10B981), 'Healthy stock'),
              const SizedBox(width: 16),
              _buildLegendItem(const Color(0xFFF59E0B), 'Low stock'),
              const SizedBox(width: 16),
              _buildLegendItem(const Color(0xFFEF4444), 'Out of stock'),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                'Stock levels are updated in real-time.',
                style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color dotColor, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF4B5563), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
