// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../inventory/data/product_repository.dart';
import '../../../inventory/domain/models/product.dart';

class ProductDemandForecastView extends StatefulWidget {
  const ProductDemandForecastView({
    super.key,
    this.productId,
    this.onDraftReplenishmentPo,
    this.onNavigateToPurchasing,
    this.onSwitchToWorkspace,
  });

  final String? productId;
  final VoidCallback? onDraftReplenishmentPo;
  final VoidCallback? onNavigateToPurchasing;
  final VoidCallback? onSwitchToWorkspace;

  @override
  State<ProductDemandForecastView> createState() =>
      _ProductDemandForecastViewState();
}

class _ProductDemandForecastViewState extends State<ProductDemandForecastView> {
  String _selectedTimeframe = '90 days';
  bool _isLoading = true;
  Product? _product;
  Map<String, dynamic>? _productDetails;
  final ProductRepository _productRepo = ProductRepository();

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  Future<void> _loadProductData() async {
    try {
      final products = await _productRepo.getProducts();
      if (products.isNotEmpty) {
        Product target;
        if (widget.productId != null) {
          target = products.firstWhere(
            (p) => p.id == widget.productId,
            orElse: () => products.first,
          );
        } else {
          target = products.first;
        }
        final details = await _productRepo.getProductDetails(target.id);
        if (mounted) {
          setState(() {
            _product = target;
            _productDetails = details;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _product = null;
            _productDetails = null;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFBA8A55)),
          ),
        ),
      );
    }

    if (_product == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 36,
                color: Color(0xFFCBD5E1),
              ),
              const SizedBox(height: 12),
              Text(
                'No products in catalog',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Create products in Inventory to begin tracking demand forecasts.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Product Header Card (Image, Title, SKU, Tags, Timeframe Buttons)
          _buildProductHeaderCard(),
          const SizedBox(height: 16),

          // 2. 4 Metric Cards Row (Current Stock, 30-Day Forecast, Coverage, Reorder Point)
          _buildMetricsRow(),
          const SizedBox(height: 16),

          // 3. Sales & Demand Projection Trend (Interactive Custom Chart)
          _buildTrendChartCard(),
          const SizedBox(height: 16),

          // 4. Bottom Section: Identified Demand Drivers & AI Recommended Safety Action
          _buildBottomSection(),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. TOP PRODUCT HEADER CARD
  // ===========================================================================
  Widget _buildProductHeaderCard() {
    final name = _product?.name ?? 'Catalog Product';
    final variants = (_productDetails?['variants'] as List?) ?? [];
    String sku = 'No SKU';
    if (variants.isNotEmpty && variants.first is Map) {
      sku = (variants.first['sku'] as String?) ?? 'No SKU';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 800;

          final productInfo = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Placeholder Icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.checkroom_rounded,
                    size: 34,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(width: 18),

              // Title, SKU, Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'SKU: $sku',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tags Row
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildTagPill('Active', isGreen: true),
                        _buildTagPill('Catalog'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final timeframeSelector = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimeframeButton('30 days'),
              const SizedBox(width: 6),
              _buildTimeframeButton('60 days'),
              const SizedBox(width: 6),
              _buildTimeframeButton('90 days'),
            ],
          );

          if (isStacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                productInfo,
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: timeframeSelector,
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: productInfo),
              const SizedBox(width: 16),
              timeframeSelector,
            ],
          );
        },
      ),
    );
  }

  Widget _buildTagPill(String label, {bool isGreen = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isGreen ? const Color(0xFFEAF7EE) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isGreen ? FontWeight.w600 : FontWeight.w500,
          color: isGreen ? const Color(0xFF15803D) : const Color(0xFF475569),
        ),
      ),
    );
  }

  Widget _buildTimeframeButton(String label) {
    final isSelected = _selectedTimeframe == label;
    return InkWell(
      onTap: () {
        setState(() => _selectedTimeframe = label);
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF181513)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF181513)
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 2. 4 METRIC CARDS ROW
  // ===========================================================================
  Widget _buildMetricsRow() {
    final totalStock = (_productDetails?['total_stock'] as int?) ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.inventory_2_outlined,
            iconBg: const Color(0xFFF1F5F9),
            iconColor: const Color(0xFF64748B),
            title: 'Current Stock',
            value: '$totalStock units',
            badgeLabel: 'Real Stock',
            badgeColor: const Color(0xFFF1F5F9),
            badgeTextColor: const Color(0xFF64748B),
            subtext: 'Recorded inventory balances',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.trending_up_rounded,
            iconBg: const Color(0xFFF1F5F9),
            iconColor: const Color(0xFF94A3B8),
            title: '30-Day Forecast',
            value: '—',
            badgeLabel: 'Awaiting data',
            badgeColor: const Color(0xFFF1F5F9),
            badgeTextColor: const Color(0xFF94A3B8),
            subtext: 'Awaiting sufficient history',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.shield_outlined,
            iconBg: const Color(0xFFF1F5F9),
            iconColor: const Color(0xFF94A3B8),
            title: 'Coverage',
            value: '—',
            badgeLabel: 'Awaiting data',
            badgeColor: const Color(0xFFF1F5F9),
            badgeTextColor: const Color(0xFF94A3B8),
            subtext: 'Awaiting sufficient history',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.shopping_cart_outlined,
            iconBg: const Color(0xFFF1F5F9),
            iconColor: const Color(0xFF94A3B8),
            title: 'Reorder Point',
            value: '—',
            badgeLabel: 'Awaiting data',
            badgeColor: const Color(0xFFF1F5F9),
            badgeTextColor: const Color(0xFF94A3B8),
            subtext: 'Awaiting sufficient history',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String badgeLabel,
    required Color badgeColor,
    required Color badgeTextColor,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(icon, size: 20, color: iconColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: value == '—'
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF181513),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badgeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtext,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. SALES & DEMAND PROJECTION TREND (CHART)
  // ===========================================================================
  Widget _buildTrendChartCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sales & Demand Projection Trend',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 190,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.auto_graph_outlined,
                  size: 32,
                  color: Color(0xFFCBD5E1),
                ),
                const SizedBox(height: 10),
                Text(
                  'No forecast available yet',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Historical sales over at least 14 days are required to project trend lines.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 4. BOTTOM SECTION: DEMAND DRIVERS & SAFETY ACTION
  // ===========================================================================
  Widget _buildBottomSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isStacked = constraints.maxWidth < 960;

        final driversCard = Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identified Demand Drivers',
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.analytics_outlined,
                      size: 28,
                      color: Color(0xFFCBD5E1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No demand drivers identified yet',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Demand drivers such as seasonality and promotion effects require real transaction history to calculate.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        final safetyActionCard = Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 15,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AI RECOMMENDED SAFETY ACTION',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB45309),
                          letterSpacing: 0.7,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No actions recommended yet',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Replenishment and buffer stock recommendations will appear here when stockout risks are detected.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 40,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Draft Replenishment PO',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        );

        if (isStacked) {
          return Column(
            children: [
              driversCard,
              const SizedBox(height: 16),
              safetyActionCard,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: driversCard),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: safetyActionCard),
          ],
        );
      },
    );
  }
}
