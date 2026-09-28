import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/inventory_ledger_repository.dart';
import '../../data/location_repository.dart';
import '../../domain/models/inventory_ledger_entry.dart';
import '../../domain/models/stock_location.dart';

class StockHistoryView extends StatefulWidget {
  final VoidCallback? onBack;
  final String? initialVariantId;
  final String? initialLocationId;

  const StockHistoryView({
    super.key,
    this.onBack,
    this.initialVariantId,
    this.initialLocationId,
  });

  @override
  State<StockHistoryView> createState() => _StockHistoryViewState();
}

class _StockHistoryViewState extends State<StockHistoryView> {
  final InventoryLedgerRepository _ledgerRepo = InventoryLedgerRepository();
  final LocationRepository _locationRepo = LocationRepository();

  bool _isLoading = true;
  String? _errorMessage;
  List<InventoryLedgerEntry> _entries = [];
  List<StockLocation> _locations = [];

  String? _selectedLocationId;
  String _selectedEventType = 'all';
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;

  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _eventTypes = [
    {'value': 'all', 'label': 'All Events'},
    {'value': 'adjustment', 'label': 'Stock Adjustment'},
    {'value': 'damage', 'label': 'Marked Damaged'},
    {'value': 'damage_restore', 'label': 'Restored to Sellable'},
    {'value': 'damage_writeoff', 'label': 'Damage Write-off'},
    {'value': 'count_reconciliation', 'label': 'Physical Count Reconciliation'},
    {'value': 'opening_stock', 'label': 'Opening Stock'},
    {'value': 'sale', 'label': 'Sale'},
    {'value': 'return_restock', 'label': 'Customer Return'},
    {'value': 'transfer_in', 'label': 'Transfer In'},
    {'value': 'transfer_out', 'label': 'Transfer Out'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocationId = widget.initialLocationId;
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final locs = await _locationRepo.getLocations();
      final list = await _ledgerRepo.getLedgerEntries(
        locationId: _selectedLocationId,
        variantId: widget.initialVariantId,
        eventType: _selectedEventType == 'all' ? null : _selectedEventType,
        startDate: _startDate,
        endDate: _endDate,
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _locations = locs;
          _entries = list;
          _isLoading = false;
        });
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

  List<InventoryLedgerEntry> get _filteredEntries {
    if (_searchQuery.isEmpty) return _entries;
    final q = _searchQuery.toLowerCase();
    return _entries.where((e) {
      final pName = (e.productName ?? '').toLowerCase();
      final sku = (e.variantSku ?? '').toLowerCase();
      final notes = (e.notes ?? '').toLowerCase();
      final actor = (e.actorName ?? '').toLowerCase();
      final ref = (e.referenceType ?? '').toLowerCase();
      return pName.contains(q) || sku.contains(q) || notes.contains(q) || actor.contains(q) || ref.contains(q);
    }).toList();
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'damage':
      case 'damage_writeoff':
        return const Color(0xFFDC2626);
      case 'damage_restore':
      case 'opening_stock':
        return const Color(0xFF16A34A);
      case 'count_reconciliation':
        return const Color(0xFF2563EB);
      case 'adjustment':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFF4B5563);
    }
  }

  String _formatEventType(String type) {
    final found = _eventTypes.firstWhere((e) => e['value'] == type, orElse: () => {'label': type});
    return found['label']!;
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
                      'Stock History & Ledger Audit',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Authoritative, immutable transaction log tracking all physical movements and inventory bucket changes.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _loadData,
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

          // Filters Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                // Location filter
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String?>(
                    initialValue: _selectedLocationId,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      labelStyle: GoogleFonts.inter(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Locations')),
                      ..._locations.map((loc) => DropdownMenuItem(value: loc.id, child: Text(loc.name))),
                    ],
                    onChanged: (val) {
                      setState(() => _selectedLocationId = val);
                      _loadData();
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Event Type filter
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedEventType,
                    decoration: InputDecoration(
                      labelText: 'Event Type',
                      labelStyle: GoogleFonts.inter(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    items: _eventTypes.map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedEventType = val);
                        _loadData();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // Search query
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search SKU, product, notes, actor...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val.trim());
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Ledger Table / Content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Text(
                            'Error: $_errorMessage',
                            style: GoogleFonts.inter(color: Colors.red),
                          ),
                        )
                      : _filteredEntries.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No inventory history entries found',
                                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF374151)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Transactions will appear here when inventory adjustments, physical counts, or movements occur.',
                                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                                  ),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 20,
                                  headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
                                  columns: [
                                    DataColumn(label: Text('Date / Time', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
                                    DataColumn(label: Text('Event', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
                                    DataColumn(label: Text('Product & SKU', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
                                    DataColumn(label: Text('Location', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
                                    DataColumn(label: Text('Available Δ', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
                                    DataColumn(label: Text('Damaged Δ', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
                                    DataColumn(label: Text('Total Physical Δ', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
                                    DataColumn(label: Text('Balance After', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
                                    DataColumn(label: Text('Notes / Reason', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
                                    DataColumn(label: Text('Actor', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 12))),
                                  ],
                                  rows: _filteredEntries.map((e) {
                                    final eventColor = _getEventColor(e.eventType);
                                    final dateStr = _formatDate(e.createdAt);

                                    return DataRow(
                                      cells: [
                                        DataCell(Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)))),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: eventColor.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _formatEventType(e.eventType),
                                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: eventColor),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(e.productName ?? 'Unknown Product', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
                                              Text(e.variantSku ?? '-', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280))),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(e.locationName ?? '-', style: GoogleFonts.inter(fontSize: 12))),
                                        DataCell(
                                          Text(
                                            '${e.availableDelta > 0 ? '+' : ''}${e.availableDelta}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: e.availableDelta > 0 ? const Color(0xFF16A34A) : (e.availableDelta < 0 ? const Color(0xFFDC2626) : const Color(0xFF6B7280)),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${e.damagedDelta > 0 ? '+' : ''}${e.damagedDelta}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: e.damagedDelta > 0 ? const Color(0xFFDC2626) : (e.damagedDelta < 0 ? const Color(0xFF16A34A) : const Color(0xFF6B7280)),
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '${e.quantityDelta > 0 ? '+' : ''}${e.quantityDelta}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: e.quantityDelta > 0 ? const Color(0xFF16A34A) : (e.quantityDelta < 0 ? const Color(0xFFDC2626) : const Color(0xFF6B7280)),
                                            ),
                                          ),
                                        ),
                                        DataCell(Text(e.balanceAfter != null ? '${e.balanceAfter}' : '-', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                                        DataCell(
                                          SizedBox(
                                            width: 180,
                                            child: Text(
                                              e.notes ?? (e.referenceType != null ? '${e.referenceType}: ${e.referenceId ?? ''}' : '-'),
                                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563)),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            e.actorName ?? (e.actorEmail ?? '-'),
                                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF374151)),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
