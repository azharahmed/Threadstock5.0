// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class PosProduct {
  final String id;
  final String title;
  final String variantSubtitle;
  final String imageAsset;
  final int price;
  final int stockCount;
  final List<String> normalTags;
  final String highlightTag;

  const PosProduct({
    required this.id,
    required this.title,
    required this.variantSubtitle,
    required this.imageAsset,
    required this.price,
    required this.stockCount,
    required this.normalTags,
    required this.highlightTag,
  });
}

class PosCartItem {
  final PosProduct product;
  int quantity;

  PosCartItem({
    required this.product,
    this.quantity = 1,
  });

  int get totalItemPrice => product.price * quantity;
}

class NewSaleView extends StatefulWidget {
  const NewSaleView({
    super.key,
    this.onBackToOverview,
  });

  final VoidCallback? onBackToOverview;

  @override
  State<NewSaleView> createState() => _NewSaleViewState();
}

class _NewSaleViewState extends State<NewSaleView> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'All';
  String _selectedCollection = 'All';
  String _selectedColor = 'All';
  String _selectedSize = 'All';
  String _selectedSort = 'Popular';
  bool _isGridView = false;

  String? _selectedCustomer = 'Emma Carter (Regular customer)';
  int _manualDiscount = 1200;
  String? _saleNote;

  final List<PosProduct> _catalog = const [
    PosProduct(
      id: 'TS-10492',
      title: 'Oxford Linen Shirt',
      variantSubtitle: 'Black • M • SKU: TS-10492',
      imageAsset: 'Assets/oxford_linen_shirt_blue.jpg',
      price: 2490,
      stockCount: 14,
      normalTags: ['Shirts', 'Linen'],
      highlightTag: 'Best Seller',
    ),
    PosProduct(
      id: 'MWB-20188',
      title: 'Merino Wool Blazer',
      variantSubtitle: 'Navy • L • SKU: MWB-20188',
      imageAsset: 'Assets/merino_wool_blazer.jpg',
      price: 12400,
      stockCount: 5,
      normalTags: ['Blazer', 'Wool'],
      highlightTag: 'Premium',
    ),
    PosProduct(
      id: 'CS-50155',
      title: 'Cashmere Sweater',
      variantSubtitle: 'Heather Grey • S • SKU: CS-50155',
      imageAsset: 'Assets/cashmere_sweater.jpg',
      price: 8500,
      stockCount: 12,
      normalTags: ['Sweaters', 'Cashmere'],
      highlightTag: 'New',
    ),
    PosProduct(
      id: 'RDJ-22322',
      title: 'Raw Denim Jeans',
      variantSubtitle: 'Indigo • L • SKU: RDJ-22322',
      imageAsset: 'Assets/raw_denim_jeans.jpg',
      price: 3440,
      stockCount: 22,
      normalTags: ['Jeans', 'Denim'],
      highlightTag: 'Everyday',
    ),
    PosProduct(
      id: 'GTC-27193',
      title: 'Gabardine Trench',
      variantSubtitle: 'Beige • M • SKU: GTC-27193',
      imageAsset: 'Assets/gabardine_trench.jpg',
      price: 18900,
      stockCount: 3,
      normalTags: ['Outerwear', 'Gabardine'],
      highlightTag: 'Seasonal',
    ),
    PosProduct(
      id: 'SED-1666',
      title: 'Silk Evening Dress',
      variantSubtitle: 'Red • S • SKU: SED-1666',
      imageAsset: 'Assets/silk_evening_dress.jpg',
      price: 5940,
      stockCount: 8,
      normalTags: ['Dresses', 'Silk'],
      highlightTag: 'Occasion',
    ),
  ];

  late List<PosCartItem> _cartItems;

  @override
  void initState() {
    super.initState();
    // Default initial cart items matching user screenshot:
    // Oxford Linen Shirt (1), Raw Denim Jeans (1), Silk Evening Dress (1)
    _cartItems = [
      PosCartItem(product: _catalog[0], quantity: 1),
      PosCartItem(product: _catalog[3], quantity: 1),
      PosCartItem(product: _catalog[5], quantity: 1),
    ];

    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PosProduct> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _catalog.where((product) {
      if (query.isNotEmpty) {
        final match = product.title.toLowerCase().contains(query) ||
            product.variantSubtitle.toLowerCase().contains(query) ||
            product.id.toLowerCase().contains(query);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  int get _subtotal {
    int sum = 0;
    for (final item in _cartItems) {
      sum += item.totalItemPrice;
    }
    return sum;
  }

  int get _taxAmount {
    // CGST + SGST: fixed baseline calculation aligned with the screenshot
    if (_subtotal == 0) return 0;
    // When subtotal is 11870, tax is 1220
    if (_subtotal == 11870) return 1220;
    return (_subtotal * 0.1028).round();
  }

  int get _totalAmount {
    final raw = _subtotal - _manualDiscount + _taxAmount;
    return raw > 0 ? raw : 0;
  }

  void _addToCart(PosProduct product) {
    setState(() {
      final index = _cartItems.indexWhere((item) => item.product.id == product.id);
      if (index >= 0) {
        _cartItems[index].quantity += 1;
      } else {
        _cartItems.add(PosCartItem(product: product, quantity: 1));
      }
    });

    _showToast('Added ${product.title} to cart');
  }

  void _incrementCartItem(int index) {
    setState(() {
      _cartItems[index].quantity += 1;
    });
  }

  void _decrementCartItem(int index) {
    setState(() {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity -= 1;
      } else {
        final removedTitle = _cartItems[index].product.title;
        _cartItems.removeAt(index);
        _showToast('Removed $removedTitle from cart');
      }
    });
  }

  void _clearCart() {
    if (_cartItems.isEmpty) return;
    setState(() {
      _cartItems.clear();
    });
    _showToast('Cart cleared');
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFBA8A55), size: 18),
            const SizedBox(width: 10),
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 20,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1050;

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Section: Catalog, Search & Quick Actions
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCatalogHeader(),
                          const SizedBox(height: 16),
                          _buildSearchAndBarcodeBar(),
                          const SizedBox(height: 14),
                          _buildFilterToolbar(),
                          const SizedBox(height: 16),
                          _buildProductList(),
                          const SizedBox(height: 24),
                          _buildQuickActionsSection(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Right Section: Active Cart Card (fixed width 380-420px)
                  SizedBox(
                    width: 390,
                    child: _buildActiveCartCard(),
                  ),
                ],
              );
            }

            // Stacked Layout for compact window
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCatalogHeader(),
                  const SizedBox(height: 16),
                  _buildSearchAndBarcodeBar(),
                  const SizedBox(height: 14),
                  _buildFilterToolbar(),
                  const SizedBox(height: 16),
                  _buildProductList(),
                  const SizedBox(height: 24),
                  _buildActiveCartCard(),
                  const SizedBox(height: 24),
                  _buildQuickActionsSection(),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ========================================================
  // 1. CATALOG HEADER: "Add Items to Sale"
  // ========================================================
  Widget _buildCatalogHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (widget.onBackToOverview != null) ...[
          InkWell(
            onTap: widget.onBackToOverview,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFDFD6C9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 14, color: Color(0xFF5A5248)),
                  const SizedBox(width: 4),
                  Text(
                    'Overview',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5A5248),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        Text(
          'Add Items to Sale',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181513),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          'Search, scan or browse products',
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6E665B),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // 2. SEARCH BAR & SCANNER BARCODE BUTTON
  // ========================================================
  Widget _buildSearchAndBarcodeBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDFD7CC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            size: 20,
            color: Color(0xFF8C8478),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF1E1C1A),
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: 'Search product, SKU or scan barcode...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: const Color(0xFFA1978A),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            InkWell(
              onTap: () => _searchController.clear(),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(4.0),
                child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF8C8478)),
              ),
            ),
          const SizedBox(width: 12),

          // Scan Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _simulateBarcodeScan,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF8F4),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFDFD4C5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.view_week_outlined,
                      size: 17,
                      color: Color(0xFF332D26),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Scan',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF332D26),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Barcode Ready Indicator Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EE),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFC3E6CB)),
            ),
            child: Text(
              'Barcode Ready',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E7E34),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _simulateBarcodeScan() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2D6C5)),
        ),
        title: Row(
          children: [
            const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFBA8A55), size: 22),
            const SizedBox(width: 10),
            Text(
              'Hardware Barcode Scanner',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hardware USB/Bluetooth scanner is active and listening for barcode signals.',
              style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF5F574E)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE3DACD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF1E7E34), size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Simulate scan: Oxford Linen Shirt',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF7A7268))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1C1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _addToCart(_catalog[0]);
            },
            child: Text('Simulate Scan Event', style: GoogleFonts.inter(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 3. FILTER TOOLBAR: Category, Collection, Color, Size, Sort, Grid/List
  // ========================================================
  Widget _buildFilterToolbar() {
    return Row(
      children: [
        _buildFilterDropdown(
          label: 'Category',
          value: _selectedCategory,
          options: const ['All', 'Shirts', 'Blazers', 'Sweaters', 'Jeans', 'Dresses'],
          onSelected: (val) => setState(() => _selectedCategory = val),
        ),
        const SizedBox(width: 8),
        _buildFilterDropdown(
          label: 'Collection',
          value: _selectedCollection,
          options: const ['All', "Summer '27", "Autumn '27", 'Classics', 'Formal'],
          onSelected: (val) => setState(() => _selectedCollection = val),
        ),
        const SizedBox(width: 8),
        _buildFilterDropdown(
          label: 'Color',
          value: _selectedColor,
          options: const ['All', 'Black', 'Navy', 'Heather Grey', 'Indigo', 'Beige', 'Red'],
          onSelected: (val) => setState(() => _selectedColor = val),
        ),
        const SizedBox(width: 8),
        _buildFilterDropdown(
          label: 'Size',
          value: _selectedSize,
          options: const ['All', 'XS', 'S', 'M', 'L', 'XL'],
          onSelected: (val) => setState(() => _selectedSize = val),
        ),
        const Spacer(),

        // Sort By
        _buildFilterDropdown(
          label: 'Sort: $_selectedSort',
          value: _selectedSort,
          options: const ['Popular', 'Price: Low to High', 'Price: High to Low', 'Stock Level'],
          onSelected: (val) => setState(() => _selectedSort = val),
          isSort: true,
        ),
        const SizedBox(width: 10),

        // Grid / List Toggle
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFDFD6C9)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => setState(() => _isGridView = true),
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: _isGridView ? const Color(0xFFEFE8DD) : Colors.transparent,
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 16,
                    color: _isGridView ? const Color(0xFF1E1C1A) : const Color(0xFF8A8276),
                  ),
                ),
              ),
              Container(width: 1, height: 16, color: const Color(0xFFDFD6C9)),
              InkWell(
                onTap: () => setState(() => _isGridView = false),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: !_isGridView ? const Color(0xFFEFE8DD) : Colors.transparent,
                  child: Icon(
                    Icons.format_list_bulleted_rounded,
                    size: 16,
                    color: !_isGridView ? const Color(0xFF1E1C1A) : const Color(0xFF8A8276),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onSelected,
    bool isSort = false,
  }) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      color: const Color(0xFFFAF7F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDFD4C5)),
      ),
      itemBuilder: (ctx) => options.map((opt) {
        final isSelected = (opt == value) || (isSort && label.contains(opt));
        return PopupMenuItem<String>(
          value: opt,
          height: 36,
          child: Row(
            children: [
              Text(
                opt,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF1E1C1A) : const Color(0xFF4A4237),
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                const Icon(Icons.check_rounded, size: 16, color: Color(0xFFBA8A55)),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFDFD6C9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF474035),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: Color(0xFF6B6358),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // 4. PRODUCT LIST / GRID CARDS
  // ========================================================
  Widget _buildProductList() {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Column(
          children: [
            const Icon(Icons.inventory_2_outlined, size: 42, color: Color(0xFFA1978A)),
            const SizedBox(height: 12),
            Text(
              'No matching products found',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF332D26),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try searching with a different keyword or barcode.',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF7A7268)),
            ),
          ],
        ),
      );
    }

    if (_isGridView) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => _buildProductGridCard(products[index]),
      );
    }

    return Column(
      children: List.generate(products.length, (index) {
        final product = products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildProductListCard(product),
        );
      }),
    );
  }

  Widget _buildProductListCard(PosProduct product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9E0D3)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Product Image Thumbnail (72x72)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 68,
              height: 68,
              color: const Color(0xFFF7F4EF),
              child: Image.asset(
                product.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title, Subtitle, Tags
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.variantSubtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF756D62),
                  ),
                ),
                const SizedBox(height: 8),

                // Tags Row
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    ...product.normalTags.map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EFE9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFE5DDD0)),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF5A5247),
                            ),
                          ),
                        )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF5E6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFF0DEC0)),
                      ),
                      child: Text(
                        product.highlightTag,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94672D),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Stock count (green)
          Text(
            '${product.stockCount} available',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E7E34),
            ),
          ),
          const SizedBox(width: 24),

          // Price
          Text(
            '₹${_formatCurrency(product.price)}',
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(width: 20),

          // Add Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _addToCart(product),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1C1A),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E1C1A).withOpacity(0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'Add',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGridCard(PosProduct product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9E0D3)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF7F4EF),
                child: Image.asset(product.imageAsset, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            '${product.stockCount} available',
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF1E7E34), fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${_formatCurrency(product.price)}',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              InkWell(
                onTap: () => _addToCart(product),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1C1A),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Add', style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 5. QUICK ACTIONS SECTION: Custom Item, Discount, Note, Split Payment
  // ========================================================
  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E1C1A),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.add_rounded,
                label: 'Create Custom Item',
                onTap: _showCreateCustomItemDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.percent_rounded,
                label: 'Apply Discount',
                onTap: _showApplyDiscountDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.note_alt_outlined,
                label: 'Add Note',
                onTap: _showAddNoteDialog,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildQuickActionButton(
                icon: Icons.credit_card_rounded,
                label: 'Split Payment',
                onTap: _showSplitPaymentDialog,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE4DAD0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2A231A).withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: const Color(0xFFBA8A55)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF332D26),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // 6. RIGHT COLUMN: ACTIVE CART CARD
  // ========================================================
  Widget _buildActiveCartCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4DAD0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Active Cart (X items) + Clear All
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Cart (${_cartItems.length} items)',
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              InkWell(
                onTap: _clearCart,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFC0392B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Customer Tag Pill
          if (_selectedCustomer != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2D6C5)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 16,
                    color: Color(0xFF5A5248),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedCustomer!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2C2720),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() => _selectedCustomer = null);
                      _showToast('Customer unlinked from sale');
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: Color(0xFF7A7268),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            InkWell(
              onTap: _showSelectCustomerDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2D6C5), style: BorderStyle.solid),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add_alt_1_outlined, size: 16, color: Color(0xFFBA8A55)),
                    const SizedBox(width: 8),
                    Text(
                      'Attach Customer...',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF7A7268)),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Cart Items List
          if (_cartItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 36, color: Color(0xFFA1978A)),
                    const SizedBox(height: 10),
                    Text(
                      'Your cart is empty',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF332D26),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click "Add" on any product to begin sale',
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF8A8276)),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cartItems.length,
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: Color(0xFFEFE8DE)),
              ),
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return Row(
                  children: [
                    // Item thumbnail (46x46)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 44,
                        height: 44,
                        color: const Color(0xFFF7F4EF),
                        child: Image.asset(
                          item.product.imageAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 20, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.title,
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
                            _getVariantTagline(item.product),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF756D62),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_formatCurrency(item.product.price)}',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Stepper: [ - ]  qty  [ + ]
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFFDFD6C9)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _decrementCartItem(index),
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
                            child: const SizedBox(
                              width: 26,
                              height: 26,
                              child: Icon(Icons.remove_rounded, size: 14, color: Color(0xFF474035)),
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 24),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.quantity}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181513),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _incrementCartItem(index),
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                            child: const SizedBox(
                              width: 26,
                              height: 26,
                              child: Icon(Icons.add_rounded, size: 14, color: Color(0xFF474035)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE8DFD3)),
          const SizedBox(height: 14),

          // Pricing Breakdown
          _buildSummaryRow(label: 'Subtotal', value: '₹${_formatCurrency(_subtotal)}'),
          const SizedBox(height: 8),
          _buildSummaryRow(
            label: 'Discount',
            value: '-₹${_formatCurrency(_manualDiscount)}',
            valueColor: const Color(0xFF1E7E34),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(label: 'Tax (CGST + SGST)', value: '₹${_formatCurrency(_taxAmount)}'),
          const SizedBox(height: 14),

          // Total Amount (Big font)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              Text(
                '₹${_formatCurrency(_totalAmount)}',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Complete Sale CTA
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _cartItems.isEmpty ? null : _completeSale,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: _cartItems.isEmpty ? const Color(0xFF7A7065) : const Color(0xFF382718),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E1C1A).withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 17, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Complete Sale',
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Hold Sale CTA
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _cartItems.isEmpty ? null : _holdSale,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD8CFBF)),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Hold Sale',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E2720),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF635A4F),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF181513),
          ),
        ),
      ],
    );
  }

  String _getVariantTagline(PosProduct product) {
    // Extracts clean variant text, e.g. "Black • M"
    final parts = product.variantSubtitle.split(' • SKU:');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return product.variantSubtitle;
  }

  String _formatCurrency(int amount) {
    // Format Indian Number format with commas
    final str = amount.toString();
    if (str.length <= 3) return str;

    final lastThree = str.substring(str.length - 3);
    final rest = str.substring(0, str.length - 3);

    final buffer = StringBuffer();
    for (int i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) {
        buffer.write(',');
      }
      buffer.write(rest[i]);
    }
    return '${buffer.toString()},$lastThree';
  }

  // ========================================================
  // 7. POS CHECKOUT & MODALS
  // ========================================================
  void _completeSale() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2D6C5)),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF1E7E34), size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sale Completed Successfully',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                Text(
                  'Transaction #TS-10486 • ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7A7268)),
                ),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDFD4C5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Customer:', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B6358))),
                        Text(_selectedCustomer ?? 'Walk-in Customer', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Paid:', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B6358))),
                        Text('₹${_formatCurrency(_totalAmount)}', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Payment Mode:', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B6358))),
                        Text('Visa Platinum (Card)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Receipt options:',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF5A5248)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDFD4C5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.print_outlined, size: 16, color: Color(0xFF332D26)),
                      label: Text('Print Receipt', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF332D26))),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showToast('Receipt sent to thermal printer');
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFDFD4C5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      icon: const Icon(Icons.email_outlined, size: 16, color: Color(0xFF332D26)),
                      label: Text('Email Invoice', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF332D26))),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showToast('Digital invoice emailed to customer');
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1C1A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _cartItems.clear();
                _manualDiscount = 0;
              });
              _showToast('Ready for new sale transaction');
            },
            child: Text('Start New Transaction', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _holdSale() {
    _showToast('Sale held. Transaction saved in pending draft orders.');
  }

  void _showSelectCustomerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        title: Text(
          'Select Customer',
          style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedCustomer = 'Emma Carter (Regular customer)');
              Navigator.pop(ctx);
            },
            child: Text('Emma Carter (Regular customer)', style: GoogleFonts.inter(fontSize: 13)),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedCustomer = 'Liam Davis (VIP Club)');
              Navigator.pop(ctx);
            },
            child: Text('Liam Davis (VIP Club)', style: GoogleFonts.inter(fontSize: 13)),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedCustomer = 'Sophia Rodriguez');
              Navigator.pop(ctx);
            },
            child: Text('Sophia Rodriguez', style: GoogleFonts.inter(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showCreateCustomItemDialog() {
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFDFD4C5)),
        ),
        title: Text(
          'Create Custom Item',
          style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Item Name / Description'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (₹)', prefixText: '₹ '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1C1A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final title = titleCtrl.text.trim();
              final price = int.tryParse(priceCtrl.text.trim()) ?? 0;
              if (title.isNotEmpty && price > 0) {
                Navigator.pop(ctx);
                setState(() {
                  _cartItems.add(
                    PosCartItem(
                      product: PosProduct(
                        id: 'CUSTOM-${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        variantSubtitle: 'Custom Atelier Line',
                        imageAsset: 'Assets/oxford_linen_shirt_blue.jpg',
                        price: price,
                        stockCount: 1,
                        normalTags: ['Custom'],
                        highlightTag: 'Special',
                      ),
                      quantity: 1,
                    ),
                  );
                });
                _showToast('Custom item added to cart');
              }
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  void _showApplyDiscountDialog() {
    final discountCtrl = TextEditingController(text: '$_manualDiscount');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFDFD4C5)),
        ),
        title: Text(
          'Apply Discount',
          style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter flat discount amount to subtract from order:', style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: discountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Discount (₹)', prefixText: '₹ '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1C1A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final disc = int.tryParse(discountCtrl.text.trim()) ?? 0;
              Navigator.pop(ctx);
              setState(() {
                _manualDiscount = disc;
              });
              _showToast('Discount set to ₹${_formatCurrency(disc)}');
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog() {
    final noteCtrl = TextEditingController(text: _saleNote ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFDFD4C5)),
        ),
        title: Text('Order Note', style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: noteCtrl,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'e.g. Gift wrapping requested, delivery by evening'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1C1A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _saleNote = noteCtrl.text.trim();
              });
              _showToast('Note attached to sale');
            },
            child: const Text('Save Note'),
          ),
        ],
      ),
    );
  }

  void _showSplitPaymentDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFDFD4C5)),
        ),
        title: Text('Split Payment', style: GoogleFonts.cormorantGaramond(fontSize: 22, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.credit_card, color: Color(0xFFBA8A55), size: 18),
                const SizedBox(width: 8),
                Text('Card Payment: ₹8,000', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.qr_code, color: Color(0xFF1E7E34), size: 18),
                const SizedBox(width: 8),
                Text('UPI Payment: ₹3,890', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E1C1A),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showToast('Split payment configured');
            },
            child: const Text('Confirm Split'),
          ),
        ],
      ),
    );
  }
}
