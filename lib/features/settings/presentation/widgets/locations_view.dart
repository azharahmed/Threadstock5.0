// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';

class LocationNodeData {
  final String id;
  final String name;
  final bool isPrimary;
  final String type;
  final String cityRegion;
  final String inventory;
  final String staff;
  final String status;
  final String code;
  final String currency;
  final String taxClass;
  final String fullAddress;
  final String timezone;
  final String description;
  final String imagePath;
  final int totalSkus;
  final int staffMembers;
  final List<String> permissions;

  const LocationNodeData({
    required this.id,
    required this.name,
    required this.isPrimary,
    required this.type,
    required this.cityRegion,
    required this.inventory,
    required this.staff,
    required this.status,
    required this.code,
    required this.currency,
    required this.taxClass,
    required this.fullAddress,
    required this.timezone,
    required this.description,
    required this.imagePath,
    required this.totalSkus,
    required this.staffMembers,
    required this.permissions,
  });
}

class LocationsView extends StatefulWidget {
  const LocationsView({
    super.key,
    this.onAddLocation,
  });

  final VoidCallback? onAddLocation;

  @override
  State<LocationsView> createState() => _LocationsViewState();
}

class _LocationsViewState extends State<LocationsView> {
  final List<LocationNodeData> _nodes = const [
    LocationNodeData(
      id: 'central_store',
      name: 'Central Store',
      isPrimary: true,
      type: 'Flagship Retail',
      cityRegion: 'Bengaluru',
      inventory: '14,200 SKUs',
      staff: '12 members',
      status: 'Active',
      code: 'BLR-CTRL-01',
      currency: 'INR (₹)',
      taxClass: 'CGST + SGST (18%)',
      fullAddress: 'Bengaluru, Karnataka',
      timezone: 'IST (GMT+5:30)',
      description: 'Flagship retail location and main customer-facing store.',
      imagePath: 'Assets/central_store.jpg',
      totalSkus: 14200,
      staffMembers: 12,
      permissions: [
        'Allow direct point-of-sale checkout',
        'Allow internal stock replenishment',
        'Allow receiving from outside suppliers',
      ],
    ),
    LocationNodeData(
      id: 'mg_road_store',
      name: 'MG Road Store',
      isPrimary: false,
      type: 'Retail Outlet',
      cityRegion: 'Bengaluru',
      inventory: '8,450 SKUs',
      staff: '6 members',
      status: 'Active',
      code: 'BLR-MGRD-02',
      currency: 'INR (₹)',
      taxClass: 'CGST + SGST (18%)',
      fullAddress: 'Bengaluru, Karnataka',
      timezone: 'IST (GMT+5:30)',
      description: 'Downtown commercial boutique catering to walk-in foot traffic.',
      imagePath: 'Assets/central_store.jpg',
      totalSkus: 8450,
      staffMembers: 6,
      permissions: [
        'Allow direct point-of-sale checkout',
        'Allow internal stock replenishment',
      ],
    ),
    LocationNodeData(
      id: 'main_warehouse',
      name: 'Main Warehouse',
      isPrimary: false,
      type: 'Storage Node',
      cityRegion: 'Delhi NCR',
      inventory: '42,800 SKUs',
      staff: '18 members',
      status: 'Active',
      code: 'DEL-WHSE-01',
      currency: 'INR (₹)',
      taxClass: 'IGST (18%)',
      fullAddress: 'Gurugram, Delhi NCR',
      timezone: 'IST (GMT+5:30)',
      description: 'Central distribution center and high-density textile staging depot.',
      imagePath: 'Assets/central_store.jpg',
      totalSkus: 42800,
      staffMembers: 18,
      permissions: [
        'Allow internal stock replenishment',
        'Allow receiving from outside suppliers',
        'Automated bulk dispatch handling',
      ],
    ),
  ];

  late String _selectedNodeId;

  @override
  void initState() {
    super.initState();
    _selectedNodeId = _nodes.first.id;
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFFBA8A55), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E1C1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddLocationDialog() {
    final nameController = TextEditingController();
    final cityController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFAF7F2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFDFD4C5)),
        ),
        title: Text(
          'Add Operational Node',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181513),
          ),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location Name',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF474035)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Bandra Boutique',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9E958A)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDFD4C5))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDFD4C5))),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'City / Region',
                style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xFF474035)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: cityController,
                decoration: InputDecoration(
                  hintText: 'e.g. Mumbai, Maharashtra',
                  hintStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF9E958A)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDFD4C5))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDFD4C5))),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF6E665B), fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showFeedback('Location node provision request submitted.');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF382718),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Create Node',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedNode = _nodes.firstWhere(
      (n) => n.id == _selectedNodeId,
      orElse: () => _nodes.first,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DesktopContentConstraint(
        verticalPadding: 20,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Operational Nodes + 3 SYSTEM NODES pill + [+ Add Location]
              _buildHeader(),
              const SizedBox(height: 24),

              // Two-Column Layout: Left Nodes Table + Right Selected Node Detail Card
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Table Area
                  Expanded(
                    flex: 14,
                    child: _buildNodesTableCard(),
                  ),
                  const SizedBox(width: 24),

                  // Right Detail Card
                  Expanded(
                    flex: 9,
                    child: _buildNodeDetailPanel(selectedNode),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================================
  // HEADER ROW
  // ========================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Title & System Nodes Badge & Subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Operational Nodes',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF181513),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD4E3F3)),
                    ),
                    child: Text(
                      '3 SYSTEM NODES',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: const Color(0xFF2F669A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your stores, warehouses, and distribution locations.',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6E665B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),

        // [+ Add Location] Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onAddLocation ?? _showAddLocationDialog,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                  const Icon(
                    Icons.add,
                    size: 17,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Add Location',
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
        ),
      ],
    );
  }

  // ========================================================
  // LEFT: OPERATIONAL NODES TABLE
  // ========================================================
  Widget _buildNodesTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEBE2D5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A231A).withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidget = Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEBE2D5), width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: Text(
                        'Location Name',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Type',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'City / Region',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Inventory',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Staff',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Status',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),

              // Table Rows
              ...List.generate(_nodes.length, (index) {
                final node = _nodes[index];
                final isSelected = node.id == _selectedNodeId;
                final isLast = index == _nodes.length - 1;

                return InkWell(
                  onTap: () {
                    setState(() => _selectedNodeId = node.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFFFF9EE) : Colors.white,
                      border: Border(
                        bottom: isLast
                            ? BorderSide.none
                            : const BorderSide(color: Color(0xFFF1EAE0), width: 1.0),
                        left: isSelected
                            ? const BorderSide(color: Color(0xFFBA8A55), width: 3.0)
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Location Name + Icon + (Primary badge)
                        Expanded(
                          flex: 7,
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFF6EBDD)
                                      : const Color(0xFFF5F2EC),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  node.isPrimary
                                      ? Icons.storefront_outlined
                                      : (node.type.contains('Warehouse') || node.type.contains('Storage')
                                          ? Icons.home_work_outlined
                                          : Icons.store_mall_directory_outlined),
                                  size: 17,
                                  color: isSelected
                                      ? const Color(0xFFBA8A55)
                                      : const Color(0xFF7A7268),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            node.name,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: GoogleFonts.inter(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF181513),
                                            ),
                                          ),
                                        ),
                                        if (node.isPrimary) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 14,
                                            color: Color(0xFFC08A4E),
                                          ),
                                        ],
                                      ],
                                    ),
                                    if (node.isPrimary) ...[
                                      const SizedBox(height: 3),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFBF2DC),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Primary',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF9A6A2F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                          ),
                        ),

                        // Type
                        Expanded(
                          flex: 3,
                          child: Text(
                            node.type,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF5A5248),
                            ),
                          ),
                        ),

                        // City / Region
                        Expanded(
                          flex: 3,
                          child: Text(
                            node.cityRegion,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF5A5248),
                            ),
                          ),
                        ),

                        // Inventory
                        Expanded(
                          flex: 3,
                          child: Text(
                            node.inventory,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF181513),
                            ),
                          ),
                        ),

                        // Staff
                        Expanded(
                          flex: 2,
                          child: Text(
                            node.staff,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF5A5248),
                            ),
                          ),
                        ),

                        // Status Pill
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2E7D32),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      node.status,
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Right arrow chevron
                        const SizedBox(
                          width: 20,
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: Color(0xFF8E867B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );

          if (constraints.maxWidth < 620) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 620,
                child: tableWidget,
              ),
            );
          }
          return tableWidget;
        },
      ),
    );
  }

  // ========================================================
  // RIGHT: SELECTED LOCATION DETAIL CARD
  // ========================================================
  Widget _buildNodeDetailPanel(LocationNodeData node) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          // Top Row: SELECTED LOCATION pill + [✏ Edit] button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBF2DC),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SELECTED LOCATION',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: const Color(0xFF9A6A2F),
                  ),
                ),
              ),
              InkWell(
                onTap: () => _showFeedback('Editing location details for ${node.name}.'),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFDFD4C5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: Color(0xFF5C5449),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Edit',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF382718),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Description
          Text(
            node.name,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF181513),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            node.description,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF7A7268),
            ),
          ),
          const SizedBox(height: 14),

          // High-Res Location Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 16 / 8.5,
              child: Image.asset(
                node.imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFFAF7F2),
                  child: const Center(
                    child: Icon(Icons.storefront_outlined, size: 36, color: Color(0xFFBA8A55)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Key-Value Metadata List
          _buildDetailRow('Location Code', node.code, valueColor: const Color(0xFF181513)),
          const SizedBox(height: 9),
          _buildDetailRow('Core Currency', node.currency, valueColor: const Color(0xFF9A6A2F)),
          const SizedBox(height: 9),
          _buildDetailRow('Assigned Tax Class', node.taxClass, valueColor: const Color(0xFF181513)),
          const SizedBox(height: 9),
          _buildDetailRow('City / Region', node.fullAddress, valueColor: const Color(0xFF181513)),
          const SizedBox(height: 9),
          _buildDetailRow('Time Zone', node.timezone, valueColor: const Color(0xFF181513)),
          const SizedBox(height: 16),

          // Explicit Operation Permissions Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
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
                    const Icon(
                      Icons.shield_outlined,
                      size: 15,
                      color: Color(0xFFB37B42),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'EXPLICIT OPERATION PERMISSIONS',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: const Color(0xFF9A6A2F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...node.permissions.map((perm) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            perm,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF382718),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Metric Summary 3-Column Boxes
          Row(
            children: [
              // Total SKUs
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEBE2D5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 14,
                            color: Color(0xFF8C7F72),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              node.totalSkus.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF181513),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total SKUs',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF8C8478),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Staff Members
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEBE2D5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline_rounded,
                            size: 14,
                            color: Color(0xFF8C7F72),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${node.staffMembers}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF181513),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Staff Members',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF8C8478),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Node Status
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8F5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEBE2D5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            node.status,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Node Status',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: const Color(0xFF8C8478),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // [⚙ Edit Location Settings] Full-width Button
          InkWell(
            onTap: () => _showFeedback('Opening settings configuration for ${node.name}...'),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFDFD4C5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.settings_outlined,
                    size: 15,
                    color: Color(0xFF1E1C1A),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Edit Location Settings',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1C1A),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // [⏻ Deactivate Node] Full-width Danger Button
          InkWell(
            onTap: () {
              if (node.isPrimary) {
                _showFeedback('Primary node cannot be deactivated while operational.');
              } else {
                _showFeedback('${node.name} node decommission queued.');
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFDE4A4A),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDE4A4A).withOpacity(0.20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.power_settings_new_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Deactivate Node',
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
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF7A7268),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: valueColor ?? const Color(0xFF181513),
          ),
        ),
      ],
    );
  }
}
