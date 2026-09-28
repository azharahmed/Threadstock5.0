import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/auth/authorization_service.dart';
import '../../data/location_repository.dart';
import '../../data/product_repository.dart';
import '../../data/stock_count_repository.dart';
import '../../domain/models/product_variant.dart';
import '../../domain/models/stock_count.dart';
import '../../domain/models/stock_count_line.dart';
import '../../domain/models/stock_location.dart';

class ActiveStockCountView extends StatefulWidget {
  final VoidCallback? onViewFullReport;
  final VoidCallback? onPauseSession;
  final VoidCallback? onSubmitAudit;
  final VoidCallback? onScanBarcode;
  final VoidCallback? onGoToReconciliation;

  const ActiveStockCountView({
    super.key,
    this.onViewFullReport,
    this.onPauseSession,
    this.onSubmitAudit,
    this.onScanBarcode,
    this.onGoToReconciliation,
  });

  @override
  State<ActiveStockCountView> createState() => _ActiveStockCountViewState();
}

class _ActiveStockCountViewState extends State<ActiveStockCountView> {
  final StockCountRepository _stockCountRepo = StockCountRepository();
  final LocationRepository _locationRepo = LocationRepository();
  final ProductRepository _productRepo = ProductRepository();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<StockLocation> _locations = [];
  List<StockCount> _activeCounts = [];
  StockCount? _selectedCount;
  List<StockCountLine> _lines = [];

  final Map<String, int> _countedQuantities = {};
  final Map<String, String> _lineReasons = {};

  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'all'; // all, uncounted, discrepant

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locs = await _locationRepo.getLocations();
      final inProgressCounts = await _stockCountRepo.getStockCounts(status: 'in_progress');

      _locations = locs;
      _activeCounts = inProgressCounts;

      if (_activeCounts.isNotEmpty) {
        _selectedCount = _activeCounts.first;
        await _loadCountLines(_selectedCount!.id);
      } else {
        _selectedCount = null;
        _lines = [];
      }

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

  Future<void> _loadCountLines(String countId) async {
    final list = await _stockCountRepo.getStockCountLines(countId: countId);
    _countedQuantities.clear();
    _lineReasons.clear();
    for (final line in list) {
      if (line.countedQty != null) {
        _countedQuantities[line.variantId] = line.countedQty!;
      }
      if (line.reason != null) {
        _lineReasons[line.variantId] = line.reason!;
      }
    }
    if (mounted) {
      setState(() => _lines = list);
    }
  }

  Future<void> _showStartCountModal() async {
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

    if (_locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No stock locations available to count.')),
      );
      return;
    }

    String selectedLocId = _locations.first.id;
    String countType = 'full';
    final notesController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text('Start Physical Stock Count', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Creates an audited count session snapshotting active product variants. Zero-balance variants are automatically included.',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedLocId,
                      decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder(), isDense: true),
                      items: _locations.map((loc) => DropdownMenuItem(value: loc.id, child: Text(loc.name))).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedLocId = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: countType,
                      decoration: const InputDecoration(labelText: 'Count Scope', border: OutlineInputBorder(), isDense: true),
                      items: const [
                        DropdownMenuItem(value: 'full', child: Text('Full Physical Count (All SKUs)')),
                        DropdownMenuItem(value: 'cycle', child: Text('Cycle Count')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => countType = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes / Session Label', border: OutlineInputBorder(), isDense: true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF181513), foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.of(dialogCtx).pop();
                    setState(() => _isLoading = true);
                    try {
                      final res = await _stockCountRepo.startStockCount(
                        locationId: selectedLocId,
                        countType: countType,
                        notes: notesController.text.trim().isNotEmpty ? notesController.text.trim() : null,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Count started successfully: ${res['count_number']} (${res['lines_initialized']} items in scope)'),
                          backgroundColor: const Color(0xFF16A34A),
                        ),
                      );
                      await _loadInitialData();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to start count: $e'), backgroundColor: const Color(0xFFDC2626)),
                      );
                      setState(() => _isLoading = false);
                    }
                  },
                  child: const Text('Start Count'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddUnexpectedSkuModal() async {
    if (_selectedCount == null) return;

    final skuController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    String? modalError;
    ProductVariant? foundVariant;

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text('Scan / Add Unexpected SKU', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'If a physically present item was not initially expected in this count, discover and add it with expected_qty = 0.',
                      style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: skuController,
                            decoration: const InputDecoration(
                              labelText: 'SKU or Barcode',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final code = skuController.text.trim();
                            if (code.isEmpty) return;
                            try {
                              final variant = await _productRepo.findVariantBySkuOrBarcode(code);
                              setModalState(() {
                                foundVariant = variant;
                                modalError = variant == null ? 'No variant found with SKU: $code' : null;
                              });
                            } catch (e) {
                              setModalState(() => modalError = e.toString());
                            }
                          },
                          child: const Text('Lookup'),
                        ),
                      ],
                    ),
                    if (modalError != null) ...[
                      const SizedBox(height: 8),
                      Text(modalError!, style: GoogleFonts.inter(fontSize: 12, color: Colors.red)),
                    ],
                    if (foundVariant != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Discovered: ${foundVariant!.title}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                            Text('SKU: ${foundVariant!.sku} | Expected: 0 units', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Counted Quantity Physically Present', border: OutlineInputBorder(), isDense: true),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF181513), foregroundColor: Colors.white),
                  onPressed: foundVariant == null
                      ? null
                      : () {
                          final counted = int.tryParse(qtyController.text) ?? 1;
                          setState(() {
                            _countedQuantities[foundVariant!.id] = counted;
                            // Add synthetic line into UI list if not present
                            if (!_lines.any((l) => l.variantId == foundVariant!.id)) {
                              _lines.add(
                                StockCountLine(
                                  id: 'temp_${foundVariant!.id}',
                                  businessId: _selectedCount!.businessId,
                                  countId: _selectedCount!.id,
                                  variantId: foundVariant!.id,
                                  expectedQty: 0,
                                  countedQty: counted,
                                  discrepancy: counted,
                                  status: 'counted',
                                  sku: foundVariant!.sku,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                ),
                              );
                            }
                          });
                          Navigator.of(dialogCtx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added SKU ${foundVariant!.sku} with counted quantity: $counted')),
                          );
                        },
                  child: const Text('Add to Count'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitAuditForReconciliation() async {
    final canAdjust = AuthorizationService.instance.can('inventory.adjust');
    if (!canAdjust) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Access Denied: You do not have inventory.adjust permission.'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }

    if (_selectedCount == null) return;

    final uncountedCount = _lines.where((l) => !_countedQuantities.containsKey(l.variantId)).length;
    if (uncountedCount > 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Uncounted Items Remain'),
          content: Text(
            'There are $uncountedCount items with no counted quantity recorded. Uncounted items will default to 0 during submission. Continue?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Review Count')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Proceed & Submit')),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isSubmitting = true);

    final linesPayload = _lines.map((l) {
      final counted = _countedQuantities[l.variantId] ?? 0;
      return {
        'variant_id': l.variantId,
        'counted_qty': counted,
        'reason': _lineReasons[l.variantId] ?? (counted != l.expectedQty ? 'Discrepancy recorded during count' : null),
      };
    }).toList();

    try {
      final res = await _stockCountRepo.submitStockCount(
        countId: _selectedCount!.id,
        lines: linesPayload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stock count submitted for reconciliation: ${res['discrepant_lines_count']} discrepancies found.'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
        widget.onGoToReconciliation?.call();
        await _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: const Color(0xFFDC2626)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _cancelActiveCount() async {
    if (_selectedCount == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Stock Count'),
        content: const Text('Are you sure you want to cancel this stock count? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Back')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel Count Session'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isSubmitting = true);
    try {
      await _stockCountRepo.cancelStockCount(countId: _selectedCount!.id, reason: 'Cancelled by user');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stock count session cancelled.')));
        await _loadInitialData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  List<StockCountLine> get _filteredLines {
    var list = _lines;
    if (_filterType == 'uncounted') {
      list = list.where((l) => !_countedQuantities.containsKey(l.variantId)).toList();
    } else if (_filterType == 'discrepant') {
      list = list.where((l) {
        final c = _countedQuantities[l.variantId];
        return c != null && c != l.expectedQty;
      }).toList();
    }

    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((l) {
      final sku = (l.variantSku ?? '').toLowerCase();
      final name = (l.productName ?? '').toLowerCase();
      return sku.contains(q) || name.contains(q);
    }).toList();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
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
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('Error loading count data: $_errorMessage', style: GoogleFonts.inter(color: Colors.red)),
        ),
      );
    }

    final totalCount = _lines.length;
    final countedCount = _lines.where((l) => _countedQuantities.containsKey(l.variantId)).length;
    final discrepantCount = _lines.where((l) {
      final c = _countedQuantities[l.variantId];
      return c != null && c != l.expectedQty;
    }).length;

    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Active Stock Count', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                    const SizedBox(height: 4),
                    Text(
                      _selectedCount != null
                          ? 'Session ${_selectedCount!.countNumber} • Location: ${_selectedCount!.locationName ?? 'Store'} • Started ${_formatDate(_selectedCount!.startedAt)}'
                          : 'No active stock count session in progress.',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              if (_selectedCount == null)
                ElevatedButton.icon(
                  onPressed: _showStartCountModal,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Start New Count'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF181513), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                )
              else ...[
                OutlinedButton.icon(
                  onPressed: _showAddUnexpectedSkuModal,
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                  label: const Text('Scan Unexpected SKU'),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF374151), side: const BorderSide(color: Color(0xFFD1D5DB))),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _cancelActiveCount,
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626), side: const BorderSide(color: Color(0xFFFCA5A5))),
                  child: const Text('Cancel Session'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitAuditForReconciliation,
                  icon: _isSubmitting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Submit for Reconciliation'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF181513), foregroundColor: Colors.white),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          if (_selectedCount == null) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fact_check_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No Active Physical Count', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                    const SizedBox(height: 6),
                    Text('Start a new count to snapshot expected quantities across all tracked products.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF181513), foregroundColor: Colors.white),
                      onPressed: _showStartCountModal,
                      child: const Text('Start Stock Count'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Metrics Summary Row (Honest Data)
            Row(
              children: [
                _buildStatCard('Total Items in Scope', '$totalCount SKUs', Icons.inventory_2_outlined, const Color(0xFF475569)),
                const SizedBox(width: 12),
                _buildStatCard('Counted Items', '$countedCount / $totalCount', Icons.check_circle_outline_rounded, const Color(0xFF16A34A)),
                const SizedBox(width: 12),
                _buildStatCard('Discrepancies', '$discrepantCount SKUs', Icons.warning_amber_rounded, const Color(0xFFDC2626)),
              ],
            ),
            const SizedBox(height: 16),

            // Filter bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search SKU or product name...',
                        prefixIcon: Icon(Icons.search, size: 18),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('All')),
                      ButtonSegment(value: 'uncounted', label: Text('Uncounted')),
                      ButtonSegment(value: 'discrepant', label: Text('Discrepancies')),
                    ],
                    selected: {_filterType},
                    onSelectionChanged: (set) => setState(() => _filterType = set.first),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Count Lines Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
                child: ListView.separated(
                  itemCount: _filteredLines.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (ctx, i) {
                    final line = _filteredLines[i];
                    final hasCounted = _countedQuantities.containsKey(line.variantId);
                    final counted = _countedQuantities[line.variantId] ?? 0;
                    final variance = hasCounted ? (counted - line.expectedQty) : null;

                    return ListTile(
                      title: Text(line.productName ?? 'Product', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: Text('SKU: ${line.variantSku ?? '-'} | Expected: ${line.expectedQty} units', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (variance != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: variance == 0
                                    ? const Color(0xFFDCFCE7)
                                    : (variance < 0 ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${variance > 0 ? '+' : ''}$variance',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: variance == 0
                                      ? const Color(0xFF15803D)
                                      : (variance < 0 ? const Color(0xFFDC2626) : const Color(0xFFD97706)),
                                ),
                              ),
                            ),
                          const SizedBox(width: 14),
                          // Stepper
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: () {
                              final current = _countedQuantities[line.variantId] ?? line.expectedQty;
                              if (current > 0) {
                                setState(() => _countedQuantities[line.variantId] = current - 1);
                              }
                            },
                          ),
                          SizedBox(
                            width: 50,
                            child: TextFormField(
                              key: ValueKey('${line.variantId}_$counted'),
                              initialValue: hasCounted ? '$counted' : '',
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(hintText: '-', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 6)),
                              onChanged: (val) {
                                final parsed = int.tryParse(val);
                                if (parsed != null && parsed >= 0) {
                                  setState(() => _countedQuantities[line.variantId] = parsed);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () {
                              final current = _countedQuantities[line.variantId] ?? line.expectedQty;
                              setState(() => _countedQuantities[line.variantId] = current + 1);
                            },
                          ),
                        ],
                      ),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280))),
                Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
