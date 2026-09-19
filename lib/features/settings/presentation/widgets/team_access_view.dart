// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MemberItem {
  MemberItem({
    required this.name,
    required this.email,
    required this.role,
    required this.location,
    required this.status,
    required this.avatarAsset,
    this.isCurrentUser = false,
    this.isSelected = false,
    required this.systemRole,
    required this.primaryNode,
    required this.phone,
    required this.joinedOn,
    required this.permissions,
  });

  final String name;
  final String email;
  final String role;
  final String location;
  final String status;
  final String avatarAsset;
  final bool isCurrentUser;
  bool isSelected;
  final String systemRole;
  final String primaryNode;
  final String phone;
  final String joinedOn;
  final List<PermissionItem> permissions;
}

class PermissionItem {
  const PermissionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class TeamAccessView extends StatefulWidget {
  const TeamAccessView({
    super.key,
    this.onInviteMember,
    this.onTabChanged,
  });

  final VoidCallback? onInviteMember;
  final ValueChanged<String>? onTabChanged;

  @override
  State<TeamAccessView> createState() => _TeamAccessViewState();
}

class _TeamAccessViewState extends State<TeamAccessView> {
  int _activeSubNavIndex = 0; // 0: Team & Access, 1: Roles & Permissions, 2: Locations, 3: Integrations, 4: System
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  int _selectedMemberIndex = 1; // Priya Sharma is selected by default

  late final List<MemberItem> _members;

  @override
  void initState() {
    super.initState();
    _members = [
      MemberItem(
        name: 'Alex Mercer',
        email: 'alex@threadstock.ai',
        role: 'Central Admin',
        location: 'Warehouse Zone A',
        status: 'Active',
        avatarAsset: 'assets/alex_mercer.jpg',
        isCurrentUser: true,
        isSelected: false,
        systemRole: 'Central Administrator',
        primaryNode: 'Warehouse Zone A',
        phone: '+1 555-019-2834',
        joinedOn: '10 Oct 2023',
        permissions: const [
          PermissionItem(
            title: 'Full workspace access',
            subtitle: 'Superuser system override',
            icon: Icons.admin_panel_settings_outlined,
          ),
          PermissionItem(
            title: 'Manage roles & billing',
            subtitle: 'Enterprise subscription control',
            icon: Icons.credit_card_outlined,
          ),
        ],
      ),
      MemberItem(
        name: 'Priya Sharma',
        email: 'priya@threadstock.ai',
        role: 'Manager',
        location: 'Delhi Flagship Hub',
        status: 'Active',
        avatarAsset: 'assets/priya_nair.jpg',
        isCurrentUser: false,
        isSelected: true,
        systemRole: 'Regional Manager',
        primaryNode: 'Delhi Hub (Zone A)',
        phone: '+91 98765 43210',
        joinedOn: '12 Jan 2024',
        permissions: const [
          PermissionItem(
            title: 'Edit stock quantities',
            subtitle: 'Allows counts modification',
            icon: Icons.edit_note_rounded,
          ),
          PermissionItem(
            title: 'Trigger stock transfers',
            subtitle: 'Authorize regional logistics',
            icon: Icons.sync_alt_rounded,
          ),
          PermissionItem(
            title: 'Access intelligence reports',
            subtitle: 'Read executive insights',
            icon: Icons.access_time_rounded,
          ),
          PermissionItem(
            title: 'Direct billing control',
            subtitle: 'Update plan & add cards',
            icon: Icons.credit_card_outlined,
          ),
        ],
      ),
      MemberItem(
        name: 'Karan Johar',
        email: 'karan@threadstock.ai',
        role: 'Inventory Staff',
        location: 'Warehouse Zone A',
        status: 'Active',
        avatarAsset: 'assets/arun_kapoor.jpg',
        isCurrentUser: false,
        isSelected: false,
        systemRole: 'Inventory Specialist',
        primaryNode: 'Warehouse Zone A',
        phone: '+91 98112 34567',
        joinedOn: '04 Mar 2024',
        permissions: const [
          PermissionItem(
            title: 'Perform cycle counts',
            subtitle: 'Scan and recount inventory batches',
            icon: Icons.qr_code_scanner_rounded,
          ),
          PermissionItem(
            title: 'Receive PO shipments',
            subtitle: 'Mark incoming deliveries',
            icon: Icons.inventory_2_outlined,
          ),
        ],
      ),
      MemberItem(
        name: 'Sarah Connor',
        email: 'sarah@threadstock.ai',
        role: 'Purchasing',
        location: 'Central Office',
        status: 'Active',
        avatarAsset: 'assets/emma_carter.jpg',
        isCurrentUser: false,
        isSelected: false,
        systemRole: 'Procurement Lead',
        primaryNode: 'Central Office',
        phone: '+1 415-882-9012',
        joinedOn: '15 Nov 2023',
        permissions: const [
          PermissionItem(
            title: 'Create purchase orders',
            subtitle: 'Issue POs to external suppliers',
            icon: Icons.shopping_bag_outlined,
          ),
          PermissionItem(
            title: 'Approve vendor quotes',
            subtitle: 'Contract price adjustments',
            icon: Icons.assignment_turned_in_outlined,
          ),
        ],
      ),
      MemberItem(
        name: 'Rohit Shetty',
        email: 'rohit@threadstock.ai',
        role: 'Cashier',
        location: 'Mumbai Phoenix',
        status: 'Inactive',
        avatarAsset: 'assets/vikram_singh.jpg',
        isCurrentUser: false,
        isSelected: false,
        systemRole: 'Store Cashier',
        primaryNode: 'Mumbai Phoenix',
        phone: '+91 97654 32109',
        joinedOn: '20 Feb 2024',
        permissions: const [
          PermissionItem(
            title: 'POS terminal register',
            subtitle: 'Ring up retail orders',
            icon: Icons.point_of_sale_rounded,
          ),
        ],
      ),
      MemberItem(
        name: 'Vikram Malhotra',
        email: 'vikram@threadstock.ai',
        role: 'Manager',
        location: 'Lucknow Regent',
        status: 'Active',
        avatarAsset: 'assets/arun_kapoor.jpg',
        isCurrentUser: false,
        isSelected: false,
        systemRole: 'Store Manager',
        primaryNode: 'Lucknow Regent',
        phone: '+91 99887 76655',
        joinedOn: '01 Feb 2024',
        permissions: const [
          PermissionItem(
            title: 'Store stock control',
            subtitle: 'Manage local allocations',
            icon: Icons.storefront_outlined,
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  MemberItem get _selectedMember => _members[_selectedMemberIndex];

  List<MemberItem> get _filteredMembers {
    final q = _searchController.text.trim().toLowerCase();
    return _members.where((m) {
      if (_selectedFilter == 'Managers' && m.role != 'Manager') return false;
      if (_selectedFilter == 'Inventory Staff' && m.role != 'Inventory Staff') return false;
      if (_selectedFilter == 'Purchasing' && m.role != 'Purchasing') return false;
      if (_selectedFilter == 'Cashier' && m.role != 'Cashier') return false;
      if (_selectedFilter == 'Inactive' && m.status != 'Inactive') return false;

      if (q.isNotEmpty) {
        final match = m.name.toLowerCase().contains(q) ||
            m.email.toLowerCase().contains(q) ||
            m.role.toLowerCase().contains(q) ||
            m.location.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sub-Navigation Tabs
          _buildSubNavTabs(),
          const SizedBox(height: 22),

          // 2. Title Row & Invite Button
          _buildTitleRow(),
          const SizedBox(height: 18),

          // 3. Filter Pills & Search
          _buildFiltersRow(),
          const SizedBox(height: 16),

          // 4. Two-Column Layout: Table + Member Details Inspector
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Team Members Table
              Expanded(
                child: _buildMembersTable(),
              ),
              const SizedBox(width: 20),

              // Right: Member Details Card
              SizedBox(
                width: 360,
                child: _buildMemberDetailsCard(),
              ),
            ],
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // 1. Sub-Navigation Tabs
  Widget _buildSubNavTabs() {
    final tabs = [
      'Team & Access',
      'Roles & Permissions',
      'Locations',
      'Integrations',
      'System',
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            _buildSubNavTabItem(tabs[i], i),
            if (i < tabs.length - 1) const SizedBox(width: 26),
          ],
        ],
      ),
    );
  }

  Widget _buildSubNavTabItem(String title, int index) {
    final isActive = _activeSubNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _activeSubNavIndex = index);
        if (index == 1) {
          widget.onTabChanged?.call('roles_permissions');
        } else if (index == 2) {
          widget.onTabChanged?.call('locations');
        } else if (index == 3) {
          widget.onTabChanged?.call('integrations');
        } else if (index == 4) {
          widget.onTabChanged?.call('system_settings');
        }
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFFD97706) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF181513) : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  // 2. Title Row & Invite Button
  Widget _buildTitleRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Team Directory',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '24 members',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your team members, roles and access across all locations.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: widget.onInviteMember ?? _showInviteModal,
          icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
          label: const Text('Invite Member'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF181513),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // 3. Filter Pills & Search
  Widget _buildFiltersRow() {
    final filters = [
      'All',
      'Managers',
      'Inventory Staff',
      'Purchasing',
      'Cashier',
      'Inactive',
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            for (final f in filters) ...[
              _buildFilterPill(f),
              const SizedBox(width: 8),
            ],
          ],
        ),
        Container(
          width: 220,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'Search members...',
                    hintStyle: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String filter) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = filter),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF18181B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF18181B) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          filter,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  // 4. Team Members Table
  Widget _buildMembersTable() {
    final filtered = _filteredMembers;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Icon(Icons.check_box_outline_blank, size: 16, color: const Color(0xFFCBD5E1)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 32,
                  child: Text('Member', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ),
                Expanded(
                  flex: 20,
                  child: Text('Role', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ),
                Expanded(
                  flex: 24,
                  child: Text('Location', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ),
                Expanded(
                  flex: 14,
                  child: Text('Status', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
                ),
                const SizedBox(
                  width: 32,
                  child: Text('Actions', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Rows
          for (int i = 0; i < filtered.length; i++) ...[
            _buildTableRow(i, filtered[i]),
            if (i < filtered.length - 1) const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],

          // Footer Pagination
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing 1–6 of 24 members',
                  style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                ),
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.chevron_left_rounded, size: 16, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFD97706)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '1',
                        style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFFB45309)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _buildPageItem('2'),
                    const SizedBox(width: 6),
                    _buildPageItem('3'),
                    const SizedBox(width: 6),
                    _buildPageItem('4'),
                    const SizedBox(width: 6),
                    Text('...', style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF94A3B8))),
                    const SizedBox(width: 6),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(int index, MemberItem item) {
    final isSelected = _selectedMemberIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedMemberIndex = index;
          for (int j = 0; j < _members.length; j++) {
            _members[j].isSelected = (j == index);
          }
        });
      },
      child: Container(
        color: isSelected ? const Color(0xFFFFFBEB).withOpacity(0.6) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Checkbox
            SizedBox(
              width: 24,
              child: Icon(
                item.isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
                size: 16,
                color: item.isSelected ? const Color(0xFF181513) : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(width: 8),

            // Avatar + Name + Subtitle (Email) + You badge
            Expanded(
              flex: 32,
              child: Row(
                children: [
                  ClipOval(
                    child: Image.asset(
                      item.avatarAsset,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 32,
                        height: 32,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(Icons.person, size: 18, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ),
                            if (item.isCurrentUser) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'You',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          item.email,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Role
            Expanded(
              flex: 20,
              child: Text(
                item.role,
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF374151)),
              ),
            ),

            // Location
            Expanded(
              flex: 24,
              child: Text(
                item.location,
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF374151)),
              ),
            ),

            // Status
            Expanded(
              flex: 14,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: item.status == 'Active' ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.status,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: item.status == 'Active' ? const Color(0xFF15803D) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),

            // Actions
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFF9CA3AF)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageItem(String num) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      alignment: Alignment.center,
      child: Text(num, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF6B7280))),
    );
  }

  // 5. Right Member Details Inspector Card
  Widget _buildMemberDetailsCard() {
    final member = _selectedMember;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Member Details',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, size: 13),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  textStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Member Info with Large Avatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  member.avatarAsset,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.person, size: 40, color: Color(0xFF94A3B8)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: member.status == 'Active' ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            member.status,
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: member.status == 'Active' ? const Color(0xFF15803D) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      member.email,
                      style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      member.systemRole,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Metadata Details List
          _buildMetaRow(Icons.person_outline_rounded, 'System Role', member.systemRole),
          const SizedBox(height: 12),
          _buildMetaRow(Icons.shield_outlined, 'Primary Node Access', member.primaryNode, isHighlighted: true),
          const SizedBox(height: 12),
          _buildMetaRow(Icons.phone_outlined, 'Phone', member.phone),
          const SizedBox(height: 12),
          _buildMetaRow(Icons.location_on_outlined, 'Location', member.location),
          const SizedBox(height: 12),
          _buildMetaRow(Icons.calendar_today_outlined, 'Joined On', member.joinedOn),

          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Explicit System Permissions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Explicit System Permissions',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                ),
              ),
              InkWell(
                onTap: () {},
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          for (final perm in member.permissions) ...[
            _buildPermissionItem(perm),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 14),

          // Buttons
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Edit Permissions'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 11),
                textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delete_outline_rounded, size: 15, color: Color(0xFFDC2626)),
              label: const Text('Deactivate Member'),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                foregroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFFEE2E2)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
                textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String label, String value, {bool isHighlighted = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w400),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isHighlighted ? const Color(0xFFD97706) : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildPermissionItem(PermissionItem item) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(item.icon, size: 15, color: const Color(0xFF475569)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              Text(
                item.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showInviteModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF4EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF92400E), size: 20),
            ),
            const SizedBox(width: 12),
            Text('Invite Team Member', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'colleague@threadstock.ai',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Assigned Role',
                  hintText: 'Manager, Inventory Staff, Purchasing...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Location Scope',
                  hintText: 'e.g. Delhi Flagship Hub, Warehouse Zone A',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invitation sent successfully.'),
                  backgroundColor: Color(0xFF181513),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF181513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }
}
