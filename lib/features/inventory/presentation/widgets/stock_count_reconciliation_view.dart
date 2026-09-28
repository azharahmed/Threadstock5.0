import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/auth/authorization_service.dart';
import '../../data/stock_count_repository.dart';
import '../../domain/models/stock_count.dart';
import '../../domain/models/stock_count_line.dart';

class StockCountReconciliationView extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback? onReconciliationCompleted;

  const StockCountReconciliationView({
    super.key,
    this.onBack,
    this.onReconciliationCompleted,
  });

  @override
  State<StockCountReconciliationView> createState() => _StockCountReconciliationViewState();
}

class _StockCountReconciliationViewState extends State<StockCountReconciliationView> {
  final StockCountRepository _stockCountRepo = StockCountRepository();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<StockCount> _pendingCounts = [];
  StockCount? _selectedCount;
  List<StockCountLine> _lines = [];

  final Map<String, int> _reconciledQuantities = {};
  final Map<String, String> _reconcileNotes = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPendingCounts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingCounts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final submitted = await _stockCountRepo.getStockCounts(status: 'submitted');
      final inReconcile = await _stockCountRepo.getStockCounts(status: 'in_reconciliation');
      final combined = [...submitted, ...inReconcile];

      _pendingCounts = combined;
      if (_pendingCounts.isNotEmpty) {
        _selectedCount = _pendingCounts.first;
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
    _reconciledQuantities.clear();
    _reconcileNotes.clear();
    for (final line in list) {
      // Reconciled quantity defaults to reconciled_qty ?? counted_qty ?? expected_qty
      final r = line.reconciledQty ?? line.countedQty ?? line.expectedQty;
      _reconciledQuantities[line.variantId] = r;
      if (line.reason != null) {
        _reconcileNotes[line.variantId] = line.reason!;
      }
    }
    if (mounted) {
      setState(() => _lines = list);
    }
  }

  Future<void> _finalizeReconciliation() async {
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

    if (_selectedCount == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Physical Count Reconciliation'),
        content: const Text(
          'This will finalize the count session, update available balances server-side with concurrency safety, update last_counted_at, and post immutable reconciliation ledger entries. Proceed?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Review Lines')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF181513), foregroundColor: Colors.white),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Finalize & Post'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isSubmitting = true);

    final linesPayload = _lines.map((l) {
      final rQty = _reconciledQuantities[l.variantId] ?? l.expectedQty;
      return {
        'variant_id': l.variantId,
        'reconciled_qty': rQty,
        'reason': _reconcileNotes[l.variantId] ?? l.reason,
      };
    }).toList();

    try {
      final res = await _stockCountRepo.completeStockCount(
        countId: _selectedCount!.id,
        lines: linesPayload,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock count ${_selectedCount!.countNumber} finalized! '
              '${res['reconciled_lines_count']} lines reconciled, '
              '${res['adjusted_lines_count']} balance adjustments posted, '
              '${res['zero_discrepancy_lines_count']} verified zero discrepancies.',
            ),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 4),
          ),
        );
        widget.onReconciliationCompleted?.call();
        await _loadPendingCounts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reconciliation Failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  List<StockCountLine> get _filteredLines {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _lines;
    return _lines.where((l) {
      final sku = (l.variantSku ?? '').toLowerCase();
      final name = (l.productName ?? '').toLowerCase();
      return sku.contains(q) || name.contains(q);
    }).toList();
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
          child: Text('Error loading count lines: $_errorMessage', style: GoogleFonts.inter(color: Colors.red)),
        ),
      );
    }

    final totalLines = _lines.length;
    final discrepantLines = _lines.where((l) {
      final r = _reconciledQuantities[l.variantId] ?? l.expectedQty;
      return r != l.expectedQty;
    }).length;
    final matchedLines = totalLines - discrepantLines;
    int netVariance = 0;
    for (final l in _lines) {
      final r = _reconciledQuantities[l.variantId] ?? l.expectedQty;
      netVariance += (r - l.expectedQty);
    }

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
                    Text('Stock Count Reconciliation', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
                    const SizedBox(height: 4),
                    Text(
                      _selectedCount != null
                          ? 'Reconciling Count ${_selectedCount!.countNumber} • Location: ${_selectedCount!.locationName ?? 'Store'} • Status: ${_selectedCount!.status}'
                          : 'No pending stock count submissions awaiting reconciliation.',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              if (_selectedCount != null) ...[
                OutlinedButton(
                  onPressed: _loadPendingCounts,
                  child: const Text('Refresh'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _finalizeReconciliation,
                  icon: _isSubmitting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text('Apply Adjustments & Finalize'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF181513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
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
                    Icon(Icons.inventory_rounded, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No Counts Awaiting Reconciliation', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
                    const SizedBox(height: 6),
                    Text('Once an active physical count is submitted by inventory staff, it will appear here for management approval.', style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280))),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Metrics Row (Honest Data)
            Row(
              children: [
                _buildStatCard('Tracked Items', '$totalLines SKUs', Icons.inventory_2_outlined, const Color(0xFF475569)),
                const SizedBox(width: 12),
                _buildStatCard('Matched Items', '$matchedLines SKUs', Icons.check_circle_outline_rounded, const Color(0xFF16A34A)),
                const SizedBox(width: 12),
                _buildStatCard('Discrepant Items', '$discrepantLines SKUs', Icons.warning_amber_rounded, const Color(0xFFDC2626)),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Net Quantity Variance',
                  '${netVariance > 0 ? '+' : ''}$netVariance units',
                  Icons.trending_up_rounded,
                  netVariance < 0 ? const Color(0xFFDC2626) : (netVariance > 0 ? const Color(0xFF16A34A) : const Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFE5E7EB))),
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
            const SizedBox(height: 12),

            // Discrepancy & Line Table
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE5E7EB))),
                child: ListView.separated(
                  itemCount: _filteredLines.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  itemBuilder: (ctx, i) {
                    final line = _filteredLines[i];
                    final reconciled = _reconciledQuantities[line.variantId] ?? line.expectedQty;
                    final variance = reconciled - line.expectedQty;

                    return ListTile(
                      title: Text(line.productName ?? 'Product', style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'SKU: ${line.variantSku ?? '-'} | Expected: ${line.expectedQty} | Physically Counted: ${line.countedQty ?? 'Uncounted'}',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: variance == 0
                                  ? const Color(0xFFDCFCE7)
                                  : (variance < 0 ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Variance: ${variance > 0 ? '+' : ''}$variance',
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
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Approved Reconciled Qty', style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF6B7280))),
                              const SizedBox(height: 2),
                              SizedBox(
                                width: 70,
                                height: 32,
                                child: TextFormField(
                                  key: ValueKey('${line.variantId}_$reconciled'),
                                  initialValue: '$reconciled',
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                    isDense: true,
                                  ),
                                  onChanged: (val) {
                                    final parsed = int.tryParse(val);
                                    if (parsed != null && parsed >= 0) {
                                      setState(() => _reconciledQuantities[line.variantId] = parsed);
                                    }
                                  },
                                ),
                              ),
                            ],
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
