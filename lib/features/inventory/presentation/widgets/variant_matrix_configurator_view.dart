// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VariantMatrixItem {
  VariantMatrixItem({
    required this.size,
    required this.colorName,
    required this.colorDot,
    required this.sku,
    required this.retailPrice,
    required this.costPrice,
    required this.initialStock,
    this.isActive = true,
    this.isSelected = false,
  });

  final String size;
  final String colorName;
  final Color colorDot;
  final String sku;
  final int retailPrice;
  final int costPrice;
  final int initialStock;
  bool isActive;
  bool isSelected;

  String get variantLabel => '$size / $colorName';
}

class VariantMatrixConfiguratorView extends StatefulWidget {
  const VariantMatrixConfiguratorView({super.key, this.onBackToProductInfo});

  final VoidCallback? onBackToProductInfo;

  @override
  State<VariantMatrixConfiguratorView> createState() =>
      _VariantMatrixConfiguratorViewState();
}

class _VariantMatrixConfiguratorViewState
    extends State<VariantMatrixConfiguratorView> {
  final List<String> _sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];

  final List<Map<String, dynamic>> _colors = [
    {'name': 'Navy', 'color': const Color(0xFF0F172A)},
    {'name': 'Charcoal', 'color': const Color(0xFF475569)},
    {'name': 'Cream', 'color': const Color(0xFFE2D9C8)},
    {'name': 'Burgundy', 'color': const Color(0xFF7F1D1D)},
  ];

  late final List<VariantMatrixItem> _variants;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _variants = [
      VariantMatrixItem(
        size: 'XS',
        colorName: 'Navy',
        colorDot: const Color(0xFF0F172A),
        sku: 'VAR-XS-NVY',
        retailPrice: 3999,
        costPrice: 1450,
        initialStock: 12,
        isActive: true,
      ),
      VariantMatrixItem(
        size: 'S',
        colorName: 'Navy',
        colorDot: const Color(0xFF0F172A),
        sku: 'VAR-S-NVY',
        retailPrice: 3999,
        costPrice: 1450,
        initialStock: 24,
        isActive: true,
      ),
      VariantMatrixItem(
        size: 'M',
        colorName: 'Navy',
        colorDot: const Color(0xFF0F172A),
        sku: 'VAR-M-NVY',
        retailPrice: 3999,
        costPrice: 1450,
        initialStock: 18,
        isActive: true,
      ),
      VariantMatrixItem(
        size: 'L',
        colorName: 'Navy',
        colorDot: const Color(0xFF0F172A),
        sku: 'VAR-L-NVY',
        retailPrice: 3999,
        costPrice: 1450,
        initialStock: 14,
        isActive: true,
      ),
      VariantMatrixItem(
        size: 'XS',
        colorName: 'Charcoal',
        colorDot: const Color(0xFF475569),
        sku: 'VAR-XS-CHAR',
        retailPrice: 3999,
        costPrice: 1450,
        initialStock: 10,
        isActive: true,
      ),
      VariantMatrixItem(
        size: 'M',
        colorName: 'Charcoal',
        colorDot: const Color(0xFF475569),
        sku: 'VAR-M-CHAR',
        retailPrice: 3999,
        costPrice: 1450,
        initialStock: 14,
        isActive: true,
      ),
      VariantMatrixItem(
        size: 'L',
        colorName: 'Cream',
        colorDot: const Color(0xFFE2D9C8),
        sku: 'VAR-L-CREAM',
        retailPrice: 4199,
        costPrice: 1550,
        initialStock: 3,
        isActive: false,
      ),
      VariantMatrixItem(
        size: 'XL',
        colorName: 'Burgundy',
        colorDot: const Color(0xFF7F1D1D),
        sku: 'VAR-XL-BURG',
        retailPrice: 4199,
        costPrice: 1550,
        initialStock: 8,
        isActive: true,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<VariantMatrixItem> get _filteredVariants {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _variants;
    return _variants.where((v) {
      return v.variantLabel.toLowerCase().contains(q) ||
          v.sku.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Product Meta Header Banner (Thumbnail, Name, SKU, Category, Status, Back Button)
          _buildProductMetaBanner(),
          const SizedBox(height: 18),

          // 2. Page Header: Title & Subtitle
          _buildPageHeader(),
          const SizedBox(height: 20),

          // 3. Top Configuration Section: Option Building Blocks & Variant Preview Card
          _buildTopConfigCard(),
          const SizedBox(height: 20),

          // 4. Generated Variants Table Card
          _buildVariantsTableCard(),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // 1. Product Meta Header Banner
  Widget _buildProductMetaBanner() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                '',
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 42,
                  height: 42,
                  color: const Color(0xFFF1F5F9),
                  child: const Icon(
                    Icons.checkroom_rounded,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Product Variant Matrix',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '|   TS-SKU-BASE',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Apparel',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4B5563),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Active',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed:
              widget.onBackToProductInfo ?? () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 15),
          label: const Text('Back to Product Info'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF374151),
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // 2. Page Header: Title & Subtitle
  Widget _buildPageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Variant Matrix Configurator',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Define sizes, colors and pricing for this product. Generate all variants automatically.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // 3. Top Configuration Section
  Widget _buildTopConfigCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 860;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 68, child: _buildBuildingBlocks()),
                const SizedBox(width: 24),
                Expanded(flex: 32, child: _buildPreviewBox()),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBuildingBlocks(),
              const SizedBox(height: 20),
              _buildPreviewBox(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBuildingBlocks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF4EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.layers_outlined,
                size: 18,
                color: Color(0xFFB45309),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Product Option Building Blocks',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Sizes row
        Text(
          'Sizes (${_sizes.length} selected)',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final size in _sizes)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      size,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _sizes.remove(size)),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            InkWell(
              onTap: _showAddSizeDialog,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD97706)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add size',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Colors row
        Text(
          'Colors (${_colors.length} selected)',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final col in _colors)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: col['color'] as Color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      col['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _colors.remove(col)),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 13,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
            InkWell(
              onTap: _showAddColorDialog,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFD97706)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.add_rounded,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Add color',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPreviewBox() {
    final totalCount = _sizes.length * _colors.length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: Color(0xFFB45309),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Variant Preview',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB45309),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$totalCount variants',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          Text(
            '${_sizes.length} sizes × ${_colors.length} colors',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Regenerated $totalCount variants based on active sizes and colors.',
                  ),
                  backgroundColor: const Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(
              Icons.sync_rounded,
              size: 15,
              color: Color(0xFFB45309),
            ),
            label: const Text('Regenerate Matrix'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFFDE68A)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Generated Variants Table Card
  Widget _buildVariantsTableCard() {
    final activeCount = _variants.where((v) => v.isActive).length;
    final totalCount = 24;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Table Toolbar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$totalCount variants generated ($activeCount active)',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                Row(
                  children: [
                    // Search
                    Container(
                      width: 170,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 15,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: GoogleFonts.inter(fontSize: 12),
                              decoration: const InputDecoration(
                                hintText: 'Search variants...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 11.5,
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
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        minimumSize: Size.zero,
                        textStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Bulk Set Prices'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        minimumSize: Size.zero,
                        textStyle: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('Manage SKUs'),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: const Icon(
                        Icons.more_vert_rounded,
                        size: 16,
                        color: Color(0xFF6B7280),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                InkWell(
                  onTap: () {
                    final allSelected = _variants.every((v) => v.isSelected);
                    setState(() {
                      for (final v in _variants) {
                        v.isSelected = !allSelected;
                      }
                    });
                  },
                  child: SizedBox(
                    width: 20,
                    child: Icon(
                      _variants.every((v) => v.isSelected)
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank,
                      size: 16,
                      color: const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 22,
                  child: Text(
                    'Variant (Size / Color)',
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
                    'SKU',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Retail Price (₹)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Cost Price (₹)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 12,
                  child: Center(
                    child: Text(
                      'Initial Stock',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Center(
                    child: Text(
                      'Status',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Center(
                    child: Text(
                      'Actions',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table Rows
          for (final item in _filteredVariants) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  InkWell(
                    onTap: () =>
                        setState(() => item.isSelected = !item.isSelected),
                    child: SizedBox(
                      width: 20,
                      child: Icon(
                        item.isSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank,
                        size: 16,
                        color: item.isSelected
                            ? const Color(0xFFB45309)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Variant Size / Color
                  Expanded(
                    flex: 22,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item.colorDot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.variantLabel,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SKU
                  Expanded(
                    flex: 20,
                    child: Text(
                      item.sku,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF4B5563),
                      ),
                    ),
                  ),

                  // Retail Price
                  Expanded(
                    flex: 15,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _formatNumber(item.retailPrice),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),

                  // Cost Price
                  Expanded(
                    flex: 15,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        _formatNumber(item.costPrice),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),

                  // Initial Stock
                  Expanded(
                    flex: 12,
                    child: Center(
                      child: Text(
                        '${item.initialStock}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: item.initialStock <= 5
                              ? const Color(0xFFD97706)
                              : const Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),

                  // Status Toggle Switch
                  Expanded(
                    flex: 10,
                    child: Center(
                      child: SizedBox(
                        height: 24,
                        width: 40,
                        child: Switch(
                          value: item.isActive,
                          onChanged: (val) =>
                              setState(() => item.isActive = val),
                          activeColor: Colors.white,
                          activeTrackColor: const Color(0xFF059669),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ),

                  // Actions
                  Expanded(
                    flex: 8,
                    child: Center(
                      child: IconButton(
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          size: 16,
                          color: Color(0xFF9CA3AF),
                        ),
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],

          // Footer Pagination
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing 1–8 of 24 variants',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFD97706)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '1',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildPageNum('2'),
                    const SizedBox(width: 4),
                    _buildPageNum('3'),
                    const SizedBox(width: 4),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
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

  Widget _buildPageNum(String num) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: Text(
        num,
        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
      ),
    );
  }

  String _formatNumber(int n) {
    final s = n.toString();
    if (s.length > 3) {
      return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
    }
    return s;
  }

  void _showAddSizeDialog() {
    final sizeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add Size',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: sizeCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. 3XL, Petite, One Size',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newSize = sizeCtrl.text.trim();
              if (newSize.isNotEmpty && !_sizes.contains(newSize)) {
                setState(() => _sizes.add(newSize));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddColorDialog() {
    final colorCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add Color',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: colorCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Olive Green, Heather Gray',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newCol = colorCtrl.text.trim();
              if (newCol.isNotEmpty) {
                setState(() {
                  _colors.add({
                    'name': newCol,
                    'color': const Color(0xFF334155),
                  });
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
