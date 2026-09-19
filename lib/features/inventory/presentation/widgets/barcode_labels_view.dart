// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LabelVariantItem {
  LabelVariantItem({
    required this.name,
    required this.variant,
    required this.sku,
    required this.price,
    required this.qty,
    required this.imageAsset,
    this.isSelected = false,
  });

  final String name;
  final String variant;
  final String sku;
  final String price;
  int qty;
  final String imageAsset;
  bool isSelected;
}

class BarcodeLabelsView extends StatefulWidget {
  const BarcodeLabelsView({
    super.key,
    this.onPrint,
    this.onDownloadPdf,
    this.onSaveConfig,
  });

  final VoidCallback? onPrint;
  final VoidCallback? onDownloadPdf;
  final VoidCallback? onSaveConfig;

  @override
  State<BarcodeLabelsView> createState() => _BarcodeLabelsViewState();
}

class _BarcodeLabelsViewState extends State<BarcodeLabelsView> {
  final TextEditingController _searchController = TextEditingController();

  late final List<LabelVariantItem> _variants;

  String _selectedTemplate = '40 × 30 mm (Standard Jewelry/Hangtag)';
  bool _includeName = true;
  bool _includePrice = true;
  bool _includeBarcode = true;
  bool _includeLogo = false;

  String _selectedSymbology = 'Code 128';
  String _selectedPreset = 'Product Label (Standard)';

  @override
  void initState() {
    super.initState();
    _variants = [
      LabelVariantItem(
        name: 'Oxford Linen Shirt',
        variant: 'Black / M',
        sku: 'TS-10492-BLK-M',
        price: '₹2,490',
        qty: 12,
        imageAsset: 'assets/oxford_linen_shirt.jpg',
        isSelected: true,
      ),
      LabelVariantItem(
        name: 'Oxford Linen Shirt',
        variant: 'Navy / L',
        sku: 'TS-10492-SND-L',
        price: '₹2,490',
        qty: 8,
        imageAsset: 'assets/oxford_linen_shirt_blue.jpg',
        isSelected: true,
      ),
      LabelVariantItem(
        name: 'Oxford Linen Shirt',
        variant: 'Sand / M',
        sku: 'TS-10492-SND-M',
        price: '₹2,490',
        qty: 10,
        imageAsset: 'assets/gabardine_trench.jpg',
        isSelected: true,
      ),
      LabelVariantItem(
        name: 'Merino Wool Crewneck',
        variant: 'Navy / L',
        sku: 'MWB-20188-NVY-L',
        price: '₹8,990',
        qty: 0,
        imageAsset: 'assets/merino_wool_blazer.jpg',
        isSelected: false,
      ),
      LabelVariantItem(
        name: 'Merino Wool Crewneck',
        variant: 'Gray / M',
        sku: 'MWB-20188-GRY-M',
        price: '₹8,990',
        qty: 0,
        imageAsset: 'assets/cashmere_sweater.jpg',
        isSelected: false,
      ),
      LabelVariantItem(
        name: 'Silk Evening Dress',
        variant: 'Crimson / S',
        sku: 'TS-SED-CS',
        price: '₹6,500',
        qty: 0,
        imageAsset: 'assets/silk_evening_dress.jpg',
        isSelected: false,
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _selectedCount => _variants.where((v) => v.isSelected).length;

  int get _totalLabelsToPrint => _variants
      .where((v) => v.isSelected)
      .fold(0, (sum, item) => sum + item.qty);

  List<LabelVariantItem> get _filteredVariants {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _variants;
    return _variants.where((v) {
      return v.name.toLowerCase().contains(q) ||
          v.variant.toLowerCase().contains(q) ||
          v.sku.toLowerCase().contains(q);
    }).toList();
  }

  void _showAddVariantsModal() {
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
              child: const Icon(Icons.style_outlined, color: Color(0xFF92400E), size: 20),
            ),
            const SizedBox(width: 12),
            Text('Add Catalog Variants to Label Batch', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search catalog SKU, color, or barcode...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'All available SKUs in Central Store catalog are ready for label generation.',
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Selected variants imported to batch.'),
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
            child: const Text('Add to Batch'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: Barcode & Labels + Subtitle
          _buildHeader(),
          const SizedBox(height: 20),

          // 2. Main 3-Column Layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1120;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: Selected Variants Table (~42%)
                    Expanded(
                      flex: 42,
                      child: _buildSelectedVariantsCard(),
                    ),
                    const SizedBox(width: 18),

                    // Column 2: Label Setup & Live Preview (~33%)
                    Expanded(
                      flex: 33,
                      child: _buildLabelSetupCard(),
                    ),
                    const SizedBox(width: 18),

                    // Column 3: Print Output & Quick Presets (~25%)
                    Expanded(
                      flex: 25,
                      child: Column(
                        children: [
                          _buildPrintOutputCard(),
                          const SizedBox(height: 18),
                          _buildQuickPresetsCard(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Stacked for smaller viewports
              return Column(
                children: [
                  _buildSelectedVariantsCard(),
                  const SizedBox(height: 20),
                  _buildLabelSetupCard(),
                  const SizedBox(height: 20),
                  _buildPrintOutputCard(),
                  const SizedBox(height: 18),
                  _buildQuickPresetsCard(),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // 1. Header
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Barcode & Labels',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose variants and configure label settings for accurate and professional printing.',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  // 2. Column 1: Selected Variants Card
  Widget _buildSelectedVariantsCard() {
    final allSelected = _variants.every((v) => v.isSelected);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Selected Variants',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_selectedCount selected',
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose variants and specify print quantities.',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _showAddVariantsModal,
                  icon: const Icon(Icons.add, size: 15, color: Color(0xFFB45309)),
                  label: const Text('Add Variants'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB45309),
                    side: const BorderSide(color: Color(0xFFFDE68A)),
                    backgroundColor: const Color(0xFFFFFBEB).withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // Search Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, size: 17, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.inter(fontSize: 12.5),
                            decoration: const InputDecoration(
                              hintText: 'Search product, SKU or variant...',
                              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
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
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: const Icon(Icons.tune_rounded, size: 17, color: Color(0xFF4B5563)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Table Header
          Container(
            color: const Color(0xFFF8FAFC),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Checkbox(
                    value: allSelected,
                    activeColor: const Color(0xFFB45309),
                    onChanged: (val) {
                      setState(() {
                        for (final item in _variants) {
                          item.isSelected = val ?? false;
                          if (!item.isSelected) {
                            item.qty = 0;
                          } else if (item.qty == 0) {
                            item.qty = 10;
                          }
                        }
                      });
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(flex: 38, child: Text('Product / Variant', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 24, child: Text('SKU', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 16, child: Text('Price', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
                Expanded(flex: 22, child: Text('Qty to Print', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)))),
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
                  SizedBox(
                    width: 24,
                    child: Checkbox(
                      value: item.isSelected,
                      activeColor: const Color(0xFFB45309),
                      onChanged: (val) {
                        setState(() {
                          item.isSelected = val ?? false;
                          if (item.isSelected && item.qty == 0) {
                            item.qty = 10;
                          } else if (!item.isSelected) {
                            item.qty = 0;
                          }
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Product & Variant
                  Expanded(
                    flex: 38,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            item.imageAsset,
                            width: 38,
                            height: 38,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 38,
                              height: 38,
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.checkroom_rounded, size: 18, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(item.variant, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // SKU
                  Expanded(
                    flex: 24,
                    child: Text(
                      item.sku,
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF4B5563)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Price
                  Expanded(
                    flex: 16,
                    child: Text(
                      item.price,
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                    ),
                  ),

                  // Qty Stepper
                  Expanded(
                    flex: 22,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () {
                            if (item.qty > 0) {
                              setState(() {
                                item.qty--;
                                if (item.qty == 0) item.isSelected = false;
                              });
                            }
                          },
                          child: Container(
                            width: 24,
                            height: 26,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFD1D5DB)),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.remove, size: 13, color: Color(0xFF4B5563)),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 26,
                          decoration: const BoxDecoration(
                            border: Border.symmetric(horizontal: BorderSide(color: Color(0xFFD1D5DB))),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${item.qty}',
                            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              item.qty++;
                              item.isSelected = true;
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 26,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFD1D5DB)),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(Icons.add, size: 13, color: Color(0xFF4B5563)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_selectedCount variants selected',
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
                ),
                Text.rich(
                  TextSpan(
                    text: 'Total labels: ',
                    style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
                    children: [
                      TextSpan(
                        text: '$_totalLabelsToPrint',
                        style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Column 2: Label Setup & Live Preview
  Widget _buildLabelSetupCard() {
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
          // Header
          Text(
            'Label Setup',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
          ),
          const SizedBox(height: 2),
          Text(
            'Configure your label design and content.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),

          // LABEL TEMPLATE
          Text(
            'LABEL TEMPLATE',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF4B5563), letterSpacing: 0.3),
          ),
          const SizedBox(height: 6),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTemplate,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6B7280)),
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF1F2937)),
                items: [
                  '40 × 30 mm (Standard Jewelry/Hangtag)',
                  '50 × 30 mm (Price Label)',
                  '30 × 20 mm (Small Tag)',
                  '70 × 30 mm (Shelf Label)',
                ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTemplate = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ideal for apparel, accessories and general items.',
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 18),

          // INCLUDE CONTENT ON LABEL
          Text(
            'INCLUDE CONTENT ON LABEL',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF4B5563), letterSpacing: 0.3),
          ),
          const SizedBox(height: 8),
          _buildToggleRow('Product Name & Variant', _includeName, (v) => setState(() => _includeName = v)),
          _buildToggleRow('Retail Price (INR)', _includePrice, (v) => setState(() => _includePrice = v)),
          _buildToggleRow('Barcode Image', _includeBarcode, (v) => setState(() => _includeBarcode = v)),
          _buildToggleRow('Brand / Logo', _includeLogo, (v) => setState(() => _includeLogo = v)),
          const SizedBox(height: 16),

          // BARCODE SYMBOLOGY
          Text(
            'BARCODE SYMBOLOGY',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF4B5563), letterSpacing: 0.3),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSymbologyButton('Code 128')),
              const SizedBox(width: 8),
              Expanded(child: _buildSymbologyButton('EAN-13')),
              const SizedBox(width: 8),
              Expanded(child: _buildSymbologyButton('UPC-A')),
            ],
          ),
          const SizedBox(height: 20),

          // LIVE PREVIEW (REAL SIZE)
          Text(
            'LIVE PREVIEW (REAL SIZE)',
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF4B5563), letterSpacing: 0.3),
          ),
          const SizedBox(height: 10),

          // Live Preview Container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBFBFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_includeLogo) ...[
                  Text(
                    'THREADSTOCK',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 6),
                ] else ...[
                  Text(
                    'THREADSTOCK',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B), letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 4),
                ],
                if (_includeName) ...[
                  Text(
                    'Oxford Linen Shirt',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Black / M',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF4B5563)),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_includePrice) ...[
                  Text(
                    '₹2,490',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_includeBarcode) ...[
                  // Realistic barcode bars
                  SizedBox(
                    height: 38,
                    width: 170,
                    child: CustomPaint(
                      painter: _RealisticBarcodePainter(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TS-10492-BLK-M',
                    style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF374151))),
          SizedBox(
            height: 24,
            width: 42,
            child: Switch(
              value: value,
              activeColor: const Color(0xFFB45309),
              activeTrackColor: const Color(0xFFFDE68A),
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE2E8F0),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymbologyButton(String title) {
    final isSelected = _selectedSymbology == title;
    return InkWell(
      onTap: () => setState(() => _selectedSymbology = title),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFBF4EB) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFFD97706) : const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF92400E) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  // 4. Column 3: Print Output Card
  Widget _buildPrintOutputCard() {
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
            children: [
              const Icon(Icons.print_outlined, size: 18, color: Color(0xFF111827)),
              const SizedBox(width: 8),
              Text(
                'Print Output',
                style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Metric rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Variants', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280))),
              Text('$_selectedCount SKUs', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Labels to Print', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280))),
              Text('$_totalLabelsToPrint Labels', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFFD97706))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Est. Paper Sheets (40×30)', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280))),
              Text('2 Sheets (A4)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 20),

          // Print 30 Labels Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onPrint ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sending $_totalLabelsToPrint labels to thermal printer (Central Store)...'),
                        backgroundColor: const Color(0xFF181513),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
              icon: const Icon(Icons.print_rounded, size: 16),
              label: Text('Print $_totalLabelsToPrint Labels'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Download PDF Template
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onDownloadPdf ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Downloading 40x30mm PDF print template...'),
                        backgroundColor: Color(0xFF181513),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
              icon: const Icon(Icons.download_rounded, size: 16),
              label: const Text('Download PDF Template'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Save Configuration
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onSaveConfig ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Label format saved to store defaults.'),
                        backgroundColor: Color(0xFF181513),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
              icon: const Icon(Icons.settings_outlined, size: 16),
              label: const Text('Save Configuration'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB).withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFB45309)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use high quality labels for best scanning results. Ensure printer settings are set to 100% (Actual Size).',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF78350F), height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. Column 3: Quick Presets Card
  Widget _buildQuickPresetsCard() {
    final presets = [
      {'name': 'Product Label (Standard)', 'size': '40 × 30 mm'},
      {'name': 'Price Label', 'size': '50 × 30 mm'},
      {'name': 'Small Tag', 'size': '30 × 20 mm'},
      {'name': 'Shelf Label', 'size': '70 × 30 mm'},
    ];

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
            children: [
              const Icon(Icons.description_outlined, size: 17, color: Color(0xFF111827)),
              const SizedBox(width: 8),
              Text(
                'Quick Presets',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Use commonly used label formats.',
            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 14),

          for (final preset in presets) ...[
            InkWell(
              onTap: () => setState(() => _selectedPreset = preset['name']!),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Icon(
                      _selectedPreset == preset['name'] ? Icons.radio_button_checked : Icons.radio_button_off,
                      size: 16,
                      color: _selectedPreset == preset['name'] ? const Color(0xFFB45309) : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        preset['name']!,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: _selectedPreset == preset['name'] ? FontWeight.w600 : FontWeight.w500,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                    Text(
                      preset['size']!,
                      style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Custom Painter for Realistic Barcode
class _RealisticBarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // A realistic pattern of varying widths
    final barPattern = [
      3, 1, 1, 2, 4, 1, 2, 1, 3, 2, 1, 1, 4, 2, 1, 3, 1, 2, 1, 4,
      1, 2, 3, 1, 2, 1, 1, 4, 2, 1, 3, 1, 1, 2, 4, 1, 2, 1, 3, 2
    ];

    double currentX = 10.0;
    for (int i = 0; i < barPattern.length; i++) {
      final width = barPattern[i].toDouble() * 1.0;
      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(currentX, 0, width, size.height), paint);
      }
      currentX += width + 1.2;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
