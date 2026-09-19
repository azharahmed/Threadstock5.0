// ignore_for_file: deprecated_member_use
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class _BusinessWorkspace {
  const _BusinessWorkspace({
    required this.id,
    required this.name,
    required this.role,
    required this.roleBg,
    required this.roleColor,
    required this.locationCountText,
    required this.statusText,
    required this.isActiveNow,
  });

  final String id;
  final String name;
  final String role;
  final Color roleBg;
  final Color roleColor;
  final String locationCountText;
  final String statusText;
  final bool isActiveNow;
}

class SwitchBusinessDialog extends StatefulWidget {
  const SwitchBusinessDialog({
    super.key,
    this.initialBusinessId = 'mumbai',
    this.onBusinessSelected,
    this.onCreateNewBusiness,
  });

  final String initialBusinessId;
  final ValueChanged<String>? onBusinessSelected;
  final VoidCallback? onCreateNewBusiness;

  static Future<void> show(
    BuildContext context, {
    String initialBusinessId = 'mumbai',
    ValueChanged<String>? onBusinessSelected,
    VoidCallback? onCreateNewBusiness,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.38),
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: SwitchBusinessDialog(
          initialBusinessId: initialBusinessId,
          onBusinessSelected: onBusinessSelected,
          onCreateNewBusiness: onCreateNewBusiness,
        ),
      ),
    );
  }

  @override
  State<SwitchBusinessDialog> createState() => _SwitchBusinessDialogState();
}

class _SwitchBusinessDialogState extends State<SwitchBusinessDialog> {
  late String _selectedId;
  final _searchController = TextEditingController();

  final List<_BusinessWorkspace> _businesses = const [
    _BusinessWorkspace(
      id: 'mumbai',
      name: 'ThreadStock Mumbai',
      role: 'Owner',
      roleBg: Color(0xFFE3F3EB),
      roleColor: Color(0xFF1F7A46),
      locationCountText: '3 locations',
      statusText: 'Active Now',
      isActiveNow: true,
    ),
    _BusinessWorkspace(
      id: 'delhi',
      name: 'ThreadStock Delhi',
      role: 'Manager',
      roleBg: Color(0xFFE8EFFC),
      roleColor: Color(0xFF2A5DA8),
      locationCountText: '2 locations',
      statusText: 'Last active 2 hours ago',
      isActiveNow: false,
    ),
    _BusinessWorkspace(
      id: 'bengaluru',
      name: 'ThreadStock Bengaluru',
      role: 'Viewer',
      roleBg: Color(0xFFF0EDE8),
      roleColor: Color(0xFF6B6357),
      locationCountText: '1 location',
      statusText: 'Last active 3 days ago',
      isActiveNow: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialBusinessId;
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_BusinessWorkspace> get _filteredBusinesses {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _businesses;
    return _businesses.where((b) {
      return b.name.toLowerCase().contains(q) ||
          b.role.toLowerCase().contains(q) ||
          b.locationCountText.toLowerCase().contains(q);
    }).toList();
  }

  void _selectBusiness(_BusinessWorkspace business) {
    setState(() => _selectedId = business.id);
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.apartment_rounded,
              color: Color(0xFFD5A46C),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Switched workspace to ${business.name} (${business.role})',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B18),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(milliseconds: 3000),
      ),
    );
    widget.onBusinessSelected?.call(business.id);
  }

  void _handleCreateNewBusiness() {
    Navigator.of(context, rootNavigator: true).pop();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.add_business_rounded,
              color: Color(0xFFD5A46C),
              size: 18,
            ),
            const SizedBox(width: 10),
            Text(
              'Opening New Business Workspace wizard...',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1B18),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(milliseconds: 3000),
      ),
    );
    widget.onCreateNewBusiness?.call();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredBusinesses;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 500,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFEADBCA),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1E000000),
                blurRadius: 32,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header Row
              Padding(
                padding: const EdgeInsets.fromLTRB(26, 24, 20, 18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge Container with apartment icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF4EC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFF0E5D4),
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.apartment_rounded,
                          size: 22,
                          color: Color(0xFF8D6433),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title & Subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Switch Business',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 23,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF181513),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose a business to switch your workspace.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF6B6357),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Close Button (✕)
                    InkWell(
                      onTap: () => Navigator.of(context, rootNavigator: true).pop(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF9E958A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Search Input Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEAE2D5),
                      width: 1.0,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF181513),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search business, location or code...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF9E958A),
                        fontWeight: FontWeight.w400,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFF8C8478),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                size: 16,
                                color: Color(0xFF8C8478),
                              ),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Business List Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  children: [
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No businesses found matching your query.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF8A8275),
                            ),
                          ),
                        ),
                      )
                    else
                      for (int i = 0; i < filtered.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _buildBusinessCard(filtered[i]),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Divider
              const Divider(
                height: 1,
                color: Color(0xFFF2EBE1),
              ),

              // 4. Bottom Footer: Need a new workspace? Create New Business →
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 18,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF4EC),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFEADBCA),
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: Color(0xFF8D6433),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Need a new workspace?',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B6357),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: _handleCreateNewBusiness,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Create New Business',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF9E6721),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Color(0xFF9E6721),
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
      ),
    );
  }

  Widget _buildBusinessCard(_BusinessWorkspace item) {
    final isSelected = item.id == _selectedId;

    return InkWell(
      onTap: () => _selectBusiness(item),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFDF9F3) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFC89B67)
                : const Color(0xFFEFE7DC),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFBA8A55).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Left Building Icon Container
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFAF2E6)
                    : const Color(0xFFF4ECE0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.apartment_rounded,
                  size: 19,
                  color: isSelected
                      ? const Color(0xFF8D6433)
                      : const Color(0xFF6B6357),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Middle Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Name + Role Badge
                  Row(
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: item.roleBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.role,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Metadata Row: 📍 locations • status
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: Color(0xFF8A8275),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        item.locationCountText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7E766B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFA89F93),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (item.isActiveNow) ...[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1F7A46),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      Text(
                        item.statusText,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: item.isActiveNow
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: item.isActiveNow
                              ? const Color(0xFF1F7A46)
                              : const Color(0xFF7E766B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trailing Chevron Right
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isSelected
                  ? const Color(0xFFBA8A55)
                  : const Color(0xFFA89F93),
            ),
          ],
        ),
      ),
    );
  }
}
