// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateNewProductView extends StatefulWidget {
  const CreateNewProductView({
    super.key,
    this.onSaveDraft,
    this.onPublishProduct,
  });

  final VoidCallback? onSaveDraft;
  final VoidCallback? onPublishProduct;

  @override
  State<CreateNewProductView> createState() => _CreateNewProductViewState();
}

class _CreateNewProductViewState extends State<CreateNewProductView> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Merino Wool Crewneck');
  final TextEditingController _descriptionController = TextEditingController(
    text:
        'Premium grade merino wool sweater designed for transitional tailoring. Ethically sourced fine fibers with dynamic thermoregulation capabilities.',
  );
  final TextEditingController _costPriceController =
      TextEditingController(text: '1,450');
  final TextEditingController _retailPriceController =
      TextEditingController(text: '3,999');
  final TextEditingController _skuController =
      TextEditingController(text: 'MWC-2027-NEW (Auto-generated)');
  final TextEditingController _barcodeController =
      TextEditingController(text: '883920194821');

  String _selectedBrand = 'ThreadStock Atelier';
  String _selectedCategory = 'Knitwear';
  String _selectedSupplier = 'Milano Tessuti';
  String _selectedTaxCategory = 'Apparel Standard (12% GST)';

  final List<String> _tags = [
    'Autumn 2027',
    'Woolens',
    'Premium Network',
  ];

  int _selectedImageIndex = 0;
  final List<String> _productImages = [
    'assets/navy_merino_crewneck.jpg',
    'assets/navy_merino_folded.jpg',
    'assets/navy_merino_fabric.jpg',
  ];

  bool _trackStockLevels = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _retailPriceController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  double get _calculatedMargin {
    final costStr = _costPriceController.text.replaceAll(',', '').trim();
    final retailStr = _retailPriceController.text.replaceAll(',', '').trim();
    final cost = double.tryParse(costStr) ?? 1450.0;
    final retail = double.tryParse(retailStr) ?? 3999.0;
    if (retail <= 0) return 0.0;
    return ((retail - cost) / retail) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row
          _buildHeader(),
          const SizedBox(height: 20),

          // 2. Main Two-Column Layout (Left ~60%, Right ~40%)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      flex: 58,
                      child: Column(
                        children: [
                          _buildProductInfoCard(),
                          const SizedBox(height: 20),
                          _buildSupplierTaxCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right Column
                    Expanded(
                      flex: 42,
                      child: Column(
                        children: [
                          _buildProductImageryCard(),
                          const SizedBox(height: 20),
                          _buildPricingCard(),
                          const SizedBox(height: 20),
                          _buildInventorySettingsCard(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Stacked on smaller screens
              return Column(
                children: [
                  _buildProductInfoCard(),
                  const SizedBox(height: 20),
                  _buildSupplierTaxCard(),
                  const SizedBox(height: 20),
                  _buildProductImageryCard(),
                  const SizedBox(height: 20),
                  _buildPricingCard(),
                  const SizedBox(height: 20),
                  _buildInventorySettingsCard(),
                ],
              );
            },
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // 1. Header Row
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Product',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add product details, pricing, and inventory settings to your catalog.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: widget.onSaveDraft ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product draft saved successfully.'),
                        backgroundColor: Color(0xFF181513),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1F2937),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              child: const Text('Save Draft'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: widget.onPublishProduct ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product published and added to active catalog!'),
                        backgroundColor: Color(0xFF181513),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              child: const Text('Publish Product'),
            ),
          ],
        ),
      ],
    );
  }

  // Card 1: Product Information
  Widget _buildProductInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          _buildCardHeader(
            icon: Icons.inventory_2_outlined,
            title: 'Product Information',
            subtitle: 'Basic details about your product.',
          ),
          const SizedBox(height: 20),

          // Product Name
          _buildFieldLabel('Product Name', isRequired: true),
          const SizedBox(height: 6),
          _buildTextInput(
            controller: _nameController,
            hint: 'Enter product title',
          ),
          const SizedBox(height: 16),

          // Brand and Category
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Brand', isRequired: true),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: _selectedBrand,
                      items: const [
                        'ThreadStock Atelier',
                        'ThreadStock Essentials',
                        'Tessuti Sartoriale',
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBrand = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Category', isRequired: true),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: _selectedCategory,
                      items: const [
                        'Knitwear',
                        'Shirts',
                        'Outerwear',
                        'Denim',
                        'Dresses',
                        'Accessories',
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          _buildFieldLabel('Description'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD1D5DB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: 500,
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1F2937), height: 1.4),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 8),
                  child: Text(
                    '${_descriptionController.text.length}/500',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Workspace Tags
          _buildFieldLabel('Workspace Tags'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in _tags)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(tag, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151), fontWeight: FontWeight.w500)),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => setState(() => _tags.remove(tag)),
                        child: const Icon(Icons.close_rounded, size: 13, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
              InkWell(
                onTap: _showAddTagDialog,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFD97706),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 14, color: Color(0xFFB45309)),
                      const SizedBox(width: 4),
                      Text(
                        'Add Tag',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFB45309), fontWeight: FontWeight.w600),
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

  // Card 2: Supplier & Tax Compliance
  Widget _buildSupplierTaxCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.local_shipping_outlined,
            title: 'Supplier & Tax Compliance',
            subtitle: 'Link supplier and tax details for seamless purchasing and reporting.',
          ),
          const SizedBox(height: 20),

          // Supplier & Tax Category
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Primary Supplier', isRequired: true),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: _selectedSupplier,
                      items: const [
                        'Milano Tessuti',
                        'Como Silk Mills',
                        'Veneto Leathers',
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSupplier = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Tax Category', isRequired: true),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: _selectedTaxCategory,
                      items: const [
                        'Apparel Standard (12% GST)',
                        'Luxury Apparel (18% GST)',
                        'Export Zero-Rated (0% GST)',
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTaxCategory = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Compliance Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 22, color: Color(0xFF16A34A)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supplier Compliance Verified',
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Milano Tessuti is GST registered and active.',
                        style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Verified',
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 3: Product Imagery
  Widget _buildProductImageryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.photo_library_outlined,
            title: 'Product Imagery',
            subtitle: 'Add high-quality images to showcase your product.',
          ),
          const SizedBox(height: 18),

          // Image Gallery & Thumbnails Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Image Box
              Expanded(
                child: Container(
                  height: 230,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            _productImages[_selectedImageIndex],
                            fit: BoxFit.contain,
                            height: 220,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.checkroom_rounded,
                              size: 48,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Primary',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Thumbnail Strip (Vertical)
              Column(
                children: [
                  for (int i = 0; i < _productImages.length; i++) ...[
                    InkWell(
                      onTap: () => setState(() => _selectedImageIndex = i),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _selectedImageIndex == i
                                ? const Color(0xFFD97706)
                                : const Color(0xFFE5E7EB),
                            width: _selectedImageIndex == i ? 2 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: Image.asset(
                            _productImages[i],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.image_outlined,
                              size: 18,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  // Add image placeholder
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                    ),
                    child: const Icon(Icons.add_rounded, size: 20, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Replace Image Button & Specs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.file_upload_outlined, size: 15),
                label: const Text('Replace Image'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                'PNG, JPG up to 10MB  •  800 × 1000 recommended',
                style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 4: Cost & Selling Pricing
  Widget _buildPricingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.sell_outlined,
            title: 'Cost & Selling Pricing',
            subtitle: 'Set your cost and retail pricing.',
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Cost Price (INR)', isRequired: true),
                    const SizedBox(height: 6),
                    _buildTextInput(
                      controller: _costPriceController,
                      prefixText: '₹ ',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Retail Price (INR)', isRequired: true),
                    const SizedBox(height: 6),
                    _buildTextInput(
                      controller: _retailPriceController,
                      prefixText: '₹ ',
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Calculated Gross Margin Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.bar_chart_rounded, size: 20, color: Color(0xFF15803D)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calculated Gross Margin',
                        style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                      ),
                      Text(
                        '(Retail – Cost) / Retail × 100',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_calculatedMargin.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 5: Inventory Settings
  Widget _buildInventorySettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            icon: Icons.settings_outlined,
            title: 'Inventory Settings',
            subtitle: 'Configure SKU, barcode and stock tracking.',
          ),
          const SizedBox(height: 18),

          _buildFieldLabel('System SKU Identifier'),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Text(
              _skuController.text,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(height: 16),

          _buildFieldLabel('Barcode (UPC/EAN)'),
          const SizedBox(height: 6),
          _buildTextInput(
            controller: _barcodeController,
            hint: 'Scan or type barcode',
          ),
          const SizedBox(height: 18),

          // Track Stock Levels Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track Stock Levels',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Enable real-time inventory decrementing',
                    style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
              Switch(
                value: _trackStockLevels,
                onChanged: (val) => setState(() => _trackStockLevels = val),
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFFB45309),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: const Color(0xFFD1D5DB),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Common UI Helpers
  Widget _buildCardHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFBF4EB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: const Color(0xFFB45309)),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return RichText(
      text: TextSpan(
        text: label,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
            ),
        ],
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    String? hint,
    String? prefixText,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF111827), fontWeight: FontWeight.w500),
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixText: prefixText,
          prefixStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280), fontWeight: FontWeight.w500),
          hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF6B7280)),
          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1F2937), fontWeight: FontWeight.w500),
          items: items.map((it) {
            return DropdownMenuItem<String>(
              value: it,
              child: Text(it),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showAddTagDialog() {
    final tagCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add Workspace Tag', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: tagCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Summer Capsule',
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
              final newTag = tagCtrl.text.trim();
              if (newTag.isNotEmpty && !_tags.contains(newTag)) {
                setState(() => _tags.add(newTag));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF181513)),
            child: const Text('Add Tag'),
          ),
        ],
      ),
    );
  }
}
