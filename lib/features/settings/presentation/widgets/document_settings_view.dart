// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class DocumentSequenceItem {
  final String id;
  final String name;
  final IconData icon;
  final TextEditingController prefixController;
  final TextEditingController serialController;

  DocumentSequenceItem({
    required this.id,
    required this.name,
    required this.icon,
    required String prefix,
    required String serial,
  }) : prefixController = TextEditingController(text: prefix),
       serialController = TextEditingController(text: serial);

  void dispose() {
    prefixController.dispose();
    serialController.dispose();
  }
}

class DocumentSettingsView extends StatefulWidget {
  const DocumentSettingsView({super.key});

  @override
  State<DocumentSettingsView> createState() => _DocumentSettingsViewState();
}

class _DocumentSettingsViewState extends State<DocumentSettingsView> {
  // Sequences List
  late final List<DocumentSequenceItem> _sequences;

  // Reset counters yearly
  bool _resetCountersYearly = true;

  // Document Footer Text Controller
  final TextEditingController _footerTextController = TextEditingController(
    text:
        'Thank you for partnering with ThreadStock. For returns, standard ThreadStock policies apply. Contact support@threadstock.ai for logistics queries.',
  );

  @override
  void initState() {
    super.initState();
    _sequences = [
      DocumentSequenceItem(
        id: 'po',
        name: 'Purchase Orders',
        icon: Icons.shopping_cart_outlined,
        prefix: 'PO-',
        serial: '0001',
      ),
      DocumentSequenceItem(
        id: 'trf',
        name: 'Transfer Orders',
        icon: Icons.swap_horiz_rounded,
        prefix: 'TRF-',
        serial: '0001',
      ),
      DocumentSequenceItem(
        id: 'adj',
        name: 'Stock Adjustments',
        icon: Icons.inventory_2_outlined,
        prefix: 'ADJ-',
        serial: '0001',
      ),
      DocumentSequenceItem(
        id: 'sc',
        name: 'Stock Counts',
        icon: Icons.format_list_bulleted_rounded,
        prefix: 'SC-',
        serial: '0001',
      ),
      DocumentSequenceItem(
        id: 'inv',
        name: 'Customer Invoices',
        icon: Icons.receipt_long_outlined,
        prefix: 'INV-',
        serial: '0001',
      ),
    ];

    for (final seq in _sequences) {
      seq.prefixController.addListener(() => setState(() {}));
      seq.serialController.addListener(() => setState(() {}));
    }

    _footerTextController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final seq in _sequences) {
      seq.dispose();
    }
    _footerTextController.dispose();
    super.dispose();
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFFBA8A55),
              size: 18,
            ),
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
              // Page Header
              Text(
                'DOCUMENTS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: const Color(0xFFA37038),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Document Settings',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: const Color(0xFF181513),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure document formats, serial numbers, and brand elements for system-generated and external PDFs.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6E665B),
                ),
              ),
              const SizedBox(height: 24),

              // Two-Column Layout: Left (Sequences) + Right (Print & PDF Layout)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 940;
                  if (isWide) {
                    final leftWidth = constraints.maxWidth * 0.58;
                    final rightWidth = constraints.maxWidth - leftWidth - 24;

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column
                        SizedBox(
                          width: leftWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSequencesCard(),
                              const SizedBox(height: 18),
                              _buildResetCountersCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Right Column
                        SizedBox(
                          width: rightWidth,
                          child: _buildPrintPdfLayoutCard(),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSequencesCard(),
                        const SizedBox(height: 18),
                        _buildResetCountersCard(),
                        const SizedBox(height: 24),
                        _buildPrintPdfLayoutCard(),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // LEFT COLUMN CARD: Auto-Generation Sequences
  // ========================================================
  Widget _buildSequencesCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4E8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: 20,
                    color: Color(0xFFBA8A55),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Generation Sequences',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Set prefix formats and starting serial counters for each document type.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Hairline divider
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1EAE0)),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: const Color(0xFFFAF7F2),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Document Type',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Prefix Code',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Next Serial',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Format Preview',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ),
                const SizedBox(width: 32, child: SizedBox.shrink()),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1EAE0)),

          // Table Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _sequences.length,
            separatorBuilder: (ctx, index) => const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF6F1EA),
            ),
            itemBuilder: (ctx, index) {
              final seq = _sequences[index];
              final preview =
                  '${seq.prefixController.text}${seq.serialController.text}';

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Document Type with Icon
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Icon(
                            seq.icon,
                            size: 18,
                            color: const Color(0xFFBA8A55),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              seq.name,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181513),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Prefix Code input field
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDFD4C5)),
                        ),
                        child: TextField(
                          controller: seq.prefixController,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Next Serial input field
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDFD4C5)),
                        ),
                        child: TextField(
                          controller: seq.serialController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Format Preview
                    Expanded(
                      flex: 3,
                      child: Text(
                        preview,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA37038),
                        ),
                      ),
                    ),

                    // More Actions
                    SizedBox(
                      width: 32,
                      child: PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: Color(0xFF7A7268),
                        ),
                        padding: EdgeInsets.zero,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        itemBuilder: (ctx) => [
                          PopupMenuItem(
                            value: 'reset',
                            child: Text(
                              'Reset Counter to 0001',
                              style: GoogleFonts.inter(fontSize: 12.5),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'advanced',
                            child: Text(
                              'Configure Pattern...',
                              style: GoogleFonts.inter(fontSize: 12.5),
                            ),
                          ),
                        ],
                        onSelected: (val) {
                          if (val == 'reset') {
                            seq.serialController.text = '0001';
                            _showFeedback('Reset ${seq.name} serial to 0001');
                          } else if (val == 'advanced') {
                            _showFeedback(
                              'Configuring pattern for ${seq.name}',
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ========================================================
  // LEFT COLUMN BOTTOM CARD: Reset counters yearly
  // ========================================================
  Widget _buildResetCountersCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEBE2D5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPillToggle(
            value: _resetCountersYearly,
            onChanged: (val) => setState(() => _resetCountersYearly = val),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset counters yearly',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Automatically resets sequence serial numbers to 0001 on the 1st of January each year.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7A7268),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Luxury espresso pill toggle matching the mockup reference
  Widget _buildPillToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: 44,
          height: 24,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: value ? const Color(0xFF553519) : const Color(0xFFE2D9CC),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 19,
              height: 19,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x2A000000),
                    blurRadius: 2.5,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // RIGHT COLUMN CARD: Print & PDF Layout
  // ========================================================
  Widget _buildPrintPdfLayoutCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF4E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.brush_outlined,
                  size: 20,
                  color: Color(0xFFBA8A55),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Print & PDF Layout',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage brand elements for external documents.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF7A7268),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Section 1: Company Letterhead Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Company Letterhead Logo',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showFeedback('File upload picker opened'),
                icon: const Icon(
                  Icons.upload_rounded,
                  size: 14,
                  color: Color(0xFF181513),
                ),
                label: Text(
                  'Upload',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF181513),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFDECDB9)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Upload Dropzone
          InkWell(
            onTap: () => _showFeedback('Selecting new brand logo image...'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5DCD0), width: 1),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.image_outlined,
                    size: 32,
                    color: Color(0xFFBA8A55),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Replace brand logo',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF946A36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'PNG, JPG or SVG (Max 2MB) • Recommended: 300×80px',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8E867B),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Section 2: Document Footer Text
          Text(
            'Document Footer Text',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFDFD4C5)),
            ),
            child: TextField(
              controller: _footerTextController,
              maxLines: 3,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1E1C1A),
                height: 1.4,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This will appear on all system-generated documents.',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8E867B),
            ),
          ),
          const SizedBox(height: 22),

          // Section 3: Live Preview
          Text(
            'Preview',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF181513),
            ),
          ),
          const SizedBox(height: 8),

          // Letterhead Preview Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEBE2D5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A231A).withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Top Row: Logo monogram + Brand + Slogan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          'Assets/logo_mark.png',
                          height: 24,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.token,
                            size: 20,
                            color: Color(0xFFB37B42),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'THREADSTOCK',
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            letterSpacing: 12 * 0.20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1816),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Better tools',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF6E665B),
                          ),
                        ),
                        Text(
                          'for a more beautiful business.',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF6E665B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Gold divider
                Container(
                  width: double.infinity,
                  height: 1.2,
                  color: const Color(0xFFBA8A55).withOpacity(0.85),
                ),
                const SizedBox(height: 16),

                // Live dynamic footer text
                Text(
                  _footerTextController.text,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7A7268),
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
