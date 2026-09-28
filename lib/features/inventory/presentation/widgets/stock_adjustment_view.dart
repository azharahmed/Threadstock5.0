// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/auth/authorization_service.dart';
import '../../data/inventory_repository.dart';
import '../../data/location_repository.dart';
import '../../data/product_repository.dart';
import '../../domain/models/product.dart';
import '../../domain/models/product_variant.dart';
import '../../domain/models/stock_location.dart';

enum StockAdjustmentType {
  add,
  remove,
  correct,
}

class StockAdjustmentView extends StatefulWidget {
  const StockAdjustmentView({
    super.key,
    this.onViewHistory,
    this.onAdjustStockCompleted,
    this.onSaveDraft,
    this.initialLocation = '',
    this.initialProductId,
    this.initialVariantId,
    this.initialLocationId,
    this.initialAdjustmentType,
  });

  final VoidCallback? onViewHistory;
  final VoidCallback? onAdjustStockCompleted;
  final VoidCallback? onSaveDraft;
  final String initialLocation;
  final String? initialProductId;
  final String? initialVariantId;
  final String? initialLocationId;
  final StockAdjustmentType? initialAdjustmentType;

  @override
  State<StockAdjustmentView> createState() => _StockAdjustmentViewState();
}

class _StockAdjustmentViewState extends State<StockAdjustmentView> {
  final ProductRepository _productRepo = ProductRepository();
  final LocationRepository _locationRepo = LocationRepository();
  final InventoryRepository _inventoryRepo = InventoryRepository();

  int _currentStep = 1; // 1: Select Product, 2: Adjust Details, 3: Review & Confirm
  StockAdjustmentType _adjustmentType = StockAdjustmentType.add;
  int _quantity = 1;
  int _targetQuantity = 0;
  int _currentStock = 0;
  String _selectedReason = 'Damaged';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<StockLocation> _locations = [];
  List<Product> _products = [];
  List<ProductVariant> _variants = [];

  StockLocation? _selectedLocation;
  Product? _selectedProduct;
  ProductVariant? _selectedVariant;

  final List<String> _reasons = [
    'Damaged',
    'Lost / Stolen',
    'Found during Audit',
    'Returned by Customer',
    'Sample / Promotion',
    'Expired / Obsolete',
    'Clerical Adjustment',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialAdjustmentType != null) {
      _adjustmentType = widget.initialAdjustmentType!;
    }
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _refController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locs = await _locationRepo.getLocations();
      final prods = await _productRepo.getProducts();

      _locations = locs;
      _products = prods;

      if (_locations.isNotEmpty) {
        if (widget.initialLocationId != null) {
          _selectedLocation = _locations.firstWhere((l) => l.id == widget.initialLocationId, orElse: () => _locations.first);
        } else if (widget.initialLocation.isNotEmpty) {
          _selectedLocation = _locations.firstWhere((l) => l.name == widget.initialLocation, orElse: () => _locations.first);
        } else {
          _selectedLocation = _locations.first;
        }
      }

      if (_products.isNotEmpty) {
        if (widget.initialProductId != null) {
          _selectedProduct = _products.firstWhere((p) => p.id == widget.initialProductId, orElse: () => _products.first);
        } else {
          _selectedProduct = _products.first;
        }

        final vars = await _productRepo.getProductVariants(_selectedProduct!.id);
        _variants = vars;
        if (_variants.isNotEmpty) {
          if (widget.initialVariantId != null) {
            _selectedVariant = _variants.firstWhere((v) => v.id == widget.initialVariantId, orElse: () => _variants.first);
          } else {
            _selectedVariant = _variants.first;
          }
        }
      }

      await _refreshBalance();

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshBalance() async {
    if (_selectedVariant == null || _selectedLocation == null) {
      _currentStock = 0;
      _targetQuantity = 0;
      return;
    }
    try {
      final balances = await _inventoryRepo.getVariantBalances(
        variantId: _selectedVariant!.id,
        locationId: _selectedLocation!.id,
      );
      if (mounted) {
        setState(() {
          _currentStock = balances['available'] ?? 0;
          _targetQuantity = _currentStock;
        });
      }
    } catch (e) {
      debugPrint('[StockAdjustmentView] Error refreshing balance: $e');
    }
  }

  Future<void> _onProductSelected(Product product) async {
    setState(() {
      _selectedProduct = product;
      _selectedVariant = null;
      _variants = [];
      _isLoading = true;
    });

    try {
      final vars = await _productRepo.getProductVariants(product.id);
      _variants = vars;
      if (_variants.isNotEmpty) {
        _selectedVariant = _variants.first;
      }
      await _refreshBalance();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  int get _delta {
    switch (_adjustmentType) {
      case StockAdjustmentType.add:
        return _quantity;
      case StockAdjustmentType.remove:
        return -_quantity;
      case StockAdjustmentType.correct:
        return _targetQuantity - _currentStock;
    }
  }

  int get _expectedStock {
    switch (_adjustmentType) {
      case StockAdjustmentType.add:
        return _currentStock + _quantity;
      case StockAdjustmentType.remove:
        return (_currentStock - _quantity).clamp(0, 999999);
      case StockAdjustmentType.correct:
        return _targetQuantity.clamp(0, 999999);
    }
  }

  List<Product> get _filteredProducts {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _products;
    return _products.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _performStockAdjustment() async {
    final canAdjust = AuthorizationService.instance.can('inventory.adjust');
    if (!canAdjust) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Access Denied: You do not have inventory.adjust permission.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_selectedLocation == null || _selectedVariant == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid location and product variant.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_adjustmentType != StockAdjustmentType.correct && _quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adjustment quantity must be greater than zero.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final delta = _delta;
    if (_adjustmentType == StockAdjustmentType.correct && delta == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Corrected quantity matches current balance.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    if (_currentStock + delta < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot decrease stock below zero. Live available: $_currentStock units.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final res = await _inventoryRepo.adjustStock(
        locationId: _selectedLocation!.id,
        variantId: _selectedVariant!.id,
        quantityDelta: delta,
        reason: _selectedReason,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        referenceId: _refController.text.trim().isNotEmpty ? _refController.text.trim() : null,
      );

      final newBalance = res['balance_after'] ?? _expectedStock;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock for ${_selectedProduct?.name ?? 'Item'} adjusted ($delta). Live available balance: $newBalance units.',
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onAdjustStockCompleted?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock Adjustment Failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('Error loading inventory data: $_errorMessage', style: GoogleFonts.inter(color: Colors.red)),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Header
          _buildHeader(),
          const SizedBox(height: 20),

          // 2. Step Indicator (Wizard)
          _buildStepWizard(),
          const SizedBox(height: 24),

          // 3. Main 2-Column Section
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1020;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 66, child: _buildAdjustmentFormCard()),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 34,
                      child: Column(
                        children: [
                          _buildSummaryCard(),
                          const SizedBox(height: 20),
                          _buildHelpCard(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _buildAdjustmentFormCard(),
                  const SizedBox(height: 24),
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildHelpCard(),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stock Adjustment',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Adjust sellable inventory balances, record shrinkage, and append immutable ledger audit entries.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: widget.onViewHistory,
          icon: const Icon(Icons.access_time_rounded, size: 16),
          label: const Text('View Adjustment History'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF374151),
            side: const BorderSide(color: Color(0xFFD1D5DB)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
        ),
      ],
    );
  }

  // 2. Step Indicator
  Widget _buildStepWizard() {
    return Row(
      children: [
        _buildStepItem(1, 'Select Product'),
        const SizedBox(width: 14),
        Container(width: 48, height: 1, color: const Color(0xFFCBD5E1)),
        const SizedBox(width: 14),
        _buildStepItem(2, 'Adjust Details'),
        const SizedBox(width: 14),
        Container(width: 48, height: 1, color: const Color(0xFFCBD5E1)),
        const SizedBox(width: 14),
        _buildStepItem(3, 'Review & Confirm'),
      ],
    );
  }

  Widget _buildStepItem(int step, String title) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return InkWell(
      onTap: () => setState(() => _currentStep = step),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive || isDone ? const Color(0xFF865D36) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$step',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive || isDone ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive || isDone ? const Color(0xFF865D36) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // 3. Form Card
  Widget _buildAdjustmentFormCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentStep == 1) _buildStep1SelectProduct(),
          if (_currentStep == 2) _buildStep2AdjustDetails(),
          if (_currentStep == 3) _buildStep3ReviewAndConfirm(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentStep > 1)
                OutlinedButton(
                  onPressed: () => setState(() => _currentStep--),
                  child: const Text('Back'),
                )
              else
                const SizedBox.shrink(),
              if (_currentStep < 3)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF181513),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => setState(() => _currentStep++),
                  child: const Text('Continue'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep1SelectProduct() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Product & Variant',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search products by name...',
            prefixIcon: const Icon(Icons.search_rounded, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
        Container(
          height: 240,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            itemCount: _filteredProducts.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final prod = _filteredProducts[i];
              final isSelected = _selectedProduct?.id == prod.id;
              return ListTile(
                selected: isSelected,
                selectedTileColor: const Color(0xFFFBF4EB),
                title: Text(prod.name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('Product ID: ${prod.id.substring(0, 8)}...', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF865D36), size: 18) : null,
                onTap: () => _onProductSelected(prod),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (_variants.isNotEmpty) ...[
          Text('Select Variant', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedVariant?.id,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
            items: _variants.map((v) => DropdownMenuItem(value: v.id, child: Text('${v.title} (${v.sku})'))).toList(),
            onChanged: (val) {
              final found = _variants.firstWhere((v) => v.id == val);
              setState(() => _selectedVariant = found);
              _refreshBalance();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStep2AdjustDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Adjustment Parameters',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
        ),
        const SizedBox(height: 16),

        // Location Selector
        DropdownButtonFormField<String>(
          value: _selectedLocation?.id,
          decoration: InputDecoration(
            labelText: 'Target Location',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
          items: _locations.map((loc) => DropdownMenuItem(value: loc.id, child: Text(loc.name))).toList(),
          onChanged: (val) {
            final found = _locations.firstWhere((l) => l.id == val);
            setState(() => _selectedLocation = found);
            _refreshBalance();
          },
        ),
        const SizedBox(height: 16),

        // Adjustment Type (Add Stock / Remove Stock / Correct Quantity)
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _adjustmentType = StockAdjustmentType.add),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _adjustmentType == StockAdjustmentType.add ? const Color(0xFFF0FDF4) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _adjustmentType == StockAdjustmentType.add ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
                      width: _adjustmentType == StockAdjustmentType.add ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle, size: 16, color: _adjustmentType == StockAdjustmentType.add ? const Color(0xFF16A34A) : const Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text('Add Stock', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _adjustmentType == StockAdjustmentType.add ? const Color(0xFF15803D) : const Color(0xFF374151))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _adjustmentType = StockAdjustmentType.remove),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _adjustmentType == StockAdjustmentType.remove ? const Color(0xFFFEF2F2) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _adjustmentType == StockAdjustmentType.remove ? const Color(0xFFDC2626) : const Color(0xFFD1D5DB),
                      width: _adjustmentType == StockAdjustmentType.remove ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.remove_circle, size: 16, color: _adjustmentType == StockAdjustmentType.remove ? const Color(0xFFDC2626) : const Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text('Remove Stock', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _adjustmentType == StockAdjustmentType.remove ? const Color(0xFFB91C1C) : const Color(0xFF374151))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: InkWell(
                onTap: () => setState(() {
                  _adjustmentType = StockAdjustmentType.correct;
                  _targetQuantity = _currentStock;
                }),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _adjustmentType == StockAdjustmentType.correct ? const Color(0xFFEFF6FF) : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _adjustmentType == StockAdjustmentType.correct ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
                      width: _adjustmentType == StockAdjustmentType.correct ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tune, size: 16, color: _adjustmentType == StockAdjustmentType.correct ? const Color(0xFF2563EB) : const Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text('Correct Quantity', style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: _adjustmentType == StockAdjustmentType.correct ? const Color(0xFF1D4ED8) : const Color(0xFF374151))),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quantity Adjustment
        Row(
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('input_${_adjustmentType.name}'),
                initialValue: _adjustmentType == StockAdjustmentType.correct ? '$_targetQuantity' : '$_quantity',
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _adjustmentType == StockAdjustmentType.correct ? 'Actual Counted / New Quantity' : 'Adjustment Quantity',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val);
                  if (parsed != null && parsed >= 0) {
                    setState(() {
                      if (_adjustmentType == StockAdjustmentType.correct) {
                        _targetQuantity = parsed;
                      } else {
                        _quantity = parsed;
                      }
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('New Expected:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                    Text('$_expectedStock units', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B))),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Reason Dropdown
        DropdownButtonFormField<String>(
          value: _selectedReason,
          decoration: InputDecoration(
            labelText: 'Adjustment Reason',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
          items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedReason = val);
          },
        ),
        const SizedBox(height: 16),

        // Reference ID / External Ref
        TextField(
          controller: _refController,
          decoration: InputDecoration(
            labelText: 'Reference Number / PO / Audit ID (Optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),

        // Notes
        TextField(
          controller: _notesController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Audit Notes / Explanation (Optional)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildStep3ReviewAndConfirm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review & Confirm Adjustment',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              _buildReviewRow('Product', _selectedProduct?.name ?? '-'),
              const Divider(height: 16),
              _buildReviewRow('Variant SKU', _selectedVariant?.sku ?? '-'),
              const Divider(height: 16),
              _buildReviewRow('Location', _selectedLocation?.name ?? '-'),
              const Divider(height: 16),
              _buildReviewRow('Live Available Stock', '$_currentStock units'),
              const Divider(height: 16),
              _buildReviewRow(
                'Adjustment Delta',
                '${_delta >= 0 ? '+' : ''}$_delta units',
                highlightColor: _delta < 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
              ),
              const Divider(height: 16),
              _buildReviewRow('New Expected Balance', '$_expectedStock units', isBold: true),
              const Divider(height: 16),
              _buildReviewRow('Reason', _selectedReason),
              if (_notesController.text.trim().isNotEmpty) ...[
                const Divider(height: 16),
                _buildReviewRow('Notes', _notesController.text.trim()),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow(String label, String value, {Color? highlightColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280))),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: highlightColor ?? const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  // Summary Card (Right Column)
  Widget _buildSummaryCard() {
    final canAdjust = AuthorizationService.instance.can('inventory.adjust');

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
          Text('Adjustment Summary', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Stock:', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280))),
              Text('$_currentStock units', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delta:', style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280))),
              Text(
                '${_delta >= 0 ? '+' : ''}$_delta units',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _delta < 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Projected Available:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              Text('$_expectedStock units', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF865D36))),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (!canAdjust || _isSubmitting) ? null : _performStockAdjustment,
              icon: _isSubmitting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_isSubmitting ? 'Adjusting Stock...' : 'Confirm & Adjust Stock'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          if (!canAdjust) ...[
            const SizedBox(height: 8),
            Text(
              'Requires inventory.adjust permission',
              style: GoogleFonts.inter(fontSize: 11, fontStyle: FontStyle.italic, color: const Color(0xFF9CA3AF)),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFFB45309), size: 18),
              const SizedBox(width: 8),
              Text(
                'Audit Protocol Compliance',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'All stock adjustments are server-validated with row-level locks. Ledger entries record exact user attribution and bucket deltas. Ordinary adjustments do not overwrite physical count timestamps.',
            style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF78350F), height: 1.4),
          ),
        ],
      ),
    );
  }
}
