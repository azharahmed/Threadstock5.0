// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class CategoryThresholdOverride {
  final String id;
  String category;
  int threshold;

  CategoryThresholdOverride({
    required this.id,
    required this.category,
    required this.threshold,
  });
}

class InventoryRulesView extends StatefulWidget {
  final VoidCallback? onBackToSettings;
  final void Function(String title, String subtitle)? onSubNavChanged;

  const InventoryRulesView({
    super.key,
    this.onBackToSettings,
    this.onSubNavChanged,
  });

  @override
  State<InventoryRulesView> createState() => _InventoryRulesViewState();
}

class _InventoryRulesViewState extends State<InventoryRulesView> {
  final TextEditingController _globalThresholdController =
      TextEditingController(text: '10');
  final TextEditingController _safetyStockController = TextEditingController(
    text: '15',
  );

  String _reorderMethodology = 'Average Daily Sales + Lead Time';
  String _stockValuationMethod = 'FIFO (First-In, First-Out)';

  bool _allowNegativeInventory = false;
  bool _batchLotTracking = true;
  bool _enforceExpirySafeguards = true;

  final List<String> _reorderMethodologyOptions = const [
    'Average Daily Sales + Lead Time',
    'Min/Max Fixed Par Level',
    'Predictive Machine Learning Demand',
    'Just-In-Time (JIT) Velocity',
  ];

  final List<String> _stockValuationOptions = const [
    'FIFO (First-In, First-Out)',
    'LIFO (Last-In, First-Out)',
    'WAC (Weighted Average Cost)',
    'Standard Standardized Costing',
  ];

  final List<CategoryThresholdOverride> _categoryOverrides = [
    CategoryThresholdOverride(
      id: 'c1',
      category: 'Heavy Outerwear (Blazers, Coats)',
      threshold: 3,
    ),
    CategoryThresholdOverride(
      id: 'c2',
      category: 'Accessories (Socks, Scarves)',
      threshold: 25,
    ),
  ];

  @override
  void dispose() {
    _globalThresholdController.dispose();
    _safetyStockController.dispose();
    super.dispose();
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _openAddOverrideDialog() {
    final catCtrl = TextEditingController();
    final threshCtrl = TextEditingController(text: '5');

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF2E6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        size: 20,
                        color: Color(0xFF7A481B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Category Override',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                          Text(
                            'Specify custom threshold for a product category',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: const Color(0xFF7E766B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Product Category',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: catCtrl,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g., Knitwear & Sweaters',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF7A481B)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Low Stock Threshold (Units)',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: threshCtrl,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(fontSize: 13),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF7A481B)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final cat = catCtrl.text.trim();
                        final val = int.tryParse(threshCtrl.text.trim()) ?? 5;
                        if (cat.isNotEmpty) {
                          setState(() {
                            _categoryOverrides.add(
                              CategoryThresholdOverride(
                                id: 'c_${DateTime.now().millisecondsSinceEpoch}',
                                category: cat,
                                threshold: val,
                              ),
                            );
                          });
                          Navigator.of(dialogCtx).pop();
                          _showFeedback('Override added for "$cat".');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1C1A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add Override',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1040;

        return DesktopContentConstraint(
          maxWidth: 1320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 24,
              bottom: 48,
              left: 28,
              right: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Area
                _buildHeader(),

                const SizedBox(height: 28),

                // Main Columns Grid
                if (isCompact) ...[
                  _buildLeftColumn(),
                  const SizedBox(height: 24),
                  _buildRightColumn(),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Low Stock Thresholds & Reorder Calculations (58% flex)
                      Expanded(flex: 58, child: _buildLeftColumn()),

                      const SizedBox(width: 24),

                      // Right Column: Additional Inventory Settings (42% flex)
                      Expanded(flex: 42, child: _buildRightColumn()),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Header matching Inventory Rules screenshot
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Warm circular avatar with box icon
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFFAF2E6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            size: 26,
            color: Color(0xFF7A481B),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Inventory Rules',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: const Color(0xFF181513),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Define stock thresholds, reorder logic, and additional inventory rules for your business.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6357),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Left Column containing Low Stock Thresholds & Reorder Calculations
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Low Stock Thresholds
        _buildLowStockThresholdsCard(),

        const SizedBox(height: 24),

        // Card 2: Reorder Calculations
        _buildReorderCalculationsCard(),
      ],
    );
  }

  // Card 1: Low Stock Thresholds
  Widget _buildLowStockThresholdsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with bar chart icon badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 20,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Low Stock Thresholds',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Set global and category-specific low stock thresholds.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Global Default Threshold (Units)
          Text(
            'Global Default Threshold (Units)',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 42,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: TextField(
              controller: _globalThresholdController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                _showFeedback('Global threshold updated to $val units');
              },
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Products will be flagged as low stock when quantity falls below this value.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8E867B),
            ),
          ),

          const SizedBox(height: 24),

          // Per Category Overrides Header
          Text(
            'Per Category Overrides',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 10),

          // Category Overrides Table Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEFE8DE)),
            ),
            child: Column(
              children: [
                // Table Header Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(9),
                      topRight: Radius.circular(9),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEFE8DE)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'CATEGORY',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: const Color(0xFF8E867B),
                          ),
                        ),
                      ),
                      Text(
                        'THRESHOLD',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                          color: const Color(0xFF8E867B),
                        ),
                      ),
                      const SizedBox(width: 80),
                    ],
                  ),
                ),

                // Table Rows
                for (int i = 0; i < _categoryOverrides.length; i++) ...[
                  _buildOverrideRow(
                    _categoryOverrides[i],
                    isLast: i == _categoryOverrides.length - 1,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // + Add Category Override Button
          Center(
            child: OutlinedButton.icon(
              onPressed: _openAddOverrideDialog,
              icon: const Icon(Icons.add, size: 16, color: Color(0xFF181513)),
              label: Text(
                'Add Category Override',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF181513),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFDFD4C5)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverrideRow(
    CategoryThresholdOverride override, {
    required bool isLast,
  }) {
    final controller = TextEditingController(
      text: override.threshold.toString(),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEFE8DE))),
      ),
      child: Row(
        children: [
          // Category Label
          Expanded(
            child: Text(
              override.category,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
            ),
          ),

          // Threshold input box + units
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDFD4C5)),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181513),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (val) {
                    final num = int.tryParse(val);
                    if (num != null) {
                      setState(() => override.threshold = num);
                      _showFeedback(
                        '${override.category} threshold updated to $num',
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'units',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ],
          ),

          const SizedBox(width: 14),

          // ••• action button
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_horiz_rounded,
              size: 20,
              color: Color(0xFF7E766B),
            ),
            tooltip: 'Category options',
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Color(0xFFDFD4C5)),
            ),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'reset',
                child: Text(
                  'Reset to Default (10)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF181513),
                  ),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Remove Override',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF9E4738),
                  ),
                ),
              ),
            ],
            onSelected: (val) {
              if (val == 'reset') {
                setState(() => override.threshold = 10);
                _showFeedback('${override.category} reset to 10 units.');
              } else if (val == 'delete') {
                setState(() => _categoryOverrides.remove(override));
                _showFeedback('Removed override for ${override.category}.');
              }
            },
          ),
        ],
      ),
    );
  }

  // Card 2: Reorder Calculations
  Widget _buildReorderCalculationsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with tag icon badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  size: 19,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reorder Calculations',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Configure how reorder quantities are calculated.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Side-by-side Fields: Reorder Methodology & Safety Stock Buffer (%)
          LayoutBuilder(
            builder: (context, box) {
              final isStacked = box.maxWidth < 480;

              if (isStacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildReorderMethodologyField(),
                    const SizedBox(height: 18),
                    _buildSafetyStockField(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildReorderMethodologyField()),
                  const SizedBox(width: 18),
                  Expanded(flex: 4, child: _buildSafetyStockField()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReorderMethodologyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reorder Methodology',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181513),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDFD4C5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _reorderMethodology,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF5E574E),
                size: 20,
              ),
              items: _reorderMethodologyOptions.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(
                    opt,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF181513),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _reorderMethodology = val);
                  _showFeedback('Reorder methodology set to $val');
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Uses historical sales and lead time to suggest reorder points.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF8E867B),
          ),
        ),
      ],
    );
  }

  Widget _buildSafetyStockField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Safety Stock Buffer (%)',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181513),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDFD4C5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _safetyStockController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181513),
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    _showFeedback('Safety buffer set to $val%');
                  },
                ),
              ),
              Text(
                '%',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Additional stock to keep as buffer.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF8E867B),
          ),
        ),
      ],
    );
  }

  // Right Column containing Additional Inventory Settings
  Widget _buildRightColumn() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with gear icon badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  size: 19,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Inventory Settings',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fine-tune inventory behavior and safeguards.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Stock Valuation Method
          Text(
            'Stock Valuation Method',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _stockValuationMethod,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF5E574E),
                  size: 20,
                ),
                items: _stockValuationOptions.map((opt) {
                  return DropdownMenuItem<String>(
                    value: opt,
                    child: Text(
                      opt,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _stockValuationMethod = val);
                    _showFeedback('Valuation method set to $val');
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Determines how stock layers are valued in reports.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF8E867B),
            ),
          ),

          const SizedBox(height: 26),

          // Setting 1: Allow Negative Inventory
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allow Negative Inventory',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Process sales even if quantity goes below zero.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _buildLuxuryToggle(
                value: _allowNegativeInventory,
                onChanged: (val) {
                  setState(() => _allowNegativeInventory = val);
                  _showFeedback(
                    'Negative inventory ${val ? "enabled" : "disabled"}',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Warning banner: Warning: Allowing negative balances can cause discrepancies in valuation reports.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF7D7C1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 17,
                  color: Color(0xFFC25424),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Warning: Allowing negative balances can cause discrepancies in valuation reports.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFA24E26),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Setting 2: Batch & Lot Tracking
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Batch & Lot Tracking',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track specific batches and lots for traceability.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _buildLuxuryToggle(
                value: _batchLotTracking,
                onChanged: (val) {
                  setState(() => _batchLotTracking = val);
                  _showFeedback(
                    'Batch & lot tracking ${val ? "enabled" : "disabled"}',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Setting 3: Enforce Expiry Safeguards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enforce Expiry Safeguards',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Alert staff of expiring stock before transactions.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              _buildLuxuryToggle(
                value: _enforceExpirySafeguards,
                onChanged: (val) {
                  setState(() => _enforceExpirySafeguards = val);
                  _showFeedback(
                    'Expiry safeguards ${val ? "enforced" : "disabled"}',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Luxury Pill Toggle matching ThreadStock aesthetics
  Widget _buildLuxuryToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: value ? const Color(0xFF5C3E21) : const Color(0xFFE2D8CC),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 19,
            height: 19,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x28000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
