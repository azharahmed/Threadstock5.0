// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProposalProductItem {
  ProposalProductItem({
    required this.name,
    required this.sku,
    required this.location,
    required this.available,
    required this.forecast,
    required this.recommended,
    required this.supplier,
    required this.unitCost,
    required this.totalCost,
    required this.imageAsset,
    this.isSelected = false,
  });

  final String name;
  final String sku;
  final String location;
  final int available;
  final int forecast;
  int recommended;
  final String supplier;
  final String unitCost;
  final String totalCost;
  final String imageAsset;
  bool isSelected;
}

class ProposalDetailView extends StatefulWidget {
  const ProposalDetailView({
    super.key,
    this.onBackToActions,
    this.onApprovePo,
    this.onRejectPlan,
    this.onEditQuantities,
    this.onViewFullAnalysis,
  });

  final VoidCallback? onBackToActions;
  final VoidCallback? onApprovePo;
  final VoidCallback? onRejectPlan;
  final VoidCallback? onEditQuantities;
  final VoidCallback? onViewFullAnalysis;

  @override
  State<ProposalDetailView> createState() => _ProposalDetailViewState();
}

class _ProposalDetailViewState extends State<ProposalDetailView> {
  bool _selectAll = false;
  bool _isEditingQuantities = false;

  final List<ProposalProductItem> _products = [
    ProposalProductItem(
      name: 'Oxford Linen Shirt',
      sku: 'TS-10432-W / M',
      location: 'Delhi Flagship',
      available: 18,
      forecast: 120,
      recommended: 150,
      supplier: 'Biella Fabric',
      unitCost: '₹800',
      totalCost: '₹1,20,000',
      imageAsset: 'Assets/oxford_linen_shirt.jpg',
    ),
    ProposalProductItem(
      name: 'Merino Wool Blazer',
      sku: 'MWB-20188-L',
      location: 'Mumbai Phoenix',
      available: 4,
      forecast: 45,
      recommended: 60,
      supplier: 'Biella Fabric',
      unitCost: '₹3,000',
      totalCost: '₹1,80,000',
      imageAsset: 'Assets/merino_wool_blazer.jpg',
    ),
    ProposalProductItem(
      name: 'Silk Evening Dress',
      sku: 'SED-16186-S',
      location: 'Lucknow Regent',
      available: 0,
      forecast: 30,
      recommended: 50,
      supplier: 'Como Weavers',
      unitCost: '₹3,640',
      totalCost: '₹1,82,000',
      imageAsset: 'Assets/silk_evening_dress.jpg',
    ),
  ];

  void _toggleSelectAll(bool? val) {
    setState(() {
      _selectAll = val ?? false;
      for (final p in _products) {
        p.isSelected = _selectAll;
      }
    });
  }

  void _showQuantityEditDialog(ProposalProductItem item) {
    final controller = TextEditingController(text: '${item.recommended}');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Edit Recommended Quantity',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF181513)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.name,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF181513)),
            ),
            const SizedBox(height: 4),
            Text(
              'SKU: ${item.sku} • Location: ${item.location}',
              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Recommended Units',
                labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(controller.text);
              if (newQty != null && newQty >= 0) {
                setState(() {
                  item.recommended = newQty;
                });
              }
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1060;

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Details, Metrics, Rationale, Table, AI Recommendation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBreadcrumbs(),
                      const SizedBox(height: 14),
                      _buildHeaderAndStatus(),
                      const SizedBox(height: 20),
                      _buildKpiMetricsGrid(),
                      const SizedBox(height: 20),
                      _buildRationalizationCard(),
                      const SizedBox(height: 22),
                      _buildAffectedProductsTable(),
                      const SizedBox(height: 20),
                      _buildAiRecommendationBanner(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Column: Proposal Summary Card
                SizedBox(
                  width: 350,
                  child: _buildProposalSummaryCard(),
                ),
              ],
            );
          }

          // Stacked Layout for compact screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBreadcrumbs(),
              const SizedBox(height: 14),
              _buildHeaderAndStatus(),
              const SizedBox(height: 20),
              _buildKpiMetricsGrid(),
              const SizedBox(height: 20),
              _buildRationalizationCard(),
              const SizedBox(height: 22),
              _buildAffectedProductsTable(),
              const SizedBox(height: 20),
              _buildAiRecommendationBanner(),
              const SizedBox(height: 24),
              _buildProposalSummaryCard(),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  // 1. Breadcrumbs: AI Actions > Delhi Hub > Low Stock Replenishment
  Widget _buildBreadcrumbs() {
    return Row(
      children: [
        InkWell(
          onTap: widget.onBackToActions,
          borderRadius: BorderRadius.circular(4),
          child: Text(
            'AI Actions',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(
          'Delhi Hub',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
        const SizedBox(width: 8),
        Text(
          'Low Stock Replenishment',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // 2. Header and Awaiting Approval Status Badge
  Widget _buildHeaderAndStatus() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Replenishment Proposal',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Prepared by ThreadStock AI for Vrindavan Express route.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFDF5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule_rounded, size: 15, color: Color(0xFFB45309)),
              const SizedBox(width: 6),
              Text(
                'AWAITING APPROVAL',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 3. 4 KPI Metric Cards in a Grid / Row
  Widget _buildKpiMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 680;
        if (isSmall) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'AFFECTED SKUS',
                      value: '18 SKUs',
                      subtitle: 'Linen & Cottons',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.bar_chart_rounded,
                      label: 'OPTIMIZED VOLUME',
                      value: '640 units',
                      subtitle: 'Balanced sizing',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.currency_rupee_rounded,
                      label: 'PROJECTED COST',
                      value: '₹4,82,000',
                      subtitle: 'Biella Mills preferred',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.shield_outlined,
                      label: 'SAFETY COVERAGE',
                      value: '37 days',
                      subtitle: 'Safety target met',
                    ),
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.inventory_2_outlined,
                label: 'AFFECTED SKUS',
                value: '18 SKUs',
                subtitle: 'Linen & Cottons',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.bar_chart_rounded,
                label: 'OPTIMIZED VOLUME',
                value: '640 units',
                subtitle: 'Balanced sizing',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.currency_rupee_rounded,
                label: 'PROJECTED COST',
                value: '₹4,82,000',
                subtitle: 'Biella Mills preferred',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.shield_outlined,
                label: 'SAFETY COVERAGE',
                value: '37 days',
                subtitle: 'Safety target met',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFFB45309)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // 4. "WHY TAKE THIS ACTION?" AI Rationalization Card
  Widget _buildRationalizationCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFFB45309)),
              const SizedBox(width: 8),
              Text(
                'WHY TAKE THIS ACTION?',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 650;
              if (isSmall) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildRationaleItem(
                            icon: Icons.trending_up_rounded,
                            iconColor: const Color(0xFFDC2626),
                            label: 'DEMAND INCREASE',
                            value: '+22.4% Spike',
                            valueColor: const Color(0xFFDC2626),
                            subtitle: 'Delhi Eid holiday rush',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRationaleItem(
                            icon: Icons.schedule_outlined,
                            iconColor: const Color(0xFFDC2626),
                            label: 'CURRENT COVERAGE',
                            value: '11.4 Days Left',
                            valueColor: const Color(0xFFDC2626),
                            subtitle: 'Low stock safety alert',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildRationaleItem(
                            icon: Icons.people_outline_rounded,
                            iconColor: const Color(0xFF64748B),
                            label: 'LEAD TIMES',
                            value: '14 Business Days',
                            valueColor: const Color(0xFF181513),
                            subtitle: 'Supplier processing queue',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildRationaleItem(
                            icon: Icons.shield_outlined,
                            iconColor: const Color(0xFF16A34A),
                            label: 'SAFETY TARGET',
                            value: '28 Days Desired',
                            valueColor: const Color(0xFF16A34A),
                            subtitle: 'Secured warehouse cover',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildRationaleItem(
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFFDC2626),
                      label: 'DEMAND INCREASE',
                      value: '+22.4% Spike',
                      valueColor: const Color(0xFFDC2626),
                      subtitle: 'Delhi Eid holiday rush',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRationaleItem(
                      icon: Icons.schedule_outlined,
                      iconColor: const Color(0xFFDC2626),
                      label: 'CURRENT COVERAGE',
                      value: '11.4 Days Left',
                      valueColor: const Color(0xFFDC2626),
                      subtitle: 'Low stock safety alert',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRationaleItem(
                      icon: Icons.people_outline_rounded,
                      iconColor: const Color(0xFF64748B),
                      label: 'LEAD TIMES',
                      value: '14 Business Days',
                      valueColor: const Color(0xFF181513),
                      subtitle: 'Supplier processing queue',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRationaleItem(
                      icon: Icons.shield_outlined,
                      iconColor: const Color(0xFF16A34A),
                      label: 'SAFETY TARGET',
                      value: '28 Days Desired',
                      valueColor: const Color(0xFF16A34A),
                      subtitle: 'Secured warehouse cover',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRationaleItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Affected Products & Quantities Section
  Widget _buildAffectedProductsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Affected Products & Quantities',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181513),
              ),
            ),
            InkWell(
              onTap: () {
                setState(() {
                  _isEditingQuantities = !_isEditingQuantities;
                });
                widget.onEditQuantities?.call();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF181513)),
                    const SizedBox(width: 6),
                    Text(
                      _isEditingQuantities ? 'Done Editing' : 'Edit Quantities',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Products Table
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Checkbox(
                        value: _selectAll,
                        onChanged: _toggleSelectAll,
                        activeColor: const Color(0xFF181513),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Product / SKU',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Location',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                      ),
                    ),
                    SizedBox(
                      width: 65,
                      child: Text(
                        'Available',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                      ),
                    ),
                    SizedBox(
                      width: 65,
                      child: Text(
                        'Forecast',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                      ),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text(
                        'Recommended',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Supplier',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                      ),
                    ),
                    SizedBox(
                      width: 75,
                      child: Text(
                        'Unit Cost',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                      ),
                    ),
                    SizedBox(
                      width: 85,
                      child: Text(
                        'Total Cost',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 30),
                  ],
                ),
              ),

              // Product Rows
              ...List.generate(_products.length, (index) {
                final item = _products[index];
                final isLast = index == _products.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: item.isSelected ? const Color(0xFFFBF8F3) : Colors.white,
                    border: isLast
                        ? null
                        : const Border(
                            bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.0),
                          ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Checkbox(
                          value: item.isSelected,
                          onChanged: (val) {
                            setState(() {
                              item.isSelected = val ?? false;
                              _selectAll = _products.every((p) => p.isSelected);
                            });
                          },
                          activeColor: const Color(0xFF181513),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Product Image + Name + SKU
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.asset(
                                item.imageAsset,
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 42,
                                  height: 42,
                                  color: const Color(0xFFE2E8F0),
                                  child: const Icon(Icons.image_not_supported_outlined, size: 20, color: Color(0xFF94A3B8)),
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
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF181513),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.sku,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Location
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ),

                      // Available
                      SizedBox(
                        width: 65,
                        child: Text(
                          '${item.available}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),

                      // Forecast
                      SizedBox(
                        width: 65,
                        child: Text(
                          '${item.forecast}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),

                      // Recommended (Input Pill)
                      SizedBox(
                        width: 90,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: InkWell(
                            onTap: () => _showQuantityEditDialog(item),
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              width: 58,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _isEditingQuantities ? const Color(0xFFB45309) : const Color(0xFFE2E8F0),
                                  width: _isEditingQuantities ? 1.5 : 1.0,
                                ),
                              ),
                              child: Text(
                                '${item.recommended}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF181513),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Supplier
                      Expanded(
                        flex: 2,
                        child: Text(
                          item.supplier,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),

                      // Unit Cost
                      SizedBox(
                        width: 75,
                        child: Text(
                          item.unitCost,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),

                      // Total Cost
                      SizedBox(
                        width: 85,
                        child: Text(
                          item.totalCost,
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),

                      // Actions ⋮
                      SizedBox(
                        width: 30,
                        child: IconButton(
                          icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showQuantityEditDialog(item),
                          tooltip: 'Edit quantity',
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // 6. Bottom AI Recommendation Banner
  Widget _buildAiRecommendationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline_rounded, size: 20, color: Color(0xFFB45309)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Recommendation',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'This replenishment will cover 37 days of demand and prevent an estimated ₹84,000 in potential lost sales. Recommended to approve and prepare PO.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: widget.onViewFullAnalysis,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Full Analysis',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFB45309)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Right Column: Proposal Summary Card
  Widget _buildProposalSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proposal Summary',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 14),

          // Hero Stack Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'Assets/replenishment_stack.jpg',
              height: 175,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                height: 175,
                width: double.infinity,
                color: const Color(0xFFE2E8F0),
                child: const Icon(Icons.image_outlined, size: 36, color: Color(0xFF94A3B8)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Low Stock Replenishment',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Vrindavan Express Air  •  Delhi Zone A',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Replenish high-demand SKUs to prevent stockouts and maintain optimal availability during the upcoming holiday period.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 14),

          // Metadata Key-Values
          _buildSummaryMetadataRow(
            label: 'System Confidence',
            value: '94.2% Accurate',
            valueColor: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 10),
          _buildSummaryMetadataRow(
            label: 'Supplier Deadlines',
            value: 'Within 48 hours',
            valueColor: const Color(0xFFDC2626),
          ),
          const SizedBox(height: 10),
          _buildSummaryMetadataRow(
            label: 'Average Lead Time',
            value: '12 Business Days',
            valueColor: const Color(0xFF181513),
          ),
          const SizedBox(height: 10),
          _buildSummaryMetadataRow(
            label: 'Created',
            value: 'Sep 15, 2026, 10:24 AM',
            valueColor: const Color(0xFF181513),
          ),
          const SizedBox(height: 10),
          _buildSummaryMetadataRow(
            label: 'Created by',
            value: 'ThreadStock AI',
            valueColor: const Color(0xFF181513),
          ),

          const SizedBox(height: 18),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 18),

          // Approve & Prepare PO Button (Solid Black with plane icon)
          InkWell(
            onTap: widget.onApprovePo,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF181513),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.near_me_outlined, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Approve & Prepare PO',
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
          const SizedBox(height: 10),

          // Reject Plan + Edit Quantities Buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: widget.onRejectPlan,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.close_rounded, size: 14, color: Color(0xFF181513)),
                        const SizedBox(width: 6),
                        Text(
                          'Reject Plan',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _isEditingQuantities = !_isEditingQuantities;
                    });
                    widget.onEditQuantities?.call();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF181513)),
                        const SizedBox(width: 6),
                        Text(
                          'Edit Quantities',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetadataRow({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
