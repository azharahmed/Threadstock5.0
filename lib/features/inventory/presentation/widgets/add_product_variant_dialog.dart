// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/location_repository.dart';
import '../../data/product_repository.dart';
import '../../domain/models/stock_location.dart';

class AddProductVariantDialog extends StatefulWidget {
  final String productId;
  final String productName;
  final String? businessId;
  final int defaultCostPriceCents;
  final int defaultRetailPriceCents;
  final ProductRepository? productRepository;
  final LocationRepository? locationRepository;
  final VoidCallback? onVariantCreated;

  const AddProductVariantDialog({
    super.key,
    required this.productId,
    required this.productName,
    this.businessId,
    this.defaultCostPriceCents = 0,
    this.defaultRetailPriceCents = 0,
    this.productRepository,
    this.locationRepository,
    this.onVariantCreated,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String productId,
    required String productName,
    String? businessId,
    int defaultCostPriceCents = 0,
    int defaultRetailPriceCents = 0,
    ProductRepository? productRepository,
    LocationRepository? locationRepository,
    VoidCallback? onVariantCreated,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddProductVariantDialog(
        productId: productId,
        productName: productName,
        businessId: businessId,
        defaultCostPriceCents: defaultCostPriceCents,
        defaultRetailPriceCents: defaultRetailPriceCents,
        productRepository: productRepository,
        locationRepository: locationRepository,
        onVariantCreated: onVariantCreated,
      ),
    );
  }

  @override
  State<AddProductVariantDialog> createState() => _AddProductVariantDialogState();
}

class _AddProductVariantDialogState extends State<AddProductVariantDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _skuController;
  late final TextEditingController _barcodeController;
  late final TextEditingController _colorController;
  late final TextEditingController _sizeController;
  late final TextEditingController _materialController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _retailPriceController;
  late final TextEditingController _openingStockController;

  String _status = 'active';
  String? _selectedLocationId;
  List<StockLocation> _locations = [];
  bool _isLoadingLocations = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _skuController = TextEditingController();
    _barcodeController = TextEditingController();
    _colorController = TextEditingController();
    _sizeController = TextEditingController();
    _materialController = TextEditingController();
    _costPriceController = TextEditingController(
      text: widget.defaultCostPriceCents > 0
          ? (widget.defaultCostPriceCents / 100).toStringAsFixed(2)
          : '',
    );
    _retailPriceController = TextEditingController(
      text: widget.defaultRetailPriceCents > 0
          ? (widget.defaultRetailPriceCents / 100).toStringAsFixed(2)
          : '',
    );
    _openingStockController = TextEditingController(text: '0');

    _generateInitialSku();
    _loadLocations();
  }

  @override
  void dispose() {
    _skuController.dispose();
    _barcodeController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _materialController.dispose();
    _costPriceController.dispose();
    _retailPriceController.dispose();
    _openingStockController.dispose();
    super.dispose();
  }

  void _generateInitialSku() {
    final words = widget.productName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    String prefix = 'PRD';
    if (words.length >= 2) {
      prefix = '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words.first.length >= 3) {
      prefix = words.first.substring(0, 3).toUpperCase();
    }
    final code = (DateTime.now().millisecondsSinceEpoch % 100000)
        .toString()
        .padLeft(5, '0');
    _skuController.text = 'TS-$prefix-$code';
  }

  void _autoGenerateSku() {
    final words = widget.productName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    String prefix = 'PRD';
    if (words.length >= 2) {
      prefix = '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else if (words.isNotEmpty && words.first.length >= 3) {
      prefix = words.first.substring(0, 3).toUpperCase();
    }
    final colorVal = _colorController.text.trim();
    final sizeVal = _sizeController.text.trim();
    final colorSegment = colorVal.isNotEmpty
        ? '-${colorVal.length >= 3 ? colorVal.substring(0, 3).toUpperCase() : colorVal.toUpperCase()}'
        : '';
    final sizeSegment = sizeVal.isNotEmpty ? '-${sizeVal.toUpperCase()}' : '';
    final code = (DateTime.now().millisecondsSinceEpoch % 100000)
        .toString()
        .padLeft(5, '0');
    setState(() {
      _skuController.text = 'TS-$prefix$colorSegment$sizeSegment-$code';
      _errorMessage = null;
    });
  }

  Future<void> _loadLocations() async {
    try {
      final repo = widget.locationRepository ?? LocationRepository();
      final locs = await repo.getLocations(businessId: widget.businessId);
      if (mounted) {
        setState(() {
          _locations = locs;
          if (locs.isNotEmpty) {
            _selectedLocationId = locs.first.id;
          }
          _isLoadingLocations = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  Future<void> _submitVariant() async {
    if (_isSaving) return;
    setState(() => _errorMessage = null);

    final sku = _skuController.text.trim();
    if (sku.isEmpty) {
      setState(() => _errorMessage = 'Enter a valid System SKU.');
      return;
    }

    final costText = _costPriceController.text.replaceAll(',', '').trim();
    final retailText = _retailPriceController.text.replaceAll(',', '').trim();
    final costNum = double.tryParse(costText) ?? 0.0;
    final retailNum = double.tryParse(retailText) ?? 0.0;

    if (costNum < 0) {
      setState(() => _errorMessage = 'Unit cost cannot be negative.');
      return;
    }
    if (retailNum < 0) {
      setState(() => _errorMessage = 'Selling price cannot be negative.');
      return;
    }

    final costCents = (costNum * 100).round();
    final retailCents = (retailNum * 100).round();

    final stockText = _openingStockController.text.trim();
    final initialStock = int.tryParse(stockText) ?? 0;
    if (initialStock < 0) {
      setState(() => _errorMessage = 'Initial stock quantity cannot be negative.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = widget.productRepository ?? ProductRepository();

      await repo.createVariant(
        productId: widget.productId,
        businessId: widget.businessId,
        sku: sku,
        barcode: _barcodeController.text.trim().isEmpty
            ? null
            : _barcodeController.text.trim(),
        color: _colorController.text.trim().isEmpty
            ? null
            : _colorController.text.trim(),
        size: _sizeController.text.trim().isEmpty
            ? null
            : _sizeController.text.trim(),
        material: _materialController.text.trim().isEmpty
            ? null
            : _materialController.text.trim(),
        costPriceCents: costCents,
        retailPriceCents: retailCents,
        status: _status,
        locationId: _selectedLocationId,
        initialStock: initialStock,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: Color(0xFFD5A46C),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Variant "$sku" created successfully.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E1B18),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            duration: const Duration(milliseconds: 2500),
          ),
        );
        Navigator.of(context).pop(true);
        widget.onVariantCreated?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Error: '), '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEADBCA)),
                      ),
                      child: const Icon(
                        Icons.style_outlined,
                        size: 20,
                        color: Color(0xFFB45309),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Product Variant',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'For ${widget.productName}',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: const Color(0xFF6B7280),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: const Color(0xFF94A3B8),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),

              // Scrollable Form
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 16,
                                color: Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: const Color(0xFFB91C1C),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // SKU row
                      Text(
                        'System SKU *',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _skuController,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF111827),
                              ),
                              decoration: _inputDecoration(hint: 'e.g. TS-PRD-NVY-M-001'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _autoGenerateSku,
                            icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                            label: const Text('Auto-generate'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFB45309),
                              side: const BorderSide(color: Color(0xFFFDE68A)),
                              backgroundColor: const Color(0xFFFFFBEB),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 13,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Barcode
                      Text(
                        'Barcode / EAN (Optional)',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _barcodeController,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: _inputDecoration(hint: 'UPC / EAN / Custom code'),
                      ),
                      const SizedBox(height: 16),

                      // Attributes: Color, Size, Material
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Color',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _colorController,
                                  style: GoogleFonts.inter(fontSize: 13),
                                  decoration: _inputDecoration(hint: 'e.g. Navy'),
                                  onChanged: (_) => _errorMessage != null ? setState(() => _errorMessage = null) : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Size',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _sizeController,
                                  style: GoogleFonts.inter(fontSize: 13),
                                  decoration: _inputDecoration(hint: 'e.g. M or 42'),
                                  onChanged: (_) => _errorMessage != null ? setState(() => _errorMessage = null) : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Material',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _materialController,
                                  style: GoogleFonts.inter(fontSize: 13),
                                  decoration: _inputDecoration(hint: 'e.g. 100% Cotton'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Pricing: Cost Price & Selling Price
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unit Cost (₹)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _costPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: GoogleFonts.inter(fontSize: 13),
                                  decoration: _inputDecoration(hint: '0.00', prefix: '₹ '),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selling Price (₹) *',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _retailPriceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: _inputDecoration(hint: '0.00', prefix: '₹ '),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Status & Stock Allocation Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Initial Stock & Status',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _status,
                                      isDense: true,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'active', child: Text('Active')),
                                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                                        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                                      ],
                                      onChanged: (val) {
                                        if (val != null) setState(() => _status = val);
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Stock Location',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      if (_isLoadingLocations)
                                        const LinearProgressIndicator(minHeight: 2)
                                      else if (_locations.isEmpty)
                                        Text(
                                          'No locations available',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        )
                                      else
                                        Container(
                                          height: 42,
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFCBD5E1)),
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              isExpanded: true,
                                              value: _selectedLocationId,
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: const Color(0xFF1E293B),
                                              ),
                                              items: _locations.map((loc) {
                                                return DropdownMenuItem(
                                                  value: loc.id,
                                                  child: Text(loc.name),
                                                );
                                              }).toList(),
                                              onChanged: (val) {
                                                setState(() => _selectedLocationId = val);
                                              },
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Opening Stock',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: const Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _openingStockController,
                                        keyboardType: TextInputType.number,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        decoration: _inputDecoration(hint: '0'),
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
                ),
              ),
            ),

              // Footer
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _submitVariant,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF181513),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Variant',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
    );
  }

  InputDecoration _inputDecoration({required String hint, String? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixStyle: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 13,
        color: const Color(0xFF94A3B8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFB45309), width: 1.5),
      ),
    );
  }
}
