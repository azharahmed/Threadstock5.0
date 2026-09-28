// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/navigation/navigation_guard.dart';
import 'package:threadstock/features/inventory/data/location_repository.dart';

class TeamMemberEntry {
  final TextEditingController emailController;
  String? role;
  String? location;
  String? emailError;

  TeamMemberEntry({
    String email = '',
    this.role,
    this.location,
    this.emailError,
  }) : emailController = TextEditingController(text: email);

  void dispose() {
    emailController.dispose();
  }
}

class TeamOnboardingView extends StatefulWidget {
  const TeamOnboardingView({
    super.key,
    this.businessName,
    this.coreNode,
    this.currency,
    this.taxMatrix,
    this.availableLocations,
    this.locationRepository,
    this.progressBar,
    this.onBack,
    this.onSkip,
    this.onContinue,
    this.onOpenDashboard,
  });

  final String? businessName;
  final String? coreNode;
  final String? currency;
  final String? taxMatrix;
  final List<String>? availableLocations;
  final LocationRepository? locationRepository;
  final Widget? progressBar;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final ValueChanged<List<TeamMemberEntry>>? onContinue;
  final VoidCallback? onOpenDashboard;

  @override
  State<TeamOnboardingView> createState() => _TeamOnboardingViewState();
}

class _TeamOnboardingViewState extends State<TeamOnboardingView> {
  late final List<TeamMemberEntry> _members;
  List<String> _locations = [];
  bool _isLoadingLocations = false;

  static const List<String> _roleOptions = [
    'Owner',
    'Store Manager',
    'Inventory Staff',
    'Cashier',
  ];

  @override
  void initState() {
    super.initState();
    _members = [];
    _initLocations();
  }

  void _initLocations() {
    if (widget.availableLocations != null &&
        widget.availableLocations!.isNotEmpty) {
      _locations = List.from(widget.availableLocations!);
      _setupInitialMember();
    } else {
      _setupInitialMember();
      _fetchLocationsFromRepository();
    }
  }

  Future<void> _fetchLocationsFromRepository() async {
    setState(() => _isLoadingLocations = true);
    try {
      final repo = widget.locationRepository ?? LocationRepository();
      final fetched = await repo.getLocations();
      final names = fetched
          .map((l) => l.name.trim())
          .where((name) => name.isNotEmpty && name != 'All Locations')
          .toSet()
          .toList();

      if (mounted) {
        setState(() {
          _locations = names;
          _applyLocationAutoSelect();
        });
      }
    } catch (_) {
      // Offline or unconfigured fallback
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocations = false);
      }
    }
  }

  void _setupInitialMember() {
    final singleLocation = _locations.length == 1 ? _locations.first : null;
    final initialEntry = TeamMemberEntry(
      email: '',
      role: null,
      location: singleLocation,
    );
    initialEntry.emailController.addListener(_onEmailChanged);
    _members.add(initialEntry);
  }

  void _applyLocationAutoSelect() {
    if (_locations.length == 1) {
      final single = _locations.first;
      for (final m in _members) {
        m.location ??= single;
      }
    }
  }

  void _onEmailChanged() {
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant TeamOnboardingView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.availableLocations != oldWidget.availableLocations) {
      if (widget.availableLocations != null &&
          widget.availableLocations!.isNotEmpty) {
        _locations = List.from(widget.availableLocations!);
      } else {
        _locations = [];
      }
      _applyLocationAutoSelect();
      setState(() {});
    }
  }

  @override
  void dispose() {
    for (final member in _members) {
      member.emailController.removeListener(_onEmailChanged);
      member.dispose();
    }
    super.dispose();
  }

  void _addMember() {
    final singleLocation = _locations.length == 1 ? _locations.first : null;
    final entry = TeamMemberEntry(
      email: '',
      role: null,
      location: singleLocation,
    );
    entry.emailController.addListener(_onEmailChanged);
    setState(() {
      _members.add(entry);
    });
  }

  void _removeMember(int index) {
    if (_members.length > 1) {
      setState(() {
        final removed = _members.removeAt(index);
        removed.emailController.removeListener(_onEmailChanged);
        removed.dispose();
      });
    }
  }

  int get _validPendingInvitesCount {
    return _members.where((m) {
      final email = m.emailController.text.trim();
      return email.isNotEmpty && email.contains('@') && email.contains('.');
    }).length;
  }

  bool _validateAndProceed() {
    bool hasErrors = false;
    for (final m in _members) {
      final email = m.emailController.text.trim();
      if (email.isNotEmpty) {
        final isValid =
            email.contains('@') && email.contains('.') && email.length >= 5;
        if (!isValid) {
          hasErrors = true;
          m.emailError = 'Please enter a valid email address.';
        } else {
          m.emailError = null;
        }
      } else {
        m.emailError = null;
      }
    }

    if (hasErrors) {
      setState(() {});
      return false;
    }

    if (widget.onContinue != null) {
      widget.onContinue!(_members);
    } else if (widget.onSkip != null) {
      widget.onSkip!();
    }
    return true;
  }

  void _finishAndOpenDashboard() {
    if (widget.onOpenDashboard != null) {
      widget.onOpenDashboard!();
    } else {
      NavigationGuard.safePushNamedAndRemoveUntil(
        context,
        AppRoutes.overview,
        (route) => false,
        source: 'TeamOnboardingView._finishAndOpenDashboard',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1040),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Main Form Column (flex: 3)
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(36),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Tag
                  Text(
                    'STEP 6 OF 6 — TEAM',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: const Color(0xFFBA8A55),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Garamond Editorial Title
                  Text(
                    'Invite your team',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 34,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF161412),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    'Add the people who will help run your business. You can always invite more team members later.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF615B52),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (widget.progressBar != null) ...[
                    const SizedBox(height: 12),
                    widget.progressBar!,
                  ],
                  const SizedBox(height: 20),

                  // Table Header
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          'EMAIL ADDRESS',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: const Color(0xFF5E574E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'ROLE',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: const Color(0xFF5E574E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'LOCATION',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: const Color(0xFF5E574E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 44), // Space for delete icon
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Team rows
                  Column(
                    children: List.generate(_members.length, (index) {
                      final member = _members[index];
                      return _buildMemberRow(member, index);
                    }),
                  ),
                  const SizedBox(height: 12),

                  // Store Manager & Roles Callout Banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F3EA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE5DACD)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.badge_outlined,
                            size: 18,
                            color: Color(0xFFBA8A55),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: 'ROLE ACCESS — ',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E1C1A),
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      'Store Managers manage operations • Inventory Staff count & transfer stock • Cashiers handle checkout • You can refine granular permissions anytime in Settings.',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF5E574E),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                            style: GoogleFonts.inter(fontSize: 12, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add another member link
                  TextButton.icon(
                    onPressed: _addMember,
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Color(0xFFBA8A55),
                    ),
                    label: Text(
                      'Add another member',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFBA8A55),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bottom Action Navigation Row: Back, Skip, Invite & Continue
                  Row(
                    children: [
                      // Back button
                      OutlinedButton.icon(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: Text(
                          'Back',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E1C1A),
                          side: const BorderSide(
                            color: Color(0xFFD5C7B5),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Skip & Continue
                      TextButton(
                        onPressed: widget.onSkip,
                        child: Text(
                          'Skip for now',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5E574E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: _validateAndProceed,
                          iconAlignment: IconAlignment.end,
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                          ),
                          label: Text(
                            'Invite Team & Continue',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1C1A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),

          // Right Summary Panel Column (flex: 2)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F1E5),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDCCFBD)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 13,
                          color: Color(0xFFBA8A55),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "CONFIGURATION SUMMARY",
                          style: GoogleFonts.inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: const Color(0xFFBA8A55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'ThreadStock Setup',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF161412),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'We have prepared your operational framework. Here is a live summary of your configuration.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B6358),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE5DACD), height: 1),
                  const SizedBox(height: 18),

                  // The 5 Dynamic Configuration Summary Rows:
                  _buildSummaryRow(
                    icon: Icons.storefront_outlined,
                    label: 'Business',
                    value:
                        (widget.businessName != null &&
                            widget.businessName!.trim().isNotEmpty)
                        ? widget.businessName!.trim()
                        : '—',
                  ),
                  const SizedBox(height: 14),

                  _buildSummaryRow(
                    icon: Icons.home_work_outlined,
                    label: 'Core Node',
                    value:
                        (widget.coreNode != null &&
                            widget.coreNode!.trim().isNotEmpty)
                        ? widget.coreNode!.trim()
                        : '—',
                  ),
                  const SizedBox(height: 14),

                  _buildSummaryRow(
                    icon: Icons.monetization_on_outlined,
                    label: 'Accounting Currency',
                    value:
                        (widget.currency != null &&
                            widget.currency!.trim().isNotEmpty)
                        ? widget.currency!.trim()
                        : '—',
                  ),
                  const SizedBox(height: 14),

                  _buildSummaryRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'Tax Matrix',
                    value:
                        (widget.taxMatrix != null &&
                            widget.taxMatrix!.trim().isNotEmpty)
                        ? widget.taxMatrix!.trim()
                        : '—',
                  ),
                  const SizedBox(height: 14),

                  _buildSummaryRow(
                    icon: Icons.people_outline_rounded,
                    label: 'Pending Invites',
                    value: _validPendingInvitesCount == 0
                        ? '0 operators'
                        : '$_validPendingInvitesCount ${_validPendingInvitesCount == 1 ? 'operator' : 'operators'}',
                  ),
                  const SizedBox(height: 26),

                  // Open ThreadStock Dashboard CTA
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _finishAndOpenDashboard,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        height: 44,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF261D15),
                          borderRadius: BorderRadius.circular(10),
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
                            Flexible(
                              child: Text(
                                'Open ThreadStock Dashboard',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(TeamMemberEntry member, int index) {
    final hasError = member.emailError != null && member.emailError!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Email input
              Expanded(
                flex: 5,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: hasError
                          ? const Color(0xFFB42318)
                          : const Color(0xFFDCCFBE),
                    ),
                  ),
                  alignment: Alignment.centerLeft,
                  child: TextField(
                    controller: member.emailController,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF1E1C1A),
                      fontWeight: FontWeight.w400,
                    ),
                    decoration: InputDecoration(
                      hintText: 'name@company.com',
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF9E9589).withOpacity(0.6),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Role Dropdown
              Expanded(
                flex: 4,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDCCFBE)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: member.role,
                      isExpanded: true,
                      hint: Text(
                        'Select role',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9E9589).withOpacity(0.7),
                        ),
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF5E574E),
                      ),
                      items: _roleOptions.map((role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(
                            role,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF1E1C1A),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => member.role = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Location Dropdown
              Expanded(
                flex: 4,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDCCFBE)),
                  ),
                  child: _locations.isEmpty
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _isLoadingLocations
                                ? 'Loading…'
                                : 'No locations available',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF9E9589),
                            ),
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _locations.contains(member.location)
                                ? member.location
                                : null,
                            isExpanded: true,
                            hint: Text(
                              'Select location',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF9E9589).withOpacity(0.7),
                              ),
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: Color(0xFF5E574E),
                            ),
                            items: _locations.map((loc) {
                              return DropdownMenuItem<String>(
                                value: loc,
                                child: Text(
                                  loc,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF1E1C1A),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => member.location = val);
                            },
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),

              // Delete button (visible/enabled if _members.length > 1)
              SizedBox(
                width: 38,
                height: 44,
                child: _members.length > 1
                    ? IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Color(0xFFB42318),
                        ),
                        tooltip: 'Remove',
                        onPressed: () => _removeMember(index),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          if (hasError) ...[
            const SizedBox(height: 4),
            Text(
              member.emailError!,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFB42318),
              ),
            ),
          ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: const Color(0xFFBA8A55)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                  color: const Color(0xFF7A7268),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF181513),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: const Color(0xFFFAF7F2).withOpacity(0.92),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE8DFD3), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2A231A).withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
