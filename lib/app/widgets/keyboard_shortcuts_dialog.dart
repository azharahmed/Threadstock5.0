// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KeyboardShortcutsDialog extends StatefulWidget {
  const KeyboardShortcutsDialog({
    super.key,
    this.initialEnabled = true,
    this.onToggleEnabled,
  });

  final bool initialEnabled;
  final ValueChanged<bool>? onToggleEnabled;

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (ctx) => const KeyboardShortcutsDialog(),
    );
  }

  @override
  State<KeyboardShortcutsDialog> createState() => _KeyboardShortcutsDialogState();
}

class _KeyboardShortcutsDialogState extends State<KeyboardShortcutsDialog> {
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 520,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8DFD3), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x28000000),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.grid_view_rounded,
                          size: 20,
                          color: Color(0xFF161412),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Keyboard Shortcuts',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF161412),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: Color(0xFF6B6358),
                      ),
                      splashRadius: 18,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFEDE5DA), height: 1),

              // 2. Body List
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1: NAVIGATION
                      _buildSectionHeader('NAVIGATION'),
                      const SizedBox(height: 10),
                      _buildShortcutRow(
                        label: 'Command Palette',
                        keys: ['⌘', 'K'],
                      ),
                      _buildShortcutRow(
                        label: 'Switch Workspace Sections',
                        keys: ['⌘', '1-9'],
                      ),
                      _buildShortcutRow(
                        label: 'Search',
                        keys: ['⌘', '/'],
                      ),
                      const SizedBox(height: 18),

                      // Section 2: ACTIONS
                      _buildSectionHeader('ACTIONS'),
                      const SizedBox(height: 10),
                      _buildShortcutRow(
                        label: 'New Item (Invoice, Transfer, etc)',
                        keys: ['⌘', 'N'],
                      ),
                      _buildShortcutRow(
                        label: 'Save current draft / document',
                        keys: ['⌘', 'S'],
                      ),
                      _buildShortcutRow(
                        label: 'Print Document or Barcodes',
                        keys: ['⌘', '⇧', 'P'],
                      ),
                      const SizedBox(height: 18),

                      // Section 3: TABLES & NAVIGATION
                      _buildSectionHeader('TABLES & NAVIGATION'),
                      const SizedBox(height: 10),
                      _buildShortcutRow(
                        label: 'Navigate Rows',
                        keys: ['↑', '↓'],
                      ),
                      _buildShortcutRow(
                        label: 'Select Multiple Items',
                        keys: ['Space'],
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(color: Color(0xFFEDE5DA), height: 1),

              // 3. Footer Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enable global keyboard shortcuts',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF5E574E),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _enabled = !_enabled);
                        widget.onToggleEnabled?.call(_enabled);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 44,
                        height: 24,
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: _enabled
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFD8CFBE),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeInOut,
                          alignment: _enabled
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            width: 19,
                            height: 19,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: const Color(0xFF8C8478),
      ),
    );
  }

  Widget _buildShortcutRow({
    required String label,
    required List<String> keys,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF2C2721),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: keys.map((k) {
              return Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F2EB),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFFDCCFBD)),
                ),
                child: Text(
                  k,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C2721),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
