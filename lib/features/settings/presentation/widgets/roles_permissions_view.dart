// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RoleItem {
  final String id;
  final String title;
  final String description;
  final int memberCount;
  final IconData icon;
  final bool isSystem;

  const RoleItem({
    required this.id,
    required this.title,
    required this.description,
    required this.memberCount,
    required this.icon,
    this.isSystem = false,
  });

  RoleItem copyWith({
    String? id,
    String? title,
    String? description,
    int? memberCount,
    IconData? icon,
    bool? isSystem,
  }) {
    return RoleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      memberCount: memberCount ?? this.memberCount,
      icon: icon ?? this.icon,
      isSystem: isSystem ?? this.isSystem,
    );
  }
}

class RoleProfileItem {
  const RoleProfileItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.activeCount,
    required this.icon,
    required this.iconColor,
  });

  final String id;
  final String name;
  final String subtitle;
  final int activeCount;
  final IconData icon;
  final Color iconColor;
}

class ModulePermission {
  ModulePermission({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.canView,
    required this.canCreate,
    required this.canEdit,
    required this.canDelete,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  bool canView;
  bool canCreate;
  bool canEdit;
  bool canDelete;
}

class RolesPermissionsView extends StatefulWidget {
  final Function(String title, String subtitle)? onSubNavChanged;

  const RolesPermissionsView({
    super.key,
    this.onSubNavChanged,
  });

  @override
  State<RolesPermissionsView> createState() => _RolesPermissionsViewState();
}

class _RolesPermissionsViewState extends State<RolesPermissionsView> {
  final TextEditingController _roleSearchController = TextEditingController();
  int _selectedRoleIndex = 2; // Store Manager by default
  int _selectedTab = 0; // 0: Permissions, 1: Users (3), 2: Locations (1), 3: Activity Log

  late final List<RoleProfileItem> _roles;
  late final List<ModulePermission> _modules;

  @override
  void initState() {
    super.initState();
    _roles = const [
      RoleProfileItem(
        id: 'owner',
        name: 'Owner',
        subtitle: 'Full system access',
        activeCount: 2,
        icon: Icons.workspace_premium_outlined,
        iconColor: Color(0xFFD97706),
      ),
      RoleProfileItem(
        id: 'admin',
        name: 'Admin',
        subtitle: 'System administration',
        activeCount: 2,
        icon: Icons.security_outlined,
        iconColor: Color(0xFF4B5563),
      ),
      RoleProfileItem(
        id: 'store_manager',
        name: 'Store Manager',
        subtitle: 'Store operations & team',
        activeCount: 3,
        icon: Icons.storefront_outlined,
        iconColor: Color(0xFFD97706),
      ),
      RoleProfileItem(
        id: 'sales_associate',
        name: 'Sales Associate',
        subtitle: 'Sales and customer service',
        activeCount: 4,
        icon: Icons.people_outline_rounded,
        iconColor: Color(0xFF4B5563),
      ),
      RoleProfileItem(
        id: 'warehouse_staff',
        name: 'Warehouse Staff',
        subtitle: 'Inventory & fulfillment',
        activeCount: 3,
        icon: Icons.inventory_2_outlined,
        iconColor: Color(0xFFD97706),
      ),
      RoleProfileItem(
        id: 'inventory_manager',
        name: 'Inventory Manager',
        subtitle: 'Inventory control',
        activeCount: 2,
        icon: Icons.all_inbox_outlined,
        iconColor: Color(0xFF4B5563),
      ),
      RoleProfileItem(
        id: 'purchasing_manager',
        name: 'Purchasing Manager',
        subtitle: 'Purchase orders & suppliers',
        activeCount: 1,
        icon: Icons.shopping_cart_outlined,
        iconColor: Color(0xFF4B5563),
      ),
      RoleProfileItem(
        id: 'analyst',
        name: 'Analyst',
        subtitle: 'Reports & analytics',
        activeCount: 1,
        icon: Icons.bar_chart_outlined,
        iconColor: Color(0xFF4B5563),
      ),
    ];

    _modules = [
      ModulePermission(
        title: 'Sales Management',
        subtitle: 'Terminal registers and quick sales',
        icon: Icons.bar_chart_rounded,
        iconBg: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
        canView: true,
        canCreate: true,
        canEdit: true,
        canDelete: false,
      ),
      ModulePermission(
        title: 'Inventory Management',
        subtitle: 'Stock checks, location counts, and variants',
        icon: Icons.inventory_2_outlined,
        iconBg: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
        canView: true,
        canCreate: true,
        canEdit: true,
        canDelete: false,
      ),
      ModulePermission(
        title: 'Purchasing & Supply Orders',
        subtitle: 'Drafting POs and accepting arrivals',
        icon: Icons.shopping_cart_outlined,
        iconBg: const Color(0xFFFFFBEB),
        iconColor: const Color(0xFFD97706),
        canView: true,
        canCreate: true,
        canEdit: false,
        canDelete: false,
      ),
      ModulePermission(
        title: 'System Configuration',
        subtitle: 'Modifying taxes, API webhooks, and terminals',
        icon: Icons.settings_outlined,
        iconBg: const Color(0xFFF3E8FF),
        iconColor: const Color(0xFF9333EA),
        canView: true,
        canCreate: false,
        canEdit: false,
        canDelete: false,
      ),
    ];
  }

  @override
  void dispose() {
    _roleSearchController.dispose();
    super.dispose();
  }

  List<RoleProfileItem> get _filteredRoles {
    final q = _roleSearchController.text.trim().toLowerCase();
    if (q.isEmpty) return _roles;
    return _roles.where((r) => r.name.toLowerCase().contains(q) || r.subtitle.toLowerCase().contains(q)).toList();
  }

  void _showCreateRoleModal() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFBF4EB), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.admin_panel_settings_outlined, color: Color(0xFF92400E), size: 20),
            ),
            const SizedBox(width: 12),
            Text('Create Custom Access Role', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Role Name',
                  hintText: 'e.g. Regional Supervisor',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe responsibilities and module scope...',
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
                  content: Text('Custom role created.'),
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
            child: const Text('Create Role'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Two-Column Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1060;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Roles list (~28%)
                    SizedBox(
                      width: 290,
                      child: _buildRolesListColumn(),
                    ),
                    const SizedBox(width: 20),

                    // Right Column: Active Role Profile (~72%)
                    Expanded(
                      child: _buildRoleDetailColumn(),
                    ),
                  ],
                );
              }

              // Stacked for smaller viewports
              return Column(
                children: [
                  _buildRolesListColumn(),
                  const SizedBox(height: 20),
                  _buildRoleDetailColumn(),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Bottom Full-Width Banner: Permission Best Practices
          _buildBestPracticesBanner(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ========================================================
  // LEFT COLUMN: Atelier OS Access Roles list
  // ========================================================
  Widget _buildRolesListColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Subtitle
        Text(
          'Atelier OS Access Roles',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
        ),
        const SizedBox(height: 3),
        Text(
          'Manage roles and control permissions across your organization.',
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280), height: 1.3),
        ),
        const SizedBox(height: 14),

        // [+ Create Role] Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showCreateRoleModal,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Create Role'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFFDE68A)),
              backgroundColor: const Color(0xFFFFFBEB).withOpacity(0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 10),
              textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Search Input
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, size: 16, color: Color(0xFF9CA3AF)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _roleSearchController,
                  style: GoogleFonts.inter(fontSize: 12.5),
                  decoration: const InputDecoration(
                    hintText: 'Search roles...',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12.5),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Roles Tiles List
        for (int i = 0; i < _filteredRoles.length; i++) ...[
          _buildRoleTile(_filteredRoles[i], i),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildRoleTile(RoleProfileItem role, int index) {
    final isSelected = _selectedRoleIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedRoleIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFFBEB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFFFDE68A) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              role.icon,
              size: 18,
              color: isSelected ? const Color(0xFFD97706) : const Color(0xFF4B5563),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    role.subtitle,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7280)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${role.activeCount} active',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================
  // RIGHT COLUMN: Active Role Access Profile
  // ========================================================
  Widget _buildRoleDetailColumn() {
    final activeRole = _roles[_selectedRoleIndex.clamp(0, _roles.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activeRole.name} Access Profile',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Allows location-specific retail, transfer and analytics controls.',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Permissions for ${activeRole.name} saved.'),
                        backgroundColor: const Color(0xFF181513),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF181513),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Save Changes'),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. Tabs
        _buildTabsRow(),
        const SizedBox(height: 16),

        // 3. Access Modules Table Card
        _buildModulesCard(),
        const SizedBox(height: 16),

        // 4. Role Information & Assigned Users (2 Columns)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 740;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 54, child: _buildRoleInfoCard(activeRole)),
                  const SizedBox(width: 16),
                  Expanded(flex: 46, child: _buildAssignedUsersCard()),
                ],
              );
            }
            return Column(
              children: [
                _buildRoleInfoCard(activeRole),
                const SizedBox(height: 16),
                _buildAssignedUsersCard(),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTabsRow() {
    final tabs = ['Permissions', 'Users (3)', 'Locations (1)', 'Activity Log'];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          for (int i = 0; i < tabs.length; i++) ...[
            InkWell(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == i ? const Color(0xFFB45309) : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: _selectedTab == i ? FontWeight.w700 : FontWeight.w500,
                    color: _selectedTab == i ? const Color(0xFF92400E) : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  // 3. Access Modules Table Card
  Widget _buildModulesCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 50,
                  child: Text(
                    'Access Modules',
                    style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280)),
                  ),
                ),
                Expanded(flex: 12, child: Center(child: Text('View', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
                Expanded(flex: 12, child: Center(child: Text('Create', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
                Expanded(flex: 12, child: Center(child: Text('Edit', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
                Expanded(flex: 12, child: Center(child: Text('Delete', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))))),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Rows
          for (final mod in _modules) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 50,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: mod.iconBg, shape: BoxShape.circle),
                          child: Icon(mod.icon, size: 16, color: mod.iconColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mod.title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
                              const SizedBox(height: 1),
                              Text(mod.subtitle, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF9CA3AF))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4 Permission Toggles
                  Expanded(flex: 12, child: Center(child: _buildSwitch(mod.canView, (v) => setState(() => mod.canView = v)))),
                  Expanded(flex: 12, child: Center(child: _buildSwitch(mod.canCreate, (v) => setState(() => mod.canCreate = v)))),
                  Expanded(flex: 12, child: Center(child: _buildSwitch(mod.canEdit, (v) => setState(() => mod.canEdit = v)))),
                  Expanded(flex: 12, child: Center(child: _buildSwitch(mod.canDelete, (v) => setState(() => mod.canDelete = v)))),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitch(bool val, ValueChanged<bool> onChanged) {
    return SizedBox(
      height: 22,
      width: 38,
      child: Switch(
        value: val,
        activeColor: const Color(0xFF059669),
        activeTrackColor: const Color(0xFFA7F3D0),
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: const Color(0xFFD1D5DB),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: onChanged,
      ),
    );
  }

  // 4A. Role Information Card
  Widget _buildRoleInfoCard(RoleProfileItem role) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Role Information', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit_outlined, size: 13),
                label: const Text('Edit'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildInfoRow('Role Name', role.name, isBold: true),
          _buildInfoRow('Description', 'Allows location-specific retail, transfer and analytics controls.'),
          _buildInfoRow('Typical Users', 'Store Managers, Assistant Managers'),
          _buildInfoRow('Default Locations', 'Assigned per location'),
          _buildInfoRow('Created', 'Jan 12, 2027, 10:24 AM'),
          _buildInfoRow('Last Updated', 'Nov 14, 2027, 2:18 PM'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 115,
            child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF6B7280))),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4B. Assigned Users Card
  Widget _buildAssignedUsersCard() {
    final users = [
      {'initials': 'MB', 'bg': const Color(0xFFDBEAFE), 'color': const Color(0xFF1D4ED8), 'name': 'Marcus Brody', 'email': 'm.brody@threadstock.com', 'status': 'Active', 'sBg': const Color(0xFFDCFCE7), 'sColor': const Color(0xFF15803D)},
      {'initials': 'DP', 'bg': const Color(0xFFF3E8FF), 'color': const Color(0xFF7E22CE), 'name': 'Devendra Patel', 'email': 'd.patel@suratdenim.in', 'status': 'Pending', 'sBg': const Color(0xFFFEF3C7), 'sColor': const Color(0xFFD97706)},
      {'initials': 'RS', 'bg': const Color(0xFFDCFCE7), 'color': const Color(0xFF15803D), 'name': 'Riya Sharma', 'email': 'r.sharma@threadstock.com', 'status': 'Active', 'sBg': const Color(0xFFDCFCE7), 'sColor': const Color(0xFF15803D)},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Assigned Users (3)', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.person_add_outlined, size: 13),
                label: const Text('Manage Users'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  textStyle: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          for (final u in users) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: u['bg'] as Color,
                    child: Text(
                      u['initials'] as String,
                      style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: u['color'] as Color),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u['name'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
                        Text(u['email'] as String, style: GoogleFonts.inter(fontSize: 10.5, color: const Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(color: u['sBg'] as Color, borderRadius: BorderRadius.circular(4)),
                    child: Text(u['status'] as String, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: u['sColor'] as Color)),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.more_horiz_rounded, size: 16, color: Color(0xFF9CA3AF)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ========================================================
  // BOTTOM BANNER: Permission Best Practices
  // ========================================================
  Widget _buildBestPracticesBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFBF4EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_user_outlined, color: Color(0xFFD97706), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Permission Best Practices',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF92400E)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Review and restrict access based on the principle of least privilege. Keep your data and operations secure.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB45309),
              side: const BorderSide(color: Color(0xFFF59E0B)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('Learn More'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
