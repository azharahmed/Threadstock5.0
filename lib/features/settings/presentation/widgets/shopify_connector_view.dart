// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class ShopifyConnectorView extends StatefulWidget {
  final VoidCallback? onBackToIntegrations;
  final void Function(String title, String subtitle)? onSubNavChanged;

  const ShopifyConnectorView({
    super.key,
    this.onBackToIntegrations,
    this.onSubNavChanged,
  });

  @override
  State<ShopifyConnectorView> createState() => _ShopifyConnectorViewState();
}

class _ShopifyConnectorViewState extends State<ShopifyConnectorView> {
  int _currentStep = 2; // Step 2: Configure

  // Form Fields
  late final TextEditingController _storeUrlController;
  String _syncDirection = 'Two-way (Real-time Bidirectional)';
  String _syncFrequency = 'Real-time (Triggered by Webhooks)';

  // Product Fields to Synchronize checkboxes
  bool _syncTitleDesc = true;
  bool _syncPriceCompare = true;
  bool _syncSkuBarcode = true;
  bool _syncImagesMedia = true;
  bool _syncVariantsOptions = true;
  bool _syncInventoryLevels = false;

  // Verification state
  bool _isTestingConnection = false;
  String _lastVerified = '3 minutes ago';

  @override
  void initState() {
    super.initState();
    _storeUrlController =
        TextEditingController(text: 'mystore.myshopify.com');
  }

  @override
  void dispose() {
    _storeUrlController.dispose();
    super.dispose();
  }

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

  void _testConnection() async {
    setState(() => _isTestingConnection = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _isTestingConnection = false;
      _lastVerified = 'Just now';
    });
    _showFeedback(
        'Connection to ${_storeUrlController.text} verified successfully (24ms latency).');
  }

  void _showIntegrationGuideDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 540,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shopify Integration Guide',
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
                const SizedBox(height: 12),
                Text(
                  'Follow these steps in your Shopify Admin to generate a custom app connection:',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6E665B),
                  ),
                ),
                const SizedBox(height: 16),
                _buildGuideStep(
                  stepNumber: '1',
                  title: 'Navigate to App Settings',
                  desc: 'In Shopify Admin, go to Settings > Apps and sales channels > Develop apps.',
                ),
                _buildGuideStep(
                  stepNumber: '2',
                  title: 'Configure Admin API Scopes',
                  desc: 'Enable read_products, write_products, read_inventory, write_orders, and read_fulfillments.',
                ),
                _buildGuideStep(
                  stepNumber: '3',
                  title: 'Install App & Copy Access Token',
                  desc: 'Install the app and paste the generated Admin API access token into ThreadStock.',
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1C1A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Got It',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuideStep({
    required String stepNumber,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFFAF2E6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF7A481B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF7E766B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDocumentationDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Documentation & Webhooks API',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          content: Text(
            'ThreadStock uses Shopify Webhooks (API version 2024-10) for instant event dispatching: products/create, products/update, orders/paid, and inventory_levels/update.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6E665B)),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1C1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Close',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _showSupportDialog() {
    final msgController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Contact Integration Support',
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
                'Need assistance aligning multi-location stock or custom Shopify liquid tags?',
                style: GoogleFonts.inter(
                    fontSize: 12.5, color: const Color(0xFF6E665B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: msgController,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Describe your question or issue...',
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
              child: Text('Cancel',
                  style: GoogleFonts.inter(color: const Color(0xFF7E766B))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showFeedback(
                    'Support message sent. Our Shopify specialist will reply shortly.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1C1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Send Message',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFAF7F2),
      child: SingleChildScrollView(
        child: DesktopContentConstraint(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: Icon + Title + Subtitle + View Integration Guide
                _buildHeaderRow(),
                const SizedBox(height: 20),

                // Stepper Bar: Authorize -> Configure -> Map Fields -> Sync Catalog
                _buildStepperBar(),
                const SizedBox(height: 22),

                // Main 2-Column Content: Left (Configure Connection) + Right (Status / Recommendation / Help)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 880;
                    if (isWide) {
                      final leftWidth = constraints.maxWidth * 0.60;
                      final rightWidth = constraints.maxWidth - leftWidth - 22;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Configure Connection Card
                          SizedBox(
                            width: leftWidth,
                            child: _buildConfigureConnectionCard(),
                          ),
                          const SizedBox(width: 22),

                          // Right Column: 3 Complementary Cards
                          SizedBox(
                            width: rightWidth,
                            child: Column(
                              children: [
                                _buildConnectionStatusCard(),
                                const SizedBox(height: 18),
                                _buildSyncRecommendationCard(),
                                const SizedBox(height: 18),
                                _buildNeedHelpCard(),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildConfigureConnectionCard(),
                          const SizedBox(height: 20),
                          _buildConnectionStatusCard(),
                          const SizedBox(height: 18),
                          _buildSyncRecommendationCard(),
                          const SizedBox(height: 18),
                          _buildNeedHelpCard(),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // HEADER ROW: Shopify Logo + Title + Subtitle + Action Button
  // ========================================================
  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Logo + Title + Subtitle
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7EA),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFFD4E8C8), width: 1.2),
                ),
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_bag_rounded,
                      color: Color(0xFF5E8E3E),
                      size: 26,
                    ),
                    Positioned(
                      top: 15,
                      child: Text(
                        'S',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shopify Connector',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Connect your Shopify store to sync products, inventory and orders with ThreadStock.',
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
          ),
        ),
        const SizedBox(width: 16),

        // Right: View Integration Guide Outlined Button
        OutlinedButton.icon(
          onPressed: _showIntegrationGuideDialog,
          icon: const Icon(
            Icons.menu_book_outlined,
            size: 16,
            color: Color(0xFF181513),
          ),
          label: Text(
            'View Integration Guide',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE2D8CC)),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // STEPPER BAR: Authorize -> Configure -> Map Fields -> Sync Catalog
  // ========================================================
  Widget _buildStepperBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEBE2D5)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 640;
          return Row(
            children: [
              // Step 1: Authorize (Completed when >= 2)
              _buildStepItem(
                stepIndex: 1,
                label: 'Authorize',
                isCompleted: _currentStep > 1,
                isActive: _currentStep == 1,
                isNarrow: isNarrow,
              ),

              // Connector Line 1 (Brown/Cognac active when >= 2)
              Expanded(
                child: Container(
                  height: 2,
                  color: _currentStep >= 2
                      ? const Color(0xFFB39274)
                      : const Color(0xFFE2D8CC),
                ),
              ),

              // Step 2: Configure (Active at step 2, completed when > 2)
              _buildStepItem(
                stepIndex: 2,
                label: 'Configure',
                isCompleted: _currentStep > 2,
                isActive: _currentStep == 2,
                isNarrow: isNarrow,
              ),

              // Connector Line 2 (Active when >= 3)
              Expanded(
                child: Container(
                  height: 2,
                  color: _currentStep >= 3
                      ? const Color(0xFFB39274)
                      : const Color(0xFFE2D8CC),
                ),
              ),

              // Step 3: Map Fields (Active at step 3, completed when > 3)
              _buildStepItem(
                stepIndex: 3,
                label: 'Map Fields',
                isCompleted: _currentStep > 3,
                isActive: _currentStep == 3,
                isNarrow: isNarrow,
              ),

              // Connector Line 3 (Active when >= 4)
              Expanded(
                child: Container(
                  height: 2,
                  color: _currentStep >= 4
                      ? const Color(0xFFB39274)
                      : const Color(0xFFE2D8CC),
                ),
              ),

              // Step 4: Sync Catalog (Active at step 4)
              _buildStepItem(
                stepIndex: 4,
                label: 'Sync Catalog',
                isCompleted: false,
                isActive: _currentStep == 4,
                isNarrow: isNarrow,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepItem({
    required int stepIndex,
    required String label,
    required bool isCompleted,
    required bool isActive,
    required bool isNarrow,
  }) {
    Widget circleWidget;
    if (isCompleted) {
      circleWidget = Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFF5C3E21),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.check_rounded,
          size: 14,
          color: Colors.white,
        ),
      );
    } else if (isActive) {
      circleWidget = Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: Color(0xFF5C3E21),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          '$stepIndex',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    } else {
      circleWidget = Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFDCD2C3), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          '$stepIndex',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF7E766B),
          ),
        ),
      );
    }

    return InkWell(
      onTap: () {
        setState(() => _currentStep = stepIndex);
        _showFeedback('Viewing Step $stepIndex: $label');
      },
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            circleWidget,
            if (!isNarrow) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight:
                      (isActive || isCompleted) ? FontWeight.w700 : FontWeight.w500,
                  color: (isActive || isCompleted)
                      ? const Color(0xFF181513)
                      : const Color(0xFF7E766B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========================================================
  // LEFT COLUMN: CONFIGURE CONNECTION CARD
  // ========================================================
  Widget _buildConfigureConnectionCard() {
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title + Subtitle
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.settings_outlined,
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
                      'Configure Connection',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Enter your Shopify store details and sync preferences.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Field 1: Shopify Store URL
          Text(
            'Shopify Store URL',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _storeUrlController,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF181513)),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2D8CC)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2D8CC)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFBA8A55), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Shopify store domain (e.g. mystore.myshopify.com)',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 18),

          // Field 2: Sync Direction
          Text(
            'Sync Direction',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2D8CC)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _syncDirection,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: Color(0xFF181513)),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF181513),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Two-way (Real-time Bidirectional)',
                    child: Text('Two-way (Real-time Bidirectional)'),
                  ),
                  DropdownMenuItem(
                    value: 'One-way (Shopify to ThreadStock)',
                    child: Text('One-way (Shopify to ThreadStock)'),
                  ),
                  DropdownMenuItem(
                    value: 'One-way (ThreadStock to Shopify)',
                    child: Text('One-way (ThreadStock to Shopify)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _syncDirection = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sync products, inventory, and orders between Shopify and ThreadStock.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 18),

          // Field 3: Sync Frequency
          Text(
            'Sync Frequency',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2D8CC)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _syncFrequency,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: Color(0xFF181513)),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF181513),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Real-time (Triggered by Webhooks)',
                    child: Text('Real-time (Triggered by Webhooks)'),
                  ),
                  DropdownMenuItem(
                    value: 'Hourly (Batch Sync)',
                    child: Text('Hourly (Batch Sync)'),
                  ),
                  DropdownMenuItem(
                    value: 'Daily at Midnight',
                    child: Text('Daily at Midnight'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _syncFrequency = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Changes are synced instantly when events occur in either system.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 22),

          // Field 4: Product Fields to Synchronize
          Text(
            'Product Fields to Synchronize',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 12),

          // 2-Column Checkboxes
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Column 1
              Expanded(
                child: Column(
                  children: [
                    _buildCheckboxRow(
                      label: 'Title & Description',
                      value: _syncTitleDesc,
                      onChanged: (val) => setState(() => _syncTitleDesc = val),
                    ),
                    const SizedBox(height: 10),
                    _buildCheckboxRow(
                      label: 'Price & Compare Price',
                      value: _syncPriceCompare,
                      onChanged: (val) =>
                          setState(() => _syncPriceCompare = val),
                    ),
                    const SizedBox(height: 10),
                    _buildCheckboxRow(
                      label: 'SKU & Barcode',
                      value: _syncSkuBarcode,
                      onChanged: (val) =>
                          setState(() => _syncSkuBarcode = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Column 2
              Expanded(
                child: Column(
                  children: [
                    _buildCheckboxRow(
                      label: 'Images & Media',
                      value: _syncImagesMedia,
                      onChanged: (val) =>
                          setState(() => _syncImagesMedia = val),
                    ),
                    const SizedBox(height: 10),
                    _buildCheckboxRow(
                      label: 'Variants & Options',
                      value: _syncVariantsOptions,
                      onChanged: (val) =>
                          setState(() => _syncVariantsOptions = val),
                    ),
                    const SizedBox(height: 10),
                    _buildCheckboxRow(
                      label: 'Inventory Levels',
                      value: _syncInventoryLevels,
                      onChanged: (val) =>
                          setState(() => _syncInventoryLevels = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You can modify field mappings in the next step.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7E766B),
            ),
          ),
          const SizedBox(height: 28),

          // Bottom Action Buttons: Back + Continue to Mapping →
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: widget.onBackToIntegrations,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD8CEC1)),
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Back',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() => _currentStep = 3);
                  _showFeedback(
                      'Saved connection preferences. Navigating to Map Fields.');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E3F16),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continue to Mapping',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: Colors.white,
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

  Widget _buildCheckboxRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF5C3E21) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: value
                      ? const Color(0xFF5C3E21)
                      : const Color(0xFFDCD2C3),
                  width: 1.4,
                ),
              ),
              alignment: Alignment.center,
              child: value
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
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
    );
  }

  // ========================================================
  // RIGHT COLUMN CARD 1: SHOPIFY API CONNECTED STATUS
  // ========================================================
  Widget _buildConnectionStatusCard() {
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
          // Top Row: Green dot + Title + Test Connection Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Shopify API Connected',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: _isTestingConnection ? null : _testConnection,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE2D8CC)),
                  backgroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _isTestingConnection
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.8,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFBA8A55)),
                        ),
                      )
                    : Text(
                        'Test Connection',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Explanatory copy with bold domain
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF6E665B),
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'Credentials for '),
                TextSpan(
                  text: _storeUrlController.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF181513),
                  ),
                ),
                const TextSpan(
                  text:
                      ' have been verified. In the next step, you will align Shopify variant attributes with ThreadStock product dimensions.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Metadata key-values
          _buildMetadataRow(
            icon: Icons.storefront_outlined,
            label: 'Store',
            value: _storeUrlController.text,
          ),
          const SizedBox(height: 10),
          _buildMetadataRow(
            icon: Icons.verified_user_outlined,
            label: 'Plan',
            value: 'Shopify Plus',
          ),
          const SizedBox(height: 10),
          _buildMetadataRow(
            icon: Icons.alt_route_rounded,
            label: 'API Version',
            value: '2024-10',
          ),
          const SizedBox(height: 10),

          // Last Verified + Success Badge
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 16, color: Color(0xFF7E766B)),
              const SizedBox(width: 10),
              Text(
                'Last Verified',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7E766B),
                ),
              ),
              const Spacer(),
              Text(
                _lastVerified,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6E665B),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Success',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF7E766B)),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF7E766B),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181513),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // RIGHT COLUMN CARD 2: SYNC RECOMMENDATION
  // ========================================================
  Widget _buildSyncRecommendationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3E7D3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            size: 22,
            color: Color(0xFFBA8A55),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync Recommendation',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF8C531B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We suggest mapping "SKU" to ThreadStock standard identifier and selecting "Two-way" sync to ensure stock integrity across physical and digital storefronts.',
                  style: GoogleFonts.inter(
                    fontSize: 11.8,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6E665B),
                    height: 1.38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // RIGHT COLUMN CARD 3: NEED HELP?
  // ========================================================
  Widget _buildNeedHelpCard() {
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Help icon + Title + Subtitle
          Row(
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 20,
                color: Color(0xFF7E766B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need Help?',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    Text(
                      'Check our integration guide or contact support for assistance.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Two Links: View Documentation -> | Contact Support ->
          Row(
            children: [
              InkWell(
                onTap: _showDocumentationDialog,
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 14,
                      color: Color(0xFF181513),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'View Documentation →',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: _showSupportDialog,
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      size: 14,
                      color: Color(0xFF181513),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Contact Support →',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
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
}
