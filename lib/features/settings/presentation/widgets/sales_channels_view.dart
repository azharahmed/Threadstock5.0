// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/responsive/desktop_layout.dart';
import 'instore_pos_channel_view.dart';

enum ChannelStatus { active, pending, disabled }

class SalesChannelItem {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final ChannelStatus status;
  final String? lastSync;
  final bool hasWarning;
  final String? warningMessage;

  const SalesChannelItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.status,
    this.lastSync,
    this.hasWarning = false,
    this.warningMessage,
  });

  SalesChannelItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    IconData? icon,
    ChannelStatus? status,
    String? lastSync,
    bool? hasWarning,
    String? warningMessage,
  }) {
    return SalesChannelItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      lastSync: lastSync ?? this.lastSync,
      hasWarning: hasWarning ?? this.hasWarning,
      warningMessage: warningMessage ?? this.warningMessage,
    );
  }
}

class SalesChannelsView extends StatefulWidget {
  final VoidCallback? onBackToSettings;
  final void Function(String title, String subtitle)? onSubNavChanged;

  const SalesChannelsView({
    super.key,
    this.onBackToSettings,
    this.onSubNavChanged,
  });

  @override
  State<SalesChannelsView> createState() => _SalesChannelsViewState();
}

class _SalesChannelsViewState extends State<SalesChannelsView> {
  late List<SalesChannelItem> _channels;
  String? _selectedChannelDetail;

  @override
  void initState() {
    super.initState();
    _channels = [
      const SalesChannelItem(
        id: 'instore_pos',
        title: 'In-Store POS',
        subtitle: 'Central Delhi, Mumbai Phoenix',
        description:
            'Dual location terminal setup running Atelier OS POS engine.',
        icon: Icons.storefront_outlined,
        status: ChannelStatus.active,
        lastSync: '3m ago',
      ),
      const SalesChannelItem(
        id: 'online_store',
        title: 'Online Store',
        subtitle: 'Shopify Connect',
        description:
            'Live e-commerce inventory sync with Shopify store profile.',
        icon: Icons.shopping_cart_outlined,
        status: ChannelStatus.active,
        lastSync: '12m ago',
      ),
      const SalesChannelItem(
        id: 'whatsapp_commerce',
        title: 'WhatsApp Commerce',
        subtitle: 'Direct Integration',
        description:
            'ThreadStock automation catalog with chat order entry.',
        icon: Icons.chat_bubble_outline_rounded,
        status: ChannelStatus.active,
        lastSync: '1h ago',
      ),
      const SalesChannelItem(
        id: 'instagram_shop',
        title: 'Instagram Shop',
        subtitle: 'Unassigned',
        description:
            'Connect your Instagram catalogs to capture social discovery checkouts.',
        icon: Icons.camera_alt_outlined,
        status: ChannelStatus.pending,
        hasWarning: true,
        warningMessage: 'Configuration missing',
      ),
    ];
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

  void _showAddChannelDialog() {
    final nameController = TextEditingController();
    String selectedType = 'Shopify';
    String selectedLocation = 'All Nodes (Global)';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: 480,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Connect Sales Channel',
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF181513),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              size: 20, color: Color(0xFF7A7268)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Link a physical counter or online catalog for automatic stock sync and order intake.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: const Color(0xFF7A7268),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Channel Type Dropdown
                    Text('Channel Type',
                        style: GoogleFonts.inter(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2D8CC)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Shopify', child: Text('Shopify Online Store')),
                        DropdownMenuItem(
                            value: 'WooCommerce', child: Text('WooCommerce Store')),
                        DropdownMenuItem(
                            value: 'In-Store POS',
                            child: Text('Physical POS Terminal Node')),
                        DropdownMenuItem(
                            value: 'WhatsApp',
                            child: Text('WhatsApp Conversational Commerce')),
                        DropdownMenuItem(
                            value: 'Instagram',
                            child: Text('Instagram Social Discovery Catalog')),
                        DropdownMenuItem(
                            value: 'Amazon', child: Text('Amazon Marketplace')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDlgState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Channel Name
                    Text('Display Name',
                        style: GoogleFonts.inter(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      style: GoogleFonts.inter(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Bandra Flagship POS or Shopify US',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2D8CC)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fulfillment Location
                    Text('Fulfillment Location',
                        style: GoogleFonts.inter(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedLocation,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE2D8CC)),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'All Nodes (Global)',
                            child: Text('All Nodes (Global Inventory)')),
                        DropdownMenuItem(
                            value: 'Central Warehouse (Zone A)',
                            child: Text('Central Warehouse (Zone A)')),
                        DropdownMenuItem(
                            value: 'Delhi Flagship Boutique',
                            child: Text('Delhi Flagship Boutique')),
                        DropdownMenuItem(
                            value: 'Mumbai Phoenix Node',
                            child: Text('Mumbai Phoenix Node')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDlgState(() => selectedLocation = val);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD8CEC1)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Cancel',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF1E1C1A))),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            final name = nameController.text.trim().isEmpty
                                ? selectedType
                                : nameController.text.trim();
                            setState(() {
                              _channels.add(
                                SalesChannelItem(
                                  id: 'channel_${DateTime.now().millisecondsSinceEpoch}',
                                  title: name,
                                  subtitle: selectedLocation,
                                  description:
                                      'Direct integrated sales channel routing transactions to ThreadStock inventory.',
                                  icon: selectedType.contains('POS')
                                      ? Icons.storefront_outlined
                                      : (selectedType.contains('Shopify') ||
                                              selectedType.contains('Woo')
                                          ? Icons.shopping_cart_outlined
                                          : (selectedType.contains('WhatsApp')
                                              ? Icons.chat_bubble_outline_rounded
                                              : (selectedType.contains('Instagram')
                                                  ? Icons.camera_alt_outlined
                                                  : Icons.language_rounded))),
                                  status: ChannelStatus.active,
                                  lastSync: 'Just now',
                                ),
                              );
                            });
                            Navigator.pop(ctx);
                            _showFeedback('Channel "$name" connected successfully');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E1C1A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text('Connect Channel',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showConfigureDialog(SalesChannelItem channel) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Configure ${channel.title}',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF181513),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: Color(0xFF7A7268)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage automated product publishing, sync cadence, and tax rules for this channel.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: const Color(0xFF7A7268),
                  ),
                ),
                const SizedBox(height: 18),

                // Channel Info Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF7F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEBE2D5)),
                  ),
                  child: Row(
                    children: [
                      Icon(channel.icon, color: const Color(0xFF7A481B), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channel.title,
                              style: GoogleFonts.inter(
                                  fontSize: 13.5, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              channel.subtitle,
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: const Color(0xFF7E766B)),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: channel.status == ChannelStatus.active
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          channel.status == ChannelStatus.active
                              ? 'Active'
                              : 'Pending',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: channel.status == ChannelStatus.active
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFB86B1D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Setting Switch 1
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Real-Time Stock Decrement',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(
                              'Instantly deduct available units across other channels on order creation.',
                              style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF7E766B))),
                        ],
                      ),
                    ),
                    const Icon(Icons.toggle_on_rounded,
                        color: Color(0xFF5C3E21), size: 36),
                  ],
                ),
                const SizedBox(height: 14),

                // Setting Switch 2
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Auto-Publish New Collections',
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          Text(
                              'Automatically push newly launched fabrics and garments to this catalog.',
                              style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: const Color(0xFF7E766B))),
                        ],
                      ),
                    ),
                    const Icon(Icons.toggle_on_rounded,
                        color: Color(0xFF5C3E21), size: 36),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD8CEC1)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Close',
                          style: GoogleFonts.inter(
                              fontSize: 13, color: const Color(0xFF1E1C1A))),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          final idx = _channels.indexWhere((c) => c.id == channel.id);
                          if (idx != -1) {
                            _channels[idx] = channel.copyWith(
                              status: ChannelStatus.active,
                              hasWarning: false,
                              lastSync: 'Just now',
                            );
                          }
                        });
                        Navigator.pop(ctx);
                        _showFeedback(
                            '${channel.title} configuration updated and synced.');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1C1A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Save & Sync',
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleConfigure(SalesChannelItem channel) {
    if (channel.id == 'instore_pos') {
      setState(() => _selectedChannelDetail = 'instore_pos');
      widget.onSubNavChanged?.call(
        'Settings > Sales Channels > In-Store POS',
        '',
      );
    } else {
      _showConfigureDialog(channel);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedChannelDetail == 'instore_pos') {
      return InStorePosChannelView(
        onBackToChannels: () {
          setState(() => _selectedChannelDetail = null);
          widget.onSubNavChanged?.call(
            'Settings > Sales Channels',
            'Connect, manage and configure active physical or digital checkout points of sale.',
          );
        },
      );
    }

    return Container(
      color: const Color(0xFFFAF7F2),
      child: SingleChildScrollView(
        child: DesktopContentConstraint(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Title + Subtitle + Add Channel Button
                _buildHeader(),
                const SizedBox(height: 24),

                // Channels Grid (2 Columns on Desktop)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 860;
                    if (isWide) {
                      final itemWidth = (constraints.maxWidth - 20) / 2;
                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          for (final channel in _channels)
                            SizedBox(
                              width: itemWidth,
                              child: _buildChannelCard(channel),
                            ),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          for (final channel in _channels) ...[
                            _buildChannelCard(channel),
                            const SizedBox(height: 18),
                          ],
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
  // HEADER ROW: Title + Subtitle + Add Channel Button
  // ========================================================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Description
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sales Channels',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: const Color(0xFF181513),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect, manage and configure active physical or digital checkout points of sale.',
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

        // Add Channel CTA Button
        ElevatedButton.icon(
          onPressed: _showAddChannelDialog,
          icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
          label: Text(
            'Add Channel',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E1C1A),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // ========================================================
  // CHANNEL CARD: Icon + Title + Status + Description + Footer
  // ========================================================
  Widget _buildChannelCard(SalesChannelItem channel) {
    return InkWell(
      onTap: () => _handleConfigure(channel),
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Circular Icon + Title/Subtitle + Status Pill + More Menu
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAF2E6),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: const Color(0xFFE8DDD0), width: 1.2),
                        ),
                        child: Icon(
                          channel.icon,
                          color: const Color(0xFF7A481B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channel.title,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF181513),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              channel.subtitle,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF7E766B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Status Pill
                      _buildStatusPill(channel.status),
                      const SizedBox(width: 6),

                      // More Menu
                      PopupMenuButton<String>(
                        onSelected: (val) {
                          if (val == 'configure') {
                            _handleConfigure(channel);
                          } else if (val == 'sync') {
                            _showFeedback('Triggered sync for ${channel.title}');
                          } else if (val == 'disconnect') {
                            setState(() {
                              _channels.removeWhere((c) => c.id == channel.id);
                            });
                            _showFeedback('Disconnected ${channel.title}');
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                              value: 'configure', child: Text('Configure Settings')),
                          const PopupMenuItem(
                              value: 'sync', child: Text('Force Sync Now')),
                          const PopupMenuItem(
                              value: 'disconnect',
                              child: Text('Disconnect Channel',
                                  style: TextStyle(color: Colors.red))),
                        ],
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.more_horiz_rounded,
                              size: 18, color: Color(0xFF7E766B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    channel.description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6E665B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF0E8DD)),

            // Bottom Footer: Sync / Status Info + Configure CTA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Warning or Sync Info
                  if (channel.hasWarning)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: Color(0xFFB86B1D),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          channel.warningMessage ?? 'Configuration missing',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFFB86B1D),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.sync_rounded,
                          size: 15,
                          color: Color(0xFF7E766B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Last sync ${channel.lastSync ?? 'recently'}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF7E766B),
                          ),
                        ),
                      ],
                    ),

                  // Right: Configure Button
                  OutlinedButton(
                    onPressed: () => _handleConfigure(channel),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2D8CC)),
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Configure',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF181513),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: Color(0xFF181513),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPill(ChannelStatus status) {
    final isActive = status == ChannelStatus.active;
    final dotColor =
        isActive ? const Color(0xFF2E7D32) : const Color(0xFFB86B1D);
    final bgColor =
        isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final label = isActive ? 'Active' : 'Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: dotColor,
            ),
          ),
        ],
      ),
    );
  }
}
