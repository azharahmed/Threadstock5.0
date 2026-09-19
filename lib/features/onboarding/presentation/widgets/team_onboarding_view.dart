// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamMemberEntry {
  final TextEditingController emailController;
  String role;
  String location;

  TeamMemberEntry({
    required String email,
    required this.role,
    required this.location,
  }) : emailController = TextEditingController(text: email);

  void dispose() {
    emailController.dispose();
  }
}

class TeamOnboardingView extends StatefulWidget {
  const TeamOnboardingView({
    super.key,
    this.onBack,
    this.onSkip,
    this.onContinue,
    this.onOpenDashboard,
  });

  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final VoidCallback? onContinue;
  final VoidCallback? onOpenDashboard;

  @override
  State<TeamOnboardingView> createState() => _TeamOnboardingViewState();
}

class _TeamOnboardingViewState extends State<TeamOnboardingView> {
  late final List<TeamMemberEntry> _members;

  final List<String> _roleOptions = const [
    'Manager',
    'Inventory Staff',
    'Purchasing',
    'Cashier',
    'Store Associate',
  ];

  final List<String> _locationOptions = const [
    'Central Warehouse',
    'Delhi Flagship Hub',
    'All Locations',
    'Mumbai Boutique',
    'Bengaluru Flagship',
  ];

  @override
  void initState() {
    super.initState();
    _members = [
      TeamMemberEntry(
        email: 'name@threadstock.ai',
        role: 'Manager',
        location: 'Central Warehouse',
      ),
      TeamMemberEntry(
        email: 'team@threadstock.ai',
        role: 'Inventory Staff',
        location: 'Delhi Flagship Hub',
      ),
      TeamMemberEntry(
        email: 'purchasing@threadstock.ai',
        role: 'Purchasing',
        location: 'All Locations',
      ),
    ];
  }

  @override
  void dispose() {
    for (final member in _members) {
      member.dispose();
    }
    super.dispose();
  }

  void _addMember() {
    setState(() {
      _members.add(
        TeamMemberEntry(
          email: '',
          role: 'Store Associate',
          location: 'All Locations',
        ),
      );
    });
  }

  void _removeMember(int index) {
    if (_members.length > 1) {
      setState(() {
        _members.removeAt(index).dispose();
      });
    }
  }

  void _finishAndOpenDashboard() {
    if (widget.onOpenDashboard != null) {
      widget.onOpenDashboard!();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: Row(
        children: [
          // Left Luxury Editorial Sidebar with Folded Fabric & Bottom Quote
          _buildEditorialSidebar(),

          // Main Workspace Area
          Expanded(
            child: Column(
              children: [
                // Top Header Row: Onboarding setup • STEP 5 OF 5
                _buildTopBar(),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: 36,
                      right: 36,
                      top: 10,
                      bottom: 36,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Page Category + Title + Subtitle
                        Text(
                          'TEAM ONBOARDING',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: const Color(0xFF9A6A2F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Invite your team',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181513),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Grant workspace access to your managers, cashiers, and warehouse operators. You can change permissions anytime later.',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6E665B),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Two Column Layout: Left Forms + Right Setup Complete Card
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Main Form Column
                            Expanded(
                              flex: 13,
                              child: Column(
                                children: [
                                  // Card 1: Team Members Table
                                  _buildTeamMembersCard(),
                                  const SizedBox(height: 18),

                                  // Card 2: Permission Info
                                  _buildPermissionInfoCard(),
                                  const SizedBox(height: 24),

                                  // Bottom Navigation Buttons: Back, Skip, Continue
                                  _buildNavigationRow(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 24),

                            // Right Summary Panel: YOU'RE READY
                            SizedBox(
                              width: 360,
                              child: _buildSetupCompleteCard(),
                            ),
                          ],
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
    );
  }

  // ========================================================
  // LEFT EDITORIAL SIDEBAR (Folded Linen & Serif Quote)
  // ========================================================
  Widget _buildEditorialSidebar() {
    return Container(
      width: 230,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F3EC),
        border: Border(
          right: BorderSide(color: Color(0xFFEADBCA), width: 1.0),
        ),
      ),
      child: Stack(
        children: [
          // Folded Raw Linen Texture Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.92,
              child: Image.asset(
                'Assets/OnBoardBG/BG.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerLeft,
                errorBuilder: (_, _, _) => Image.asset(
                  'Assets/Desktop_Background.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),
          ),

          // Gentle Warm Gradient Vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.55),
                    Colors.transparent,
                    Colors.white.withOpacity(0.70),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Content: Top Logo & Bottom Quote
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand Logo & Monogram
                  Row(
                    children: [
                      Image.asset(
                        'Assets/logo_mark.png',
                        height: 30,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'THREADSTOCK',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          letterSpacing: 14 * 0.20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1816),
                        ),
                      ),
                    ],
                  ),

                  // Bottom Editorial Quote
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '“ Better tools\nfor a more beautiful\nbusiness. ”',
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2A241E),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 24,
                        height: 1.5,
                        color: const Color(0xFFBA8A55),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // TOP BAR: Onboarding setup • STEP 5 OF 5
  // ========================================================
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Onboarding setup',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7A7268),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF3FB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFD7E3F3)),
            ),
            child: Text(
              'STEP 5 OF 5',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: const Color(0xFF3A6CA8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // CARD 1: TEAM MEMBERS FORM TABLE
  // ========================================================
  Widget _buildTeamMembersCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
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
          // Header: Round People Icon + Title + Subtitle
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBF4E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people_outline_rounded,
                  size: 18,
                  color: Color(0xFFBA8A55),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Members',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add team members who will access this workspace.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Column Headers
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  'EMAIL ADDRESS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: const Color(0xFF7A7268),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Text(
                  'ROLE',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: const Color(0xFF7A7268),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Text(
                  'ASSIGNED LOCATION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: const Color(0xFF7A7268),
                  ),
                ),
              ),
              const SizedBox(width: 38), // Space for trash icon
            ],
          ),
          const SizedBox(height: 10),

          // Member Rows
          ...List.generate(_members.length, (index) {
            final member = _members[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Email Input Field
                  Expanded(
                    flex: 5,
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
                          const Icon(
                            Icons.mail_outline_rounded,
                            size: 16,
                            color: Color(0xFF7A7268),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: member.emailController,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF181513),
                              ),
                              decoration: const InputDecoration(
                                hintText: 'name@threadstock.ai',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Role Dropdown
                  Expanded(
                    flex: 4,
                    child: _buildRoleDropdown(member),
                  ),
                  const SizedBox(width: 12),

                  // Location Dropdown
                  Expanded(
                    flex: 5,
                    child: _buildLocationDropdown(member),
                  ),
                  const SizedBox(width: 8),

                  // Trash Delete Button
                  IconButton(
                    onPressed: () => _removeMember(index),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Color(0xFFB56A6A),
                    ),
                    tooltip: 'Remove',
                    splashRadius: 18,
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 6),

          // [+ Add another member] Button
          InkWell(
            onTap: _addMember,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFCF9F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEADBCA)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add,
                    size: 16,
                    color: Color(0xFF382718),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Add another member',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF382718),
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

  Widget _buildRoleDropdown(TeamMemberEntry member) {
    IconData getRoleIcon(String role) {
      switch (role) {
        case 'Manager':
          return Icons.person_outline_rounded;
        case 'Inventory Staff':
          return Icons.inventory_2_outlined;
        case 'Purchasing':
          return Icons.shopping_cart_outlined;
        default:
          return Icons.badge_outlined;
      }
    }

    return PopupMenuButton<String>(
      onSelected: (val) => setState(() => member.role = val),
      color: const Color(0xFFFAF7F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDFD4C5)),
      ),
      itemBuilder: (ctx) => _roleOptions.map((role) {
        final isSelected = role == member.role;
        return PopupMenuItem<String>(
          value: role,
          height: 38,
          child: Row(
            children: [
              Icon(getRoleIcon(role), size: 15, color: const Color(0xFF7A7268)),
              const SizedBox(width: 8),
              Text(
                role,
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
            Icon(getRoleIcon(member.role), size: 16, color: const Color(0xFF7A7268)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                member.role,
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
    );
  }

  Widget _buildLocationDropdown(TeamMemberEntry member) {
    IconData getLocationIcon(String loc) {
      if (loc.contains('Warehouse')) {
        return Icons.apartment_outlined;
      } else if (loc.contains('Hub') || loc.contains('Store') || loc.contains('Boutique')) {
        return Icons.storefront_outlined;
      }
      return Icons.location_on_outlined;
    }

    return PopupMenuButton<String>(
      onSelected: (val) => setState(() => member.location = val),
      color: const Color(0xFFFAF7F2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDFD4C5)),
      ),
      itemBuilder: (ctx) => _locationOptions.map((loc) {
        final isSelected = loc == member.location;
        return PopupMenuItem<String>(
          value: loc,
          height: 38,
          child: Row(
            children: [
              Icon(getLocationIcon(loc), size: 15, color: const Color(0xFF7A7268)),
              const SizedBox(width: 8),
              Text(
                loc,
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
            Icon(getLocationIcon(member.location), size: 16, color: const Color(0xFF7A7268)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                member.location,
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
    );
  }

  // ========================================================
  // CARD 2: PERMISSION INFO
  // ========================================================
  Widget _buildPermissionInfoCard() {
    return Container(
      width: double.infinity,
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
          // Header: Shield Icon + Title + Subtitle
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFBF4E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: Color(0xFFBA8A55),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permission Info',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'You can refine permissions for each role after setup from Settings → Team.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF7A7268),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 Role Cards Row
          Row(
            children: [
              Expanded(
                child: _buildRoleInfoBox(
                  icon: Icons.person_outline_rounded,
                  title: 'Manager',
                  description: 'Full operational access excluding system settings.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRoleInfoBox(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory Staff',
                  description: 'Manage inventory, view reports, process stock.',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRoleInfoBox(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Purchasing',
                  description: 'Create and manage purchase orders and suppliers.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleInfoBox({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEADBCA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFF181513)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6E665B),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================
  // BOTTOM NAVIGATION: Back, Skip, Invite Team & Continue
  // ========================================================
  Widget _buildNavigationRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // [← Back]
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onBack,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDFD6C9)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.arrow_back_rounded,
                    size: 16,
                    color: Color(0xFF181513),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Back',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Right side: [Skip for now] + [Invite Team & Continue →]
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onSkip,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFDFD6C9)),
                  ),
                  child: Text(
                    'Skip for now',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF181513),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onContinue ?? _finishAndOpenDashboard,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF382718),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E1C1A).withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Invite Team & Continue',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.white,
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

  // ========================================================
  // RIGHT: YOU'RE READY / ATELIER OS SETUP COMPLETE CARD
  // ========================================================
  Widget _buildSetupCompleteCard() {
    return Container(
      padding: const EdgeInsets.all(22),
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
          // Top Pill: YOU'RE READY
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF5EC),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "YOU'RE READY",
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: const Color(0xFF2E7D32),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Title & Description
          Text(
            'Atelier OS Setup Complete',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We have prepared your operational framework. Here is a summary of your configuration.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7A7268),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Configuration Summary List
          _buildSummaryRow(
            icon: Icons.storefront_outlined,
            label: 'Business',
            value: 'ThreadStock India Ltd',
          ),
          const SizedBox(height: 14),
          _buildSummaryRow(
            icon: Icons.home_work_outlined,
            label: 'Core Node',
            value: 'Central Warehouse (Zone A)',
          ),
          const SizedBox(height: 14),
          _buildSummaryRow(
            icon: Icons.monetization_on_outlined,
            label: 'Accounting Currency',
            value: 'INR (₹)',
          ),
          const SizedBox(height: 14),
          _buildSummaryRow(
            icon: Icons.receipt_long_outlined,
            label: 'Tax Matrix',
            value: 'GST Schema Configured',
          ),
          const SizedBox(height: 14),
          _buildSummaryRow(
            icon: Icons.people_outline_rounded,
            label: 'Pending Invites',
            value: '${_members.length} operators',
          ),
          const SizedBox(height: 26),

          // [Open ThreadStock Dashboard ↗] Main CTA
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _finishAndOpenDashboard,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF261D15),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E1C1A).withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Open ThreadStock Dashboard',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Footnote Disclaimer
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1.5),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: Color(0xFF9E958A),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'By opening, you confirm system parameter constraints.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8C8478),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFBA8A55)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7A7268),
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF181513),
          ),
        ),
      ],
    );
  }
}
