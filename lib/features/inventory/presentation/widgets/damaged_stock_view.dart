import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/auth/authorization_service.dart';
import '../../data/inventory_ledger_repository.dart';
import '../../data/inventory_repository.dart';
import '../../data/location_repository.dart';
import '../../data/product_repository.dart';
import '../../domain/models/inventory_ledger_entry.dart';
import '../../domain/models/product.dart';
import '../../domain/models/product_variant.dart';
import '../../domain/models/stock_location.dart';

class DamagedStockView extends StatefulWidget {
  final VoidCallback? onBack;
  final String? initialProductId;
  final String? initialVariantId;
  final String? initialLocationId;

  const DamagedStockView({
    super.key,
    this.onBack,
    this.initialProductId,
    this.initialVariantId,
    this.initialLocationId,
  });

  @override
  State<DamagedStockView> createState() => _DamagedStockViewState();
}

class _DamagedStockViewState extends State<DamagedStockView> {
  final InventoryRepository _inventoryRepo = InventoryRepository();
  final ProductRepository _productRepo = ProductRepository();
  final LocationRepository _locationRepo = LocationRepository();
  final InventoryLedgerRepository _ledgerRepo = InventoryLedgerRepository();

  bool _isLoading = true;
  String? _errorMessage;

  List<StockLocation> _locations = [];
  List<Product> _products = [];
  List<ProductVariant> _variants = [];
  List<InventoryLedgerEntry> _recentDamageHistory = [];

  String? _selectedLocationId;
  String? _selectedProductId;
  String? _selectedVariantId;

  int _availableQty = 0;
  int _damagedQty = 0;
  int _committedQty = 0;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedLocationId = widget.initialLocationId;
    _selectedProductId = widget.initialProductId;
    _selectedVariantId = widget.initialVariantId;
    _initializeData();
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

      if (_selectedLocationId == null && _locations.isNotEmpty) {
        _selectedLocationId = _locations.first.id;
      }

      if (_selectedProductId == null && _products.isNotEmpty) {
        _selectedProductId = _products.first.id;
      }

      if (_selectedProductId != null) {
        _variants = await _productRepo.getProductVariants(_selectedProductId!);
        if (_selectedVariantId == null && _variants.isNotEmpty) {
          _selectedVariantId = _variants.first.id;
        }
      }

      await _refreshBalancesAndHistory();

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

  Future<void> _onProductChanged(String? newProductId) async {
    if (newProductId == null || newProductId == _selectedProductId) return;
    setState(() {
      _selectedProductId = newProductId;
      _selectedVariantId = null;
      _variants = [];
      _isLoading = true;
    });

    try {
      final vars = await _productRepo.getProductVariants(newProductId);
      _variants = vars;
      if (_variants.isNotEmpty) {
        _selectedVariantId = _variants.first.id;
      }
      await _refreshBalancesAndHistory();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshBalancesAndHistory() async {
    if (_selectedVariantId == null || _selectedLocationId == null) {
      setState(() {
        _availableQty = 0;
        _damagedQty = 0;
        _committedQty = 0;
        _recentDamageHistory = [];
      });
      return;
    }

    try {
      final balances = await _inventoryRepo.getVariantBalances(
        variantId: _selectedVariantId!,
        locationId: _selectedLocationId,
      );

      final history = await _ledgerRepo.getLedgerEntries(
        locationId: _selectedLocationId,
        variantId: _selectedVariantId,
        limit: 20,
      );

      final damageEntries = history
          .where((e) => e.eventType == 'damage' || e.eventType == 'damage_restore' || e.eventType == 'damage_writeoff')
          .toList();

      if (mounted) {
        setState(() {
          _availableQty = balances['available'] ?? 0;
          _damagedQty = balances['damaged'] ?? 0;
          _committedQty = balances['committed'] ?? 0;
          _recentDamageHistory = damageEntries;
        });
      }
    } catch (e) {
      debugPrint('[DamagedStockView] Error refreshing balances: $e');
    }
  }

  Future<void> _showActionDialog({
    required String action,
    required String title,
    required String subtitle,
    required int maxAllowed,
    required IconData icon,
    required Color iconColor,
  }) async {
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

    if (maxAllowed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot perform $title: current quantity is 0.'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    final qtyController = TextEditingController(text: '1');
    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    String? localError;

    await showDialog(
      context: context,
      barrierDismissible: !_isSubmitting,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantity (Max: $maxAllowed)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        setDialogState(() {
                          if (parsed == null || parsed <= 0) {
                            localError = 'Enter a valid positive number';
                          } else if (parsed > maxAllowed) {
                            localError = 'Quantity cannot exceed $maxAllowed';
                          } else {
                            localError = null;
                          }
                        });
                      },
                    ),
                    if (localError != null) ...[
                      const SizedBox(height: 6),
                      Text(localError!, style: GoogleFonts.inter(fontSize: 12, color: Colors.red)),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: reasonController,
                      decoration: InputDecoration(
                        labelText: 'Reason (Required)',
                        hintText: action == 'mark_damaged'
                            ? 'e.g., Fabric torn, Water damage'
                            : (action == 'restore_sellable' ? 'e.g., Repaired, False alarm' : 'e.g., Disposed, Recycled'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Additional Notes (Optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          final qty = int.tryParse(qtyController.text);
                          final reason = reasonController.text.trim();
                          if (qty == null || qty <= 0 || qty > maxAllowed) {
                            setDialogState(() => localError = 'Please specify a valid quantity (1 to $maxAllowed)');
                            return;
                          }
                          if (reason.isEmpty) {
                            setDialogState(() => localError = 'Reason is required for audit compliance');
                            return;
                          }

                          setDialogState(() => _isSubmitting = true);
                          setState(() => _isSubmitting = true);

                          try {
                            final res = await _inventoryRepo.recordDamagedStock(
                              locationId: _selectedLocationId!,
                              variantId: _selectedVariantId!,
                              action: action,
                              quantity: qty,
                              reason: reason,
                              notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                            );

                            if (ctx.mounted) {
                              Navigator.of(dialogCtx).pop();
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message']?.toString() ?? 'Damage transaction recorded successfully.'),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                              await _refreshBalancesAndHistory();
                            }
                          } catch (e) {
                            setDialogState(() {
                              localError = e.toString();
                              _isSubmitting = false;
                            });
                          } finally {
                            if (mounted) {
                              setState(() => _isSubmitting = false);
                            }
                          }
                        },
                  child: _isSubmitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Confirm $title'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final canAdjust = AuthorizationService.instance.can('inventory.adjust');

    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (widget.onBack != null) ...[
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Back',
                  color: const Color(0xFF374151),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Damaged Stock & Quarantine Operations',
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Quarantine damaged inventory, return repaired goods to sellable stock, or process disposal write-offs.',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _refreshBalancesAndHistory,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Selection Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                // Location Selector
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedLocationId,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      labelStyle: GoogleFonts.inter(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    items: _locations.map((loc) => DropdownMenuItem(value: loc.id, child: Text(loc.name))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedLocationId = val);
                      _refreshBalancesAndHistory();
                    },
                  ),
                ),
                const SizedBox(width: 14),

                // Product Selector
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedProductId,
                    decoration: InputDecoration(
                      labelText: 'Product',
                      labelStyle: GoogleFonts.inter(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    items: _products.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name, overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: _onProductChanged,
                  ),
                ),
                const SizedBox(width: 14),

                // Variant Selector
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedVariantId,
                    decoration: InputDecoration(
                      labelText: 'Variant / SKU',
                      labelStyle: GoogleFonts.inter(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    items: _variants.map((v) => DropdownMenuItem(value: v.id, child: Text('${v.title} (${v.sku})'))).toList(),
                    onChanged: (val) {
                      setState(() => _selectedVariantId = val);
                      _refreshBalancesAndHistory();
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Balances & Actions
          if (_isLoading)
            const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            Center(child: Text('Error: $_errorMessage', style: GoogleFonts.inter(color: Colors.red)))
          else ...[
            Row(
              children: [
                // Damaged (Quarantined) Balance Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Damaged (Quarantined)',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF991B1B)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_damagedQty units',
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFFDC2626)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Physically present but quarantined from sellable stock.',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF7F1D1D)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Available Sellable Balance Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Available (Sellable)',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF166534)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '$_availableQty units',
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current sellable stock available for sales orders.',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF14532D)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Total Physical On-Hand Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.inventory_2_outlined, color: Color(0xFF475569), size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Physical On-Hand',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF334155)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_availableQty + _damagedQty + _committedQty} units',
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total physical stock: Available + Quarantined.',
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Actions Row
            Row(
              children: [
                // 1. Mark Damaged Button
                ElevatedButton.icon(
                  onPressed: (!canAdjust || _isSubmitting || _availableQty <= 0)
                      ? null
                      : () => _showActionDialog(
                            action: 'mark_damaged',
                            title: 'Mark Damaged',
                            subtitle: 'Quarantine items by moving them from available stock to damaged stock.',
                            maxAllowed: _availableQty,
                            icon: Icons.remove_circle_outline_rounded,
                            iconColor: const Color(0xFFDC2626),
                          ),
                  icon: const Icon(Icons.remove_circle_outline_rounded, size: 16),
                  label: const Text('Mark Damaged'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Restore Sellable Button
                ElevatedButton.icon(
                  onPressed: (!canAdjust || _isSubmitting || _damagedQty <= 0)
                      ? null
                      : () => _showActionDialog(
                            action: 'restore_sellable',
                            title: 'Restore Sellable',
                            subtitle: 'Return repaired or unquarantined items from damaged back into available stock.',
                            maxAllowed: _damagedQty,
                            icon: Icons.add_circle_outline_rounded,
                            iconColor: const Color(0xFF16A34A),
                          ),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                  label: const Text('Restore Sellable'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 12),

                // 3. Write Off Button
                OutlinedButton.icon(
                  onPressed: (!canAdjust || _isSubmitting || _damagedQty <= 0)
                      ? null
                      : () => _showActionDialog(
                            action: 'write_off',
                            title: 'Write Off Damaged',
                            subtitle: 'Permanently remove unsalvageable damaged items from physical inventory.',
                            maxAllowed: _damagedQty,
                            icon: Icons.delete_outline_rounded,
                            iconColor: const Color(0xFF991B1B),
                          ),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Write Off Damaged'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF991B1B),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const Spacer(),
                if (!canAdjust)
                  Text(
                    'Requires inventory.adjust permission',
                    style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: const Color(0xFF9CA3AF)),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Damage Audit History Section
            Text(
              'Recent Damage Activity for Selected Variant',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: _recentDamageHistory.isEmpty
                    ? Center(
                        child: Text(
                          'No damage events recorded for this variant.',
                          style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _recentDamageHistory.length,
                        separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                        itemBuilder: (ctx, i) {
                          final e = _recentDamageHistory[i];
                          final dateStr = _formatDate(e.createdAt);

                          return ListTile(
                            dense: true,
                            leading: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (e.eventType == 'damage'
                                        ? const Color(0xFFDC2626)
                                        : (e.eventType == 'damage_restore' ? const Color(0xFF16A34A) : const Color(0xFF991B1B)))
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                e.eventType == 'damage'
                                    ? Icons.remove_circle_outline_rounded
                                    : (e.eventType == 'damage_restore' ? Icons.add_circle_outline_rounded : Icons.delete_outline_rounded),
                                size: 16,
                                color: e.eventType == 'damage'
                                    ? const Color(0xFFDC2626)
                                    : (e.eventType == 'damage_restore' ? const Color(0xFF16A34A) : const Color(0xFF991B1B)),
                              ),
                            ),
                            title: Text(
                              '${e.eventType == 'damage' ? 'Marked Damaged' : (e.eventType == 'damage_restore' ? 'Restored to Sellable' : 'Written Off')} '
                              '(${e.damagedDelta > 0 ? '+' : ''}${e.damagedDelta} damaged, ${e.availableDelta > 0 ? '+' : ''}${e.availableDelta} available)',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${e.notes ?? 'No reason recorded'} • By: ${e.actorName ?? 'Staff'}',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                            ),
                            trailing: Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF))),
                          );
                        },
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
