// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class SystemIntegrationSyncView extends StatefulWidget {
  const SystemIntegrationSyncView({
    super.key,
    this.onBackToSettings,
    this.onSubNavChanged,
    this.onSelectSection,
  });

  final VoidCallback? onBackToSettings;
  final void Function(String title, String subtitle)? onSubNavChanged;
  final ValueChanged<String>? onSelectSection;

  @override
  State<SystemIntegrationSyncView> createState() =>
      _SystemIntegrationSyncViewState();
}

class _SystemIntegrationSyncViewState extends State<SystemIntegrationSyncView> {
  bool _isRetryingWooCommerce = false;
  bool _isRetryingFailed = false;

  void _showFeedback(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: isError
                  ? const Color(0xFFFCA5A5)
                  : const Color(0xFFD5A46C),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B18),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }

  void _handleRetryFailed() async {
    setState(() => _isRetryingFailed = true);
    _showFeedback('Initiating retry for failed sync jobs...');
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isRetryingFailed = false);
    _showFeedback('WooCommerce push re-queued for sync execution.');
  }

  void _handleRetryWooCommerce() async {
    setState(() => _isRetryingWooCommerce = true);
    _showFeedback('Re-authenticating WooCommerce API credentials...');
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _isRetryingWooCommerce = false);
    _showFeedback('WooCommerce API handshake refreshed. Push queued.');
  }

  @override
  Widget build(BuildContext context) {
    return DesktopContentConstraint(
      maxWidth: 1320,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Area with Title and Operational Status Badge
            _buildPageHeader(),

            const SizedBox(height: 24),

            // Card 1: Sync Integrations Table
            _buildSyncIntegrationsCard(),

            const SizedBox(height: 24),

            // Card 2: Scheduled Jobs
            _buildScheduledJobsCard(),

            const SizedBox(height: 24),

            // Card 3: Sync Health Bottom Banner
            _buildSyncHealthBanner(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PAGE HEADER
  // ---------------------------------------------------------------------------
  Widget _buildPageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 760;

        final leftHeader = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circular warm avatar badge with sync icon
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFFFAF2E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sync_rounded,
                size: 24,
                color: Color(0xFF7A481B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Integration Sync',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Monitor real-time data flows between ThreadStock and connected external integrations.',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B6357),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final rightStatusCard = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEADBCA)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isNarrow
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'All Systems Operational',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Last updated: Oct 24, 2026 11:24 AM',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [leftHeader, const SizedBox(height: 16), rightStatusCard],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: leftHeader),
            const SizedBox(width: 24),
            rightStatusCard,
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 1: SYNC INTEGRATIONS TABLE
  // ---------------------------------------------------------------------------
  Widget _buildSyncIntegrationsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DFD3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EDE0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.sync_rounded,
                        size: 18,
                        color: Color(0xFF7A481B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sync Integrations',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0ECE5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '4 Integrations',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B6357),
                        ),
                      ),
                    ),
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: _isRetryingFailed ? null : _handleRetryFailed,
                  icon: _isRetryingFailed
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF181513),
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 16,
                          color: Color(0xFF181513),
                        ),
                  label: Text(
                    'Retry Failed',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFDFD5C6)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFEFE8DD)),

          // Scrollable Table Container
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 880),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Table Column Headers
                  Container(
                    color: const Color(0xFFFAF8F5),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 11,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 250,
                          child: _buildColumnHeader('INTEGRATION'),
                        ),
                        SizedBox(
                          width: 110,
                          child: _buildColumnHeader('DIRECTION'),
                        ),
                        SizedBox(
                          width: 100,
                          child: _buildColumnHeader('STARTED'),
                        ),
                        SizedBox(
                          width: 150,
                          child: _buildColumnHeader('RECORDS'),
                        ),
                        SizedBox(
                          width: 160,
                          child: _buildColumnHeader('PROGRESS'),
                        ),
                        SizedBox(
                          width: 120,
                          child: _buildColumnHeader('STATUS'),
                        ),
                        SizedBox(
                          width: 60,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _buildColumnHeader('ACTIONS'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFEFE8DD)),

                  // Row 1: Shopify Catalog Sync
                  _buildIntegrationRow(
                    iconWidget: _buildShopifyLogo(),
                    title: 'Shopify Catalog Sync',
                    subtitle: 'Products, variants, inventory',
                    direction: 'Inbound',
                    isInbound: true,
                    started: '10:42 AM',
                    records: '847 / 1,200 styles',
                    progressPercent: 0.70,
                    progressLabel: '70% completed',
                    progressColor: const Color(0xFFB68953),
                    statusText: 'Running',
                    statusType: _StatusType.running,
                  ),

                  const Divider(height: 1, color: Color(0xFFEFE8DD)),

                  // Row 2: Tally ERP Invoices
                  _buildIntegrationRow(
                    iconWidget: _buildTallyLogo(),
                    title: 'Tally ERP Invoices',
                    subtitle: 'Purchase invoices, vendors',
                    direction: 'Outbound',
                    isInbound: false,
                    started: 'Pending',
                    records: '42 invoices',
                    progressPercent: 0.0,
                    progressLabel: '0% queued',
                    progressColor: const Color(0xFFD1D5DB),
                    statusText: 'Queued',
                    statusType: _StatusType.queued,
                  ),

                  const Divider(height: 1, color: Color(0xFFEFE8DD)),

                  // Row 3: WhatsApp Business Leads
                  _buildIntegrationRow(
                    iconWidget: _buildWhatsAppLogo(),
                    title: 'WhatsApp Business Leads',
                    subtitle: 'Customer inquiries, leads',
                    direction: 'Inbound',
                    isInbound: true,
                    started: '09:15 AM',
                    records: '118 messages',
                    progressPercent: 1.0,
                    progressLabel: '100% synced',
                    progressColor: const Color(0xFF16A34A),
                    statusText: 'Completed',
                    statusType: _StatusType.completed,
                  ),

                  const Divider(height: 1, color: Color(0xFFEFE8DD)),

                  // Row 4: WooCommerce Sales Push (Failed State)
                  _buildIntegrationRow(
                    iconWidget: _buildWooCommerceLogo(),
                    title: 'WooCommerce Sales Push',
                    subtitle: 'Orders, customers, inventory',
                    direction: 'Outbound',
                    isInbound: false,
                    started: '10:10 AM',
                    records: '34 orders remaining',
                    progressPercent: 0.30,
                    progressLabel: '30% failed',
                    progressColor: const Color(0xFFDC2626),
                    statusText: 'Failed',
                    statusType: _StatusType.failed,
                    isRowHighlighted: true,
                  ),

                  // Error Trace Banner (Directly attached under row 4)
                  _buildErrorTraceBanner(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeader(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.7,
        color: const Color(0xFF8C8377),
      ),
    );
  }

  Widget _buildIntegrationRow({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required String direction,
    required bool isInbound,
    required String started,
    required String records,
    required double progressPercent,
    required String progressLabel,
    required Color progressColor,
    required String statusText,
    required _StatusType statusType,
    bool isRowHighlighted = false,
  }) {
    return Container(
      color: isRowHighlighted ? const Color(0xFFFEF4F4) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Integration Name & Icon
          SizedBox(
            width: 250,
            child: Row(
              children: [
                iconWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Direction
          SizedBox(
            width: 110,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isInbound
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                  size: 14,
                  color: const Color(0xFF7E766B),
                ),
                const SizedBox(width: 6),
                Text(
                  direction,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF4A433A),
                  ),
                ),
              ],
            ),
          ),

          // Started
          SizedBox(
            width: 100,
            child: Text(
              started,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: started == 'Pending'
                    ? const Color(0xFF7E766B)
                    : const Color(0xFF4A433A),
              ),
            ),
          ),

          // Records
          SizedBox(
            width: 150,
            child: Text(
              records,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF4A433A),
              ),
            ),
          ),

          // Progress Bar & Label
          SizedBox(
            width: 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Container(
                    height: 5,
                    width: 130,
                    color: const Color(0xFFEAE4DC),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progressPercent.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: progressColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  progressLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: statusType == _StatusType.failed
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF7E766B),
                  ),
                ),
              ],
            ),
          ),

          // Status Badge
          SizedBox(width: 120, child: _buildStatusPill(statusText, statusType)),

          // Actions Menu
          SizedBox(
            width: 60,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: Color(0xFF6B6357),
                ),
                tooltip: 'More options',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFEADBCA)),
                ),
                onSelected: (val) {
                  if (val == 'sync_now') {
                    _showFeedback('Triggering instant sync for $title...');
                  } else if (val == 'view_logs') {
                    _showFeedback('Viewing execution logs for $title.');
                  } else if (val == 'config') {
                    widget.onSelectSection?.call('integrations');
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'sync_now',
                    child: Text(
                      'Sync Now',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'view_logs',
                    child: Text(
                      'View Logs',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem(
                    value: 'config',
                    child: Text(
                      'Configure Integration',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF7A481B),
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

  Widget _buildStatusPill(String text, _StatusType type) {
    Color bg;
    Color border;
    Color dotColor;
    Color textColor;

    switch (type) {
      case _StatusType.running:
        bg = const Color(0xFFFEF3C7);
        border = const Color(0xFFFDE68A);
        dotColor = const Color(0xFFD97706);
        textColor = const Color(0xFFB45309);
        break;
      case _StatusType.queued:
        bg = const Color(0xFFF3F4F6);
        border = const Color(0xFFE5E7EB);
        dotColor = const Color(0xFF6B7280);
        textColor = const Color(0xFF4B5563);
        break;
      case _StatusType.completed:
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFFBBF7D0);
        dotColor = const Color(0xFF16A34A);
        textColor = const Color(0xFF15803D);
        break;
      case _StatusType.failed:
        bg = const Color(0xFFFEE2E2);
        border = const Color(0xFFFECACA);
        dotColor = const Color(0xFFDC2626);
        textColor = const Color(0xFFB91C1C);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.5,
            height: 6.5,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR TRACE BANNER
  // ---------------------------------------------------------------------------
  Widget _buildErrorTraceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFFEF2F2),
        border: Border(top: BorderSide(color: Color(0xFFFCA5A5), width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Red exclamation icon inside circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF87171), width: 1.5),
            ),
            child: const Icon(
              Icons.priority_high_rounded,
              color: Color(0xFFDC2626),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ERROR TRACE (WOOCOMMERCE API - 401 UNAUTHORIZED)',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'The authorization credentials provided are invalid or expired. Check API Client Secret in Settings > Integrations.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6357),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Solid Red Retry Sync Button
          ElevatedButton.icon(
            onPressed: _isRetryingWooCommerce ? null : _handleRetryWooCommerce,
            icon: _isRetryingWooCommerce
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
            label: Text(
              'Retry Sync',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF991B1B),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 2: SCHEDULED JOBS
  // ---------------------------------------------------------------------------
  Widget _buildScheduledJobsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DFD3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5EDE0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      size: 20,
                      color: Color(0xFF7A481B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scheduled Jobs',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Automated sync jobs and data processing schedules.',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B6357),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  _showFeedback('Opening Schedule Manager dialog...');
                },
                icon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF181513),
                ),
                label: Text(
                  'Manage Schedule',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFDFD5C6)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 3 Responsive Mini Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 880;

              if (isNarrow) {
                return Column(
                  children: [
                    _buildScheduledJobCard(
                      iconWidget: _buildShopifyMiniLogo(),
                      title: 'Shopify Auto-Sync',
                      schedule: 'Every 15 Minutes',
                      nextRun: 'Next run: in 8 minutes (11:00 AM)',
                    ),
                    const SizedBox(height: 12),
                    _buildScheduledJobCard(
                      iconWidget: _buildTallyMiniLogo(),
                      title: 'Tally Report Compile',
                      schedule: 'Daily at 11:30 PM',
                      nextRun: 'Next run: tonight',
                    ),
                    const SizedBox(height: 12),
                    _buildScheduledJobCard(
                      iconWidget: _buildChartMiniLogo(),
                      title: 'Metric Summary Push',
                      schedule: 'Weekly on Sundays',
                      nextRun: 'Next run: Jan 26, 2026',
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: _buildScheduledJobCard(
                      iconWidget: _buildShopifyMiniLogo(),
                      title: 'Shopify Auto-Sync',
                      schedule: 'Every 15 Minutes',
                      nextRun: 'Next run: in 8 minutes (11:00 AM)',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildScheduledJobCard(
                      iconWidget: _buildTallyMiniLogo(),
                      title: 'Tally Report Compile',
                      schedule: 'Daily at 11:30 PM',
                      nextRun: 'Next run: tonight',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildScheduledJobCard(
                      iconWidget: _buildChartMiniLogo(),
                      title: 'Metric Summary Push',
                      schedule: 'Weekly on Sundays',
                      nextRun: 'Next run: Jan 26, 2026',
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledJobCard({
    required Widget iconWidget,
    required String title,
    required String schedule,
    required String nextRun,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAE2D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Icon + Title + Enabled Badge + More Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Enabled',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  size: 18,
                  color: Color(0xFF7E766B),
                ),
                tooltip: 'Job actions',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFEADBCA)),
                ),
                onSelected: (val) {
                  _showFeedback('Job action triggered for $title.');
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'run_now',
                    child: Text(
                      'Run Now',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit_schedule',
                    child: Text(
                      'Edit Schedule',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'disable',
                    child: Text(
                      'Disable Job',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Schedule Interval
          Text(
            schedule,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),

          const SizedBox(height: 8),

          // Next Run Info with Clock Icon
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  nextRun,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CARD 3: SYNC HEALTH BOTTOM BANNER
  // ---------------------------------------------------------------------------
  Widget _buildSyncHealthBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
      ),
      child: Row(
        children: [
          // Information Icon in Circle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF2E6),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDCCFBD), width: 1.5),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF7A481B),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sync Health',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF7A481B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Monitor your integration performance and ensure all systems are up to date. Failed syncs will be retried automatically based on your retry policy.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6357),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          OutlinedButton.icon(
            onPressed: () {
              widget.onSelectSection?.call('audit_log');
            },
            icon: const Icon(
              Icons.description_outlined,
              size: 16,
              color: Color(0xFF181513),
            ),
            label: Text(
              'View Sync History',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFDFD5C6)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOGO BUILDERS
  // ---------------------------------------------------------------------------
  Widget _buildShopifyLogo() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF95BF47),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'S',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildShopifyMiniLogo() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFF95BF47),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          'S',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildTallyLogo() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'T',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  Widget _buildTallyMiniLogo() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          'T',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildWhatsAppLogo() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF25D366),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Icon(Icons.chat_bubble_rounded, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildWooCommerceLogo() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF96588A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'WOO',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildChartMiniLogo() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFFAF2E6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Center(
        child: Icon(
          Icons.bar_chart_rounded,
          size: 18,
          color: Color(0xFFB68953),
        ),
      ),
    );
  }
}

enum _StatusType { running, queued, completed, failed }
