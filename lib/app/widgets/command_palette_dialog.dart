// ignore_for_file: deprecated_member_use
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/inventory/data/product_repository.dart';

enum CommandItemType { aiPrompt, navigation, product }

class CommandPaletteItem {
  final String id;
  final String section;
  final String title;
  final String? subtitle;
  final String? shortcut;
  final String? badge;
  final IconData? icon;
  final String? imageAsset;
  final CommandItemType type;
  final VoidCallback? onSelect;

  const CommandPaletteItem({
    required this.id,
    required this.section,
    required this.title,
    this.subtitle,
    this.shortcut,
    this.badge,
    this.icon,
    this.imageAsset,
    required this.type,
    this.onSelect,
  });
}

class CommandPaletteDialog extends StatefulWidget {
  const CommandPaletteDialog({
    super.key,
    this.initialQuery = '',
    this.onNavigateToIndex,
    this.onNavigateToSalesMode,
    this.onNavigateToInventoryMode,
    this.onNavigateToSettingsSection,
  });

  final String initialQuery;
  final ValueChanged<int>? onNavigateToIndex;
  final ValueChanged<String>? onNavigateToSalesMode;
  final ValueChanged<String>? onNavigateToInventoryMode;
  final ValueChanged<String>? onNavigateToSettingsSection;

  static Future<void> show(
    BuildContext context, {
    String initialQuery = '',
    ValueChanged<int>? onNavigateToIndex,
    ValueChanged<String>? onNavigateToSalesMode,
    ValueChanged<String>? onNavigateToInventoryMode,
    ValueChanged<String>? onNavigateToSettingsSection,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.40),
      builder: (ctx) => CommandPaletteDialog(
        initialQuery: initialQuery,
        onNavigateToIndex: onNavigateToIndex,
        onNavigateToSalesMode: onNavigateToSalesMode,
        onNavigateToInventoryMode: onNavigateToInventoryMode,
        onNavigateToSettingsSection: onNavigateToSettingsSection,
      ),
    );
  }

  @override
  State<CommandPaletteDialog> createState() => _CommandPaletteDialogState();
}

class _CommandPaletteDialogState extends State<CommandPaletteDialog> {
  late final TextEditingController _searchController;
  late final FocusNode _inputFocusNode;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _inputFocusNode = FocusNode();

    if (_searchController.text.isNotEmpty) {
      _searchController.selection = TextSelection.fromPosition(
        TextPosition(offset: _searchController.text.length),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inputFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  List<CommandPaletteItem> _getAllItems() {
    final isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
    final mod = isMacOS ? '⌘' : 'Ctrl+';

    final items = <CommandPaletteItem>[
      // 1. ASK THREADSTOCK AI
      CommandPaletteItem(
        id: 'ai_inventory_query',
        section: 'ASK THREADSTOCK AI',
        title: 'Ask about your inventory',
        type: CommandItemType.aiPrompt,
        badge: 'AI Prompt',
        onSelect: () {
          Navigator.of(context).pop();
          widget.onNavigateToIndex?.call(6); // AI Studio / Insights
          _showSnack('Opening ThreadStock AI Inventory Assistant...');
        },
      ),
      CommandPaletteItem(
        id: 'ai_find_product',
        section: 'ASK THREADSTOCK AI',
        title: 'Find a product',
        type: CommandItemType.aiPrompt,
        badge: 'AI Prompt',
        onSelect: () {
          Navigator.of(context).pop();
          widget.onNavigateToIndex?.call(1); // Inventory
          _showSnack('Searching inventory products...');
        },
      ),
      CommandPaletteItem(
        id: 'ai_search_suppliers',
        section: 'ASK THREADSTOCK AI',
        title: 'Search suppliers',
        type: CommandItemType.aiPrompt,
        badge: 'AI Prompt',
        onSelect: () {
          Navigator.of(context).pop();
          widget.onNavigateToIndex?.call(5); // Suppliers
          _showSnack('Searching suppliers...');
        },
      ),

      // 2. QUICK NAVIGATION
      CommandPaletteItem(
        id: 'nav_create_sale',
        section: 'QUICK NAVIGATION',
        title: 'Create New Sale',
        shortcut: '${mod}N',
        icon: Icons.add_rounded,
        type: CommandItemType.navigation,
        onSelect: () {
          Navigator.of(context).pop();
          widget.onNavigateToIndex?.call(2); // Sales
          widget.onNavigateToSalesMode?.call('newSale');
          _showSnack('Navigating to Create New Sale...');
        },
      ),
      CommandPaletteItem(
        id: 'nav_new_product',
        section: 'QUICK NAVIGATION',
        title: 'Add New Inventory Product',
        shortcut: '${mod}I',
        icon: Icons.inventory_2_outlined,
        type: CommandItemType.navigation,
        onSelect: () {
          Navigator.of(context).pop();
          widget.onNavigateToIndex?.call(1); // Inventory
          widget.onNavigateToInventoryMode?.call('Create New Product');
          _showSnack('Navigating to Add New Product...');
        },
      ),
      CommandPaletteItem(
        id: 'nav_stock_transfer',
        section: 'QUICK NAVIGATION',
        title: 'Initiate Stock Transfer',
        shortcut: '${mod}T',
        icon: Icons.local_shipping_outlined,
        type: CommandItemType.navigation,
        onSelect: () {
          Navigator.of(context).pop();
          widget.onNavigateToIndex?.call(4); // Transfers
          _showSnack('Navigating to Initiate Stock Transfer...');
        },
      ),
      CommandPaletteItem(
        id: 'nav_return_exchange',
        section: 'QUICK NAVIGATION',
        title: 'Process Return / Exchange',
        shortcut: '${mod}R',
        icon: Icons.sync_rounded,
        type: CommandItemType.navigation,
        onSelect: () {
          Navigator.of(context).pop();
          widget.onNavigateToIndex?.call(2); // Sales
          widget.onNavigateToSalesMode?.call('returnExchange');
          _showSnack('Opening Return / Exchange Processor...');
        },
      ),
    ];

    // 3. RECENT PRODUCTS (Only real products if any exist; empty for fresh account)
    final fallbackProducts = ProductRepository.localFallbackProducts;
    for (final p in fallbackProducts.values.take(3)) {
      items.add(
        CommandPaletteItem(
          id: 'recent_${p.id}',
          section: 'RECENT PRODUCTS',
          title: p.name,
          subtitle: p.description ?? p.status,
          badge: 'Inventory',
          type: CommandItemType.product,
          onSelect: () {
            Navigator.of(context).pop();
            widget.onNavigateToIndex?.call(1);
            widget.onNavigateToInventoryMode?.call('Product details');
            _showSnack('Opening ${p.name} details...');
          },
        ),
      );
    }

    return items;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFF59E0B), size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF181513),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(milliseconds: 2500),
      ),
    );
  }

  void _handleKeyDown(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final items = _getFilteredItems();
    if (items.isEmpty) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedIndex = (_selectedIndex + 1) % items.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedIndex = (_selectedIndex - 1 + items.length) % items.length;
      });
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedIndex >= 0 && _selectedIndex < items.length) {
        items[_selectedIndex].onSelect?.call();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
    }
  }

  List<CommandPaletteItem> _getFilteredItems() {
    final all = _getAllItems();
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return all;

    final matches = all.where((item) {
      final titleMatch = item.title.toLowerCase().contains(query);
      final subMatch = (item.subtitle ?? '').toLowerCase().contains(query);
      final secMatch = item.section.toLowerCase().contains(query);
      return titleMatch || subMatch || secMatch;
    }).toList();

    return matches.isNotEmpty ? matches : all;
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems();

    // Group items by section
    final Map<String, List<CommandPaletteItem>> grouped = {};
    for (final item in filteredItems) {
      grouped.putIfAbsent(item.section, () => []).add(item);
    }

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyDown,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 620,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x28000000),
                  blurRadius: 36,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Search Header
                  _buildSearchInputHeader(),

                  const Divider(height: 1, color: Color(0xFFF1F5F9)),

                  // 2. Body List
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final entry in grouped.entries) ...[
                          _buildSectionBlock(
                            sectionName: entry.key,
                            items: entry.value,
                            allFilteredItems: filteredItems,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),

                  // 3. Footer Bar
                  _buildFooterBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 1. Search Input Header
  Widget _buildSearchInputHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 22, color: Color(0xFF181513)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _inputFocusNode,
              onChanged: (_) {
                setState(() {
                  _selectedIndex = 0;
                });
              },
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF181513),
              ),
              decoration: InputDecoration(
                hintText: 'Search ThreadStock or ask AI...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'ESC',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Section Block
  Widget _buildSectionBlock({
    required String sectionName,
    required List<CommandPaletteItem> items,
    required List<CommandPaletteItem> allFilteredItems,
  }) {
    final isAiSection = sectionName == 'ASK THREADSTOCK AI';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            children: [
              if (isAiSection) ...[
                const Icon(
                  Icons.auto_awesome,
                  size: 12,
                  color: Color(0xFFD97706),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                sectionName,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isAiSection
                      ? const Color(0xFFB45309)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        for (final item in items) ...[
          _buildItemRow(
            item: item,
            isSelected: allFilteredItems.indexOf(item) == _selectedIndex,
            onTap: () {
              setState(() {
                _selectedIndex = allFilteredItems.indexOf(item);
              });
              item.onSelect?.call();
            },
          ),
          const SizedBox(height: 2),
        ],
      ],
    );
  }

  Widget _buildItemRow({
    required CommandPaletteItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    if (item.type == CommandItemType.aiPrompt) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFFFBEB)
                : const Color(0xFFFFFDF8),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFFDE68A) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 14,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                    color: const Color(0xFF181513),
                  ),
                ),
              ),
              if (item.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.badge!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (item.type == CommandItemType.product) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF8FAFC) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  item.imageAsset ?? '',
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Container(
                    width: 38,
                    height: 38,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(
                      Icons.checkroom_rounded,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (item.subtitle != null)
                      Text(
                        item.subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                  ],
                ),
              ),
              if (item.badge != null)
                Text(
                  item.badge!,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF64748B),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Default Navigation Item
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF8FAFC) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (item.icon != null)
              Icon(item.icon, size: 17, color: const Color(0xFF181513)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF181513),
                ),
              ),
            ),
            if (item.shortcut != null)
              Text(
                item.shortcut!,
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 3. Footer Bar
  Widget _buildFooterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                size: 12,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 1),
              const Icon(
                Icons.arrow_downward_rounded,
                size: 12,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                'to navigate',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.keyboard_return_rounded,
                size: 12,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                'to select',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Text(
            'ThreadStock OS v2.4',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
