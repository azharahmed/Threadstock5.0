import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../inventory/data/location_repository.dart';
import '../../../inventory/domain/models/stock_location.dart';

class TransferManifestItem {
  TransferManifestItem({
    required this.name,
    required this.categoryVariant,
    required this.sku,
    required this.imagePath,
    required this.srcAvailable,
    required this.transferQty,
    this.unit = 'units',
    this.isSelected = false,
  });

  final String name;
  final String categoryVariant;
  final String sku;
  final String imagePath;
  final int srcAvailable;
  int transferQty;
  final String unit;
  bool isSelected;
}

class NewStockTransferView extends StatefulWidget {
  const NewStockTransferView({
    super.key,
    this.onSaveDraft,
    this.onShipTransfer,
  });

  final VoidCallback? onSaveDraft;
  final VoidCallback? onShipTransfer;

  @override
  State<NewStockTransferView> createState() => _NewStockTransferViewState();
}

class _NewStockTransferViewState extends State<NewStockTransferView> {
  final LocationRepository _locationRepository = LocationRepository();
  List<StockLocation> _locations = [];
  bool _isLoadingLocations = true;

  String _fromLocation = '';
  String _toLocation = '';
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchManifestController =
      TextEditingController();

  final List<TransferManifestItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final locs = await _locationRepository.getLocations();
      if (!mounted) return;
      setState(() {
        _locations = locs;
        if (locs.isNotEmpty) {
          _fromLocation = locs.first.name;
          _toLocation = locs.length > 1 ? locs[1].name : locs.first.name;
        }
        _isLoadingLocations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingLocations = false);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _notesController.dispose();
    _searchManifestController.dispose();
    super.dispose();
  }

  int get _totalTransferUnits {
    return _items.fold(0, (sum, it) => sum + it.transferQty);
  }

  int get _totalStylesCount => _items.length;

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

          // 2. Main Two-Column Layout (Left ~68%, Right ~32%)
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    Expanded(
                      flex: 66,
                      child: Column(
                        children: [
                          _buildOriginDestinationCard(),
                          const SizedBox(height: 20),
                          _buildManifestCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right Column
                    Expanded(
                      flex: 34,
                      child: Column(
                        children: [
                          _buildSummaryCard(),
                          const SizedBox(height: 20),
                          _buildAiInsightsCard(),
                          const SizedBox(height: 20),
                          _buildShippingApprovalCard(),
                        ],
                      ),
                    ),
                  ],
                );
              }

              // Stacked on compact screen
              return Column(
                children: [
                  _buildOriginDestinationCard(),
                  const SizedBox(height: 20),
                  _buildManifestCard(),
                  const SizedBox(height: 20),
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  _buildAiInsightsCard(),
                  const SizedBox(height: 20),
                  _buildShippingApprovalCard(),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF4EB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.swap_horiz_rounded,
                size: 26,
                color: Color(0xFFB45309),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Stock Transfer',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Move physical inventory between warehouses or retail locations.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: _locations.length <= 1
                  ? null
                  : (widget.onSaveDraft ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Transfer draft saved successfully.',
                              ),
                              backgroundColor: Color(0xFF181513),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1F2937),
                disabledForegroundColor: const Color(0xFF9CA3AF),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Save Draft'),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: (_locations.length <= 1 || _items.isEmpty)
                  ? null
                  : (widget.onShipTransfer ??
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Stock transfer initiated and status updated to In-Transit!',
                              ),
                              backgroundColor: Color(0xFF181513),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF94A3B8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Ship Transfer'),
            ),
          ],
        ),
      ],
    );
  }

  // Left Card 1: Origin & Destination Details
  Widget _buildOriginDestinationCard() {
    final locationNames = _locations.isNotEmpty
        ? _locations.map((l) => l.name).toList()
        : ['No locations available'];
    final safeFrom = locationNames.contains(_fromLocation)
        ? _fromLocation
        : locationNames.first;
    final safeTo = locationNames.contains(_toLocation)
        ? _toLocation
        : locationNames.first;

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
            icon: Icons.location_on_outlined,
            title: 'Origin & Destination Details',
            subtitle:
                'Select source and destination locations with expected delivery details.',
          ),
          const SizedBox(height: 16),

          if (!_isLoadingLocations && _locations.length <= 1) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFFB45309),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Add another location before creating an inter-location transfer.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // From and To Locations
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('From Location', isRequired: true),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: safeFrom,
                      items: locationNames,
                      onChanged: (val) {
                        if (val != null) setState(() => _fromLocation = val);
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Source stock location',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('To Location', isRequired: true),
                    const SizedBox(height: 6),
                    _buildDropdown(
                      value: safeTo,
                      items: locationNames,
                      onChanged: (val) {
                        if (val != null) setState(() => _toLocation = val);
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Destination stock location',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Expected Delivery Date and Dispatch Notes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel(
                      'Expected Delivery Date',
                      isRequired: true,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _dateController,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF1F2937),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Dispatch Notes'),
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
                            controller: _notesController,
                            maxLines: 2,
                            maxLength: 200,
                            buildCounter:
                                (
                                  _, {
                                  required currentLength,
                                  required isFocused,
                                  maxLength,
                                }) => null,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF1F2937),
                            ),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(10),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8, bottom: 6),
                            child: Text(
                              '${_notesController.text.length}/200',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Left Card 2: Transfer Cargo Manifest
  Widget _buildManifestCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCardHeader(
                  icon: Icons.inventory_2_outlined,
                  title: 'Transfer Cargo Manifest',
                  subtitle: 'Add products and specify transfer quantities.',
                ),
                Row(
                  children: [
                    Container(
                      width: 180,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            size: 15,
                            color: Color(0xFF9CA3AF),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: TextField(
                              controller: _searchManifestController,
                              style: GoogleFonts.inter(fontSize: 12),
                              decoration: const InputDecoration(
                                hintText: 'Search or scan items...',
                                hintStyle: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 11.5,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 15,
                        color: Color(0xFFB45309),
                      ),
                      label: const Text('Add Items'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB45309),
                        side: const BorderSide(color: Color(0xFFD97706)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        textStyle: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: Icon(
                    Icons.check_box_outline_blank,
                    size: 16,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 38,
                  child: Text(
                    'Product',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  flex: 20,
                  child: Text(
                    'SKU',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  flex: 16,
                  child: Text(
                    'Src Available',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  flex: 14,
                  child: Text(
                    'Transfer Qty',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Text(
                    'Unit',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Table Rows
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      size: 36,
                      color: Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No items in transfer manifest',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add items to be transferred between locations.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final item in _items) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () =>
                          setState(() => item.isSelected = !item.isSelected),
                      child: SizedBox(
                        width: 20,
                        child: Icon(
                          item.isSelected
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank,
                          size: 16,
                          color: item.isSelected
                              ? const Color(0xFFB45309)
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Product thumbnail and info
                    Expanded(
                      flex: 38,
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset(
                              item.imagePath,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    width: 36,
                                    height: 36,
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(
                                      Icons.checkroom_rounded,
                                      size: 18,
                                      color: Color(0xFF94A3B8),
                                    ),
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  item.categoryVariant,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // SKU
                    Expanded(
                      flex: 20,
                      child: Text(
                        item.sku,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),

                    // Src Available
                    Expanded(
                      flex: 16,
                      child: Text(
                        '${item.srcAvailable} units',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),

                    // Transfer Qty (Editable input box)
                    Expanded(
                      flex: 14,
                      child: Container(
                        width: 54,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.transferQty}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),

                    // Unit
                    Expanded(
                      flex: 10,
                      child: Text(
                        item.unit,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ),

                    // Delete action
                    IconButton(
                      onPressed: () => setState(() => _items.remove(item)),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ],

          // Bottom Inventory Check Banner
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inventory Check',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                          Text(
                            'All selected items are available for transfer.',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Transfer Units',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      Text(
                        '$_totalTransferUnits units',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Right Card 1: Transfer Cargo Summary
  Widget _buildSummaryCard() {
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
            icon: Icons.inventory_2_outlined,
            title: 'Transfer Cargo Summary',
            subtitle: 'Overview of items in this transfer.',
          ),
          const SizedBox(height: 18),

          _buildSummaryRow(
            'Total Distinct Line Items',
            '$_totalStylesCount styles',
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildSummaryRow('Cumulative Units', '$_totalTransferUnits units'),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _buildSummaryRow('Estimated Cargo Value', '₹91,977'),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Logistics Carriage Priority',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF4B5563),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flight_takeoff_rounded,
                      size: 14,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Express Air',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: const Color(0xFF4B5563),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  // Right Card 2: AI Audit Insights
  Widget _buildAiInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: Color(0xFFB45309),
              ),
              const SizedBox(width: 8),
              Text(
                'AI AUDIT INSIGHTS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFB45309),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'ThreadStock AI will analyze demand spikes and recommend inter-location rebalancing once inventory transfers and sales history are established.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.45,
              color: const Color(0xFF451A03),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFFDE68A)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: const Text('View AI Insights →'),
          ),
        ],
      ),
    );
  }

  // Right Card 3: Shipping & Approval (Vertical Stepper)
  Widget _buildShippingApprovalCard() {
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
            title: 'Shipping & Approval',
            subtitle: 'Review and initiate the stock transfer.',
          ),
          const SizedBox(height: 20),

          // Stepper Items
          _buildStepRow(
            number: '1',
            title: 'Draft',
            subtitle: 'Create and verify transfer details',
            isCompletedOrActive: true,
            isLast: false,
          ),
          _buildStepRow(
            number: '2',
            title: 'Approval',
            subtitle: 'Manager approval (if required)',
            isCompletedOrActive: false,
            isLast: false,
          ),
          _buildStepRow(
            number: '3',
            title: 'Pick & Pack',
            subtitle: 'Prepare items for shipment',
            isCompletedOrActive: false,
            isLast: false,
          ),
          _buildStepRow(
            number: '4',
            title: 'Ship',
            subtitle: 'Generate transfer order and update inventory',
            isCompletedOrActive: false,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required String title,
    required String subtitle,
    required bool isCompletedOrActive,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompletedOrActive
                      ? const Color(0xFFD97706)
                      : Colors.white,
                  shape: BoxShape.circle,
                  border: isCompletedOrActive
                      ? null
                      : Border.all(color: const Color(0xFFD1D5DB)),
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isCompletedOrActive
                        ? Colors.white
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: const Color(0xFFE5E7EB),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
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
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                color: const Color(0xFF6B7280),
              ),
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
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF374151),
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
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
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF6B7280),
          ),
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.w500,
          ),
          items: items.map((it) {
            return DropdownMenuItem<String>(value: it, child: Text(it));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
