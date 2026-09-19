// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';
import 'shopify_connector_view.dart';

enum IntegrationStatus { connected, notConnected }

class IntegrationItem {
  final String id;
  final String title;
  final String category;
  final String description;
  final Widget iconWidget;
  IntegrationStatus status;
  final bool isMarketplaceTile;
  final String? lastSync;

  IntegrationItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.iconWidget,
    required this.status,
    this.isMarketplaceTile = false,
    this.lastSync,
  });
}

class IntegrationsMarketplaceView extends StatefulWidget {
  final VoidCallback? onBackToSettings;
  final void Function(String title, String subtitle)? onSubNavChanged;

  const IntegrationsMarketplaceView({
    super.key,
    this.onBackToSettings,
    this.onSubNavChanged,
  });

  @override
  State<IntegrationsMarketplaceView> createState() =>
      _IntegrationsMarketplaceViewState();
}

class _IntegrationsMarketplaceViewState
    extends State<IntegrationsMarketplaceView> {
  late List<IntegrationItem> _integrations;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All Categories';
  String _searchQuery = '';
  String? _selectedIntegrationDetail;

  final List<String> _categories = [
    'All Categories',
    'E-Commerce',
    'Accounting',
    'Communications',
    'Logistics',
    'Payments',
    'Data / Storage',
    'Developer API',
  ];

  @override
  void initState() {
    super.initState();
    _integrations = _buildInitialIntegrations();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<IntegrationItem> _buildInitialIntegrations() {
    return [
      // 1. Shopify
      IntegrationItem(
        id: 'shopify',
        title: 'Shopify',
        category: 'E-Commerce',
        description:
            'Real-time sync of digital store sales, variant matrices, and refunds.',
        status: IntegrationStatus.connected,
        lastSync: '2m ago',
        iconWidget: _buildBrandIconContainer(
          backgroundColor: const Color(0xFFF0F7EA),
          borderColor: const Color(0xFFD4E8C8),
          child: _buildShopifyLogo(),
        ),
      ),

      // 2. Tally Prime
      IntegrationItem(
        id: 'tally_prime',
        title: 'Tally Prime',
        category: 'Accounting',
        description:
            'Automate cashbook, daybook ledger logs and tax filings entries.',
        status: IntegrationStatus.connected,
        lastSync: '15m ago',
        iconWidget: _buildBrandIconContainer(
          backgroundColor: const Color(0xFFEEF5FA),
          borderColor: const Color(0xFFCCE2F2),
          child: _buildTallyLogo(),
        ),
      ),

      // 3. WhatsApp Business API
      IntegrationItem(
        id: 'whatsapp_api',
        title: 'WhatsApp Business API',
        category: 'Communications',
        description:
            'Trigger automatic dispatch updates, payment receipts, and marketing catalogs.',
        status: IntegrationStatus.connected,
        lastSync: 'Live',
        iconWidget: _buildBrandIconContainer(
          backgroundColor: const Color(0xFFEDF8F1),
          borderColor: const Color(0xFFCEEBD7),
          child: _buildWhatsAppLogo(),
        ),
      ),

      // 4. Shiprocket
      IntegrationItem(
        id: 'shiprocket',
        title: 'Shiprocket',
        category: 'Logistics',
        description:
            'Courier service bookings, shipment tracking sync, and state-wise logistics.',
        status: IntegrationStatus.notConnected,
        iconWidget: _buildBrandIconContainer(
          backgroundColor: const Color(0xFFF6F0FA),
          borderColor: const Color(0xFFE2D3F2),
          child: _buildShiprocketLogo(),
        ),
      ),

      // 5. Razorpay
      IntegrationItem(
        id: 'razorpay',
        title: 'Razorpay',
        category: 'Payments',
        description:
            'Support terminal link payouts, digital invoices, and secure payment links.',
        status: IntegrationStatus.connected,
        lastSync: '10m ago',
        iconWidget: _buildBrandIconContainer(
          backgroundColor: const Color(0xFFEDF4FA),
          borderColor: const Color(0xFFCDE0F3),
          child: _buildRazorpayLogo(),
        ),
      ),

      // 6. Google Sheets
      IntegrationItem(
        id: 'google_sheets',
        title: 'Google Sheets',
        category: 'Data / Storage',
        description:
            'Auto-export low stock SKUs alerts, weekly reports and sales ledger dumps.',
        status: IntegrationStatus.notConnected,
        iconWidget: _buildBrandIconContainer(
          backgroundColor: const Color(0xFFEEF8F2),
          borderColor: const Color(0xFFCEEBD9),
          child: _buildGoogleSheetsLogo(),
        ),
      ),

      // 7. Slack Alerts
      IntegrationItem(
        id: 'slack_alerts',
        title: 'Slack Alerts',
        category: 'Communications',
        description:
            'Push notification webhooks for emergency stock-outs and regional transfer requests.',
        status: IntegrationStatus.notConnected,
        iconWidget: _buildBrandIconContainer(
          backgroundColor: const Color(0xFFFAF7F2),
          borderColor: const Color(0xFFEBDDC9),
          child: _buildSlackLogo(),
        ),
      ),

      // 8. Custom Webhook
      IntegrationItem(
        id: 'custom_webhook',
        title: 'Custom Webhook',
        category: 'Developer API',
        description:
            'Deploy REST webhooks mapping to ThreadStock system stock change events.',
        status: IntegrationStatus.connected,
        lastSync: 'Real-time',
        iconWidget: _buildBrandIconContainer(
          backgroundColor: const Color(0xFFFAF2F5),
          borderColor: const Color(0xFFF2D3DF),
          child: _buildWebhookLogo(),
        ),
      ),

      // 9. More Integrations
      IntegrationItem(
        id: 'more_integrations',
        title: 'More Integrations',
        category: 'Explore',
        description:
            'Explore more apps and connect tools your business relies on.',
        status: IntegrationStatus.notConnected,
        isMarketplaceTile: true,
        iconWidget: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFAF2E6),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE8DDD0), width: 1.2),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Color(0xFF7A481B),
            size: 24,
          ),
        ),
      ),
    ];
  }

  // ========================================================
  // BRAND LOGOS HELPER WIDGETS
  // ========================================================
  Widget _buildBrandIconContainer({
    required Color backgroundColor,
    required Color borderColor,
    required Widget child,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.2),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  // Shopify
  Widget _buildShopifyLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Icon(Icons.shopping_bag_rounded,
            color: Color(0xFF5E8E3E), size: 22),
        Positioned(
          top: 13,
          child: Text(
            'S',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // Tally Prime (split blue & gold squares)
  Widget _buildTallyLogo() {
    return SizedBox(
      width: 22,
      height: 22,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF00599C),
                borderRadius:
                    BorderRadius.horizontal(left: Radius.circular(2.5)),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFFB703),
                borderRadius:
                    BorderRadius.horizontal(right: Radius.circular(2.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WhatsApp
  Widget _buildWhatsAppLogo() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF25D366),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.call, color: Colors.white, size: 14),
    );
  }

  // Shiprocket (purple geometric rocket / play arrow)
  Widget _buildShiprocketLogo() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF572A99),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16),
    );
  }

  // Razorpay (blue angular blade)
  Widget _buildRazorpayLogo() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF0C2F55),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(
        '₹',
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF3395FF),
        ),
      ),
    );
  }

  // Google Sheets
  Widget _buildGoogleSheetsLogo() {
    return Container(
      width: 22,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFF0F9D58),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 14,
            height: 2,
            color: Colors.white,
          ),
          const SizedBox(height: 2),
          Container(
            width: 14,
            height: 2,
            color: Colors.white,
          ),
          const SizedBox(height: 2),
          Container(
            width: 14,
            height: 2,
            color: Colors.white,
          ),
        ],
      ),
    );
  }

  // Slack (colored octothorpe)
  Widget _buildSlackLogo() {
    return SizedBox(
      width: 22,
      height: 22,
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF36C5F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2EB67D),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFECB22E),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE01E5A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Webhook
  Widget _buildWebhookLogo() {
    return const Icon(
      Icons.hub_outlined,
      color: Color(0xFFE11D48),
      size: 20,
    );
  }

  // ========================================================
  // USER ACTIONS & DIALOGS
  // ========================================================
  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFFBA8A55), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }

  void _showConnectDialog(IntegrationItem item) {
    final apiKeyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            item.iconWidget,
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Connect ${item.title}',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF181513),
                                  ),
                                ),
                                Text(
                                  item.category,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF7E766B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 20, color: Color(0xFF7A7268)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'Authorize ThreadStock to sync inventory, sales events, and automate operations with ${item.title}.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF6E665B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // API Key / Endpoint input
                    Text(
                      'API Key / Secret Token',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: apiKeyController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Enter secret token or click OAuth Connect below',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 12, color: const Color(0xFF9E958A)),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 11),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2D8CC)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Test Connection simulated check
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEBE2D5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined,
                              size: 18, color: Color(0xFFBA8A55)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'End-to-end 256-bit encrypted credential storage. Automatic failover active.',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF6E665B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD8CEC1)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF1E1C1A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              item.status = IntegrationStatus.connected;
                            });
                            Navigator.pop(ctx);
                            _showFeedback('Connected ${item.title} successfully!');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1C1A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Connect Integration',
                            style: GoogleFonts.inter(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleConfigure(IntegrationItem item) {
    if (item.id == 'shopify') {
      setState(() => _selectedIntegrationDetail = 'shopify');
      widget.onSubNavChanged?.call(
        'Integrations > Shopify Connector',
        'Connect your Shopify store to sync products, inventory and orders with ThreadStock.',
      );
    } else {
      _showConfigureDialog(item);
    }
  }

  void _showConfigureDialog(IntegrationItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 490,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            item.iconWidget,
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Configure ${item.title}',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF181513),
                                  ),
                                ),
                                Text(
                                  'Status: Connected (Healthy)',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 20, color: Color(0xFF7A7268)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Sync Options
                    Text(
                      'Sync Preferences',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF7F2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEBE2D5)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Real-time Bidirectional Sync',
                                      style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    'Update catalog quantities and incoming orders instantaneously.',
                                    style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: const Color(0xFF7E766B)),
                                  ),
                                ],
                              ),
                              const Icon(Icons.toggle_on_rounded,
                                  color: Color(0xFF5C3E21), size: 36),
                            ],
                          ),
                          const Divider(height: 18, color: Color(0xFFEBE2D5)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Automated Error Reconciliation',
                                      style: GoogleFonts.inter(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600)),
                                  Text(
                                    'Retry failed payload dispatches up to 5 times.',
                                    style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: const Color(0xFF7E766B)),
                                  ),
                                ],
                              ),
                              const Icon(Icons.toggle_on_rounded,
                                  color: Color(0xFF5C3E21), size: 36),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              item.status = IntegrationStatus.notConnected;
                            });
                            Navigator.pop(ctx);
                            _showFeedback('Disconnected ${item.title}');
                          },
                          child: Text(
                            'Disconnect',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFFD32F2F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFD8CEC1)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF1E1C1A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _showFeedback(
                                    '${item.title} configuration updated and synced.');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E1C1A),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Text(
                                'Save Settings',
                                style: GoogleFonts.inter(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBrowseMarketplaceDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 520,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'App Marketplace & Catalog',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: Color(0xFF7A7268)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Explore planned connectors and third-party extensions verified for ThreadStock OS.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF6E665B),
                  ),
                ),
                const SizedBox(height: 18),

                // Upcoming integrations
                for (final upcoming in [
                  {
                    'name': 'WooCommerce',
                    'cat': 'E-Commerce',
                    'desc': 'WordPress store sync with automated stock management.'
                  },
                  {
                    'name': 'Zoho Books',
                    'cat': 'Accounting',
                    'desc': 'GST compliant cloud ledger and invoice generation.'
                  },
                  {
                    'name': 'Delhivery Direct',
                    'cat': 'Logistics',
                    'desc': 'Express nationwide courier dispatch & AWB label generation.'
                  },
                  {
                    'name': 'Salesforce CRM',
                    'cat': 'Enterprise',
                    'desc': 'B2B client order books and client accounts sync.'
                  },
                ]) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF7F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEBE2D5)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2D8CC)),
                          ),
                          child: const Icon(Icons.extension_outlined,
                              size: 18, color: Color(0xFF7A481B)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    upcoming['name']!,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF181513),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0EBE1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      upcoming['cat']!,
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF7E766B)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                upcoming['desc']!,
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF6E665B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showFeedback(
                                'Requested early access to ${upcoming['name']} integration');
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFBA8A55)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          child: Text(
                            'Request',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF946A36),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showContactSupportDialog() {
    final supportDescController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Request Custom Integration',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us about your proprietary ERP, warehouse automation hardware, or unique API needs.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF6E665B),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: supportDescController,
                maxLines: 4,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText:
                      'e.g. SAP Business One connector for Delhi central store with direct SQL or webhook dispatch...',
                  hintStyle: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF9E958A)),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2D8CC)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  color: const Color(0xFF7E766B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showFeedback(
                    'Support ticket created. Our integration engineer will reach out shortly.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1C1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Submit Request',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // ========================================================
  // BUILD METHOD & RESPONSIVE GRID
  // ========================================================
  @override
  Widget build(BuildContext context) {
    if (_selectedIntegrationDetail == 'shopify') {
      return ShopifyConnectorView(
        onBackToIntegrations: () {
          setState(() => _selectedIntegrationDetail = null);
          widget.onSubNavChanged?.call(
            'Settings > Integrations',
            'Link e-commerce channels, courier aggregators, and enterprise accounting software.',
          );
        },
        onSubNavChanged: widget.onSubNavChanged,
      );
    }

    // Filter integrations
    final filtered = _integrations.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery) ||
          item.description.toLowerCase().contains(_searchQuery) ||
          item.category.toLowerCase().contains(_searchQuery);

      final matchesCategory = _selectedCategory == 'All Categories' ||
          item.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    return Container(
      color: const Color(0xFFFAF7F2),
      child: SingleChildScrollView(
        child: DesktopContentConstraint(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                _buildHeaderRow(),
                const SizedBox(height: 22),

                // Responsive 3-Column Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    int crossAxisCount = 3;
                    if (width < 680) {
                      crossAxisCount = 1;
                    } else if (width < 980) {
                      crossAxisCount = 2;
                    }

                    if (filtered.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEBE2D5)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.search_off_rounded,
                                size: 40, color: Color(0xFFBA8A55)),
                            const SizedBox(height: 12),
                            Text(
                              'No integrations found',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF181513),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try adjusting your search terms or selecting "All Categories".',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFF7E766B),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final spacing = 20.0;
                    final totalSpacing = spacing * (crossAxisCount - 1);
                    final itemWidth = (width - totalSpacing) / crossAxisCount;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: [
                        for (final item in filtered)
                          SizedBox(
                            width: itemWidth,
                            child: _buildIntegrationCard(item),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Bottom Callout Banner
                _buildBottomSupportBanner(),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // HEADER ROW: Avatar + Title + Subtitle + Search & Filter
  // ========================================================
  Widget _buildHeaderRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 880;

        final titleSection = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFAF2E6),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8DDD0), width: 1.2),
              ),
              child: const Icon(
                Icons.extension_outlined,
                color: Color(0xFF7A481B),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Integrations Marketplace',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Link e-commerce channels, courier aggregators, and enterprise accounting software.',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6E665B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final controlsSection = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Search Input Field
            Container(
              width: 210,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDFD4C5)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      size: 17, color: Color(0xFF8C8478)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.inter(
                          fontSize: 12.5, fontWeight: FontWeight.w400),
                      decoration: InputDecoration(
                        hintText: 'Search integrations...',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF9E958A),
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    InkWell(
                      onTap: () => _searchController.clear(),
                      child: const Icon(Icons.close_rounded,
                          size: 15, color: Color(0xFF8C8478)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Category Dropdown
            Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDFD4C5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: Color(0xFF181513)),
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181513),
                  ),
                  items: _categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedCategory = val);
                    }
                  },
                ),
              ),
            ),
          ],
        );

        if (isWide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleSection),
              const SizedBox(width: 18),
              controlsSection,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 14),
              controlsSection,
            ],
          );
        }
      },
    );
  }

  // ========================================================
  // INTEGRATION CARD: Logo + Title/Cat + Status Pill + More + Desc + CTA
  // ========================================================
  Widget _buildIntegrationCard(IntegrationItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE2D5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Logo + Title/Subtitle + Status Pill + More Menu
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              item.iconWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.category.isNotEmpty && !item.isMarketplaceTile)
                      Text(
                        item.category,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Status Pill (Connected / Not Connected)
              if (!item.isMarketplaceTile) ...[
                _buildStatusPill(item.status),
                const SizedBox(width: 4),
              ],

              // Popup Menu
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'configure') {
                    _handleConfigure(item);
                  } else if (val == 'connect') {
                    _showConnectDialog(item);
                  } else if (val == 'disconnect') {
                    setState(() {
                      item.status = IntegrationStatus.notConnected;
                    });
                    _showFeedback('Disconnected ${item.title}');
                  } else if (val == 'sync') {
                    _showFeedback('Synced ${item.title} data');
                  }
                },
                itemBuilder: (ctx) => [
                  if (item.status == IntegrationStatus.connected) ...[
                    const PopupMenuItem(
                        value: 'configure', child: Text('Configure Settings')),
                    const PopupMenuItem(
                        value: 'sync', child: Text('Force Sync Now')),
                    const PopupMenuItem(
                        value: 'disconnect',
                        child: Text('Disconnect',
                            style: TextStyle(color: Colors.red))),
                  ] else ...[
                    const PopupMenuItem(
                        value: 'connect', child: Text('Connect Integration')),
                  ],
                ],
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.more_horiz_rounded,
                      size: 18, color: Color(0xFF7E766B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Description
          SizedBox(
            height: 42,
            child: Text(
              item.description,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF6E665B),
                height: 1.35,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 18),

          // Action Button
          _buildActionButton(item),
        ],
      ),
    );
  }

  // ========================================================
  // STATUS PILL (Connected / Not Connected)
  // ========================================================
  Widget _buildStatusPill(IntegrationStatus status) {
    final isConnected = status == IntegrationStatus.connected;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: isConnected ? const Color(0xFFE8F5E9) : const Color(0xFFF2F0EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(
              color: isConnected
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF8A8278),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isConnected ? 'Connected' : 'Not Connected',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isConnected
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF70675D),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // ACTION BUTTON: Configure → / Connect / Browse Marketplace →
  // ========================================================
  Widget _buildActionButton(IntegrationItem item) {
    if (item.isMarketplaceTile) {
      return SizedBox(
        width: double.infinity,
        height: 38,
        child: OutlinedButton(
          onPressed: _showBrowseMarketplaceDialog,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE2D8CC)),
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Browse Marketplace',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: Color(0xFF181513),
              ),
            ],
          ),
        ),
      );
    }

    if (item.status == IntegrationStatus.connected) {
      return SizedBox(
        width: double.infinity,
        height: 38,
        child: OutlinedButton(
          onPressed: () => _handleConfigure(item),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE2D8CC)),
            backgroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Configure',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: Color(0xFF181513),
              ),
            ],
          ),
        ),
      );
    }

    // Not Connected -> Dark Obsidian Solid "Connect"
    return SizedBox(
      width: double.infinity,
      height: 38,
      child: ElevatedButton(
        onPressed: () => _showConnectDialog(item),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1C1A),
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          'Connect',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ========================================================
  // BOTTOM CALLOUT: Need a custom integration? Contact Support
  // ========================================================
  Widget _buildBottomSupportBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3E7D3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 22,
            color: Color(0xFFBA8A55),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Need a custom integration? Contact our support team to set up a tailored solution for your business.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF734E1D),
              ),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: _showContactSupportDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE2D8CC)),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Contact Support',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF181513),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
