// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class SecurityAuthenticationView extends StatefulWidget {
  final VoidCallback? onBackToSettings;

  const SecurityAuthenticationView({
    super.key,
    this.onBackToSettings,
  });

  @override
  State<SecurityAuthenticationView> createState() =>
      _SecurityAuthenticationViewState();
}

class _SecurityAuthenticationViewState
    extends State<SecurityAuthenticationView> {
  // Authentication Rules State
  bool _require2FA = true;
  bool _enforceCustomPasswordPolicy = true;
  int _minCharLength = 12;
  bool _forceSpecialChars = true;
  bool _expirePasswords90Days = false;

  // Session Control State
  String _autoLogoutDuration = '30 Minutes';
  String _maxConcurrentSessions = '2';

  // Access Restrictions State
  bool _ipAllowlistRestriction = true;
  late TextEditingController _ipController;
  bool _restrictOfficeHours = false;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(
      text: '103.45.2.0/24, 192.168.1.0/24',
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
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
    return Container(
      color: const Color(0xFFFAF7F2),
      child: SingleChildScrollView(
        child: DesktopContentConstraint(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Shield Icon + Title & Subtitle
                _buildHeader(),
                const SizedBox(height: 22),

                // Responsive Two-Column Layout (Left: Auth & Session, Right: Access & Activity)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 940;
                    if (isWide) {
                      final leftWidth = constraints.maxWidth * 0.54;
                      final rightWidth = constraints.maxWidth - leftWidth - 22;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Authentication Rules + Session Control
                          SizedBox(
                            width: leftWidth,
                            child: Column(
                              children: [
                                _buildAuthenticationRulesCard(),
                                const SizedBox(height: 20),
                                _buildSessionControlCard(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 22),

                          // Right Column: Access Restrictions + Recent Login Activity
                          SizedBox(
                            width: rightWidth,
                            child: Column(
                              children: [
                                _buildAccessRestrictionsCard(),
                                const SizedBox(height: 20),
                                _buildRecentLoginActivityCard(),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildAuthenticationRulesCard(),
                          const SizedBox(height: 20),
                          _buildSessionControlCard(),
                          const SizedBox(height: 20),
                          _buildAccessRestrictionsCard(),
                          const SizedBox(height: 20),
                          _buildRecentLoginActivityCard(),
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
  // HEADER ROW: Shield Avatar + Title + Subtitle
  // ========================================================
  Widget _buildHeader() {
    return Row(
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
            Icons.shield_outlined,
            color: Color(0xFF7A481B),
            size: 26,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Security & Authentication',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: const Color(0xFF181513),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Enforce strong security policies, session handling and review active team session logs.',
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
    );
  }

  // ========================================================
  // CARD 1: Authentication Rules
  // ========================================================
  Widget _buildAuthenticationRulesCard() {
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
                    Icons.lock_outline_rounded,
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
                        'Authentication Rules',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Configure login security, password requirements, and account protection.',
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
            const SizedBox(height: 22),

            // Item 1: Require Two-Factor Authentication (2FA)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Require Two-Factor Authentication (2FA)',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Enforce OTP generation on all admin and purchasing accounts during login.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildToggle(
                  value: _require2FA,
                  onChanged: (val) {
                    setState(() => _require2FA = val);
                    _showFeedback(_require2FA
                        ? 'Two-Factor Authentication enabled'
                        : 'Two-Factor Authentication disabled');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Item 2: Enforce Custom Password Policy
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enforce Custom Password Policy',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Require complex rules for floor staff and regional store roles.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                _buildToggle(
                  value: _enforceCustomPasswordPolicy,
                  onChanged: (val) {
                    setState(() => _enforceCustomPasswordPolicy = val);
                    _showFeedback(_enforceCustomPasswordPolicy
                        ? 'Custom password policy enforced'
                        : 'Custom password policy relaxed');
                  },
                ),
              ],
            ),

            // Nested Policy Box
            if (_enforceCustomPasswordPolicy) ...[
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF7F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFEFE6DA)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Sub-item 1: Minimum Character Length
                    Row(
                      children: [
                        Text(
                          'Aa',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF945725),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Minimum Character Length',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF382718),
                            ),
                          ),
                        ),
                        PopupMenuButton<int>(
                          initialValue: _minCharLength,
                          onSelected: (val) {
                            setState(() => _minCharLength = val);
                            _showFeedback('Minimum password length set to $val characters');
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 8, child: Text('8 Characters')),
                            const PopupMenuItem(value: 10, child: Text('10 Characters')),
                            const PopupMenuItem(value: 12, child: Text('12 Characters')),
                            const PopupMenuItem(value: 16, child: Text('16 Characters')),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE4D8),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE2D8CC)),
                            ),
                            child: Text(
                              '$_minCharLength Characters',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF181513),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0xFFEDE2D4)),
                    ),

                    // Sub-item 2: Force special chars and symbols
                    Row(
                      children: [
                        Text(
                          '#',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF945725),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Force special chars and symbols',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF382718),
                            ),
                          ),
                        ),
                        _buildToggle(
                          value: _forceSpecialChars,
                          onChanged: (val) {
                            setState(() => _forceSpecialChars = val);
                          },
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: Color(0xFFEDE2D4)),
                    ),

                    // Sub-item 3: Expire passwords every 90 days
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: Color(0xFF945725),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Expire passwords every 90 days',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF382718),
                            ),
                          ),
                        ),
                        _buildToggle(
                          value: _expirePasswords90Days,
                          onChanged: (val) {
                            setState(() => _expirePasswords90Days = val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ========================================================
  // CARD 2: Session Control
  // ========================================================
  Widget _buildSessionControlCard() {
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
                    Icons.desktop_windows_outlined,
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
                        'Session Control',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage session timeouts and concurrent logins.',
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
            const SizedBox(height: 22),

            // Item 1: Auto-Logout Idle Sessions
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Logout Idle Sessions',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Log out terminal sessions after absolute inactivity window.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                PopupMenuButton<String>(
                  initialValue: _autoLogoutDuration,
                  onSelected: (val) {
                    setState(() => _autoLogoutDuration = val);
                    _showFeedback('Session auto-logout set to $val');
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: '15 Minutes', child: Text('15 Minutes')),
                    const PopupMenuItem(value: '30 Minutes', child: Text('30 Minutes')),
                    const PopupMenuItem(value: '1 Hour', child: Text('1 Hour')),
                    const PopupMenuItem(value: '2 Hours', child: Text('2 Hours')),
                    const PopupMenuItem(value: '4 Hours', child: Text('4 Hours')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2D8CC)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _autoLogoutDuration,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF181513),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF7E766B),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Item 2: Max Concurrent Sessions
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Max Concurrent Sessions',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Prevent single staff account logging in on multiple physical counters.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2D8CC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSegmentOption('1'),
                      _buildSegmentOption('2'),
                      _buildSegmentOption('3'),
                      _buildSegmentOption('Unlimited'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentOption(String label) {
    final isSelected = _maxConcurrentSessions == label;
    return InkWell(
      onTap: () {
        setState(() => _maxConcurrentSessions = label);
        _showFeedback('Max concurrent sessions set to $label');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5EBE1) : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF181513) : const Color(0xFF6E665B),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // CARD 3: Access Restrictions
  // ========================================================
  Widget _buildAccessRestrictionsCard() {
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
                    Icons.language_rounded,
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
                        'Access Restrictions',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Control network and location-based access.',
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

            // Item 1: IP Allowlist Restriction
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'IP ALLOWLIST RESTRICTION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFF7E766B),
                  ),
                ),
                _buildToggle(
                  value: _ipAllowlistRestriction,
                  onChanged: (val) {
                    setState(() => _ipAllowlistRestriction = val);
                    _showFeedback(_ipAllowlistRestriction
                        ? 'IP Allowlist restriction activated'
                        : 'IP Allowlist restriction paused');
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // IP Input Box
            TextField(
              controller: _ipController,
              enabled: _ipAllowlistRestriction,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF181513),
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFFAF7F2),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            const SizedBox(height: 6),
            Text(
              'Only allow access from trusted IP addresses.',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF7E766B),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Divider(height: 1, color: Color(0xFFF0E8DD)),
            ),

            // Item 2: Restrict Office Hour Login
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RESTRICT OFFICE HOUR LOGIN',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFF7E766B),
                  ),
                ),
                _buildToggle(
                  value: _restrictOfficeHours,
                  onChanged: (val) {
                    setState(() => _restrictOfficeHours = val);
                    _showFeedback(_restrictOfficeHours
                        ? 'Office hour login restrictions enabled'
                        : 'Office hour login restrictions disabled');
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Disable non-manager logins outside 8:00 AM – 9:00 PM.',
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

  // ========================================================
  // CARD 4: Recent Login Activity
  // ========================================================
  Widget _buildRecentLoginActivityCard() {
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
            // Card Title Header + View All Button
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
                          Icons.format_list_bulleted_rounded,
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
                              'Recent Login Activity',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF181513),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Monitor recent team sign-ins and security events.',
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
                OutlinedButton(
                  onPressed: () => _showFeedback('Viewing comprehensive security logs'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2D8CC)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    'View All →',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // 4 Login Activity Rows
            _buildLoginRow(
              name: 'Alex Mercer',
              device: 'MacBook Pro — Chrome',
              time: '10 mins ago',
              status: 'Success',
              isSuccess: true,
              imagePath: 'Assets/alex_mercer.jpg',
            ),
            const Divider(height: 18, color: Color(0xFFF4ECE1)),

            _buildLoginRow(
              name: 'Priya Sharma',
              device: 'iPad Central POS',
              time: '1 hour ago',
              status: 'Success',
              isSuccess: true,
              imagePath: 'Assets/priya_nair.jpg',
            ),
            const Divider(height: 18, color: Color(0xFFF4ECE1)),

            _buildLoginRow(
              name: 'Sarah Connor',
              device: 'iPhone 15 — Mobile App',
              time: '4 hours ago',
              status: 'Success',
              isSuccess: true,
              imagePath: 'Assets/emma_carter.jpg',
            ),
            const Divider(height: 18, color: Color(0xFFF4ECE1)),

            _buildLoginRow(
              name: 'Unknown User',
              device: 'Linux — Firefox',
              time: '1 day ago',
              status: 'Blocked Attempt',
              isSuccess: false,
              isUnknown: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRow({
    required String name,
    required String device,
    required String time,
    required String status,
    required bool isSuccess,
    String? imagePath,
    bool isUnknown = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar
        ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Container(
            width: 38,
            height: 38,
            color: const Color(0xFFECE7E1),
            child: isUnknown
                ? const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFF8A8075),
                    size: 20,
                  )
                : Image.asset(
                    imagePath ?? 'Assets/alex_mercer.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Text(
                        name.substring(0, 1),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: const Color(0xFF5C3E21),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),

        // Name & Device
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                device,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF7E766B),
                ),
              ),
            ],
          ),
        ),

        // Time + Status Badge + More Icon
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF7E766B),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                status,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),

        PopupMenuButton<String>(
          onSelected: (val) => _showFeedback('$val for $name'),
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'Inspect Session', child: Text('Inspect Session')),
            const PopupMenuItem(value: 'Revoke Access', child: Text('Revoke Access')),
          ],
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.more_horiz_rounded, size: 18, color: Color(0xFF7E766B)),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // CUSTOM PILL TOGGLE
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
