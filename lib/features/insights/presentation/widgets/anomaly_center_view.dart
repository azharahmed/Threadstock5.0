// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnomalyItemData {
  const AnomalyItemData({
    required this.id,
    required this.title,
    required this.description,
    required this.productName,
    required this.location,
    required this.timeAgo,
    required this.severityLabel,
    required this.severityColor,
    required this.severityBg,
    required this.iconData,
    required this.iconColor,
    required this.iconBg,
    required this.projectedLoss,
    required this.category,
    required this.detectedDate,
    required this.imageAsset,
    this.isNew = false,
  });

  final String id;
  final String title;
  final String description;
  final String productName;
  final String location;
  final String timeAgo;
  final String severityLabel;
  final Color severityColor;
  final Color severityBg;
  final IconData iconData;
  final Color iconColor;
  final Color iconBg;
  final String projectedLoss;
  final String category;
  final String detectedDate;
  final String imageAsset;
  final bool isNew;
}

class AnomalyCenterView extends StatefulWidget {
  const AnomalyCenterView({
    super.key,
    this.onNavigateToInventory,
    this.onNavigateToAutomations,
    this.onLaunchDeepInvestigation,
  });

  final VoidCallback? onNavigateToInventory;
  final VoidCallback? onNavigateToAutomations;
  final VoidCallback? onLaunchDeepInvestigation;

  @override
  State<AnomalyCenterView> createState() => _AnomalyCenterViewState();
}

class _AnomalyCenterViewState extends State<AnomalyCenterView> {
  String _selectedSeverity = 'All';
  String _selectedType = 'Discrepancies';
  String _selectedLocation = 'All Locations';
  String _selectedSort = 'Newest';
  int _currentPage = 1;
  String _selectedAnomalyId = 'TS-ANM-20948';

  final List<AnomalyItemData> _anomalies = const [
    AnomalyItemData(
      id: 'TS-ANM-20948',
      title: 'Shrinkage Spike Detected',
      description:
          'RFID system logged 12 missing physical units without a corresponding checkout sales transaction marker.',
      productName: 'Apparel Line Item (Standard / OS)',
      location: 'Flagship Store (Zone B)',
      timeAgo: '2 hours ago',
      severityLabel: 'HIGH',
      severityColor: Color(0xFFDC2626),
      severityBg: Color(0xFFFEE2E2),
      iconData: Icons.warning_amber_rounded,
      iconColor: Color(0xFFDC2626),
      iconBg: Color(0xFFFEE2E2),
      projectedLoss: '~ ₹84,000',
      category: 'Apparel',
      detectedDate: 'Sep 15, 2026, 08:12 AM',
      imageAsset: '',
      isNew: true,
    ),
    AnomalyItemData(
      id: 'TS-ANM-20941',
      title: 'Out-of-Trend Demand Anomaly',
      description:
          'Unusual velocity burst observed. Sales velocity is currently 3x above forecasted model expectations.',
      productName: 'Outerwear Line Item (Sand / L)',
      location: 'Flagship Boutique',
      timeAgo: '4 hours ago',
      severityLabel: 'MEDIUM',
      severityColor: Color(0xFFB45309),
      severityBg: Color(0xFFFEF3C7),
      iconData: Icons.trending_up_rounded,
      iconColor: Color(0xFFD97706),
      iconBg: Color(0xFFFEF3C7),
      projectedLoss: '~ ₹42,500',
      category: 'Outerwear',
      detectedDate: 'Sep 15, 2026, 06:30 AM',
      imageAsset: '',
    ),
    AnomalyItemData(
      id: 'TS-ANM-20935',
      title: 'Receiving Discrepancy',
      description:
          'Carton scan mismatch during intake. Expected 40 physical units but invoice bill of lading counted 36 units.',
      productName: 'Knitwear Line Item (Navy / M)',
      location: 'Warehouse Hub A',
      timeAgo: '1 day ago',
      severityLabel: 'LOW',
      severityColor: Color(0xFF2563EB),
      severityBg: Color(0xFFEFF6FF),
      iconData: Icons.info_outline_rounded,
      iconColor: Color(0xFF2563EB),
      iconBg: Color(0xFFEFF6FF),
      projectedLoss: '~ ₹18,200',
      category: 'Knitwear',
      detectedDate: 'Sep 14, 2026, 02:45 PM',
      imageAsset: '',
    ),
    AnomalyItemData(
      id: 'TS-ANM-20929',
      title: 'Price Mismatch Detected',
      description:
          'Supplier invoice price for 15 units is 22% higher than contracted rate.',
      productName: 'Apparel Item (White / M)',
      location: 'Secondary Hub',
      timeAgo: '1 day ago',
      severityLabel: 'HIGH',
      severityColor: Color(0xFFDC2626),
      severityBg: Color(0xFFFEE2E2),
      iconData: Icons.warning_amber_rounded,
      iconColor: Color(0xFFDC2626),
      iconBg: Color(0xFFFEE2E2),
      projectedLoss: '~ ₹26,400',
      category: 'Shirts',
      detectedDate: 'Sep 14, 2026, 11:15 AM',
      imageAsset: '',
    ),
    AnomalyItemData(
      id: 'TS-ANM-20914',
      title: 'Duplicate Stock Entry',
      description: 'Same GRN appears to be posted twice for 24 units.',
      productName: 'Knitwear Item (Grey / S)',
      location: 'Warehouse Hub A',
      timeAgo: '2 days ago',
      severityLabel: 'MEDIUM',
      severityColor: Color(0xFFB45309),
      severityBg: Color(0xFFFEF3C7),
      iconData: Icons.layers_outlined,
      iconColor: Color(0xFFD97706),
      iconBg: Color(0xFFFEF3C7),
      projectedLoss: '~ ₹34,800',
      category: 'Knitwear',
      detectedDate: 'Sep 13, 2026, 04:20 PM',
      imageAsset: '',
    ),
  ];

  AnomalyItemData get _selectedAnomaly {
    return _anomalies.firstWhere(
      (a) => a.id == _selectedAnomalyId,
      orElse: () => _anomalies.first,
    );
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF181513),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isStacked = constraints.maxWidth < 1050;

          if (isStacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildActiveAnomaliesList(),
                const SizedBox(height: 24),
                _buildQuickInspectionPanel(),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Active Anomalies List (~68% width)
              Expanded(flex: 68, child: _buildActiveAnomaliesList()),
              const SizedBox(width: 22),

              // Right Column: Quick Inspection Panel (~32% width)
              SizedBox(width: 370, child: _buildQuickInspectionPanel()),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 1. LEFT COLUMN: ACTIVE ANOMALIES LIST
  // ===========================================================================
  Widget _buildActiveAnomaliesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header: Title & Stat Badges
        _buildHeaderRow(),
        const SizedBox(height: 18),

        // Filter Controls Row
        _buildFilterControlsRow(),
        const SizedBox(height: 16),

        // Anomaly Cards
        ..._anomalies.map(_buildAnomalyCard),

        const SizedBox(height: 18),

        // Pagination Footer
        _buildPaginationFooter(),
      ],
    );
  }

  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Anomalies',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181513),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'AI-detected issues that need your attention.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),

        // 3 Summary Stat Capsules
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatCapsule('Active:', '8 Issues'),
            const SizedBox(width: 8),
            _buildStatCapsule('Resolved Today:', '3'),
            const SizedBox(width: 8),
            _buildStatCapsule('High Priority:', '2'),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCapsule(String label, String value) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: RichText(
          text: TextSpan(
            text: '$label ',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterControlsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterDropdown(
            label: 'Severity: $_selectedSeverity',
            options: const ['All', 'High', 'Medium', 'Low'],
            onSelected: (val) => setState(() => _selectedSeverity = val),
          ),
          const SizedBox(width: 10),
          _buildFilterDropdown(
            label: 'Type: $_selectedType',
            options: const [
              'Discrepancies',
              'Price Mismatch',
              'Shrinkage',
              'Demand Velocity',
            ],
            onSelected: (val) => setState(() => _selectedType = val),
          ),
          const SizedBox(width: 10),
          _buildFilterDropdown(
            label: 'Location: $_selectedLocation',
            options: const [
              'All Locations',
              'Warehouse Hub A',
              'Flagship Store',
              'Mumbai Hub',
            ],
            onSelected: (val) => setState(() => _selectedLocation = val),
          ),
          const SizedBox(width: 10),
          _buildFilterDropdown(
            label: 'Sort by: $_selectedSort',
            options: const ['Newest', 'Highest Loss', 'Severity', 'Oldest'],
            onSelected: (val) => setState(() => _selectedSort = val),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 38),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      onSelected: onSelected,
      itemBuilder: (context) => options
          .map(
            (opt) => PopupMenuItem<String>(
              value: opt,
              height: 36,
              child: Text(
                opt,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF181513),
                ),
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 17,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyCard(AnomalyItemData item) {
    final isSelected = _selectedAnomalyId == item.id;

    return InkWell(
      onTap: () {
        setState(() => _selectedAnomalyId = item.id);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFDFD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF87171)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.03 : 0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Leading Icon Container
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(item.iconData, size: 21, color: item.iconColor),
              ),
            ),
            const SizedBox(width: 14),

            // Content Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Badges Row
                  Row(
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      if (item.isNew) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'New',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.severityBg,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          item.severityLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: item.severityColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Description
                  Text(
                    item.description,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bottom Metadata
                  Row(
                    children: [
                      Text(
                        'Product: ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        item.productName,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Location: ',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        item.location,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        item.timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Trailing Chevron
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing 1–5 of 8 anomalies',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPageNavButton(
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
              onTap: () {
                if (_currentPage > 1) setState(() => _currentPage = 1);
              },
            ),
            const SizedBox(width: 6),
            _buildPageNumberButton(
              page: 1,
              isSelected: _currentPage == 1,
              onTap: () => setState(() => _currentPage = 1),
            ),
            const SizedBox(width: 6),
            _buildPageNumberButton(
              page: 2,
              isSelected: _currentPage == 2,
              onTap: () => setState(() => _currentPage = 2),
            ),
            const SizedBox(width: 6),
            _buildPageNavButton(
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF64748B),
              ),
              onTap: () {
                if (_currentPage < 2) setState(() => _currentPage = 2);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPageNumberButton({
    required int page,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB45309) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: isSelected
              ? null
              : Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(
          child: Text(
            '$page',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageNavButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Center(child: child),
      ),
    );
  }

  // ===========================================================================
  // 2. RIGHT COLUMN: QUICK INSPECTION PANEL
  // ===========================================================================
  Widget _buildQuickInspectionPanel() {
    final item = _selectedAnomaly;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Quick Inspection & Close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quick Inspection',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                ),
              ),
              InkWell(
                onTap: () => _showNotification('Inspection panel minimized.'),
                borderRadius: BorderRadius.circular(16),
                child: const Icon(
                  Icons.cancel_outlined,
                  size: 19,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Product Thumbnail & Anomaly ID
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFFF8FAFC),
                  child: Image.asset(
                    item.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Icon(
                        Icons.checkroom_rounded,
                        size: 28,
                        color: Color(0xFFBA8A55),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.replaceAll(' Detected', ''),
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${item.id}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Metadata Table
          _buildInspectionMetaRow(
            'Severity',
            item.severityLabel,
            isSeverity: true,
            statusValue: 'Open',
          ),
          const SizedBox(height: 10),
          _buildInspectionMetaRow('Detected', item.detectedDate),
          const SizedBox(height: 10),
          _buildInspectionMetaRow('Location', item.location),
          const SizedBox(height: 10),
          _buildInspectionMetaRow('Product', item.productName),
          const SizedBox(height: 10),
          _buildInspectionMetaRow('Category', item.category),
          const SizedBox(height: 18),

          // Projected Financial Loss Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Projected Financial Loss',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.projectedLoss,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFDC2626),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Risk Context Assessment
          Text(
            'Risk Context Assessment',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The system detected multiple consecutive stock decreases during high footfall hours without checkout matching scans. Highly likely an intake logging skip or a retail floor theft cluster.',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons
          // 1. Launch Deep Investigation
          InkWell(
            onTap: () {
              if (widget.onLaunchDeepInvestigation != null) {
                widget.onLaunchDeepInvestigation!();
              } else {
                _showNotification(
                  'Deep investigation launched for ${item.id}.',
                );
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF181513),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Launch Deep Investigation',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Mute Anomaly Alert
          InkWell(
            onTap: () =>
                _showNotification('Anomaly alert muted for ${item.id}.'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.notifications_off_outlined,
                    size: 16,
                    color: Color(0xFF181513),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Mute Anomaly Alert',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 3. View Related Transactions
          InkWell(
            onTap: () => _showNotification(
              'Opening transactions matching ${item.productName}.',
            ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.description_outlined,
                    size: 16,
                    color: Color(0xFF181513),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'View Related Transactions',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Bottom AI Insight Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A), width: 1.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: Color(0xFFB45309),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Insight',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Similar shrinkage patterns were observed 3 times in the last 30 days at this location. Consider reviewing CCTV footage and staff access logs.',
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () => _showNotification(
                    'Opening full AI mitigation recommendations.',
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View AI Recommendations',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: Color(0xFFB45309),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectionMetaRow(
    String label,
    String value, {
    bool isSeverity = false,
    String? statusValue,
  }) {
    if (isSeverity) {
      return Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
          if (statusValue != null) ...[
            const Spacer(),
            Text(
              'Status   ',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
            ),
            Text(
              statusValue,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF181513),
            ),
          ),
        ),
      ],
    );
  }
}
