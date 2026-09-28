// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

enum LabelTemplateType {
  standard('Standard (50 × 25 mm)', '50 × 25 mm', 170.0),
  largeShipping('Large Shipping (100 × 50 mm)', '100 × 50 mm', 220.0),
  jewelryTag('Jewelry Tag (Loop Cable)', '28 × 12 mm', 150.0);

  final String label;
  final String dimensions;
  final double previewHeight;
  const LabelTemplateType(this.label, this.dimensions, this.previewHeight);
}

class PrinterDevice {
  final String id;
  final String name;
  final String location;
  final String type;
  bool isReady;

  PrinterDevice({
    required this.id,
    required this.name,
    required this.location,
    required this.type,
    required this.isReady,
  });
}

class BarcodePrintingView extends StatefulWidget {
  final VoidCallback? onBackToSettings;
  final void Function(String title, String subtitle)? onSubNavChanged;

  const BarcodePrintingView({
    super.key,
    this.onBackToSettings,
    this.onSubNavChanged,
  });

  @override
  State<BarcodePrintingView> createState() => _BarcodePrintingViewState();
}

class _BarcodePrintingViewState extends State<BarcodePrintingView> {
  String _selectedSymbology = 'Code 128 (Standard)';
  final TextEditingController _prefixController = TextEditingController(
    text: 'TS-',
  );
  LabelTemplateType _selectedTemplate = LabelTemplateType.standard;

  final List<String> _symbologyOptions = const [
    'Code 128 (Standard)',
    'EAN-13 (International)',
    'UPC-A (North America)',
    'Code 39 (Alphanumeric)',
    'QR Code (2D Matrix)',
  ];

  final List<PrinterDevice> _printers = [
    PrinterDevice(
      id: 'p1',
      name: 'Zebra ZD420-T',
      location: 'Main Warehouse',
      type: 'Thermal Label',
      isReady: true,
    ),
    PrinterDevice(
      id: 'p2',
      name: 'Office Jet Pro (8020)',
      location: 'Admin Office',
      type: 'Inkjet (A4)',
      isReady: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _prefixController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _prefixController.dispose();
    super.dispose();
  }

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

  void _openAddPrinterDialog() {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Central Depot');
    String selectedType = 'Thermal Label (ZPL)';

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF2E6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.print_outlined,
                          size: 20,
                          color: Color(0xFF7A481B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add Label Printer',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181513),
                              ),
                            ),
                            Text(
                              'Configure network or local hardware printing terminal',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: const Color(0xFF7E766B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Printer Model / Name',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g., Zebra ZT411 Industrial',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFFA59E92),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF7A481B)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Assigned Location',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: locationCtrl,
                    style: GoogleFonts.inter(fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFDFD4C5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF7A481B)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Printer Type',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDFD4C5)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Color(0xFF5E574E),
                          size: 18,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Thermal Label (ZPL)',
                            child: Text('Thermal Label (ZPL)'),
                          ),
                          DropdownMenuItem(
                            value: 'Thermal Label (EPL)',
                            child: Text('Thermal Label (EPL)'),
                          ),
                          DropdownMenuItem(
                            value: 'Inkjet / Laser (A4 Sheet)',
                            child: Text('Inkjet / Laser (A4 Sheet)'),
                          ),
                          DropdownMenuItem(
                            value: 'Direct Network IP Printer',
                            child: Text('Direct Network IP Printer'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedType = val);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF7E766B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isNotEmpty) {
                            setState(() {
                              _printers.add(
                                PrinterDevice(
                                  id: 'p_${DateTime.now().millisecondsSinceEpoch}',
                                  name: name,
                                  location: locationCtrl.text.trim(),
                                  type: selectedType,
                                  isReady: true,
                                ),
                              );
                            });
                            Navigator.of(dialogCtx).pop();
                            _showFeedback(
                              'Printer "$name" connected successfully.',
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E1C1A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Connect Device',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1040;

        return DesktopContentConstraint(
          maxWidth: 1320,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 24,
              bottom: 48,
              left: 28,
              right: 28,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main Header Area
                _buildHeader(),

                const SizedBox(height: 28),

                // Main Responsive Columns
                if (isCompact) ...[
                  // Single Column Mode for Compact Screens
                  _buildLeftColumn(),
                  const SizedBox(height: 24),
                  _buildRightColumn(),
                ] else ...[
                  // 2-Column Desktop Grid
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Barcode Config & Connected Devices (Flex 58%)
                      Expanded(flex: 58, child: _buildLeftColumn()),

                      const SizedBox(width: 24),

                      // Right Column: Label Preview, Active Template & Tips (Flex 42%)
                      Expanded(flex: 42, child: _buildRightColumn()),
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

  // Header matching Barcode & Printing screenshot
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Warm circular avatar with barcode glyph
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFFAF2E6),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(26, 22),
              painter: _BarcodeIconPainter(color: const Color(0xFF7A481B)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Barcode & Printing',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: const Color(0xFF181513),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure barcode settings, manage printers and customize label templates.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6357),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Left Column containing Barcode Configuration & Connected Devices
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Barcode Configuration
        _buildBarcodeConfigurationCard(),

        const SizedBox(height: 24),

        // Card 2: Connected Devices
        _buildConnectedDevicesCard(),
      ],
    );
  }

  // Card 1: Barcode Configuration
  Widget _buildBarcodeConfigurationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with gear icon badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings_outlined,
                  size: 19,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Barcode Configuration',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Set the default barcode format and prefix for your products.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Fields Row: Default Symbology & Prefix
          LayoutBuilder(
            builder: (context, box) {
              final isStacked = box.maxWidth < 480;

              if (isStacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSymbologyField(),
                    const SizedBox(height: 18),
                    _buildPrefixField(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: _buildSymbologyField()),
                  const SizedBox(width: 18),
                  Expanded(flex: 5, child: _buildPrefixField()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSymbologyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default Symbology',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181513),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDFD4C5)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSymbology,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF5E574E),
                size: 20,
              ),
              items: _symbologyOptions.map((opt) {
                return DropdownMenuItem<String>(
                  value: opt,
                  child: Text(
                    opt,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF181513),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedSymbology = val);
                  _showFeedback('Symbology updated to $val');
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrefixField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prefix',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181513),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 42,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDFD4C5)),
          ),
          child: TextField(
            controller: _prefixController,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF181513),
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'This prefix will be added before the product SKU.',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF8E867B),
          ),
        ),
      ],
    );
  }

  // Card 2: Connected Devices
  Widget _buildConnectedDevicesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with printer icon badge and + Add Printer button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.print_outlined,
                  size: 19,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected Devices',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your label printers and print settings.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _openAddPrinterDialog,
                icon: const Icon(Icons.add, size: 16, color: Color(0xFF181513)),
                label: Text(
                  'Add Printer',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDFD4C5)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Connected Devices Table
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEFE8DE)),
            ),
            child: Column(
              children: [
                // Table Header Row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(9),
                      topRight: Radius.circular(9),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEFE8DE)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'PRINTER NAME',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: const Color(0xFF8E867B),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'TYPE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: const Color(0xFF8E867B),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'STATUS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: const Color(0xFF8E867B),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 44,
                        child: Text(
                          'ACTIONS',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: const Color(0xFF8E867B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Table Rows
                for (int i = 0; i < _printers.length; i++) ...[
                  _buildPrinterRow(
                    _printers[i],
                    isLast: i == _printers.length - 1,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterRow(PrinterDevice printer, {required bool isLast}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEFE8DE))),
      ),
      child: Row(
        children: [
          // PRINTER NAME with icon
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFBF9F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.print_outlined,
                    size: 18,
                    color: Color(0xFF181513),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        printer.name,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        printer.location,
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
          ),

          // TYPE
          Expanded(
            flex: 3,
            child: Text(
              printer.type,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF4C453C),
              ),
            ),
          ),

          // STATUS Badge
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: printer.isReady
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFF0EAE1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: printer.isReady
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF7E766B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      printer.isReady ? 'Ready' : 'Offline',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: printer.isReady
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF5E574E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ACTIONS (••• menu)
          SizedBox(
            width: 44,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz_rounded,
                  size: 20,
                  color: Color(0xFF7E766B),
                ),
                tooltip: 'Printer options',
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFDFD4C5)),
                ),
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'test',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.receipt_long_outlined,
                          size: 16,
                          color: Color(0xFF5E574E),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Print Test Label',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'calibrate',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: Color(0xFF5E574E),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Calibrate Sensor',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          printer.isReady
                              ? Icons.power_settings_new_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 16,
                          color: printer.isReady
                              ? const Color(0xFF9E4738)
                              : const Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          printer.isReady ? 'Set to Offline' : 'Set to Ready',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'test') {
                    _showFeedback(
                      'Sending test print job to ${printer.name}...',
                    );
                  } else if (val == 'calibrate') {
                    _showFeedback(
                      'Sensor calibration initiated on ${printer.name}.',
                    );
                  } else if (val == 'toggle_status') {
                    setState(() {
                      printer.isReady = !printer.isReady;
                    });
                    _showFeedback(
                      '${printer.name} status changed to ${printer.isReady ? "Ready" : "Offline"}.',
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Right Column containing Label Preview, Active Template & Printing Tips
  Widget _buildRightColumn() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEADBCA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Label Preview Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  size: 19,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Label Preview',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'See how your label will look with the selected template.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Label Preview Box simulating physical printed sticker
          _buildPhysicalLabelSticker(),

          const SizedBox(height: 24),

          // Section 2: Active Template Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_offer_outlined,
                  size: 19,
                  color: Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Template',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose a label template for printing.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF7E766B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Template Option Selectors
          _buildTemplateOption(LabelTemplateType.standard),
          const SizedBox(height: 10),
          _buildTemplateOption(LabelTemplateType.largeShipping),
          const SizedBox(height: 10),
          _buildTemplateOption(LabelTemplateType.jewelryTag),

          const SizedBox(height: 24),

          // Section 3: Printing Tips Callout
          _buildPrintingTipsCallout(),
        ],
      ),
    );
  }

  // Physical sticker label container with realistic barcode
  Widget _buildPhysicalLabelSticker() {
    final prefix = _prefixController.text.trim();
    final fullSkuCode = '${prefix}OXFLN-M-BLK';
    final isQr = _selectedSymbology.contains('QR Code');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDFD4C5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Brand Name
          Text(
            'THREADSTOCK',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: const Color(0xFF181513),
            ),
          ),

          const SizedBox(height: 6),

          // Product Description
          Text(
            'Sample Barcode Label — Standard',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF181513),
            ),
          ),

          const SizedBox(height: 12),

          // Barcode Graphic
          if (isQr) ...[
            // 2D QR Code graphic
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF181513), width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: CustomPaint(painter: _QrCodePainter()),
            ),
          ] else ...[
            // Realistic 1D Barcode
            SizedBox(
              height: 48,
              width: 220,
              child: CustomPaint(painter: _RealisticBarcodePainter()),
            ),
          ],

          const SizedBox(height: 6),

          // SKU text with dynamic prefix
          Text(
            fullSkuCode,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.0,
              color: const Color(0xFF5E574E),
            ),
          ),
        ],
      ),
    );
  }

  // Template Option Button Card
  Widget _buildTemplateOption(LabelTemplateType template) {
    final isSelected = _selectedTemplate == template;

    return InkWell(
      onTap: () {
        setState(() => _selectedTemplate = template);
        _showFeedback('Selected ${template.label}');
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFCFAF7) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFB37B42)
                : const Color(0xFFE2D8CC),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              template.label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF181513),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: Color(0xFFB37B42),
              ),
          ],
        ),
      ),
    );
  }

  // Printing Tips Callout Box
  Widget _buildPrintingTipsCallout() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3E7D3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFFFBF0DF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              size: 15,
              color: Color(0xFF8B5E34),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Printing Tips',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Use thermal labels for best results. Ensure your printer is calibrated for accurate sizing and alignment.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF736B5E),
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
}

// CustomPainter for the Barcode Icon in Header Avatar
class _BarcodeIconPainter extends CustomPainter {
  final Color color;

  _BarcodeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    // Pattern of 5 vertical bars: width and spacing
    final bars = [
      (2.5, 0.0),
      (4.0, 5.0),
      (2.5, 11.5),
      (5.0, 16.5),
      (2.5, 23.5),
    ];

    for (final bar in bars) {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bar.$2, 0, bar.$1, size.height),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodeIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

// CustomPainter for the realistic label barcode
class _RealisticBarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF181513)
      ..style = PaintingStyle.fill;

    // Fixed sequence of bar thicknesses replicating standard Code 128
    final barPattern = [
      2.0,
      1.0,
      3.0,
      1.5,
      2.0,
      1.0,
      4.0,
      1.5,
      2.0,
      1.0,
      1.5,
      3.0,
      1.5,
      2.0,
      1.0,
      4.0,
      2.0,
      1.5,
      3.0,
      1.0,
      2.0,
      3.5,
      1.0,
      2.0,
      1.5,
      4.0,
      1.0,
      2.5,
      1.5,
      3.0,
      1.0,
      2.0,
      1.5,
      4.0,
      2.0,
      1.0,
      3.0,
      1.5,
      2.0,
      1.0,
      4.0,
      1.5,
      2.0,
      1.0,
      3.0,
      1.5,
      2.0,
    ];

    double currentX = 2.0;
    bool isBar = true;

    for (final width in barPattern) {
      if (currentX + width > size.width - 2.0) break;

      if (isBar) {
        canvas.drawRect(Rect.fromLTWH(currentX, 0, width, size.height), paint);
      }
      currentX += width + 1.2;
      isBar = !isBar;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// CustomPainter for QR Code fallback
class _QrCodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF181513)
      ..style = PaintingStyle.fill;

    final step = size.width / 6;

    // Outer corner finder patterns
    void drawFinder(double x, double y) {
      canvas.drawRect(Rect.fromLTWH(x, y, step * 2.2, step * 2.2), paint);
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRect(
        Rect.fromLTWH(x + step * 0.45, y + step * 0.45, step * 1.3, step * 1.3),
        whitePaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(x + step * 0.75, y + step * 0.75, step * 0.7, step * 0.7),
        paint,
      );
    }

    drawFinder(0, 0);
    drawFinder(size.width - step * 2.2, 0);
    drawFinder(0, size.height - step * 2.2);

    // Some decorative data dots
    canvas.drawRect(
      Rect.fromLTWH(step * 3, step * 2, step * 0.8, step * 0.8),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(step * 4, step * 3, step * 0.8, step * 0.8),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(step * 2.5, step * 4, step * 0.8, step * 0.8),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(step * 4.2, step * 4.5, step * 0.8, step * 0.8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
