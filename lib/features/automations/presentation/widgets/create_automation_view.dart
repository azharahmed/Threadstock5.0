// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateAutomationView extends StatefulWidget {
  const CreateAutomationView({
    super.key,
    this.onSaveAndActivate,
    this.onSaveDraft,
    this.onTestRun,
    this.onBackToAutomations,
  });

  final VoidCallback? onSaveAndActivate;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onTestRun;
  final VoidCallback? onBackToAutomations;

  @override
  State<CreateAutomationView> createState() => _CreateAutomationViewState();
}

class _CreateAutomationViewState extends State<CreateAutomationView> {
  final TextEditingController _promptController = TextEditingController(
    text:
        '“If projected stock coverage of Classic White Oxford M drops below 14 days, check if Delhi Warehouse has excess surplus. If yes, generate an automatic transit dispatch through Vrindavan Express cargo. Notify team admin.”',
  );

  final TextEditingController _ruleNameController = TextEditingController(
    text: 'Low Stock Replenishment Action',
  );

  String _triggerType = 'Stock Depletion Alert: Threshold';
  String _executionSchedule = 'Daily Stock Check Audit (08:00 AM)';

  final List<String> _notifications = [
    'Team Admin',
    'Warehouse Manager',
    'Procurement Team',
  ];

  bool _autoCreateDraftPo = true;
  bool _sendEmailNotification = true;
  bool _logToAuditTrail = false;
  bool _pauseRuleOnFailures = false;
  bool _isAdvancedOptionsOpen = true;

  @override
  void dispose() {
    _promptController.dispose();
    _ruleNameController.dispose();
    super.dispose();
  }

  void _showNotification(String message, {bool isSuccess = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
              color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFFD97706),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF181513),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showTestRunDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.science_outlined,
                color: Color(0xFF2563EB),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Simulate Automation Test Run',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF181513),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Running dry simulation across 14-day stock projections for Classic White Oxford M at Central Warehouse (Zone A)...',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF475569),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildSimStep('1. Trigger Evaluation', 'Condition met (Coverage = 9 days < 14 days)', true),
                  const SizedBox(height: 8),
                  _buildSimStep('2. Regional Stock Check', 'Delhi Warehouse surplus verified (+140 units)', true),
                  const SizedBox(height: 8),
                  _buildSimStep('3. Draft Dispatch', 'Simulated PO & Vrindavan Express dispatch route ready', true),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showNotification('Test Run passed successfully! All 3 conditions validated.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Done',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimStep(String title, String desc, bool passed) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: passed ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Title & Subtitle
          Text(
            'Create Automation',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Define a rule, set conditions, and let ThreadStock automate the rest.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 22),

          // Main 2-Column Responsive Layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 1050;

              if (isStacked) {
                return Column(
                  children: [
                    _buildLeftColumn(),
                    const SizedBox(height: 24),
                    _buildRightColumn(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column (~65% width)
                  Expanded(
                    flex: 65,
                    child: _buildLeftColumn(),
                  ),
                  const SizedBox(width: 24),

                  // Right Column (~35% width, Configure Rule)
                  SizedBox(
                    width: 375,
                    child: _buildRightColumn(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. LEFT COLUMN: NATURAL LANGUAGE BUILDER & 3-STEP FLOW
  // ===========================================================================
  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card 1: Describe What You Want to Automate
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.015),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: Color(0xFFB45309),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Describe what you want to automate...',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    offset: const Offset(0, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    color: Colors.white,
                    onSelected: (template) {
                      setState(() {
                        if (template == 'reorder') {
                          _promptController.text =
                              '“If projected stock coverage of Classic White Oxford M drops below 14 days, check if Delhi Warehouse has excess surplus. If yes, generate an automatic transit dispatch through Vrindavan Express cargo. Notify team admin.”';
                        } else if (template == 'markdown') {
                          _promptController.text =
                              '“When collection items remain unsold for 45 days, automatically draft a 20% seasonal markdown proposal. Notify merchandising lead.”';
                        } else if (template == 'po_remind') {
                          _promptController.text =
                              '“Send reminder notification to approver if purchase order is pending for over 48 hours without approval.”';
                        }
                      });
                      _showNotification('Applied template: $template');
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'reorder',
                        height: 36,
                        child: Text(
                          'Stock Depletion Replenishment',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'markdown',
                        height: 36,
                        child: Text(
                          'Slow-Moving Markdown Action',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'po_remind',
                        height: 36,
                        child: Text(
                          'Pending PO Reminder',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                      ),
                    ],
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Use a template',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Text Area / Prompt Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _promptController,
                  maxLines: 4,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF181513),
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Bottom Hint & AI Assist
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 15,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tip: Be specific about products, locations, thresholds, and actions.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => _showNotification('AI parsed prompt and updated the 3-step workflow.'),
                    borderRadius: BorderRadius.circular(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI Assist',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section 2: AI-Parsed Automation Flow
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI-Parsed Automation Flow',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF181513),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'ThreadStock AI has broken this into a clear 3-step workflow.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            InkWell(
              onTap: () => _showNotification('Workflow editor mode activated.'),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: Color(0xFF181513),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Edit Flow',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF181513),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Step 1: Trigger Condition
        _buildFlowStep(
          stepNumber: 1,
          badgeLabel: 'Trigger',
          badgeBg: const Color(0xFFFEF3C7),
          badgeColor: const Color(0xFFB45309),
          icon: Icons.bar_chart_rounded,
          conditionType: 'TRIGGER CONDITION',
          title: 'Stock Coverage Limit',
          description:
              'Triggers when projected supply coverage of high-velocity item SKUs falls below 14 days.',
          hasNext: true,
        ),

        // Step 2: Validation Condition
        _buildFlowStep(
          stepNumber: 2,
          badgeLabel: 'Validate',
          badgeBg: const Color(0xFFEFF6FF),
          badgeColor: const Color(0xFF2563EB),
          icon: Icons.view_in_ar_rounded,
          conditionType: 'VALIDATION CONDITION',
          title: 'Regional Stock Availability Check',
          description:
              'AI checks if adjacent regional nodes have collective surplus > 100 units.',
          hasNext: true,
        ),

        // Step 3: Dispatch Action
        _buildFlowStep(
          stepNumber: 3,
          badgeLabel: 'Action',
          badgeBg: const Color(0xFFECFDF5),
          badgeColor: const Color(0xFF059669),
          icon: Icons.local_shipping_outlined,
          conditionType: 'DISPATCH ACTION',
          title: 'Draft Transfer & Dispatch',
          description:
              'Automate PO formulation and draft a transfer path through Vrindavan Express.',
          hasNext: false,
        ),
      ],
    );
  }

  Widget _buildFlowStep({
    required int stepNumber,
    required String badgeLabel,
    required Color badgeBg,
    required Color badgeColor,
    required IconData icon,
    required String conditionType,
    required String title,
    required String description,
    required bool hasNext,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Node with Dashed Connector Line
          SizedBox(
            width: 32,
            child: Column(
              children: [
                // Circular Node
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFDF9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB45309),
                      ),
                    ),
                  ),
                ),
                if (hasNext)
                  Expanded(
                    child: CustomPaint(
                      painter: _DashedLinePainter(
                        color: const Color(0xFFF59E0B),
                        dashHeight: 4,
                        dashSpace: 3,
                      ),
                      size: const Size(1.5, double.infinity),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Flow Step Content Card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: hasNext ? 14 : 0),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Center(
                      child: Icon(icon, size: 19, color: const Color(0xFF181513)),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conditionType,
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181513),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Pill Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeLabel,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
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

  // ===========================================================================
  // 2. RIGHT COLUMN: CONFIGURE RULE (RULE SETTINGS & CONTROLS)
  // ===========================================================================
  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Text(
          'CONFIGURE RULE',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFB45309),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Rule Settings & Controls',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181513),
          ),
        ),
        const SizedBox(height: 18),

        // Field 1: Rule Name
        Text(
          'Rule Name',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: _ruleNameController,
            style: GoogleFonts.inter(
              fontSize: 13,
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
        const SizedBox(height: 16),

        // Field 2: Trigger Type
        Text(
          'Trigger Type',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        PopupMenuButton<String>(
          offset: const Offset(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          onSelected: (val) => setState(() => _triggerType = val),
          itemBuilder: (context) => [
            'Stock Depletion Alert: Threshold',
            'Lead Time Expiry Alert',
            'Supplier Delayed Dispatch',
            'Surplus Holding Buffer',
          ]
              .map(
                (opt) => PopupMenuItem(
                  value: opt,
                  height: 36,
                  child: Text(opt, style: GoogleFonts.inter(fontSize: 13)),
                ),
              )
              .toList(),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _triggerType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Field 3: Conditions
        Text(
          'Conditions',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• Projected Stock Coverage < 14 days',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF181513),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '• Regional Warehouse Surplus > 100 units',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF181513),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Field 4: Execution Schedule
        Text(
          'Execution Schedule',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        PopupMenuButton<String>(
          offset: const Offset(0, 42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          onSelected: (val) => setState(() => _executionSchedule = val),
          itemBuilder: (context) => [
            'Daily Stock Check Audit (08:00 AM)',
            'Real-Time on Stock Transaction',
            'Twice Daily (08:00 AM, 06:00 PM)',
            'Weekly Inventory Sync (Monday 09:00 AM)',
          ]
              .map(
                (opt) => PopupMenuItem(
                  value: opt,
                  height: 36,
                  child: Text(opt, style: GoogleFonts.inter(fontSize: 13)),
                ),
              )
              .toList(),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 15,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _executionSchedule,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Field 5: Notifications
        Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _notifications
                .map(
                  (role) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          role,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _notifications.remove(role);
                            });
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            size: 13,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Field 6: Advanced Options Collapsible
        InkWell(
          onTap: () => setState(() => _isAdvancedOptionsOpen = !_isAdvancedOptionsOpen),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Advanced Options',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              Icon(
                _isAdvancedOptionsOpen
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: const Color(0xFF64748B),
              ),
            ],
          ),
        ),
        if (_isAdvancedOptionsOpen) ...[
          const SizedBox(height: 8),
          _buildCheckboxOption(
            value: _autoCreateDraftPo,
            onChanged: (val) => setState(() => _autoCreateDraftPo = val ?? false),
            label: 'Auto-create draft PO',
            showInfo: true,
          ),
          _buildCheckboxOption(
            value: _sendEmailNotification,
            onChanged: (val) => setState(() => _sendEmailNotification = val ?? false),
            label: 'Send email notification',
          ),
          _buildCheckboxOption(
            value: _logToAuditTrail,
            onChanged: (val) => setState(() => _logToAuditTrail = val ?? false),
            label: 'Log to audit trail',
          ),
          _buildCheckboxOption(
            value: _pauseRuleOnFailures,
            onChanged: (val) => setState(() => _pauseRuleOnFailures = val ?? false),
            label: 'Pause rule on repeated failures (3 times)',
            showInfo: true,
          ),
        ],
        const SizedBox(height: 18),

        // Action 1: Save & Activate Automation Button
        InkWell(
          onTap: () {
            if (widget.onSaveAndActivate != null) {
              widget.onSaveAndActivate!();
            } else {
              _showNotification('Automation rule "${_ruleNameController.text}" activated successfully!');
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 42,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF181513),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Save & Activate Automation',
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Bottom 2 Buttons: Save Draft & Test Run
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  if (widget.onSaveDraft != null) {
                    widget.onSaveDraft!();
                  } else {
                    _showNotification('Rule draft saved to workspace.');
                  }
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 16,
                        color: Color(0xFF181513),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Save Draft',
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
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: _showTestRunDialog,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.science_outlined,
                        size: 16,
                        color: Color(0xFF181513),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Test Run',
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
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckboxOption({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
    bool showInfo = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
                if (showInfo) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({
    required this.color,
    this.dashHeight = 4,
    this.dashSpace = 3,
  });

  final Color color;
  final double dashHeight;
  final double dashSpace;

  @override
  void paint(Canvas canvas, Size size) {
    double startY = 0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width
      ..style = PaintingStyle.stroke;

    final x = size.width / 2;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashHeight != dashHeight ||
        oldDelegate.dashSpace != dashSpace;
  }
}
