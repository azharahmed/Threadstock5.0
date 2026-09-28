import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// An item for the ThreadStock Dropdown menu.
class ThreadStockDropdownItem<T> {
  final T value;
  final String title;
  final String? subtitle;
  final IconData? icon;

  const ThreadStockDropdownItem({
    required this.value,
    required this.title,
    this.subtitle,
    this.icon,
  });
}

/// An optional footer action item at the bottom of the dropdown menu.
class ThreadStockDropdownAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const ThreadStockDropdownAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

/// A ThreadStock-styled dropdown menu adhering to ThreadStock's visual design.
///
/// Features:
/// - Warm parchment pill trigger with custom prefix and arrow
/// - Ivory floating card overlay with rounded corners and soft shadow
/// - Rich item rows with icon badges, bold title, muted subtitle, and checkmark
/// - Optional divider and footer action (e.g. "Manage locations")
class ThreadStockDropdown<T> extends StatefulWidget {
  final T value;
  final List<ThreadStockDropdownItem<T>> items;
  final ValueChanged<T> onChanged;
  final IconData? prefixIcon;
  final String Function(ThreadStockDropdownItem<T> item)? triggerLabel;
  final ThreadStockDropdownAction? footerAction;
  final double menuWidth;
  final bool isBorderless;

  const ThreadStockDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.prefixIcon,
    this.triggerLabel,
    this.footerAction,
    this.menuWidth = 264,
    this.isBorderless = false,
  });

  @override
  State<ThreadStockDropdown<T>> createState() => _ThreadStockDropdownState<T>();
}

class _ThreadStockDropdownState<T> extends State<ThreadStockDropdown<T>> {
  final MenuController _controller = MenuController();

  ThreadStockDropdownItem<T>? get _selectedItem {
    for (final item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return widget.items.isNotEmpty ? widget.items.first : null;
  }

  String get _displayTriggerLabel {
    final item = _selectedItem;
    if (item == null) return '';
    if (widget.triggerLabel != null) {
      return widget.triggerLabel!(item);
    }
    if (item.subtitle != null && item.subtitle!.isNotEmpty) {
      return '${item.title} (${item.subtitle})';
    }
    return item.title;
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _controller,
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Color(0xFFFAF7F2)),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(12),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: 0.12),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE5DACD), width: 1.0),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
        maximumSize: WidgetStatePropertyAll(Size(widget.menuWidth, 600)),
      ),
      builder: (context, controller, child) {
        final isOpen = controller.isOpen;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 36,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isBorderless ? 4 : 10,
              ),
              decoration: widget.isBorderless
                  ? BoxDecoration(
                      color: isOpen
                          ? const Color(0xFFBA8A55).withValues(alpha: 0.08)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    )
                  : BoxDecoration(
                      color: const Color(0xFFF3EDE3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isOpen
                            ? const Color(0xFFBA8A55)
                            : const Color(0xFFDFD4C5),
                        width: 1.0,
                      ),
                    ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.prefixIcon != null) ...[
                    Icon(
                      widget.prefixIcon,
                      size: 16,
                      color: const Color(0xFF8A6034),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      _displayTriggerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: widget.isBorderless ? 14.5 : 13,
                        fontWeight: widget.isBorderless
                            ? FontWeight.w400
                            : FontWeight.w500,
                        color: widget.isBorderless
                            ? const Color(0xFF38332D)
                            : const Color(0xFF1E1C1A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: widget.isBorderless
                        ? const Color(0xFF5E574E)
                        : const Color(0xFF1E1C1A),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      menuChildren: [
        SizedBox(
          width: widget.menuWidth - 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...widget.items.map((item) {
                final isSelected = item.value == widget.value;
                return _buildItemRow(item, isSelected);
              }),
              if (widget.footerAction != null) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Divider(
                    color: Color(0xFFE5DACD),
                    height: 1,
                    thickness: 1,
                  ),
                ),
                _buildFooterRow(widget.footerAction!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemRow(ThreadStockDropdownItem<T> item, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onChanged(item.value);
          _controller.close();
        },
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFFBA8A55).withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFE6D9) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (item.icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFE5D5C1)
                        : const Color(0xFFEFE6D8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    item.icon,
                    size: 17,
                    color: const Color(0xFF785125),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: const Color(0xFF1E1C1A),
                      ),
                    ),
                    if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF7A7268),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: Color(0xFF785125),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterRow(ThreadStockDropdownAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _controller.close();
          action.onTap();
        },
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFFBA8A55).withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(action.icon, size: 17, color: const Color(0xFF5E574E)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  action.label,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF3B362F),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: Color(0xFF8E867B),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
