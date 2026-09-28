// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../inventory/data/supplier_repository.dart';
import '../../../inventory/domain/models/supplier.dart';
import '../widgets/partner_directory_view.dart';

enum SuppliersViewMode { directory, profile }

class SuppliersPage extends StatefulWidget {
  const SuppliersPage({
    super.key,
    this.initialMode = SuppliersViewMode.directory,
    this.supplierId = '',
    this.supplierName = '',
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
  int _selectedTab = 0;

  final SupplierRepository _supplierRepo = SupplierRepository();
  Supplier? _selectedSupplier;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _currentSupplierName = widget.supplierName;
    _loadSupplier();
  }

  @override
  void didUpdateWidget(covariant SuppliersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      _mode = widget.initialMode;
    }
    if (oldWidget.supplierName != widget.supplierName ||
        oldWidget.supplierId != widget.supplierId) {
      _currentSupplierName = widget.supplierName;
      _loadSupplier();
    }
  }

  Future<void> _loadSupplier() async {
    setState(() => _isLoading = true);
    try {
      final list = await _supplierRepo.getSuppliers();
      if (!mounted) return;
      Supplier? match;
      if (widget.supplierId.isNotEmpty) {
        match = list.where((s) => s.id == widget.supplierId).firstOrNull;
      }
      if (match == null && _currentSupplierName.isNotEmpty) {
        match = list
            .where(
              (s) => s.name.toLowerCase() == _currentSupplierName.toLowerCase(),
            )
            .firstOrNull;
      }
      match ??= list.firstOrNull;
      setState(() {
        _selectedSupplier = match;
        if (match != null) {
          _currentSupplierName = match.name;
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  final List<String> _tabs = [
    'Overview',
    'Purchase Orders',
    'Products',
    'Documents',
    'Compliance',
    'Activity Log',
  ];

  void _showMessageModal() {
    final msgController = TextEditingController();
    final recipientName = _selectedSupplier?.name ?? _currentSupplierName;
    final recipientEmail =
        _selectedSupplier?.contactEmail ?? 'No email provided';

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
              child: const Icon(
                Icons.mail_outline_rounded,
                color: Color(0xFF92400E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Message $recipientName',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
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
                'To: $recipientName ($recipientEmail)',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: msgController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Type your message or delivery inquiry here...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Message sent to $recipientName.'),
                  backgroundColor: const Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Send Message'),
          ),
        ],
      ),
    );
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF181513),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mode == SuppliersViewMode.directory) {
      return PartnerDirectoryView(
        onViewFullProfile: (partner) {
          setState(() {
            _mode = SuppliersViewMode.profile;
            _currentSupplierName = partner.name;
          });
          _loadSupplier();
          widget.onTitleChanged?.call(partner.name);
        },
        onAddSupplier: () => _showFeedback('Add Supplier modal'),
      );
    }
    if (_mode == SuppliersViewMode.profile && _isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9F7F2),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFC59A68)),
        ),
      );
    }

    return _buildProfileView();
  }

  Widget _buildProfileView() {
    final supplierDisplayName =
        _selectedSupplier?.name ??
        (_currentSupplierName.isNotEmpty
            ? _currentSupplierName
            : 'Supplier Profile');

    return Scaffold(
      backgroundColor: const Color(0xFFFBF8F5),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button Breadcrumb
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () {
                    setState(() => _mode = SuppliersViewMode.directory);
                    widget.onTitleChanged?.call('Partner Directory');
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_back_rounded,
                          size: 16,
                          color: Color(0xFFB45309),
                        ),
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
              ),

              // 1. Header with Avatar, title, subtitle & action buttons
              _buildProfileHeader(supplierDisplayName),
              const SizedBox(height: 20),

              // 2. Navigation Tabs Row
              _buildTabsRow(),
              const SizedBox(height: 24),

              // 3. Supplier KPIs (Honest State)
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
                              _buildContactInfoCard(),
                              const SizedBox(height: 20),
                              _buildLogisticsTermsCard(),
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
                      _buildContactInfoCard(),
                      const SizedBox(height: 20),
                      _buildLogisticsTermsCard(),
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
  Widget _buildProfileHeader(String displayName) {
    final initials = displayName.trim().isNotEmpty
        ? (displayName.trim().length >= 2
              ? displayName.trim().substring(0, 2).toUpperCase()
              : displayName.trim().toUpperCase())
        : 'SU';

    final statusLabel = _selectedSupplier?.status.toUpperCase() ?? 'ACTIVE';
    final emailText = _selectedSupplier?.contactEmail ?? 'No email provided';
    final phoneText = _selectedSupplier?.contactPhone ?? 'Not provided';
    final taxIdText = _selectedSupplier?.taxIdentifier ?? 'Not provided';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 800;

        final avatarAndTitle = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFF5EDE1),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEADBCA), width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                            letterSpacing: -0.4,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Email: $emailText  •  Phone: $phoneText  •  Tax ID: $taxIdText',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );

        final actionButtons = Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _showMessageModal,
              icon: const Icon(Icons.mail_outline_rounded, size: 16),
              label: const Text('Send Message'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _showFeedback('Purchase orders module is not configured yet.');
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('New Purchase Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                textStyle: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatarAndTitle,
              const SizedBox(height: 14),
              actionButtons,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: avatarAndTitle),
            const SizedBox(width: 16),
            actionButtons,
          ],
        );
      },
    );
  }

  // 2. Navigation Tabs Row
  Widget _buildTabsRow() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (idx) {
            final isSelected = _selectedTab == idx;
            return InkWell(
              onTap: () => setState(() => _selectedTab = idx),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected
                          ? const Color(0xFFB45309)
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  _tabs[idx],
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFFB45309)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // 3. Supplier KPIs (Zero-Data / Honest State)
  Widget _buildMetricCardsRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFFBF4EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                color: Color(0xFF92400E),
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No performance history yet',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Supplier KPIs and delivery metrics will be calculated after receipt of purchase orders.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Contact Information Card (Stored fields only)
  Widget _buildContactInfoCard() {
    final s = _selectedSupplier;
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
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: Color(0xFF92400E),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Contact Information',
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildKeyValueRow('Supplier Name', s?.name ?? 'Not provided'),
          const SizedBox(height: 12),
          _buildKeyValueRow('Status', s?.status.toUpperCase() ?? 'ACTIVE'),
          const SizedBox(height: 12),
          _buildKeyValueRow(
            'Email',
            s?.contactEmail ?? 'Not provided',
            isLink: s?.contactEmail != null,
          ),
          const SizedBox(height: 12),
          _buildKeyValueRow('Phone', s?.contactPhone ?? 'Not provided'),
          const SizedBox(height: 12),
          _buildKeyValueRow('Tax ID', s?.taxIdentifier ?? 'Not provided'),
        ],
      ),
    );
  }

  // 5. Logistics & Terms Card (Honest state)
  Widget _buildLogisticsTermsCard() {
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
          Row(
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                color: Color(0xFF92400E),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Terms & Logistics',
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildKeyValueRow('Payment Terms', 'Not provided'),
          const SizedBox(height: 12),
          _buildKeyValueRow('Minimum Order (MOQ)', 'Not provided'),
          const SizedBox(height: 12),
          _buildKeyValueRow('Shipping Hub', 'Not provided'),
          const SizedBox(height: 12),
          _buildKeyValueRow('Incoterms', 'Not provided'),
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String label, String value, {bool isLink = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),
        Expanded(
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
      ],
    );
  }

  // 6. Active Purchase Orders Card (Honest state)
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
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: Color(0xFF92400E),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Purchase Orders',
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 32,
                    color: Color(0xFFD1D5DB),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No purchase orders yet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Purchase orders created with this supplier will appear here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 7. Recent Activity Card (Honest state)
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
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Color(0xFF92400E),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Recent Activity',
                style: GoogleFonts.inter(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Icon(
                    Icons.history_toggle_off_rounded,
                    size: 32,
                    color: Color(0xFFD1D5DB),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No supplier activity yet',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Activity records will appear after orders and receipts are processed.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 8. AI Supplier Insights Banner (Honest state)
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
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'AI insights will appear after sufficient supplier and purchasing history is available.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
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
}
