import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchShortcutCoachmark extends StatefulWidget {
  const SearchShortcutCoachmark({
    super.key,
    required this.onDismiss,
    this.autoDismissDuration = const Duration(milliseconds: 4500),
  });

  final VoidCallback onDismiss;
  final Duration autoDismissDuration;

  @override
  State<SearchShortcutCoachmark> createState() =>
      _SearchShortcutCoachmarkState();
}

class _SearchShortcutCoachmarkState extends State<SearchShortcutCoachmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _autoDismissTimer;

  bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.15), end: Offset.zero).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward();

    _autoDismissTimer = Timer(widget.autoDismissDuration, () {
      _dismiss();
    });
  }

  void _dismiss() {
    if (!mounted) return;
    _autoDismissTimer?.cancel();
    _animController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modKey = _isMacOS ? '⌘' : 'Ctrl';
    const keyLetter = 'K';

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _dismiss,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 320,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFDFBF7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDFD4C5), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x18181513),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Icon + Title + Close Button
                  Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 16,
                        color: Color(0xFFBA8A55),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Search',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181513),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: _dismiss,
                        borderRadius: BorderRadius.circular(10),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Color(0xFF9E958A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Body: Press [Chip] + [Chip] to search ThreadStock or ask AI.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Press  ',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: const Color(0xFF5E574E),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      _buildKeyChip(modKey),
                      const SizedBox(width: 4),
                      Text(
                        '+',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF8C8478),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _buildKeyChip(keyLetter),
                      Expanded(
                        child: Text(
                          '  to search',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF5E574E),
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ThreadStock or ask AI.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: const Color(0xFF5E574E),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: const Color(0xFFD4C8B8), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF181513),
        ),
      ),
    );
  }
}
