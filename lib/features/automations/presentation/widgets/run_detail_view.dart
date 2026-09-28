import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../inventory/data/product_repository.dart';
import '../../../inventory/domain/models/product.dart';

class _AffectedVariantItem {
  final String sku;
  final String productName;
  final String unitsLeft;
  final String reorderLevel;
  final String imagePath;

  const _AffectedVariantItem({
    required this.sku,
    required this.productName,
    required this.unitsLeft,
    required this.reorderLevel,
    this.imagePath = '',
  });
}

class RunDetailView extends StatefulWidget {
  const RunDetailView({
    super.key,
    this.runId = 'RUN-1847',
    this.productName,
    this.productRepository,
    this.onRetryRun,
    this.onSkipAndContinue,
    this.onEditAutomationRule,
    this.onViewAllAffectedItems,
    this.onSelectRelatedRun,
    this.onGetAiRecommendation,
  });

  final String runId;
  final String? productName;
  final ProductRepository? productRepository;
  final VoidCallback? onRetryRun;
  final VoidCallback? onSkipAndContinue;
  final VoidCallback? onEditAutomationRule;
  final VoidCallback? onViewAllAffectedItems;
  final void Function(String runId)? onSelectRelatedRun;
  final VoidCallback? onGetAiRecommendation;

  @override
  State<RunDetailView> createState() => _RunDetailViewState();
}

class _RunDetailViewState extends State<RunDetailView> {
  bool _isStackTraceExpanded = false;
  late final ProductRepository _productRepository;
  List<Product> _loadedProducts = [];

  @override
  void initState() {
    super.initState();
    _productRepository = widget.productRepository ?? ProductRepository();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final prods = await _productRepository.getProducts();
      if (mounted) {
        setState(() {
          _loadedProducts = prods;
        });
      }
    } catch (_) {}
  }

  List<_AffectedVariantItem> _resolveAffectedItems() {
    if (widget.productName != null && widget.productName!.trim().isNotEmpty) {
      final cleanName = widget.productName!.trim();
      return [
        _AffectedVariantItem(
          sku: 'SKU-${widget.runId}',
          productName: cleanName,
          unitsLeft: '0 units left',
          reorderLevel: '< 3 units',
          imagePath: '',
        ),
      ];
    }

    final prods = _loadedProducts.isNotEmpty
        ? _loadedProducts
        : ProductRepository.localFallbackProducts.values.toList();

    if (prods.isEmpty) {
      return const [];
    }

    final items = <_AffectedVariantItem>[];
    for (final p in prods.take(3)) {
      final variants = ProductRepository.getFallbackVariants(p.id);
      final sku = variants.isNotEmpty && variants.first.sku.isNotEmpty
          ? variants.first.sku
          : (p.tags.isNotEmpty
                ? p.tags.first
                : (p.id.length >= 8
                      ? 'SKU-${p.id.substring(0, 8).toUpperCase()}'
                      : 'SKU-${p.id.toUpperCase()}'));

      final threshold = p.lowStockThreshold ?? 3;
      items.add(
        _AffectedVariantItem(
          sku: sku,
          productName: p.name,
          unitsLeft: '0 units left',
          reorderLevel: '< $threshold units',
          imagePath: '',
        ),
      );
    }
    return items;
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 960;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Failure Alert Banner
            _buildFailureAlertBanner(),
            const SizedBox(height: 18),

            // Two-column layout or stacked layout
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column (~72% flex)
                  Expanded(
                    flex: 72,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimelineCard(),
                        const SizedBox(height: 18),
                        _buildAffectedItemsCard(),
                        const SizedBox(height: 18),
                        _buildActionButtonsRow(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),

                  // Right Column (~28% flex)
                  SizedBox(width: 290, child: _buildErrorDetailsCard()),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimelineCard(),
                  const SizedBox(height: 18),
                  _buildAffectedItemsCard(),
                  const SizedBox(height: 18),
                  _buildErrorDetailsCard(),
                  const SizedBox(height: 18),
                  _buildActionButtonsRow(),
                ],
              ),

            const SizedBox(height: 18),

            // Bottom AI Insight Banner
            _buildAiInsightBanner(),
          ],
        );
      },
    );
  }

  // ========================================================
  // 1. TOP FAILURE ALERT BANNER
  // ========================================================
  Widget _buildFailureAlertBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFDC2626),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'This automation failed during execution. Review the error details below.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
          Text(
            'Sep 15, 2026, 08:12:44 AM',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF6E675F),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 2. AUTOMATION TIMELINE & EXECUTION STEPS
  // ========================================================
  Widget _buildTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Automation Timeline & Execution Steps',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 20),

          // Step 1: Trigger Detected
          _buildTimelineStep(
            stepNumber: 1,
            title: 'Step 1: Trigger Detected',
            subtitle: 'Low stock threshold breached for 18 variants.',
            timestamp: 'Sep 15, 2026, 08:12:40 AM',
            duration: '0.4s',
            status: _StepStatus.success,
            hasNext: true,
            isNextSuccess: true,
          ),

          // Step 2: Conditions Evaluated
          _buildTimelineStep(
            stepNumber: 2,
            title: 'Step 2: Conditions Evaluated',
            subtitle: 'All 3 conditional parameters resolved to TRUE.',
            timestamp: 'Sep 15, 2026, 08:12:41 AM',
            duration: '0.6s',
            status: _StepStatus.success,
            hasNext: true,
            isNextSuccess: false,
          ),

          // Step 3: Create PO (Failed)
          _buildTimelineStep(
            stepNumber: 3,
            title: 'Step 3: Create PO',
            subtitle: 'Attempted connection with external supplier endpoint.',
            timestamp: 'Sep 15, 2026, 08:12:44 AM',
            duration: '0.1s',
            status: _StepStatus.failed,
            hasNext: false,
            errorBox: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Supplier API timeout — Arrind Mills endpoint did not respond within 30s.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDE8E8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'TIMEOUT',
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
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

  Widget _buildTimelineStep({
    required int stepNumber,
    required String title,
    required String subtitle,
    required String timestamp,
    required String duration,
    required _StepStatus status,
    required bool hasNext,
    bool isNextSuccess = true,
    Widget? errorBox,
  }) {
    final isSuccess = status == _StepStatus.success;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Icon + Vertical Connector Line
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSuccess
                      ? const Color(0xFFEAF7EE)
                      : const Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 20,
                    color: isSuccess
                        ? const Color(0xFF10B981)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
              if (hasNext)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isNextSuccess
                        ? const Color(0xFF10B981)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Content + Timestamp & Duration
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: hasNext ? 22 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            timestamp,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF6E675F),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              duration,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF6E675F),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  ?errorBox,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 3. AFFECTED ITEMS CARD
  // ========================================================
  Widget _buildAffectedItemsCard() {
    final items = _resolveAffectedItems();
    final hasItems = items.isNotEmpty;
    final totalVariants = hasItems ? items.length : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasItems
                ? 'Affected Items ($totalVariants variant${totalVariants == 1 ? '' : 's'})'
                : 'Affected Items',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 14),

          if (!hasItems) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF9F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 28,
                    color: Color(0xFFB0A79E),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No affected inventory items found for this run.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6E675F),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8.5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF9F6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  _buildHeaderCell('SKU', flex: 18),
                  _buildHeaderCell('Product', flex: 32),
                  _buildHeaderCell('Units Left', flex: 15),
                  _buildHeaderCell('Reorder Level', flex: 15),
                ],
              ),
            ),
            const SizedBox(height: 2),

            // Table Rows
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0)
                const Divider(
                  color: Color(0xFFF2ECE4),
                  height: 1,
                  thickness: 1,
                ),
              _buildItemRow(
                imagePath: items[i].imagePath,
                sku: items[i].sku,
                productName: items[i].productName,
                unitsLeft: items[i].unitsLeft,
                reorderLevel: items[i].reorderLevel,
              ),
            ],
            const SizedBox(height: 14),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${items.length} of $totalVariants affected variant${totalVariants == 1 ? '' : 's'}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF6E675F),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                InkWell(
                  onTap:
                      widget.onViewAllAffectedItems ??
                      () => _showToast(
                        'Viewing full list of $totalVariants affected variants...',
                      ),
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All Items',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8C5A2B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF8C5A2B),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6E675F),
        ),
      ),
    );
  }

  Widget _buildItemRow({
    required String imagePath,
    required String sku,
    String? productName,
    required String unitsLeft,
    required String reorderLevel,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // SKU + Thumbnail
          Expanded(
            flex: 18,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 30,
                    height: 30,
                    color: const Color(0xFFF3ECE1),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.checkroom_outlined,
                        size: 16,
                        color: Color(0xFF8C5A2B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sku,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Name
          Expanded(
            flex: 32,
            child: Text(
              productName ?? '—',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
            ),
          ),

          // Units Left
          Expanded(
            flex: 15,
            child: Text(
              unitsLeft,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),

          // Reorder Level
          Expanded(
            flex: 15,
            child: Text(
              reorderLevel,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6E675F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // 4. ACTION BUTTONS ROW
  // ========================================================
  Widget _buildActionButtonsRow() {
    return Row(
      children: [
        // Button 1: Retry Run
        InkWell(
          onTap:
              widget.onRetryRun ??
              () => _showToast('Retrying automation run RUN-1847...'),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF181513),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Retry Run',
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
        const SizedBox(width: 12),

        // Button 2: Skip & Continue
        InkWell(
          onTap:
              widget.onSkipAndContinue ??
              () => _showToast(
                'Skipping RUN-1847 and returning to Run History...',
              ),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD7CB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fast_forward_rounded,
                  size: 16,
                  color: Color(0xFF181513),
                ),
                const SizedBox(width: 8),
                Text(
                  'Skip & Continue',
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
        const SizedBox(width: 12),

        // Button 3: Edit Automation Rule
        InkWell(
          onTap:
              widget.onEditAutomationRule ??
              () => _showToast('Opening Low Stock Auto-Reorder rule editor...'),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9.5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD7CB)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Color(0xFF181513),
                ),
                const SizedBox(width: 8),
                Text(
                  'Edit Automation Rule',
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

  // ========================================================
  // 5. ERROR DETAILS CARD (RIGHT COLUMN)
  // ========================================================
  Widget _buildErrorDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error Details',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 14),

          // Error Code Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.code_rounded,
                  size: 18,
                  color: Color(0xFFDC2626),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ERROR CODE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ETMEOUT_SUPPLIER_API',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(
                      const ClipboardData(text: 'ETMEOUT_SUPPLIER_API'),
                    );
                    _showToast('Copied ETMEOUT_SUPPLIER_API to clipboard');
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.content_copy_outlined,
                      size: 16,
                      color: Color(0xFF6E675F),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // FAIL TIME
          _buildMetaSection('FAIL TIME', 'Sep 15, 2026, 08:12:44 AM'),
          const SizedBox(height: 16),

          // RELATED SUPPLIER
          _buildMetaSection('RELATED SUPPLIER', 'Primary Supplier Partner'),
          const SizedBox(height: 18),

          // STACK TRACE (COLLAPSIBLE)
          InkWell(
            onTap: () {
              setState(() {
                _isStackTraceExpanded = !_isStackTraceExpanded;
              });
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STACK TRACE (${_isStackTraceExpanded ? "EXPANDED" : "COLLAPSED"})',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  Icon(
                    _isStackTraceExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ),
          if (_isStackTraceExpanded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'SupplierTimeoutException: [Arrind Mills Gateway] Connection dropped after 30000ms.\n'
                '  at HttpTransport.request (procurement_client.dart:184)\n'
                '  at PurchaseOrderService.createDraft (po_service.dart:62)\n'
                '  at AutomationRunner.executeAction (runner.dart:312)',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: const Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // RELATED RUNS
          Text(
            'RELATED RUNS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6E675F),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          _buildRelatedRunBullet('RUN-1846 (Success, 1d ago)', 'RUN-1846'),
          const SizedBox(height: 6),
          _buildRelatedRunBullet('RUN-1839 (Success, 2d ago)', 'RUN-1839'),
        ],
      ),
    );
  }

  Widget _buildMetaSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6E675F),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF181513),
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedRunBullet(String label, String runId) {
    return InkWell(
      onTap: () {
        if (widget.onSelectRelatedRun != null) {
          widget.onSelectRelatedRun!(runId);
        } else {
          _showToast('Viewing log profile for $runId');
        }
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            const Text(
              '• ',
              style: TextStyle(color: Color(0xFF2563EB), fontSize: 13),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // 6. BOTTOM AI INSIGHT BANNER
  // ========================================================
  Widget _buildAiInsightBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF2DCBE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 26,
            color: Color(0xFFB45309),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI Insight',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'This appears to be a supplier API timeout. Arrind Mills has had 2 similar failures in the last 7 days. Consider retrying with extended timeout or alternative endpoint.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6E675F),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap:
                widget.onGetAiRecommendation ??
                () => _showToast(
                  'Generating AI endpoint retry recommendation...',
                ),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC8A275)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Get AI Recommendation',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8C5A2B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Color(0xFF8C5A2B),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _StepStatus { success, failed }
