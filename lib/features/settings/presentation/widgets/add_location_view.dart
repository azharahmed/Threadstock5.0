// ignore_for_file: deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class AddLocationView extends StatefulWidget {
  const AddLocationView({
    super.key,
    this.onCancel,
    this.onCreated,
  });

  final VoidCallback? onCancel;
  final ValueChanged<String>? onCreated;

  @override
  State<AddLocationView> createState() => _AddLocationViewState();
}

class _AddLocationViewState extends State<AddLocationView> {
  // General Information
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String _locationType = 'Retail Store';

  // Physical Address & Localization
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _cityController = TextEditingController(text: 'Bengaluru');
  final TextEditingController _stateController = TextEditingController(text: 'Karnataka');
  final TextEditingController _postalCodeController = TextEditingController(text: '560066');
  String _country = 'India (IN)';
  String _timezone = 'IST (GMT+5:30)';

  // Operational Logistics Matrix
  bool _allowDirectSales = true;
  bool _allowInventoryReceiving = true;
  bool _allowInternalTransfers = true;
  bool _allowScheduledStockCounts = false;

  // Hardware & Receipts (Optional)
  String _defaultTaxRule = 'GST Schema (18%)';
  String _receiptTemplate = 'Standard Minimalist Receipt';
  String _assignedPrinter = 'Zebra ZD420 (Zone A)';

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _handleCreate() {
    final locationName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'New Operational Node';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFBA8A55), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Location "$locationName" created and initialized successfully.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
    widget.onCreated?.call(locationName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 20,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row: Title + Subtitle + Action Buttons (Cancel / Create Location)
              _buildHeader(),
              const SizedBox(height: 24),

              // Card 1: GENERAL INFORMATION
              _buildGeneralInfoCard(),
              const SizedBox(height: 18),

              // Card 2: PHYSICAL ADDRESS & LOCALIZATION
              _buildAddressCard(),
              const SizedBox(height: 18),

              // Card 3: OPERATIONAL LOGISTICS MATRIX
              _buildLogisticsMatrixCard(),
              const SizedBox(height: 18),

              // Card 4: HARDWARE & RECEIPTS (OPTIONAL)
              _buildHardwareReceiptsCard(),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // HEADER ROW
  // ========================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Location',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF181513),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Introduce a new operational physical store, warehouse facility, or stockroom partition.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6E665B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // Action Buttons: [Cancel] and [Create Location]
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cancel Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onCancel,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDFD6C9)),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Create Location Button
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleCreate,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181513),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E1C1A).withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Create Location',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================
  // CARD 1: GENERAL INFORMATION
  // ========================================================
  Widget _buildGeneralInfoCard() {
    return _buildCardWrapper(
      title: 'GENERAL INFORMATION',
      child: Row(
        children: [
          // Location Name
          Expanded(
            child: _buildInputField(
              label: 'Location Name',
              hint: 'e.g. Bangalore Whitefield Store',
              controller: _nameController,
            ),
          ),
          const SizedBox(width: 16),

          // Location Code
          Expanded(
            child: _buildInputField(
              label: 'Location Code',
              hint: 'e.g. BLR-WHFD-02',
              controller: _codeController,
            ),
          ),
          const SizedBox(width: 16),

          // Location Type
          Expanded(
            child: _buildDropdownField(
              label: 'Location Type',
              value: _locationType,
              options: const [
                'Retail Store',
                'Flagship Retail',
                'Storage Node / Warehouse',
                'Showroom',
                'Pop-up Boutique',
              ],
              onSelected: (val) => setState(() => _locationType = val),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // CARD 2: PHYSICAL ADDRESS & LOCALIZATION
  // ========================================================
  Widget _buildAddressCard() {
    return _buildCardWrapper(
      title: 'PHYSICAL ADDRESS & LOCALIZATION',
      child: Column(
        children: [
          // Row 1: Street Address, City, State / Region
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Street Address',
                  hint: 'e.g. 12, Whitefield Main Road',
                  controller: _streetController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  label: 'City',
                  hint: 'Bengaluru',
                  controller: _cityController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  label: 'State / Region',
                  hint: 'Karnataka',
                  controller: _stateController,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Row 2: Postal / ZIP Code, Country, Local Timezone
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  label: 'Postal / ZIP Code',
                  hint: '560066',
                  controller: _postalCodeController,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  label: 'Country',
                  value: _country,
                  options: const [
                    'India (IN)',
                    'United States (US)',
                    'United Kingdom (UK)',
                    'United Arab Emirates (AE)',
                    'Singapore (SG)',
                  ],
                  onSelected: (val) => setState(() => _country = val),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdownField(
                  label: 'Local Timezone',
                  value: _timezone,
                  options: const [
                    'IST (GMT+5:30)',
                    'GMT (GMT+0:00)',
                    'EST (GMT-5:00)',
                    'PST (GMT-8:00)',
                  ],
                  onSelected: (val) => setState(() => _timezone = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ========================================================
  // CARD 3: OPERATIONAL LOGISTICS MATRIX
  // ========================================================
  Widget _buildLogisticsMatrixCard() {
    return _buildCardWrapper(
      title: 'OPERATIONAL LOGISTICS MATRIX',
      child: Column(
        children: [
          _buildToggleRow(
            title: 'Allow Direct Sales',
            subtitle: 'Enable Point of Sale checkouts and customer billing from this node',
            value: _allowDirectSales,
            onChanged: (val) => setState(() => _allowDirectSales = val),
            isLast: false,
          ),
          _buildToggleRow(
            title: 'Allow Inventory Receiving',
            subtitle: 'Authorise staff to check in incoming stock from suppliers directly',
            value: _allowInventoryReceiving,
            onChanged: (val) => setState(() => _allowInventoryReceiving = val),
            isLast: false,
          ),
          _buildToggleRow(
            title: 'Allow Internal Transfers',
            subtitle: 'Allow logistics transfers to send and receive inventory from other zones',
            value: _allowInternalTransfers,
            onChanged: (val) => setState(() => _allowInternalTransfers = val),
            isLast: false,
          ),
          _buildToggleRow(
            title: 'Allow Scheduled Stock Counts',
            subtitle: 'Enable periodic barcode cycle audits for operational safety',
            value: _allowScheduledStockCounts,
            onChanged: (val) => setState(() => _allowScheduledStockCounts = val),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isLast,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
                    color: const Color(0xFF7A7268),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Transform.scale(
            scale: 0.82,
            child: CupertinoSwitch(
              value: value,
              activeColor: const Color(0xFF2E7D32),
              trackColor: const Color(0xFFE5E0D8),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // CARD 4: HARDWARE & RECEIPTS (OPTIONAL)
  // ========================================================
  Widget _buildHardwareReceiptsCard() {
    return _buildCardWrapper(
      title: 'HARDWARE & RECEIPTS (OPTIONAL)',
      child: Row(
        children: [
          // Default Tax Rule
          Expanded(
            child: _buildDropdownField(
              label: 'Default Tax Rule',
              value: _defaultTaxRule,
              options: const [
                'GST Schema (18%)',
                'Zero Rated Export (0%)',
                'Standard VAT (12%)',
                'Exempt Goods',
              ],
              onSelected: (val) => setState(() => _defaultTaxRule = val),
            ),
          ),
          const SizedBox(width: 16),

          // Receipt Template
          Expanded(
            child: _buildDropdownField(
              label: 'Receipt Template',
              value: _receiptTemplate,
              options: const [
                'Standard Minimalist Receipt',
                'Luxury Boutique Invoice',
                'Compact Thermal Slip',
                'Digital e-Receipt Only',
              ],
              onSelected: (val) => setState(() => _receiptTemplate = val),
            ),
          ),
          const SizedBox(width: 16),

          // Assigned Label Printer
          Expanded(
            child: _buildDropdownField(
              label: 'Assigned Label Printer',
              value: _assignedPrinter,
              options: const [
                'Zebra ZD420 (Zone A)',
                'Brother QL-820NWB (Zone B)',
                'Dymo LabelWriter 450',
                'Network AirPrint Default',
              ],
              onSelected: (val) => setState(() => _assignedPrinter = val),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // REUSABLE CARD WRAPPER
  // ========================================================
  Widget _buildCardWrapper({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEBE2D5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: const Color(0xFF1E1C1A),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF474035),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDFD6C9)),
          ),
          child: Center(
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF9E958A),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF474035),
          ),
        ),
        const SizedBox(height: 6),
        PopupMenuButton<String>(
          onSelected: onSelected,
          color: const Color(0xFFFAF7F2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFDFD4C5)),
          ),
          itemBuilder: (ctx) => options.map((opt) {
            final isSelected = opt == value;
            return PopupMenuItem<String>(
              value: opt,
              height: 38,
              child: Row(
                children: [
                  Text(
                    opt,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? const Color(0xFF1E1C1A) : const Color(0xFF4A4237),
                    ),
                  ),
                  if (isSelected) ...[
                    const Spacer(),
                    const Icon(Icons.check_rounded, size: 16, color: Color(0xFFBA8A55)),
                  ],
                ],
              ),
            );
          }).toList(),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD6C9)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF6B6358),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
