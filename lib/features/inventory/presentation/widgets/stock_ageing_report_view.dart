// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/responsive_values.dart';

class StockAgeingReportView extends StatefulWidget {
  final VoidCallback? onExportBreakdown;
  final VoidCallback? onTriggerMarkdownPlan;
  final VoidCallback? onViewRecommendations;
  final VoidCallback? onCreateTransferPlan;

  const StockAgeingReportView({
    super.key,
    this.onExportBreakdown,
    this.onTriggerMarkdownPlan,
    this.onViewRecommendations,
    this.onCreateTransferPlan,
  });

  @override
  State<StockAgeingReportView> createState() => _StockAgeingReportViewState();
}

class _AgeingProductRecord {
  final String name;
  final String sku;
  final String category;
  final int ageDays;
  final int qty;
  final String value;
  final String location;
  final String riskLevel;
  final Color riskBg;
  final Color riskColor;
  final String monthlyCarryingCost;
  final String imageAsset;
  final String aiSuggestion;

  const _AgeingProductRecord({
    required this.name,
    required this.sku,
    required this.category,
    required this.ageDays,
    required this.qty,
    required this.value,
    required this.location,
    required this.riskLevel,
    required this.riskBg,
    required this.riskColor,
    required this.monthlyCarryingCost,
    required this.imageAsset,
    required this.aiSuggestion,
  });
}

class _StockAgeingReportViewState extends State<StockAgeingReportView> {
  String _selectedInterval = 'All Ageing Intervals';
  String _selectedCategory = 'All Categories';

  final List<String> _intervals = const [
    'All Ageing Intervals',
    '0–30 Days (Fresh)',
    '31–90 Days (Active)',
    '91–180 Days (Aging)',
    '180+ Days (Critical)',
  ];

  final List<String> _categories = const [
    'All Categories',
    'Shirts',
    'Knitwear',
    'Blazers',
    'Trousers',
    'Dresses',
  ];

  late List<_AgeingProductRecord> _records;
  late int _selectedRecordIndex;

  @override
  void initState() {
    super.initState();
    _selectedRecordIndex = 2; // Default to Silk Evening Dress (Red/S)
    _records = const [
      _AgeingProductRecord(
        name: 'Oxford Linen Shirt (Blue/M)',
        sku: 'OX-LN-BLU-M',
        category: 'Shirts',
        ageDays: 42,
        qty: 110,
        value: '₹1.4L',
        location: 'Delhi Flagship',
        riskLevel: 'Medium',
        riskBg: Color(0xFFFEF3C7),
        riskColor: Color(0xFFB45309),
        monthlyCarryingCost: '₹1,800 / mo',
        imageAsset: 'Assets/oxford_linen_shirt_blue.jpg',
        aiSuggestion: 'Normal sales velocity observed. Monitor inventory velocity for next 30 days before any discount intervention.',
      ),
      _AgeingProductRecord(
        name: 'Merino Wool Blazer (Navy/L)',
        sku: 'MW-BLZ-NVY-L',
        category: 'Blazers',
        ageDays: 18,
        qty: 45,
        value: '₹3.8L',
        location: 'Central Warehouse',
        riskLevel: 'Low',
        riskBg: Color(0xFFE6F4EA),
        riskColor: Color(0xFF137333),
        monthlyCarryingCost: '₹1,200 / mo',
        imageAsset: 'Assets/merino_wool_blazer.jpg',
        aiSuggestion: 'Recently received autumn stock. Current sales rate is tracking 12% above projected seasonal forecast.',
      ),
      _AgeingProductRecord(
        name: 'Silk Evening Dress (Red/S)',
        sku: 'SED-16166',
        category: 'Dresses',
        ageDays: 184,
        qty: 12,
        value: '₹2.2L',
        location: 'Mumbai',
        riskLevel: 'Critical',
        riskBg: Color(0xFFFEE2E2),
        riskColor: Color(0xFFDC2626),
        monthlyCarryingCost: '₹4,200 / mo',
        imageAsset: 'Assets/silk_evening_dress.jpg',
        aiSuggestion: 'Immediate Inter-Store Transfer to Delhi flagship is advised. Red sizes are currently out of stock there and have a high index of purchase interest.',
      ),
      _AgeingProductRecord(
        name: 'Gabardine Trench (Beige/M)',
        sku: 'GB-TRN-BGE-M',
        category: 'Trousers',
        ageDays: 120,
        qty: 28,
        value: '₹1.9L',
        location: 'Mumbai Boutique',
        riskLevel: 'High',
        riskBg: Color(0xFFFFEDD5),
        riskColor: Color(0xFFC2410C),
        monthlyCarryingCost: '₹2,600 / mo',
        imageAsset: 'Assets/gabardine_trench.jpg',
        aiSuggestion: 'Approaching end-of-season carrying cap. Bundle with matching knitwear or schedule targeted digital campaign.',
      ),
      _AgeingProductRecord(
        name: 'Cashmere Sweater (Grey/L)',
        sku: 'CS-SWT-GRY-L',
        category: 'Knitwear',
        ageDays: 95,
        qty: 62,
        value: '₹2.6L',
        location: 'Central Warehouse',
        riskLevel: 'High',
        riskBg: Color(0xFFFFEDD5),
        riskColor: Color(0xFFC2410C),
        monthlyCarryingCost: '₹3,100 / mo',
        imageAsset: 'Assets/cashmere_sweater.jpg',
        aiSuggestion: 'High static duration in Zone A. Transfer to high-altitude regional stores ahead of winter demand surge.',
      ),
    ];
  }

  void _showMarkdownPlanDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            const Icon(Icons.flash_on_rounded, size: 20, color: Color(0xFF181512)),
            const SizedBox(width: 10),
            Text(
              'Trigger Markdown Plan',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181512),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Apply tiered promotional markdown strategy across stagnant stock categories:',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B6358)),
              ),
              const SizedBox(height: 14),
              _buildMarkdownOption('180+ Days (Critical Aging)', '25% Clearance Markdown', 'Recovers ~₹4.8L capital in 14 days'),
              _buildMarkdownOption('91–180 Days (High Aging)', '15% Seasonal Markdown', 'Recovers ~₹6.2L capital in 30 days'),
              _buildMarkdownOption('31–90 Days (Moderate Aging)', 'Bundled Promotion (Buy 2, 10% Off)', 'Boosts multi-unit velocity'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF6B6358)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tiered markdown plan submitted for merchant approval.', style: GoogleFonts.inter(fontSize: 13)),
                  backgroundColor: const Color(0xFF181512),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181512),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Deploy Plan',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownOption(String title, String action, String outcome) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEADBCA)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF181512))),
            const SizedBox(height: 2),
            Text(action, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF8C5E33))),
            Text(outcome, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B6358))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRecord = _records[_selectedRecordIndex];

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveHorizontalMargin,
        vertical: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Filter and Action Bar
          _buildFilterBar(),
          const SizedBox(height: 16),

          // 2. Ageing Distribution by Category (Stacked Bars)
          _buildDistributionStackedBarsCard(),
          const SizedBox(height: 16),

          // 3. Middle Section (Detailed Ledger + Product Inspector)
          _buildMiddleSection(currentRecord),
          const SizedBox(height: 16),

          // 4. Bottom AI Callout Banner
          _buildAiInsightBanner(),
        ],
      ),
    );
  }

  // 1. Filter and Action Bar
  Widget _buildFilterBar() {
    return Row(
      children: [
        // Intervals Dropdown
        PopupMenuButton<String>(
          tooltip: 'Select Ageing Interval',
          offset: const Offset(0, 40),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE5DACD)),
          ),
          onSelected: (val) => setState(() => _selectedInterval = val),
          itemBuilder: (context) => _intervals.map((item) {
            return PopupMenuItem<String>(
              value: item,
              height: 36,
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: item == _selectedInterval ? FontWeight.w600 : FontWeight.w400,
                  color: item == _selectedInterval ? const Color(0xFF8C5E33) : const Color(0xFF181512),
                ),
              ),
            );
          }).toList(),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5DACD)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF6B6358)),
                const SizedBox(width: 8),
                Text(
                  _selectedInterval,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181512),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6B6358)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Categories Dropdown
        PopupMenuButton<String>(
          tooltip: 'Select Category',
          offset: const Offset(0, 40),
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE5DACD)),
          ),
          onSelected: (val) => setState(() => _selectedCategory = val),
          itemBuilder: (context) => _categories.map((cat) {
            return PopupMenuItem<String>(
              value: cat,
              height: 36,
              child: Text(
                cat,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: cat == _selectedCategory ? FontWeight.w600 : FontWeight.w400,
                  color: cat == _selectedCategory ? const Color(0xFF8C5E33) : const Color(0xFF181512),
                ),
              ),
            );
          }).toList(),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5DACD)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_offer_outlined, size: 14, color: Color(0xFF6B6358)),
                const SizedBox(width: 8),
                Text(
                  _selectedCategory,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181512),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6B6358)),
              ],
            ),
          ),
        ),

        const Spacer(),

        // Export Breakdown Button
        InkWell(
          onTap: widget.onExportBreakdown ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Exporting Stock Ageing Report CSV...', style: GoogleFonts.inter(fontSize: 13)),
                backgroundColor: const Color(0xFF181512),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5DACD)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.file_download_outlined, size: 16, color: Color(0xFF181512)),
                const SizedBox(width: 6),
                Text(
                  'Export Breakdown',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181512),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Trigger Markdown Plan Button
        InkWell(
          onTap: widget.onTriggerMarkdownPlan ?? _showMarkdownPlanDialog,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF181512),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Trigger Markdown Plan',
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
      ],
    );
  }

  // 2. Ageing Distribution by Category (Stacked Bar Chart)
  Widget _buildDistributionStackedBarsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ageing Distribution by Category',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181512),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Share of inventory value across ageing buckets',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B6358),
                    ),
                  ),
                ],
              ),
              // Legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendBox(const Color(0xFF8E9EAB), '0-30d'),
                  const SizedBox(width: 14),
                  _buildLegendBox(const Color(0xFF5D6B78), '31-90d'),
                  const SizedBox(width: 14),
                  _buildLegendBox(const Color(0xFF2E3842), '91-180d'),
                  const SizedBox(width: 14),
                  _buildLegendBox(const Color(0xFFC89748), '180+d'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Stacked Bars for 4 categories
          _buildStackedCategoryBar(
            category: 'Shirts',
            pct1: 28,
            pct2: 32,
            pct3: 26,
            pct4: 14,
          ),
          const SizedBox(height: 12),
          _buildStackedCategoryBar(
            category: 'Knitwear',
            pct1: 22,
            pct2: 38,
            pct3: 28,
            pct4: 12,
          ),
          const SizedBox(height: 12),
          _buildStackedCategoryBar(
            category: 'Blazers',
            pct1: 18,
            pct2: 34,
            pct3: 36,
            pct4: 12,
          ),
          const SizedBox(height: 12),
          _buildStackedCategoryBar(
            category: 'Trousers',
            pct1: 26,
            pct2: 40,
            pct3: 24,
            pct4: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendBox(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B6358),
          ),
        ),
      ],
    );
  }

  Widget _buildStackedCategoryBar({
    required String category,
    required int pct1,
    required int pct2,
    required int pct3,
    required int pct4,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            category,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181512),
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 32,
              child: Row(
                children: [
                  Expanded(
                    flex: pct1,
                    child: Container(
                      color: const Color(0xFF8E9EAB),
                      alignment: Alignment.center,
                      child: Text(
                        '$pct1%',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: pct2,
                    child: Container(
                      color: const Color(0xFF5D6B78),
                      alignment: Alignment.center,
                      child: Text(
                        '$pct2%',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: pct3,
                    child: Container(
                      color: const Color(0xFF2E3842),
                      alignment: Alignment.center,
                      child: Text(
                        '$pct3%',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: pct4,
                    child: Container(
                      color: const Color(0xFFC89748),
                      alignment: Alignment.center,
                      child: Text(
                        '$pct4%',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 3. Middle Section: Detailed Ledger + Product Inspector
  Widget _buildMiddleSection(_AgeingProductRecord currentRecord) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Detailed Ageing Ledger (~62% flex)
        Expanded(
          flex: 62,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detailed Ageing Ledger',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181512),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Opening full inventory ledger with all 4,247 SKUs...', style: GoogleFonts.inter(fontSize: 13)),
                            backgroundColor: const Color(0xFF181512),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF946A36),
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF946A36)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Table Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 25,
                        child: Text('Product', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B6358))),
                      ),
                      Expanded(
                        flex: 11,
                        child: Text('Category', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B6358))),
                      ),
                      Expanded(
                        flex: 11,
                        child: Text('Age (Days)', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B6358))),
                      ),
                      Expanded(
                        flex: 7,
                        child: Text('Qty', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B6358))),
                      ),
                      Expanded(
                        flex: 9,
                        child: Text('Value', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B6358))),
                      ),
                      Expanded(
                        flex: 11,
                        child: Center(
                          child: Text('Risk Level', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B6358))),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFF3ECE1)),

                // 5 Rows
                ...List.generate(_records.length, (index) {
                  final record = _records[index];
                  final isSelected = index == _selectedRecordIndex;
                  return InkWell(
                    onTap: () => setState(() => _selectedRecordIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFCF8F2) : Colors.transparent,
                        border: Border(
                          bottom: const BorderSide(color: Color(0xFFF7F3EE)),
                          left: isSelected ? const BorderSide(color: Color(0xFFBA8A55), width: 3) : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Thumbnail + Name
                          Expanded(
                            flex: 25,
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    record.imageAsset,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) => Container(
                                      width: 36,
                                      height: 36,
                                      color: const Color(0xFFF3ECE1),
                                      child: const Icon(Icons.checkroom_rounded, size: 18, color: Color(0xFF8C5E33)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    record.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF181512),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Category
                          Expanded(
                            flex: 11,
                            child: Text(
                              record.category,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2F69A8),
                              ),
                            ),
                          ),

                          // Age (Days)
                          Expanded(
                            flex: 11,
                            child: Text(
                              '${record.ageDays} Days',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: const Color(0xFF181512),
                              ),
                            ),
                          ),

                          // Qty
                          Expanded(
                            flex: 7,
                            child: Text(
                              '${record.qty}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF2F69A8),
                              ),
                            ),
                          ),

                          // Value
                          Expanded(
                            flex: 9,
                            child: Text(
                              record.value,
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF181512),
                              ),
                            ),
                          ),

                          // Risk Level Pill
                          Expanded(
                            flex: 11,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: record.riskBg,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  record.riskLevel,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: record.riskColor,
                                  ),
                                ),
                              ),
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
        const SizedBox(width: 16),

        // Right Column: Ageing Product Inspector (~38% flex)
        Expanded(
          flex: 38,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEADBCA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ageing Product Inspector',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181512),
                  ),
                ),
                const SizedBox(height: 14),

                // Large Banner Photo
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    currentRecord.imageAsset,
                    width: double.infinity,
                    height: 115,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: double.infinity,
                      height: 115,
                      color: const Color(0xFFF3ECE1),
                      child: const Icon(Icons.image_outlined, size: 36, color: Color(0xFF8C5E33)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title & SKU
                Text(
                  currentRecord.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181512),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'SKU: ${currentRecord.sku} | Current Location: ${currentRecord.location}',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6358),
                  ),
                ),
                const SizedBox(height: 14),

                // Metrics Rows
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Days Stagnant',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B6358)),
                    ),
                    Text(
                      '${currentRecord.ageDays} Days',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: currentRecord.ageDays >= 180 ? const Color(0xFFDC2626) : const Color(0xFF181512),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Carrying Cost (Est.)',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B6358)),
                    ),
                    Text(
                      currentRecord.monthlyCarryingCost,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181512),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // AI Suggestion Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFFD97706)),
                          const SizedBox(width: 6),
                          Text(
                            'AI SUGGESTION',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD97706),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentRecord.aiSuggestion,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4B5563),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: widget.onCreateTransferPlan ?? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Generated transfer plan for ${currentRecord.name}.', style: GoogleFonts.inter(fontSize: 13)),
                              backgroundColor: const Color(0xFF181512),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDECDB9)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Create Transfer Plan',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8C5E33),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 13, color: Color(0xFF8C5E33)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 4. Bottom AI Callout Banner
  Widget _buildAiInsightBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF9F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3E8DB)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 22,
            color: Color(0xFFBA8A55),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THREADSTOCK AI INSIGHT',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF946A36),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6B6358),
                      height: 1.35,
                    ),
                    children: [
                      TextSpan(
                        text: '~18% of total inventory value (₹12.6L)',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181512),
                        ),
                      ),
                      const TextSpan(
                        text: ' is in items aged 180+ days. A targeted markdown or inter-store transfer could recover value and improve stock health.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: widget.onViewRecommendations ?? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Opening AI Ageing Recommendations...', style: GoogleFonts.inter(fontSize: 13)),
                  backgroundColor: const Color(0xFF181512),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5DACD)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Recommendations',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF946A36),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFF946A36),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
