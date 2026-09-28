// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ScheduleAutomatedReportDialog extends StatefulWidget {
  final VoidCallback? onScheduled;

  const ScheduleAutomatedReportDialog({super.key, this.onScheduled});

  static Future<void> show(BuildContext context, {VoidCallback? onScheduled}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.38),
      builder: (_) => ScheduleAutomatedReportDialog(onScheduled: onScheduled),
    );
  }

  @override
  State<ScheduleAutomatedReportDialog> createState() =>
      _ScheduleAutomatedReportDialogState();
}

class _ScheduleAutomatedReportDialogState
    extends State<ScheduleAutomatedReportDialog> {
  String _selectedTemplate = 'Weekly Sales Summary';
  String _selectedFrequency = 'Weekly';
  String _dayAndTime = 'Monday at 8:00 AM';
  bool _includeAiCommentary = true;
  final List<String> _recipients = [
    'alex@threadstock.com',
    'sarah.admin@threadstock.com',
  ];
  String _selectedLocation = 'Primary Flagship, Distribution Hub A';

  void _addRecipientDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFEADBCA)),
        ),
        title: Text(
          'Add Recipient Email',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181513),
          ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'e.g. director@threadstock.com',
            hintStyle: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF8C8377),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDFD5C6)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF6B6357)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7A481B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty && text.contains('@')) {
                setState(() => _recipients.add(text));
              }
              Navigator.of(ctx).pop();
            },
            child: Text(
              'Add',
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEADBCA), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 32,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              _buildHeader(),
              const SizedBox(height: 22),

              // Field 1: Report Template Type
              _buildReportTemplateField(),
              const SizedBox(height: 16),

              // Field 2: Frequency & Day & Time (IST)
              _buildFrequencyAndTimeField(),
              const SizedBox(height: 16),

              // Field 3: Include AI Studio Commentary (Switch Banner Card)
              _buildAiCommentaryField(),
              const SizedBox(height: 16),

              // Field 4: Email Recipients
              _buildEmailRecipientsField(),
              const SizedBox(height: 16),

              // Field 5: Locations Included
              _buildLocationsField(),
              const SizedBox(height: 24),

              // Footer Bar
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Square Icon Badge
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFBF5EE),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF0E5D4), width: 1.0),
          ),
          child: const Center(
            child: Icon(
              Icons.calendar_month_outlined,
              size: 22,
              color: Color(0xFF8D6433),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Title and subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Schedule Automated Report',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Automate execution and delivery of customized report templates.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B6357),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),

        // Close Button
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: Color(0xFF7E766B),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FIELD 1: REPORT TEMPLATE TYPE
  // ==========================================
  Widget _buildReportTemplateField() {
    final templates = [
      'Weekly Sales Summary',
      'Monthly Inventory Health',
      'Quarterly P&L Projections',
      'Supplier Audit Report',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconBadge(Icons.description_outlined),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Template Type',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5E574E),
                ),
              ),
              const SizedBox(height: 6),
              PopupMenuButton<String>(
                tooltip: 'Select Report Template',
                initialValue: _selectedTemplate,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFDFD5C6)),
                ),
                onSelected: (val) => setState(() => _selectedTemplate = val),
                itemBuilder: (ctx) => templates
                    .map(
                      (t) => PopupMenuItem(
                        value: t,
                        height: 38,
                        child: Text(t, style: GoogleFonts.inter(fontSize: 13)),
                      ),
                    )
                    .toList(),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFDFD5C6),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedTemplate,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF6B6357),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FIELD 2: FREQUENCY & DAY & TIME
  // ==========================================
  Widget _buildFrequencyAndTimeField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Frequency Column (Left)
        Expanded(
          flex: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconBadge(Icons.access_time_rounded),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Frequency',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5E574E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF8F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFDFD5C6),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildFrequencyTab('Weekly'),
                          _buildFrequencyTab('Monthly'),
                          _buildFrequencyTab('Quarterly'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),

        // Day & Time Column (Right)
        Expanded(
          flex: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIconBadge(Icons.calendar_today_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day & Time (IST)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5E574E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    PopupMenuButton<String>(
                      tooltip: 'Select schedule time',
                      initialValue: _dayAndTime,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFDFD5C6)),
                      ),
                      onSelected: (val) => setState(() => _dayAndTime = val),
                      itemBuilder: (ctx) =>
                          [
                                'Monday at 8:00 AM',
                                'Monday at 9:30 AM',
                                'Friday at 6:00 PM',
                                'Sunday at 11:00 PM',
                              ]
                              .map(
                                (t) => PopupMenuItem(
                                  value: t,
                                  height: 38,
                                  child: Text(
                                    t,
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF8F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFDFD5C6),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dayAndTime,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF181513),
                              ),
                            ),
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 16,
                              color: Color(0xFF6B6357),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyTab(String label) {
    final isSelected = _selectedFrequency == label;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedFrequency = label),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF5EBE0) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? const Color(0xFF543210)
                  : const Color(0xFF6B6357),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FIELD 3: INCLUDE AI STUDIO COMMENTARY
  // ==========================================
  Widget _buildAiCommentaryField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF2E7D5), width: 1.0),
      ),
      child: Row(
        children: [
          // Sparkle Icon Badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF4EC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF0E5D4)),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 18,
                color: Color(0xFF8D6433),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Include AI Studio Commentary',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Automatically generate insights on stockout risks and transfers.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B6357),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Custom Luxury Espresso Toggle Switch
          _buildPillToggle(
            value: _includeAiCommentary,
            onChanged: (val) => setState(() => _includeAiCommentary = val),
          ),
        ],
      ),
    );
  }

  Widget _buildPillToggle({
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          width: 44,
          height: 24,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: value ? const Color(0xFF7A481B) : const Color(0xFFE2D9CC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 19,
              height: 19,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x2A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FIELD 4: EMAIL RECIPIENTS
  // ==========================================
  Widget _buildEmailRecipientsField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconBadge(Icons.mail_outline_rounded),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email Recipients',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5E574E),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF8F5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFDFD5C6),
                    width: 1.0,
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ..._recipients.map((email) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDFD5C6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              email,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF181513),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () {
                                if (_recipients.length > 1) {
                                  setState(() => _recipients.remove(email));
                                }
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                size: 13,
                                color: Color(0xFF7E766B),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    InkWell(
                      onTap: _addRecipientDialog,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Text(
                          '+ Add Email',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFA86718),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FIELD 5: LOCATIONS INCLUDED
  // ==========================================
  Widget _buildLocationsField() {
    final locations = [
      'Primary Flagship, Distribution Hub A',
      'Distribution Hub A (Zone 1)',
      'Primary Flagship Store',
      'Mumbai Boutique (All Locations)',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildIconBadge(Icons.location_on_outlined),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Locations Included',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF5E574E),
                ),
              ),
              const SizedBox(height: 6),
              PopupMenuButton<String>(
                tooltip: 'Select Locations',
                initialValue: _selectedLocation,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFDFD5C6)),
                ),
                onSelected: (val) => setState(() => _selectedLocation = val),
                itemBuilder: (ctx) => locations
                    .map(
                      (l) => PopupMenuItem(
                        value: l,
                        height: 38,
                        child: Text(l, style: GoogleFonts.inter(fontSize: 13)),
                      ),
                    )
                    .toList(),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFDFD5C6),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _selectedLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF181513),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF6B6357),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // FOOTER
  // ==========================================
  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left info notice
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFF7E766B),
            ),
            const SizedBox(width: 8),
            Text(
              'This pipeline can be modified or paused anytime.',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF7E766B),
              ),
            ),
          ],
        ),

        // Right action buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cancel Button
            InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFDFD5C6),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF181513),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Schedule Pipeline Button
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                widget.onScheduled?.call();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFFBA8A55),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pipeline scheduled! $_selectedTemplate will deliver $_selectedFrequency on $_dayAndTime.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF1E1C1A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF7A481B),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.play_arrow_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Schedule Pipeline',
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
          ],
        ),
      ],
    );
  }

  Widget _buildIconBadge(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFFBF5EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF0E5D4), width: 1.0),
      ),
      child: Center(
        child: Icon(icon, size: 19, color: const Color(0xFF8D6433)),
      ),
    );
  }
}
