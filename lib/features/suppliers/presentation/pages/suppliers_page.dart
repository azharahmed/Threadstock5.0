// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';
import '../widgets/partner_directory_view.dart';

enum SuppliersViewMode {
  directory,
  profile,
}

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({
    super.key,
    this.initialMode = SuppliersViewMode.directory,
    this.supplierId = 'SUP-00125',
    this.supplierName = 'Milano Tessuti',
    this.onNavigateToPo,
    this.onTitleChanged,
  });

  final SuppliersViewMode initialMode;
  final String supplierId;
  final String supplierName;
  final ValueChanged<String>? onNavigateToPo;
  final ValueChanged<String>? onTitleChanged;

  @override
  State<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends State<SuppliersPage> {
  late SuppliersViewMode _mode;
  late String _currentSupplierName;
  int _selectedTab = 0; // 0: Overview, 1: Purchase Orders, 2: Products, 3: Documents, 4: Compliance, 5: Activity Log

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _currentSupplierName = widget.supplierName;
  }

  @override
  void didUpdateWidget(covariant SuppliersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      _mode = widget.initialMode;
    }
    if (oldWidget.supplierName != widget.supplierName) {
      _currentSupplierName = widget.supplierName;
    }
  }

  final List<String> _tabs = [
    'Overview',
    'Purchase Orders (12)',
    'Products (45)',
    'Documents (8)',
    'Compliance',
    'Activity Log',
  ];

  void _showMessageModal() {
    final msgController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF4EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.mail_outline_rounded, color: Color(0xFF92400E), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Message ${widget.supplierName}',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To: Giovanni Rossi (giovanni.rossi@milanotessuti.it)',
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your message or delivery inquiry here...',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9CA3AF)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Message sent to ${widget.supplierName}.'),
                  backgroundColor: const Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }

  void _showAiInsightsModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'AI Supplier Performance Review',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFFB45309), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Milano Tessuti ranks in the 98th percentile for luxury textile mill reliability across EMEA partners.',
                        style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF78350F), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildInsightRow(
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF16A34A),
                title: 'Volume Optimization Potential',
                desc: 'Consolidating Q2 linen yarn orders by +15% qualifies ThreadStock for a tier-2 manufacturer discount (€4.20/meter rebate).',
              ),
              const SizedBox(height: 12),
              _buildInsightRow(
                icon: Icons.access_time_rounded,
                color: const Color(0xFF2563EB),
                title: 'Logistics Route Efficiency',
                desc: 'Current Genoa Port sea-air freight is tracking 2.4 days faster than historical North Italian averages.',
              ),
              const SizedBox(height: 12),
              _buildInsightRow(
                icon: Icons.shield_outlined,
                color: const Color(0xFFD97706),
                title: 'Quality & Defect Rate: 0.18%',
                desc: 'Only 1 minor seal discrepancy across the last 12 shipments with zero returned fabric rolls.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightRow({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF4B5563), height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == SuppliersViewMode.directory) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DesktopContentConstraint(
          verticalPadding: 16,
          child: PartnerDirectoryView(
            onViewFullProfile: (partner) {
              setState(() {
                _currentSupplierName = partner.name;
                _mode = SuppliersViewMode.profile;
                widget.onTitleChanged?.call(partner.name);
              });
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 16,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back to Partner Directory
              InkWell(
                onTap: () {
                  setState(() {
                    _mode = SuppliersViewMode.directory;
                    widget.onTitleChanged?.call('Partner Directory');
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_rounded, size: 16, color: Color(0xFFB45309)),
                      const SizedBox(width: 6),
                      Text(
                        'Back to Partner Directory',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 1. Header with MT Avatar, title, subtitle & action buttons
              _buildProfileHeader(),
              const SizedBox(height: 20),

              // 2. Navigation Tabs Row
              _buildTabsRow(),
              const SizedBox(height: 24),

              // 3. Top 4 Metric KPI Cards
              _buildMetricCardsRow(),
              const SizedBox(height: 24),

              // 4. Main 2-Column Section
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1060;

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (~58%)
                        Expanded(
                          flex: 58,
                          child: Column(
                            children: [
                              _buildTermsAndLogisticsCard(),
                              const SizedBox(height: 20),
                              _buildContactInfoCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Right Column (~42%)
                        Expanded(
                          flex: 42,
                          child: Column(
                            children: [
                              _buildActivePurchaseOrdersCard(),
                              const SizedBox(height: 20),
                              _buildRecentActivityCard(),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Stacked for narrow viewports
                  return Column(
                    children: [
                      _buildTermsAndLogisticsCard(),
                      const SizedBox(height: 20),
                      _buildContactInfoCard(),
                      const SizedBox(height: 20),
                      _buildActivePurchaseOrdersCard(),
                      const SizedBox(height: 20),
                      _buildRecentActivityCard(),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // 5. Bottom AI Supplier Insights Banner
              _buildAiInsightsBanner(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Profile Header
  Widget _buildProfileHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Avatar + Titles
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular Avatar "MT"
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF4EB),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                'MT',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Title, Badge & Subtitle
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _currentSupplierName,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        'Preferred Network',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Milan, Italy  •  Fabrics & Linens  •  SUP-00125  •  Active since 2019',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Right: Action Buttons
        Row(
          children: [
            // Send Message
            OutlinedButton.icon(
              onPressed: _showMessageModal,
              icon: const Icon(Icons.mail_outline_rounded, size: 16),
              label: const Text('Send Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 10),

            // Edit Supplier
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Supplier profile editor active.'),
                    backgroundColor: Color(0xFF181513),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Supplier'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 10),

            // + New Purchase Order
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening Purchase Order creator for Milano Tessuti...'),
                    backgroundColor: Color(0xFF181513),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Purchase Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                textStyle: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Navigation Tabs Row
  Widget _buildTabsRow() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: List.generate(_tabs.length, (idx) {
          final isSelected = _selectedTab == idx;
          return InkWell(
            onTap: () => setState(() => _selectedTab = idx),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isSelected ? const Color(0xFFB45309) : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                _tabs[idx],
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? const Color(0xFFB45309) : const Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // 3. Top 4 Metric KPI Cards
  Widget _buildMetricCardsRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;
        final card1 = _buildMetricCard(
          icon: Icons.local_shipping_outlined,
          title: 'On-Time Delivery',
          value: '94.2%',
          trendText: '↑ 2.1%',
          badgeText: 'Healthy',
          badgeBg: const Color(0xFFDCFCE7),
          badgeColor: const Color(0xFF15803D),
        );
        final card2 = _buildMetricCard(
          icon: Icons.access_time_rounded,
          title: 'Avg Lead Time',
          value: '18 Days',
          trendText: '↓ 3 days',
          badgeText: 'On Track',
          badgeBg: const Color(0xFFEFF6FF),
          badgeColor: const Color(0xFF2563EB),
        );
        final card3 = _buildMetricCard(
          icon: Icons.shield_outlined,
          title: 'Quality Score',
          value: '4.8 / 5.0',
          trendText: '↑ 0.2',
          badgeText: 'Excellent',
          badgeBg: const Color(0xFFDCFCE7),
          badgeColor: const Color(0xFF15803D),
        );
        final card4 = _buildMetricCard(
          icon: Icons.bar_chart_rounded,
          title: 'Total Volume (YTD)',
          value: '₹12.4L',
          trendText: '↑ 18%',
          badgeText: 'Managed',
          badgeBg: const Color(0xFFEFF6FF),
          badgeColor: const Color(0xFF2563EB),
        );

        if (isCompact) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 14),
                  Expanded(child: card2),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: card3),
                  const SizedBox(width: 14),
                  Expanded(child: card4),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 16),
            Expanded(child: card2),
            const SizedBox(width: 16),
            Expanded(child: card3),
            const SizedBox(width: 16),
            Expanded(child: card4),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String trendText,
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBF4EB),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF92400E), size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: badgeColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w400, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                trendText,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Terms & Logistics Card
  Widget _buildTermsAndLogisticsCard() {
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_shipping_outlined, color: Color(0xFF92400E), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Terms & Logistics',
                    style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(0, 28),
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Content Row: Key-Values on Left, Map & Flight on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Key-Values
              Expanded(
                flex: 55,
                child: Column(
                  children: [
                    _buildKeyValueRow('Payment Terms', 'Net 30'),
                    const SizedBox(height: 12),
                    _buildKeyValueRow('Minimum Order Quantity (MOQ)', '50 Meters'),
                    const SizedBox(height: 12),
                    _buildKeyValueRow('Primary Shipping Hub', 'Genoa Port, Italy'),
                    const SizedBox(height: 12),
                    _buildKeyValueRow('Incoterms', 'FOB Genoa'),
                    const SizedBox(height: 12),
                    _buildKeyValueRow('Preferred Carriers', 'DHL, Maersk'),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Right: Map & International Shipping Info
              Expanded(
                flex: 45,
                child: Column(
                  children: [
                    // Stylized Map Card
                    Container(
                      height: 84,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBF8F3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEDE5D8)),
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFB45309), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Milan, Italy',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Ships internationally Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.flight_takeoff_rounded, color: Color(0xFFB45309), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ships internationally',
                                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Lead time: 12–18 days',
                                  style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
                                ),
                              ],
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

  // 5. Contact Information Card
  Widget _buildContactInfoCard() {
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded, color: Color(0xFF92400E), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Contact Information',
                    style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(0, 28),
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                child: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Content Row: Key-Values on Left, Quote Box on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Key-Values
              Expanded(
                flex: 55,
                child: Column(
                  children: [
                    _buildKeyValueRow('Primary Contact', 'Giovanni Rossi'),
                    const SizedBox(height: 12),
                    _buildKeyValueRow('Email', 'giovanni.rossi@milanotessuti.it', isLink: true),
                    const SizedBox(height: 12),
                    _buildKeyValueRow('Phone', '+39 02 4859 201'),
                    const SizedBox(height: 12),
                    _buildKeyValueRow('HQ Address', 'Via della Spiga 12, Milan, Italy'),
                    const SizedBox(height: 12),
                    _buildKeyValueRow('Website', 'www.milanotessuti.it', isLink: true, showExternalIcon: true),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Right: Quote Callout Box
              Expanded(
                flex: 45,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 38,
                          height: 0.8,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Premium fabrics for a more sustainable tomorrow.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF374151),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '— Milano Tessuti',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String label, String value, {bool isLink = false, bool showExternalIcon = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isLink ? FontWeight.w500 : FontWeight.w600,
                    color: isLink ? const Color(0xFF1E293B) : const Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (showExternalIcon) ...[
                const SizedBox(width: 4),
                const Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFF6B7280)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // 6. Active Purchase Orders Card
  Widget _buildActivePurchaseOrdersCard() {
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, color: Color(0xFF92400E), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Active Purchase Orders',
                    style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _selectedTab = 1),
                child: Text(
                  'View All POs →',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // PO Item 1: PO-2024-0847
          _buildPoRow(
            poNumber: 'PO-2024-0847',
            date: 'Feb 15, 2027',
            items: 'Silk Blend Premium, Wool Yarn',
            amount: '₹4,85,000',
            status: 'In Transit',
            statusBg: const Color(0xFFEFF6FF),
            statusColor: const Color(0xFF2563EB),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // PO Item 2: PO-2024-0792
          _buildPoRow(
            poNumber: 'PO-2024-0792',
            date: 'Feb 12, 2027',
            items: 'Heavy Twill Linens, Buttons',
            amount: '₹2,10,000',
            status: 'Arrived',
            statusBg: const Color(0xFFDCFCE7),
            statusColor: const Color(0xFF15803D),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),

          // PO Item 3: PO-2024-0610
          _buildPoRow(
            poNumber: 'PO-2024-0610',
            date: 'Jan 28, 2027',
            items: 'Spring Cashmere Threads',
            amount: '₹8,45,000',
            status: 'Completed',
            statusBg: const Color(0xFFDCFCE7),
            statusColor: const Color(0xFF15803D),
          ),
        ],
      ),
    );
  }

  Widget _buildPoRow({
    required String poNumber,
    required String date,
    required String items,
    required String amount,
    required String status,
    required Color statusBg,
    required Color statusColor,
  }) {
    return InkWell(
      onTap: () => widget.onNavigateToPo?.call(poNumber),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      poNumber,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                    ),
                    Text(
                      amount,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          date,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          items,
                          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        status,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF9CA3AF)),
        ],
      ),
    );
  }

  // 7. Recent Activity Card
  Widget _buildRecentActivityCard() {
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, color: Color(0xFF92400E), size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Recent Activity',
                    style: GoogleFonts.inter(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _selectedTab = 5),
                child: Text(
                  'View All →',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: const Color(0xFFB45309)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildActivityTimelineItem(
            dotColor: const Color(0xFF16A34A),
            title: 'Shipment arrived at Mumbai Port',
            poNumber: 'PO-2024-0792',
            timestamp: 'Feb 12, 2027, 10:30 AM',
          ),
          const SizedBox(height: 14),

          _buildActivityTimelineItem(
            dotColor: const Color(0xFFD97706),
            title: 'Documentation received',
            poNumber: 'PO-2024-0610',
            timestamp: 'Jan 28, 2027, 04:15 PM',
          ),
          const SizedBox(height: 14),

          _buildActivityTimelineItem(
            dotColor: const Color(0xFFD97706),
            title: 'Payment processed',
            poNumber: 'PO-2024-0458',
            timestamp: 'Jan 18, 2027, 11:00 AM',
          ),
          const SizedBox(height: 14),

          _buildActivityTimelineItem(
            dotColor: const Color(0xFFD97706),
            title: 'New purchase order created',
            poNumber: 'PO-2024-0847',
            timestamp: 'Jan 15, 2027, 09:20 AM',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimelineItem({
    required Color dotColor,
    required String title,
    required String poNumber,
    required String timestamp,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 5),
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
              ),
              const SizedBox(height: 2),
              Text(
                poNumber,
                style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
        Text(
          timestamp,
          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF9CA3AF)),
        ),
      ],
    );
  }

  // 8. AI Supplier Insights Banner
  Widget _buildAiInsightsBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFFD97706), size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Supplier Insights',
                  style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Reliable supplier with strong on-time delivery and consistent quality. Consider increasing order volume for better rates.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: _showAiInsightsModal,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFF59E0B)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('View AI Insights'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
