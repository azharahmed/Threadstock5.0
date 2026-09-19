// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AiActionCardData {
  const AiActionCardData({
    required this.id,
    required this.title,
    required this.description,
    required this.proposalType,
    required this.proposalTypeBg,
    required this.proposalTypeColor,
    required this.confidenceBadge,
    required this.confidenceBadgeBg,
    required this.confidenceBadgeColor,
    required this.confidenceScore,
    required this.confidenceScoreColor,
    required this.potentialImpact,
    required this.imageAsset,
    required this.dataCapsules,
    this.isHighlighted = false,
    this.isPrimaryApprove = false,
  });

  final String id;
  final String title;
  final String description;
  final String proposalType;
  final Color proposalTypeBg;
  final Color proposalTypeColor;
  final String confidenceBadge;
  final Color confidenceBadgeBg;
  final Color confidenceBadgeColor;
  final String confidenceScore;
  final Color confidenceScoreColor;
  final String potentialImpact;
  final String imageAsset;
  final List<String> dataCapsules;
  final bool isHighlighted;
  final bool isPrimaryApprove;
}

class AiActionsView extends StatefulWidget {
  const AiActionsView({
    super.key,
    this.onAskThreadStockAi,
    this.onReviewAction,
  });

  final VoidCallback? onAskThreadStockAi;
  final ValueChanged<String>? onReviewAction;

  @override
  State<AiActionsView> createState() => _AiActionsViewState();
}

class _AiActionsViewState extends State<AiActionsView> {
  int _selectedTabIndex = 1; // 0: All, 1: Awaiting Review, 2: Approved, 3: Rejected, 4: Completed
  final Set<String> _checkedActionIds = {};

  String _selectedLocation = 'Location';
  String _selectedActionType = 'Action Type';
  String _selectedRiskLevel = 'Risk Level';
  String _selectedPreparedDate = 'Prepared Date';

  final List<AiActionCardData> _actions = const [
    AiActionCardData(
      id: 'ACT-01',
      title: 'Replenish Silk Scarves (Scarlet / OS)',
      description:
          'Current stock will fall below 14 days. Suggested transit via Vrindavan Express cargo.',
      proposalType: 'REPLENISHMENT PROPOSAL',
      proposalTypeBg: Color(0xFFFEF3C7),
      proposalTypeColor: Color(0xFFB45309),
      confidenceBadge: 'High Confidence',
      confidenceBadgeBg: Color(0xFFECFDF5),
      confidenceBadgeColor: Color(0xFF059669),
      confidenceScore: '94.2% (High)',
      confidenceScoreColor: Color(0xFF059669),
      potentialImpact: '₹84,000',
      imageAsset: 'Assets/silk_scarves.jpg',
      dataCapsules: [
        'Current: 12 units',
        'Recommended: 120 units',
        'ETA: 5 days',
        'Fill Rate: 98%',
      ],
      isHighlighted: true,
      isPrimaryApprove: true,
    ),
    AiActionCardData(
      id: 'ACT-02',
      title: 'Transfer Classic White Oxford (M)',
      description:
          'Surplus 220 units at Delhi Hub. Suggested transfer to Mumbai Hub.',
      proposalType: 'TRANSFER SUGGESTION',
      proposalTypeBg: Color(0xFFEFF6FF),
      proposalTypeColor: Color(0xFF2563EB),
      confidenceBadge: 'High Confidence',
      confidenceBadgeBg: Color(0xFFFEF3C7),
      confidenceBadgeColor: Color(0xFFB45309),
      confidenceScore: '91.6% (High)',
      confidenceScoreColor: Color(0xFF059669),
      potentialImpact: '₹52,000',
      imageAsset: 'Assets/oxford_linen_shirt.jpg',
      dataCapsules: [
        'Transfer: 100 units',
        'From: Delhi (Zone B)',
        'To: Mumbai (Zone C)',
        'ETA: 3 days',
      ],
    ),
    AiActionCardData(
      id: 'ACT-03',
      title: 'Adjust Purchase Plan – Merino Wool Blazer (Navy / L)',
      description:
          'Forecast indicates 30% lower demand next month. Consider reducing PO quantity.',
      proposalType: 'DEMAND OPTIMIZATION',
      proposalTypeBg: Color(0xFFFEE2E2),
      proposalTypeColor: Color(0xFFDC2626),
      confidenceBadge: 'Medium Confidence',
      confidenceBadgeBg: Color(0xFFFEF3C7),
      confidenceBadgeColor: Color(0xFFB45309),
      confidenceScore: '78.4% (Medium)',
      confidenceScoreColor: Color(0xFFD97706),
      potentialImpact: '₹36,000',
      imageAsset: 'Assets/merino_wool_blazer.jpg',
      dataCapsules: [
        'Current PO: 200 units',
        'Suggested: 140 units',
        'Reduction: 60 units',
        'Savings: ₹36,000',
      ],
    ),
    AiActionCardData(
      id: 'ACT-04',
      title: 'Switch Supplier – Linen Trousers (Sand / 32)',
      description:
          'Alternative supplier offers 12% lower price with same quality.',
      proposalType: 'PRICE OPPORTUNITY',
      proposalTypeBg: Color(0xFFF3E8FF),
      proposalTypeColor: Color(0xFF9333EA),
      confidenceBadge: 'High Confidence',
      confidenceBadgeBg: Color(0xFFECFDF5),
      confidenceBadgeColor: Color(0xFF059669),
      confidenceScore: '89.1% (High)',
      confidenceScoreColor: Color(0xFF059669),
      potentialImpact: '₹48,000',
      imageAsset: 'Assets/raw_denim_jeans.jpg',
      dataCapsules: [
        'Current: ₹1,200',
        'Suggested: ₹1,056',
        'Savings: 12%',
        'Annual Impact: ₹48,000',
      ],
    ),
    AiActionCardData(
      id: 'ACT-05',
      title: 'Run Markdown – Winter Collection',
      description:
          '12 SKUs with < 15 days projected coverage. Recommend 20% markdown.',
      proposalType: 'SLOW MOVING ALERT',
      proposalTypeBg: Color(0xFFFEE2E2),
      proposalTypeColor: Color(0xFFDC2626),
      confidenceBadge: 'Medium Confidence',
      confidenceBadgeBg: Color(0xFFFEF3C7),
      confidenceBadgeColor: Color(0xFFB45309),
      confidenceScore: '76.3% (Medium)',
      confidenceScoreColor: Color(0xFFD97706),
      potentialImpact: '₹72,000',
      imageAsset: 'Assets/cashmere_sweater.jpg',
      dataCapsules: [
        'Affected SKUs: 12',
        'Est. Clearance: 45 days',
        'Revenue Recovery: ₹72,000',
      ],
    ),
  ];

  void _showNotification(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
              color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF181513),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row
          _buildHeaderRow(),
          const SizedBox(height: 18),

          // 2. KPI 3-Cards Row
          _buildKpiCardsRow(),
          const SizedBox(height: 20),

          // 3. Filter Tabs & Dropdowns Row
          _buildFilterRow(),
          const SizedBox(height: 18),

          // 4. Action Cards List
          ..._actions.map(_buildActionCard),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER ROW
  // ===========================================================================
  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Actions',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181513),
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Review replenishment, transfer, and optimization work prepared by ThreadStock AI.',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),

        // Ask ThreadStock AI Button
        InkWell(
          onTap: () {
            if (widget.onAskThreadStockAi != null) {
              widget.onAskThreadStockAi!();
            } else {
              _showNotification('ThreadStock AI assistant ready to optimize inventory.');
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFFB45309),
                ),
                const SizedBox(width: 8),
                Text(
                  'Ask ThreadStock AI',
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
      ],
    );
  }

  // ===========================================================================
  // 2. KPI 3-CARDS ROW
  // ===========================================================================
  Widget _buildKpiCardsRow() {
    return Row(
      children: [
        // Card 1: Awaiting Review
        Expanded(
          child: _buildKpiCard(
            icon: Icons.assignment_outlined,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFB45309),
            label: 'Awaiting Review',
            value: '5 actions',
            subLabel: 'Requires sign-off',
            subColor: const Color(0xFFB45309),
          ),
        ),
        const SizedBox(width: 14),

        // Card 2: Approved Today
        Expanded(
          child: _buildKpiCard(
            icon: Icons.check_circle_outline_rounded,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF059669),
            label: 'Approved Today',
            value: '3 Approved',
            subLabel: '↑ 100% execution',
            subColor: const Color(0xFF16A34A),
          ),
        ),
        const SizedBox(width: 14),

        // Card 3: Potential Revenue Impact
        Expanded(
          child: _buildKpiCard(
            icon: Icons.bar_chart_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFB45309),
            label: 'Potential Revenue Impact',
            value: '₹1,84,000',
            subLabel: 'Sales protected',
            subColor: const Color(0xFF2563EB),
            showInfoIcon: true,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String value,
    required String subLabel,
    required Color subColor,
    bool showInfoIcon = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(icon, size: 20, color: iconColor),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (showInfoIcon) ...[
                      Icon(
                        Icons.info_outline_rounded,
                        size: 13,
                        color: subColor,
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      subLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. FILTER TABS & DROPDOWNS ROW
  // ===========================================================================
  Widget _buildFilterRow() {
    final tabs = [
      'All (12)',
      'Awaiting Review (5)',
      'Approved (3)',
      'Rejected (1)',
      'Completed (3)',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tabs
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(tabs.length, (idx) {
            final isSelected = _selectedTabIndex == idx;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedTabIndex = idx),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF181513) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected ? null : Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    tabs[idx],
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        // Dropdowns on Right
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSmallDropdown(
              label: _selectedLocation,
              options: const ['Location', 'All Locations', 'Central Warehouse (Zone A)', 'Flagship Delhi (Zone B)', 'Mumbai Hub'],
              onSelected: (val) => setState(() => _selectedLocation = val),
            ),
            const SizedBox(width: 8),
            _buildSmallDropdown(
              label: _selectedActionType,
              options: const ['Action Type', 'All Types', 'Replenishment', 'Transfer', 'Demand Optimization', 'Price Opportunity', 'Markdown'],
              onSelected: (val) => setState(() => _selectedActionType = val),
            ),
            const SizedBox(width: 8),
            _buildSmallDropdown(
              label: _selectedRiskLevel,
              options: const ['Risk Level', 'All Risk', 'High Confidence', 'Medium Confidence', 'Low Risk'],
              onSelected: (val) => setState(() => _selectedRiskLevel = val),
            ),
            const SizedBox(width: 8),
            _buildSmallDropdown(
              label: _selectedPreparedDate,
              options: const ['Prepared Date', 'Today', 'Last 7 Days', 'Last 30 Days'],
              onSelected: (val) => setState(() => _selectedPreparedDate = val),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallDropdown({
    required String label,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      onSelected: onSelected,
      itemBuilder: (context) => options
          .map(
            (opt) => PopupMenuItem(
              value: opt,
              height: 34,
              child: Text(opt, style: GoogleFonts.inter(fontSize: 12.5)),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 15,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. ACTION CARD
  // ===========================================================================
  Widget _buildActionCard(AiActionCardData item) {
    final isChecked = _checkedActionIds.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: item.isHighlighted ? const Color(0xFFFFFDF9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isHighlighted ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: item.isHighlighted ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(item.isHighlighted ? 0.025 : 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SizedBox(
              width: 18,
              height: 18,
              child: Checkbox(
                value: isChecked,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _checkedActionIds.add(item.id);
                    } else {
                      _checkedActionIds.remove(item.id);
                    }
                  });
                },
                activeColor: const Color(0xFFB45309),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Product Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 64,
              height: 64,
              color: const Color(0xFFF8FAFC),
              child: Image.asset(
                item.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFFAF3E8),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.checkroom_rounded,
                    size: 24,
                    color: Color(0xFFBA8A55),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Center Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badges Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.proposalTypeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.proposalType,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: item.proposalTypeColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: item.confidenceBadgeBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.confidenceBadge,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: item.confidenceBadgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Title
                Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 3),

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
                const SizedBox(height: 10),

                // Data Capsules
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: item.dataCapsules
                      .map(
                        (cap) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            cap,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),

          // Right Side: Confidence, Impact, Action Button, More Menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Confidence Indicator
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 13,
                    color: item.confidenceScoreColor,
                  ),
                  const SizedBox(width: 5),
                  RichText(
                    text: TextSpan(
                      text: 'Confidence ',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                      ),
                      children: [
                        TextSpan(
                          text: item.confidenceScore,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: item.confidenceScoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Potential Impact
              Text(
                'Potential Impact',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.potentialImpact,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              // Action Buttons & More Icon
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.isPrimaryApprove)
                    InkWell(
                      onTap: () {
                        if (widget.onReviewAction != null) {
                          widget.onReviewAction!(item.id);
                        } else {
                          _showNotification('Action ${item.id} approved & dispatched.');
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF181513),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Review & Approve',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    InkWell(
                      onTap: () {
                        if (widget.onReviewAction != null) {
                          widget.onReviewAction!(item.id);
                        } else {
                          _showNotification('Opening review modal for ${item.title}.');
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          'Review',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    offset: const Offset(0, 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    color: Colors.white,
                    onSelected: (action) {
                      _showNotification('Action "$action" executed on ${item.id}.');
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'dismiss',
                        height: 34,
                        child: Text('Dismiss Recommendation', style: GoogleFonts.inter(fontSize: 12.5)),
                      ),
                      PopupMenuItem(
                        value: 'snooze',
                        height: 34,
                        child: Text('Snooze (24h)', style: GoogleFonts.inter(fontSize: 12.5)),
                      ),
                      PopupMenuItem(
                        value: 'view_details',
                        height: 34,
                        child: Text('View Full Context', style: GoogleFonts.inter(fontSize: 12.5)),
                      ),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
