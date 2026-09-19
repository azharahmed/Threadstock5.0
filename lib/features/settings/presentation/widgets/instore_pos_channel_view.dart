// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class PosLocationAssignment {
  final String id;
  final String name;
  final int stockCount;
  bool isEnabled;

  PosLocationAssignment({
    required this.id,
    required this.name,
    required this.stockCount,
    this.isEnabled = false,
  });
}

class InStorePosChannelView extends StatefulWidget {
  final VoidCallback? onBackToChannels;

  const InStorePosChannelView({
    super.key,
    this.onBackToChannels,
  });

  @override
  State<InStorePosChannelView> createState() => _InStorePosChannelViewState();
}

class _InStorePosChannelViewState extends State<InStorePosChannelView> {
  // Assigned Locations
  late List<PosLocationAssignment> _locations;

  // Payment Integrations
  bool _cashTransactions = true;
  bool _cardSwipeTap = true;
  bool _upiQrScan = true;
  bool _storeCredit = false;

  // Receipt Settings
  bool _autoPrintReceipt = true;
  bool _enableDigitalEmailReceipts = true;

  // Inventory Synchronization
  String _syncFrequency = 'Real-time';

  // Connected state
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _locations = [
      PosLocationAssignment(
        id: 'central_warehouse',
        name: 'Central Warehouse (Zone A)',
        stockCount: 14200,
        isEnabled: true,
      ),
      PosLocationAssignment(
        id: 'delhi_hub',
        name: 'Delhi Flagship Hub',
        stockCount: 3450,
        isEnabled: true,
      ),
      PosLocationAssignment(
        id: 'mumbai_store',
        name: 'Mumbai Phoenix Store',
        stockCount: 0,
        isEnabled: false,
      ),
    ];
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded,
                color: Color(0xFFBA8A55), size: 18),
            const SizedBox(width: 10),
            Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(milliseconds: 2000),
      ),
    );
  }

  void _showDisconnectConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Disconnect In-Store POS?',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
            ),
          ),
          content: Text(
            'Disconnecting will halt terminal transactions across physical counter registers. Active sessions will require re-authentication.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF6E665B),
            ),
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
                setState(() => _isConnected = false);
                Navigator.pop(ctx);
                _showFeedback('In-Store POS channel disconnected');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Disconnect',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddLocationDialog() {
    final locationController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Assign Location to POS',
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
                'Enter location name or select an operational hub to link with this POS channel.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF6E665B),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Bengaluru Retail Boutique',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                final name = locationController.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _locations.add(
                      PosLocationAssignment(
                        id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
                        name: name,
                        stockCount: 1200,
                        isEnabled: true,
                      ),
                    );
                  });
                  _showFeedback('Linked "$name" to POS channel');
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1C1A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Add Location',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
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
                // Top Header Row
                _buildHeaderRow(),
                const SizedBox(height: 22),

                // Responsive 2-Column Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 920;
                    if (isWide) {
                      final colWidth = (constraints.maxWidth - 22) / 2;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Assigned Locations + Payment Integrations
                          SizedBox(
                            width: colWidth,
                            child: Column(
                              children: [
                                _buildAssignedLocationsCard(),
                                const SizedBox(height: 20),
                                _buildPaymentIntegrationsCard(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 22),

                          // Right Column: Receipt Settings + Inventory Sync + Status Callout
                          SizedBox(
                            width: colWidth,
                            child: Column(
                              children: [
                                _buildReceiptSettingsCard(),
                                const SizedBox(height: 20),
                                _buildInventorySyncCard(),
                                const SizedBox(height: 20),
                                _buildChannelStatusCard(),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildAssignedLocationsCard(),
                          const SizedBox(height: 20),
                          _buildPaymentIntegrationsCard(),
                          const SizedBox(height: 20),
                          _buildReceiptSettingsCard(),
                          const SizedBox(height: 20),
                          _buildInventorySyncCard(),
                          const SizedBox(height: 20),
                          _buildChannelStatusCard(),
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
  // HEADER ROW: Avatar + Title + Status + Disconnect CTA
  // ========================================================
  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Icon Avatar + Title & Status + Subtitle
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: const Color(0xFFE8DDD0), width: 1.2),
                ),
                child: const Icon(
                  Icons.storefront_outlined,
                  color: Color(0xFF7A481B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'In-Store POS Channel',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            color: const Color(0xFF181513),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isConnected
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _isConnected
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isConnected ? 'Connected' : 'Disconnected',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _isConnected
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Manage locations access, enabled registers, and receipts configurations for retail hubs.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
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
        const SizedBox(width: 20),

        // Right Button: Disconnect Channel
        OutlinedButton.icon(
          onPressed: _showDisconnectConfirmation,
          icon: const Icon(
            Icons.power_settings_new_rounded,
            size: 16,
            color: Color(0xFFD32F2F),
          ),
          label: Text(
            'Disconnect Channel',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFD32F2F),
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFF3C8C8)),
            backgroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // CARD 1: Assigned Locations
  // ========================================================
  Widget _buildAssignedLocationsCard() {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row + Add Location Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBF4E8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.location_on_outlined,
                          size: 19,
                          color: Color(0xFF7A481B),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assigned Locations',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF181513),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select which locations can use this POS channel.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF7E766B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _showAddLocationDialog,
                  icon: const Icon(Icons.add_rounded,
                      size: 15, color: Color(0xFF181513)),
                  label: Text(
                    'Add Location',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2D8CC)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Location List Items
            for (int i = 0; i < _locations.length; i++) ...[
              _buildLocationRow(_locations[i]),
              if (i < _locations.length - 1)
                const Divider(height: 16, color: Color(0xFFF4ECE1)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(PosLocationAssignment loc) {
    return InkWell(
      onTap: () {
        setState(() => loc.isEnabled = !loc.isEnabled);
        _showFeedback(loc.isEnabled
            ? 'Linked ${loc.name} to POS channel'
            : 'Unlinked ${loc.name} from POS channel');
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: loc.isEnabled ? const Color(0xFF5C3E21) : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: loc.isEnabled
                      ? const Color(0xFF5C3E21)
                      : const Color(0xFFDCD2C3),
                  width: 1.5,
                ),
              ),
              child: loc.isEnabled
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 14),

            // Location Name
            Expanded(
              child: Text(
                loc.name,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight:
                      loc.isEnabled ? FontWeight.w600 : FontWeight.w500,
                  color: const Color(0xFF181513),
                ),
              ),
            ),

            // Stock Count
            Text(
              loc.isEnabled
                  ? 'Stock Count: ${_formatCount(loc.stockCount)}'
                  : 'Stock Count: 0 (Unlinked)',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF7E766B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      final whole = count ~/ 1000;
      final rem = (count % 1000).toString().padLeft(3, '0');
      return '$whole,$rem';
    }
    return count.toString();
  }

  // ========================================================
  // CARD 2: Payment Integrations
  // ========================================================
  Widget _buildPaymentIntegrationsCard() {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.credit_card_outlined,
                    size: 19,
                    color: Color(0xFF7A481B),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Integrations',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Enable and configure supported payment methods.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Payment Methods List
            _buildPaymentMethodRow(
              icon: Icons.payments_outlined,
              title: 'Cash Transactions',
              subtitle: 'Allow cash drawers reconciliation at day closure.',
              value: _cashTransactions,
              onChanged: (val) {
                setState(() => _cashTransactions = val);
                _showFeedback(_cashTransactions
                    ? 'Cash transactions enabled'
                    : 'Cash transactions disabled');
              },
            ),
            const Divider(height: 20, color: Color(0xFFF4ECE1)),

            _buildPaymentMethodRow(
              icon: Icons.credit_card_rounded,
              title: 'Card Swipe & Tap',
              subtitle: 'Link central checkout pin pads.',
              value: _cardSwipeTap,
              onChanged: (val) {
                setState(() => _cardSwipeTap = val);
                _showFeedback(_cardSwipeTap
                    ? 'Card swipe & tap enabled'
                    : 'Card swipe & tap disabled');
              },
            ),
            const Divider(height: 20, color: Color(0xFFF4ECE1)),

            _buildPaymentMethodRow(
              icon: Icons.qr_code_2_rounded,
              title: 'UPI & QR Scan',
              subtitle:
                  'Show immediate dynamic UPI QR code on billing display.',
              value: _upiQrScan,
              onChanged: (val) {
                setState(() => _upiQrScan = val);
                _showFeedback(_upiQrScan
                    ? 'UPI & QR scan enabled'
                    : 'UPI & QR scan disabled');
              },
            ),
            const Divider(height: 20, color: Color(0xFFF4ECE1)),

            _buildPaymentMethodRow(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Store Credit',
              subtitle: 'Redeem issue notes directly.',
              value: _storeCredit,
              onChanged: (val) {
                setState(() => _storeCredit = val);
                _showFeedback(_storeCredit
                    ? 'Store credit redemption enabled'
                    : 'Store credit redemption disabled');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFFAF2E6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF7A481B), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildToggle(value: value, onChanged: onChanged),
      ],
    );
  }

  // ========================================================
  // CARD 3: Receipt Settings
  // ========================================================
  Widget _buildReceiptSettingsCard() {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: 19,
                    color: Color(0xFF7A481B),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receipt Settings',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Configure how receipts are generated and delivered.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Item 1: Auto-Print Receipt after checkout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Print Receipt after checkout',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Print receipt automatically on successful payment.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _buildToggle(
                  value: _autoPrintReceipt,
                  onChanged: (val) {
                    setState(() => _autoPrintReceipt = val);
                    _showFeedback(_autoPrintReceipt
                        ? 'Auto-print receipts enabled'
                        : 'Auto-print receipts disabled');
                  },
                ),
              ],
            ),
            const Divider(height: 24, color: Color(0xFFF4ECE1)),

            // Item 2: Enable digital email receipts
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enable digital email receipts',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Send receipt to customer via email.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _buildToggle(
                  value: _enableDigitalEmailReceipts,
                  onChanged: (val) {
                    setState(() => _enableDigitalEmailReceipts = val);
                    _showFeedback(_enableDigitalEmailReceipts
                        ? 'Digital email receipts enabled'
                        : 'Digital email receipts disabled');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // CARD 4: Inventory Synchronization
  // ========================================================
  Widget _buildInventorySyncCard() {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title Header
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4E8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.sync_rounded,
                    size: 19,
                    color: Color(0xFF7A481B),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inventory Synchronization',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Control how often this channel syncs inventory data.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Sync Frequency Title
            Text(
              'SYNC FREQUENCY',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: const Color(0xFF7E766B),
              ),
            ),
            const SizedBox(height: 8),

            // Segmented Options: Real-time, Batch (15m), Batch (Hourly), End of Day
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2D8CC)),
              ),
              child: Row(
                children: [
                  _buildSyncOption('Real-time'),
                  _buildSyncOption('Batch (15m)'),
                  _buildSyncOption('Batch (Hourly)'),
                  _buildSyncOption('End of Day'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Last Successful Sync Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEBE2D5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Last Successful Sync',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6E665B),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E7D32),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '3 mins ago (OK)',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncOption(String label) {
    final isSelected = _syncFrequency == label;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _syncFrequency = label);
          _showFeedback('Sync frequency set to $label');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF5EBE1) : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF181513)
                  : const Color(0xFF6E665B),
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // CARD 5: Channel Status Callout
  // ========================================================
  Widget _buildChannelStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3E7D3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 22,
            color: Color(0xFFBA8A55),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Channel Status',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'In-Store POS is connected and running normally. All enabled locations are syncing inventory and transactions.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6E665B),
                    height: 1.35,
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
  // PILL TOGGLE
  // ========================================================
  Widget _buildToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 2.5),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF5C3E21) : const Color(0xFFE2D8CC),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 19,
          height: 19,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
