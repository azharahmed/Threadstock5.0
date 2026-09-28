// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/business/current_business_service.dart';
import '../../data/sales_repository.dart';
import '../../domain/models/sale.dart';
import '../active_sale_session.dart';

String formatHeldSaleAge(DateTime heldAt, [DateTime? now]) {
  final clock = now ?? DateTime.now();
  final localHeld = heldAt.toLocal();
  final localNow = clock.toLocal();
  final diff = localNow.difference(localHeld);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) {
    final mins = diff.inMinutes;
    return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
  }
  final heldDay = DateTime(localHeld.year, localHeld.month, localHeld.day);
  final today = DateTime(localNow.year, localNow.month, localNow.day);
  if (heldDay == today) {
    final hours = diff.inHours;
    return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
  }
  if (heldDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
  final days = today.difference(heldDay).inDays;
  return '$days ${days == 1 ? 'day' : 'days'} ago';
}

class HeldSalesView extends StatefulWidget {
  const HeldSalesView({super.key, this.onResumeOpened});

  final VoidCallback? onResumeOpened;

  @override
  State<HeldSalesView> createState() => _HeldSalesViewState();
}

class _HeldSalesViewState extends State<HeldSalesView> {
  final TextEditingController _searchController = TextEditingController();
  List<Sale> _sales = const [];
  bool _isLoading = true;
  String? _error;
  String _dateFilter = 'All';
  String _locationFilter = 'All';
  String _cashierFilter = 'All';
  String? _busySaleId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final businessId = await _businessId();
      if (businessId == null) {
        if (!mounted) return;
        setState(() {
          _sales = const [];
          _isLoading = false;
          _error = 'Select a business to see held sales.';
        });
        return;
      }
      final sales = await SalesRepository.instance.listHeldSales(businessId: businessId);
      if (!mounted) return;
      setState(() {
        _sales = sales;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<String?> _businessId() async {
    final current = CurrentBusinessService.instance.currentBusinessId;
    if (current != null && current.isNotEmpty && !current.startsWith('biz_')) {
      return current;
    }
    return SalesRepository.instance.resolveCurrentBusinessId();
  }

  List<Sale> get _visible {
    final query = _searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    return _sales.where((sale) {
      final held = (sale.heldAt ?? sale.createdAt ?? now).toLocal();
      if (_dateFilter == 'Today') {
        final day = DateTime(held.year, held.month, held.day);
        if (day != today) return false;
      } else if (_dateFilter == 'This Week') {
        if (held.isBefore(weekStart)) return false;
      }
      if (_locationFilter != 'All' && (sale.locationName ?? 'Location') != _locationFilter) {
        return false;
      }
      if (_cashierFilter != 'All' && (sale.heldByName ?? 'Staff') != _cashierFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      final haystack = [
        sale.saleNumber,
        sale.customerName ?? '',
        sale.customerPhone ?? '',
        sale.note ?? '',
        for (final item in sale.items) ...[
          item.productNameSnapshot,
          item.skuSnapshot,
        ],
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _resume(Sale sale) async {
    final session = ActiveSaleSession.instance;
    final sameHeldSale = session.heldSaleId == sale.id;
    if (session.hasItems && !sameHeldSale) {
      final choice = await showDialog<_CartConflictChoice>(
        context: context,
        builder: (context) => const _CartConflictDialog(),
      );
      if (!mounted || choice == null || choice == _CartConflictChoice.keep) return;
      if (choice == _CartConflictChoice.holdCurrent) {
        final held = await _holdCurrentSession();
        if (!held || !mounted) return;
      } else {
        session.clear();
      }
    }
    await _openHeldSale(sale);
  }

  Future<bool> _holdCurrentSession() async {
    final session = ActiveSaleSession.instance;
    final businessId = await _businessId();
    if (businessId == null) {
      _showMessage('Select a business before holding the current sale.');
      return false;
    }
    final result = await SalesRepository.instance.holdSale(
      businessId: businessId,
      locationId: session.locationId,
      customerId: session.customerId,
      customerName: session.customerName,
      customerPhone: session.customerPhone,
      saleId: session.heldSaleId,
      subtotal: session.subtotal,
      discount: session.discountAmount,
      discountType: session.discountType,
      discountRate: session.discountInput,
      tax: 0,
      total: session.total,
      currencyCode: CurrentBusinessService.instance.currentBusiness?.currencyCode ?? 'INR',
      note: session.note,
      items: session.itemPayload(),
    );
    if (!result.success) {
      _showMessage(result.errorMessage ?? 'Could not hold the current sale.');
      return false;
    }
    session.clear();
    return true;
  }

  Future<void> _openHeldSale(Sale sale) async {
    final businessId = await _businessId();
    if (businessId == null) return;
    setState(() => _busySaleId = sale.id);
    final result = await SalesRepository.instance.resumeHeldSale(
      businessId: businessId,
      saleId: sale.id,
    );
    if (!mounted) return;
    setState(() => _busySaleId = null);
    if (!result.success || result.sale == null) {
      _showMessage(result.errorMessage ?? 'Could not resume this held sale.');
      return;
    }
    ActiveSaleSession.instance.loadHeldSale(
      result.sale!,
      stockWarnings: result.stockWarnings,
      availableQtyByVariant: result.availableQtyByVariant,
    );
    widget.onResumeOpened?.call();
  }

  Future<void> _discard(Sale sale) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Discard held sale?',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This removes the saved cart and cannot be undone.',
          style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard Sale'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final businessId = await _businessId();
    if (businessId == null) return;
    final result = await SalesRepository.instance.discardHeldSale(
      businessId: businessId,
      saleId: sale.id,
    );
    if (!mounted) return;
    if (!result.success) {
      _showMessage(result.errorMessage ?? 'Could not discard this held sale.');
      return;
    }
    if (ActiveSaleSession.instance.heldSaleId == sale.id) {
      ActiveSaleSession.instance.clear();
    }
    await _load();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final locations = {
      'All',
      ..._sales.map((sale) => sale.locationName ?? 'Location'),
    }.toList();
    final cashiers = {
      'All',
      ..._sales.map((sale) => sale.heldByName ?? 'Staff'),
    }.toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        children: [
          Text(
            'Held Sales',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Saved carts waiting to be resumed. Holding a sale does not change stock.',
            style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search sale number, customer, phone, SKU, or product',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE7E5E4)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final filter in const ['All', 'Today', 'This Week'])
                ChoiceChip(
                  label: Text(filter),
                  selected: _dateFilter == filter,
                  onSelected: (_) => setState(() => _dateFilter = filter),
                ),
              _FilterMenu(
                label: 'Location',
                value: _locationFilter,
                options: locations,
                onChanged: (value) => setState(() => _locationFilter = value),
              ),
              _FilterMenu(
                label: 'Cashier',
                value: _cashierFilter,
                options: cashiers,
                onChanged: (value) => setState(() => _cashierFilter = value),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            _EmptyState(message: _error!)
          else if (visible.isEmpty)
            const _EmptyState(message: 'No held sales')
          else
            for (final sale in visible) _HeldSaleCard(
              sale: sale,
              isBusy: _busySaleId == sale.id,
              onResume: () => _resume(sale),
              onDiscard: () => _discard(sale),
            ),
        ],
      ),
    );
  }
}

class _HeldSaleCard extends StatelessWidget {
  const _HeldSaleCard({
    required this.sale,
    required this.isBusy,
    required this.onResume,
    required this.onDiscard,
  });

  final Sale sale;
  final bool isBusy;
  final VoidCallback onResume;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final heldAt = sale.heldAt ?? sale.createdAt ?? DateTime.now();
    final customer = (sale.customerName == null || sale.customerName!.trim().isEmpty)
        ? 'Walk-in'
        : sale.customerName!;
    final phone = sale.customerPhone;
    final itemCount = sale.items.fold<int>(0, (sum, item) => sum + item.quantity);
    final currency = sale.currencyCode == 'INR' ? '₹' : '${sale.currencyCode} ';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E5E4)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sale.saleNumber,
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                phone == null || phone.isEmpty ? customer : '$customer · $phone',
                style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF44403C)),
              ),
              const SizedBox(height: 8),
              Text(
                '$itemCount ${itemCount == 1 ? 'item' : 'items'} · $currency${sale.total.toStringAsFixed(2)}',
                style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                '${sale.locationName ?? 'Location'} · ${sale.heldByName ?? 'Staff'} · ${formatHeldSaleAge(heldAt)}',
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF78716C)),
              ),
            ],
          );
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: isBusy ? null : onDiscard,
                child: const Text('Discard'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: isBusy ? null : onResume,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF382718),
                ),
                child: isBusy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Resume'),
              ),
            ],
          );
          if (constraints.maxWidth < 720) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: details),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF78716C)),
        ),
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: options.contains(value) ? value : 'All',
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(option == 'All' ? '$label: All' : option),
          ),
      ],
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

enum _CartConflictChoice { keep, holdCurrent, discardCurrent }

class _CartConflictDialog extends StatelessWidget {
  const _CartConflictDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'You already have an active sale.',
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      content: Text(
        'What would you like to do?',
        style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, _CartConflictChoice.keep),
          child: const Text('Keep Current Sale'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _CartConflictChoice.holdCurrent),
          child: const Text('Hold Current & Resume'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _CartConflictChoice.discardCurrent),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF382718)),
          child: const Text('Discard Current & Resume'),
        ),
      ],
    );
  }
}
