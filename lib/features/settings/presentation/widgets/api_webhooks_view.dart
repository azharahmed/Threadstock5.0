// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class WebhookItem {
  String event;
  String destinationUrl;
  String status;
  String failures;

  WebhookItem({
    required this.event,
    required this.destinationUrl,
    required this.status,
    required this.failures,
  });
}

class ApiWebhooksView extends StatefulWidget {
  final VoidCallback? onBackToSettings;
  final void Function(String title, String subtitle)? onSubNavChanged;
  final void Function(String sectionKey)? onSelectSection;

  const ApiWebhooksView({
    super.key,
    this.onBackToSettings,
    this.onSubNavChanged,
    this.onSelectSection,
  });

  @override
  State<ApiWebhooksView> createState() => _ApiWebhooksViewState();
}

class _ApiWebhooksViewState extends State<ApiWebhooksView> {
  int _activeTabIndex = 3; // "API & Webhooks" is index 3

  final List<String> _tabs = const [
    'Purchasing Defaults',
    'Transfer Settings',
    'Import / Export',
    'API & Webhooks',
    'Audit Log',
  ];

  String _apiKey = '•••••••••••••••••••••••••••••3a9b';
  bool _isKeyMasked = true;

  final List<WebhookItem> _webhooks = [
    WebhookItem(
      event: 'inventory.updated',
      destinationUrl: 'https://hooks.example.com/inv',
      status: 'Active',
      failures: '0 / 10k',
    ),
    WebhookItem(
      event: 'order.created',
      destinationUrl: 'https://hooks.example.com/order',
      status: 'Active',
      failures: '2 / 10k',
    ),
  ];

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _copyApiKey() {
    Clipboard.setData(const ClipboardData(text: 'ts_live_9f82d1c748209bb41a3a9b'));
    _showFeedback('API key copied to clipboard');
  }

  void _regenerateApiKey() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEADBCA)),
          ),
          title: Text(
            'Regenerate API Key',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          content: Text(
            'Are you sure you want to regenerate your API key? The current key will be revoked immediately and existing integrations using it will fail.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6B6357),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _apiKey = '•••••••••••••••••••••••••••••7f1c';
                });
                _showFeedback('API key regenerated successfully');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC25424),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Regenerate Key',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddWebhookDialog() {
    final eventController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFEADBCA)),
          ),
          title: Text(
            'Add Webhook Endpoint',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EVENT NAME',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: eventController,
                  decoration: InputDecoration(
                    hintText: 'e.g. transfer.dispatched',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFA89F91),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAF8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5DCD2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5DCD2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF7A481B)),
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'DESTINATION URL',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    hintText: 'https://your-api.com/webhooks',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFA89F91),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFFAFAF8),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5DCD2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5DCD2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF7A481B)),
                    ),
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF181513),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (eventController.text.trim().isEmpty ||
                    urlController.text.trim().isEmpty) {
                  return;
                }
                setState(() {
                  _webhooks.add(
                    WebhookItem(
                      event: eventController.text.trim(),
                      destinationUrl: urlController.text.trim(),
                      status: 'Active',
                      failures: '0 / 10k',
                    ),
                  );
                });
                Navigator.pop(ctx);
                _showFeedback('Added webhook for ${eventController.text.trim()}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF181513),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save Webhook',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 980;

        return DesktopContentConstraint(
          maxWidth: 1320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Area
                _buildHeader(),

                const SizedBox(height: 20),

                // Operational Sub-Navigation Tabs Row
                _buildTabsRow(),

                const SizedBox(height: 24),

                // 2-Column Grid (4 Cards total)
                if (isNarrow) ...[
                  _buildLeftColumn(),
                  const SizedBox(height: 24),
                  _buildRightColumn(),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: API Access Credentials & Configured Webhooks (~55%)
                      Expanded(
                        flex: 55,
                        child: _buildLeftColumn(),
                      ),

                      const SizedBox(width: 24),

                      // Right Column: Usage This Month & Developer Reference (~45%)
                      Expanded(
                        flex: 45,
                        child: _buildRightColumn(),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // Header matching screenshot
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Warm circular avatar with link icon
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFFAF2E6),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.link_rounded,
            size: 28,
            color: Color(0xFF7A481B),
          ),
        ),

        const SizedBox(width: 16),

        // Title and Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'API & Webhooks',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage API access, configure webhooks, and integrate with external systems.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6357),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Operational Sub-Navigation Tabs Row
  Widget _buildTabsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < _tabs.length; i++) ...[
            _buildTabPill(
              title: _tabs[i],
              isSelected: _activeTabIndex == i,
              onTap: () {
                setState(() => _activeTabIndex = i);
                if (i == 0) {
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('purchasing_defaults');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > Purchasing Defaults > Central Warehouse (Zone A)',
                      'Configure buying, receiving and cost settings for your business.',
                    );
                  }
                } else if (i == 1) {
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('transfer_settings');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > Transfer Settings > Central Warehouse (Zone A)',
                      'Configure stock transfer workflows, transit times and receiving preferences.',
                    );
                  }
                } else if (i == 2) {
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('import_export');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > Import / Export Center > Central Warehouse (Zone A)',
                      'Import and export your business data with ease. Manage files, track history, and ensure data accuracy.',
                    );
                  }
                } else if (i == 4) {
                  if (widget.onSelectSection != null) {
                    widget.onSelectSection!('audit_log');
                  } else {
                    widget.onSubNavChanged?.call(
                      'Settings > System Audit Log > Central Warehouse (Zone A)',
                      'Track all system changes, user actions, and important events across ThreadStock.',
                    );
                  }
                } else {
                  _showFeedback('Viewing ${_tabs[i]}');
                }
              },
            ),
            if (i < _tabs.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF7A481B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF7A481B) : const Color(0xFFDFD4C5),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF181513),
          ),
        ),
      ),
    );
  }

  // Left Column containing API Access Credentials & Configured Webhooks
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: API Access Credentials
        _buildApiCredentialsCard(),

        const SizedBox(height: 24),

        // Card 2: Configured Webhooks
        _buildConfiguredWebhooksCard(),
      ],
    );
  }

  // Right Column containing Usage This Month & Developer Reference
  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 3: Usage This Month
        _buildUsageMonthCard(),

        const SizedBox(height: 24),

        // Card 4: Developer Reference
        _buildDeveloperReferenceCard(),
      ],
    );
  }

  // Card 1: API Access Credentials
  Widget _buildApiCredentialsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.key_outlined,
                  size: 20,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Access Credentials',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Use this API key to authenticate your requests.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF7EC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFF4E7D0)),
                ),
                child: Text(
                  'Production Environment',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9B6822),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // API Key Input Row + Regenerate Button
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAF8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5DCD2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isKeyMasked
                              ? _apiKey
                              : 'ts_live_9f82d1c748209bb41a3a9b',
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: _isKeyMasked ? 1.5 : 0.5,
                            color: const Color(0xFF181513),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isKeyMasked
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                          color: const Color(0xFF7E766B),
                        ),
                        tooltip: _isKeyMasked ? 'Reveal Key' : 'Hide Key',
                        onPressed: () {
                          setState(() => _isKeyMasked = !_isKeyMasked);
                        },
                        splashRadius: 18,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.content_copy_outlined,
                          size: 18,
                          color: Color(0xFF7E766B),
                        ),
                        tooltip: 'Copy API Key',
                        onPressed: _copyApiKey,
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: _regenerateApiKey,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFDFD4C5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Regenerate',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Metadata Details Row
          Row(
            children: [
              // Column 1: API Version
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API VERSION',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: const Color(0xFF8C827A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'v2.1 (Active)',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 40),

              // Subtle vertical line
              Container(
                width: 1,
                height: 32,
                color: const Color(0xFFEDE5D8),
              ),

              const SizedBox(width: 40),

              // Column 2: Rate Limit
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RATE LIMIT',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: const Color(0xFF8C827A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '1,000 req / minute',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
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

  // Card 2: Configured Webhooks
  Widget _buildConfiguredWebhooksCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  size: 20,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Configured Webhooks',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Manage event subscriptions and endpoints.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddWebhookDialog,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: Text(
                  'Add Webhook',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF181513),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Table Header
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'EVENT',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'DESTINATION URL',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'STATUS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'FAILURES',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
              ),
              SizedBox(
                width: 50,
                child: Text(
                  'ACTIONS',
                  textAlign: TextAlign.end,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: const Color(0xFF8C827A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF0E7DD), height: 1, thickness: 1),

          // Table Rows
          for (int i = 0; i < _webhooks.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      _webhooks[i].event,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _webhooks[i].destinationUrl,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF7EE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF28A745),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _webhooks[i].status,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E7E34),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _webhooks[i].failures,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF5E574E),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_horiz,
                          size: 18,
                          color: Color(0xFF7E766B),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (action) {
                          if (action == 'delete') {
                            setState(() => _webhooks.removeAt(i));
                            _showFeedback('Removed webhook');
                          } else if (action == 'test') {
                            _showFeedback('Triggered test event to ${_webhooks[i].destinationUrl}');
                          } else {
                            _showFeedback('Webhook details: ${_webhooks[i].event}');
                          }
                        },
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'test',
                            child: Text(
                              'Send Test Ping',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(
                              'Edit Endpoint',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              'Delete Webhook',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFC25424),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (i < _webhooks.length - 1)
              const Divider(color: Color(0xFFF7F1EA), height: 1, thickness: 1),
          ],
        ],
      ),
    );
  }

  // Card 3: Usage This Month
  Widget _buildUsageMonthCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bar_chart_outlined,
                  size: 20,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Usage This Month',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'API requests across all endpoints.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Big Counter Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '45,230',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '/ 100,000 monthly reqs',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8C827A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.4523,
              minHeight: 8,
              backgroundColor: const Color(0xFFECE6DD),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFB58E58)),
            ),
          ),

          const SizedBox(height: 18),

          // Callout Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF4E7D0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up,
                  size: 18,
                  color: Color(0xFF9B6822),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'You are at 45% of your quota. Usage resets on Nov 1st.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF8C5818),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 4: Developer Reference
  Widget _buildDeveloperReferenceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  size: 20,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Developer Reference',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Resources to help you integrate with ThreadStock.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF6B6357),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Resource Item 1: ThreadStock API Documentation
          _buildResourceLinkCard(
            title: 'ThreadStock API Documentation',
            subtitle: 'Complete API reference, examples, and schemas',
            onTap: () => _showFeedback('Opening API documentation...'),
          ),

          const SizedBox(height: 12),

          // Resource Item 2: Rate Limiting & Best Practices
          _buildResourceLinkCard(
            title: 'Rate Limiting & Best Practices',
            subtitle: 'Usage limits, error handling, and guides',
            onTap: () => _showFeedback('Opening rate limits & best practices guide...'),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceLinkCard({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEDE5D8)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 20,
              color: Color(0xFF181513),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF8C827A),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFF9E958A),
            ),
          ],
        ),
      ),
    );
  }
}
