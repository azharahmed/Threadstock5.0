// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';
import 'roles_permissions_view.dart';

/// Representation of a single permission row in a module
class PermissionOperation {
  final String id;
  final String label;
  bool view;
  bool create;
  bool edit;
  bool delete;
  bool approve;
  bool export;

  PermissionOperation({
    required this.id,
    required this.label,
    this.view = false,
    this.create = false,
    this.edit = false,
    this.delete = false,
    this.approve = false,
    this.export = false,
  });
}

/// Representation of a permission module (e.g. Inventory Management)
class PermissionModule {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<PermissionOperation> operations;

  PermissionModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.operations,
  });
}

class EditRoleView extends StatefulWidget {
  final RoleItem? role;
  final VoidCallback? onCancel;
  final ValueChanged<RoleItem>? onSave;
  final VoidCallback? onCreateCustomRole;

  const EditRoleView({
    super.key,
    this.role,
    this.onCancel,
    this.onSave,
    this.onCreateCustomRole,
  });

  @override
  State<EditRoleView> createState() => _EditRoleViewState();
}

class _EditRoleViewState extends State<EditRoleView> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  late List<PermissionModule> _modules;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.role?.title ?? 'Inventory Staff',
    );
    _descriptionController = TextEditingController(
      text:
          widget.role?.description ??
          'Responsible for physical checks, logging local adjustments and executing region transfers.',
    );

    _initPermissionModules();
  }

  void _initPermissionModules() {
    _modules = [
      // 1. Inventory Management
      PermissionModule(
        id: 'inventory_management',
        title: 'Inventory Management',
        subtitle:
            'Controls physical stock counts, variants setup, categories configuration, and logs adjustments.',
        icon: Icons.inventory_2_outlined,
        operations: [
          PermissionOperation(
            id: 'view_stock',
            label: 'View Stock',
            view: true,
            create: false,
            edit: false,
            delete: false,
            approve: false,
            export: false,
          ),
          PermissionOperation(
            id: 'create_products',
            label: 'Create Products & Variants',
            view: true,
            create: true,
            edit: false,
            delete: false,
            approve: false,
            export: false,
          ),
          PermissionOperation(
            id: 'edit_stock_quantities',
            label: 'Edit Stock Quantities',
            view: true,
            create: true,
            edit: true,
            delete: false,
            approve: false,
            export: false,
          ),
          PermissionOperation(
            id: 'adjust_costs',
            label: 'Adjust Costs & Valuations',
            view: false,
            create: false,
            edit: false,
            delete: false,
            approve: false,
            export: false,
          ),
        ],
      ),

      // 2. Transfers & Shipments
      PermissionModule(
        id: 'transfers_shipments',
        title: 'Transfers & Shipments',
        subtitle:
            'Handles inter-store requests, warehouse intake orders, and logistics tracking.',
        icon: Icons.sync_alt_rounded,
        operations: [
          PermissionOperation(
            id: 'initiate_store_transfer',
            label: 'Initiate Store Transfer',
            view: true,
            create: true,
            edit: true,
            delete: false,
            approve: false,
            export: false,
          ),
          PermissionOperation(
            id: 'approve_regional_shipments',
            label: 'Approve Regional Shipments',
            view: false,
            create: false,
            edit: false,
            delete: false,
            approve: false,
            export: false,
          ),
        ],
      ),

      // 3. Purchasing & Procurement
      PermissionModule(
        id: 'purchasing_procurement',
        title: 'Purchasing & Procurement',
        subtitle:
            'Generates supplier purchase orders and manages physical receiving mappings.',
        icon: Icons.shopping_cart_outlined,
        operations: [
          PermissionOperation(
            id: 'view_pos_suppliers',
            label: 'View POs & Suppliers',
            view: true,
            create: false,
            edit: false,
            delete: false,
            approve: false,
            export: false,
          ),
          PermissionOperation(
            id: 'approve_inbound_shipments',
            label: 'Approve Inbound Shipments',
            view: false,
            create: false,
            edit: false,
            delete: false,
            approve: false,
            export: false,
          ),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose;
    _descriptionController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final updatedRole =
        (widget.role ??
                const RoleItem(
                  id: 'inventory_staff',
                  title: 'Inventory Staff',
                  description: '',
                  memberCount: 12,
                  icon: Icons.inventory_2_outlined,
                ))
            .copyWith(
              title: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
            );

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
              "Role '${_nameController.text}' permissions updated successfully.",
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(milliseconds: 2200),
      ),
    );

    widget.onSave?.call(updatedRole);
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
                // Top Header: Role Icon + Title/Subtitle + Cancel & Save Buttons
                _buildHeaderRow(),
                const SizedBox(height: 22),

                // Main White Card: Form Inputs (Role Name & Description) + Permissions Table
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEBE2D5)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2A231A).withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Role Name & Role Description Inputs
                      _buildFormInputs(),

                      const Divider(height: 1, color: Color(0xFFF0E8DD)),

                      // Permissions Matrix Table
                      _buildPermissionsTable(),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Bottom Notice Banner: Restricted System Roles + Create Custom Role CTA
                _buildBottomNoticeBanner(),

                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================================
  // HEADER ROW: Avatar + Title & Subtitle + Action Buttons
  // ========================================================
  Widget _buildHeaderRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left: Avatar Icon + Title + Subtitle
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF2E6),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE8DDD0),
                    width: 1.2,
                  ),
                ),
                child: const Icon(
                  Icons.people_outline_rounded,
                  color: Color(0xFF7A481B),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Role: ${_nameController.text.isNotEmpty ? _nameController.text : 'Custom Role'}',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Customize granular access controls and workspace permissions for on-floor teams.',
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
          ),
        ),
        const SizedBox(width: 20),

        // Right Buttons: Cancel & Save Changes
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton(
              onPressed: widget.onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD8CEC1)),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1C1A),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C3E21),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ========================================================
  // FORM INPUTS: Role Name * & Role Description
  // ========================================================
  Widget _buildFormInputs() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 700;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _buildRoleNameField()),
                const SizedBox(width: 20),
                Expanded(flex: 6, child: _buildRoleDescriptionField()),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRoleNameField(),
                const SizedBox(height: 16),
                _buildRoleDescriptionField(),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildRoleNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Role Name ',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4A4238),
                ),
              ),
              TextSpan(
                text: '*',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB42318),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          onChanged: (_) => setState(() {}),
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF181513),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(
                color: Color(0xFFBA8A55),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Role Description',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4A4238),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _descriptionController,
          style: GoogleFonts.inter(
            fontSize: 13.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF181513),
          ),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: Colors.white,
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
              borderSide: const BorderSide(
                color: Color(0xFFBA8A55),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // PERMISSIONS MATRIX TABLE
  // ========================================================
  Widget _buildPermissionsTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table Header: MODULE / OPERATION + VIEW, CREATE, EDIT, DELETE, APPROVE, EXPORT
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFFAF8F5),
            border: Border(bottom: BorderSide(color: Color(0xFFEBE2D5))),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  'MODULE / OPERATION',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: const Color(0xFF7E766B),
                  ),
                ),
              ),
              _buildHeaderColumn('VIEW'),
              _buildHeaderColumn('CREATE'),
              _buildHeaderColumn('EDIT'),
              _buildHeaderColumn('DELETE'),
              _buildHeaderColumn('APPROVE'),
              _buildHeaderColumn('EXPORT'),
            ],
          ),
        ),

        // Modules and Operations
        for (int m = 0; m < _modules.length; m++) ...[
          _buildModuleSection(_modules[m]),
          if (m < _modules.length - 1)
            const Divider(height: 1, color: Color(0xFFF0E8DD)),
        ],
      ],
    );
  }

  Widget _buildHeaderColumn(String title) {
    return Expanded(
      flex: 1,
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: const Color(0xFF7E766B),
          ),
        ),
      ),
    );
  }

  Widget _buildModuleSection(PermissionModule module) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Module Section Header: Icon + Title + Subtitle
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF4E8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  module.icon,
                  size: 19,
                  color: const Color(0xFF7A481B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      module.subtitle,
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

        // Operation Rows
        for (final op in module.operations) _buildOperationRow(op),
      ],
    );
  }

  Widget _buildOperationRow(PermissionOperation op) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF7F2EB))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              op.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF2C2723),
              ),
            ),
          ),
          _buildCheckboxCell(
            isChecked: op.view,
            onChanged: (val) => setState(() => op.view = val),
          ),
          _buildCheckboxCell(
            isChecked: op.create,
            onChanged: (val) => setState(() => op.create = val),
          ),
          _buildCheckboxCell(
            isChecked: op.edit,
            onChanged: (val) => setState(() => op.edit = val),
          ),
          _buildCheckboxCell(
            isChecked: op.delete,
            onChanged: (val) => setState(() => op.delete = val),
          ),
          _buildCheckboxCell(
            isChecked: op.approve,
            onChanged: (val) => setState(() => op.approve = val),
          ),
          _buildCheckboxCell(
            isChecked: op.export,
            onChanged: (val) => setState(() => op.export = val),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxCell({
    required bool isChecked,
    required ValueChanged<bool> onChanged,
  }) {
    return Expanded(
      flex: 1,
      child: Center(
        child: InkWell(
          onTap: () => onChanged(!isChecked),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isChecked ? const Color(0xFF5C3E21) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isChecked
                    ? const Color(0xFF5C3E21)
                    : const Color(0xFFDCD2C3),
                width: 1.5,
              ),
            ),
            child: isChecked
                ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }

  // ========================================================
  // BOTTOM NOTICE BANNER: Info + Create Custom Role Button
  // ========================================================
  Widget _buildBottomNoticeBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF3E7D3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: Color(0xFFBA8A55),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Changes to system roles are restricted. Create a custom role to customize permissions.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF946128),
              ),
            ),
          ),
          const SizedBox(width: 16),
          OutlinedButton.icon(
            onPressed:
                widget.onCreateCustomRole ??
                () {
                  setState(() {
                    _nameController.text = 'New Custom Role';
                    _descriptionController.text =
                        'Custom access controls configured for workspace operations.';
                    for (final m in _modules) {
                      for (final op in m.operations) {
                        op.view = true;
                        op.create = false;
                        op.edit = false;
                        op.delete = false;
                        op.approve = false;
                        op.export = false;
                      }
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Initialized template for New Custom Role.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: const Color(0xFF1E1C1A),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(milliseconds: 1800),
                    ),
                  );
                },
            icon: const Icon(
              Icons.add_rounded,
              size: 16,
              color: Color(0xFF1E1C1A),
            ),
            label: Text(
              'Create Custom Role',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1C1A),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFDCD2C3)),
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
