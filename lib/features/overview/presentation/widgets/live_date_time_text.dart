import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadstock/features/overview/presentation/helpers/date_time_greeting_helper.dart';

/// A small, elegant, auto-refreshing live date/time text widget.
///
/// Features:
/// - Refreshes automatically every 15 seconds so minute changes reflect promptly
/// - Only rebuilds itself, avoiding unnecessary full-page rebuilds
/// - Resolves location timezone if provided, with safe fallback to local device time
/// - Luxury ThreadStock styling (warm slate/stone text with subtle champagne gold accent)
class LiveDateTimeText extends StatefulWidget {
  final Duration? locationOffset;
  final String? locationTimezone;
  final TextStyle? style;
  final bool showIcon;
  final Color? iconColor;
  final double iconSize;
  final bool shortFormat;
  final DateTime? customNow;

  const LiveDateTimeText({
    super.key,
    this.locationOffset,
    this.locationTimezone,
    this.style,
    this.showIcon = true,
    this.iconColor,
    this.iconSize = 13.0,
    this.shortFormat = false,
    this.customNow,
  });

  @override
  State<LiveDateTimeText> createState() => _LiveDateTimeTextState();
}

class _LiveDateTimeTextState extends State<LiveDateTimeText> {
  Timer? _refreshTimer;
  late String _formattedText;

  @override
  void initState() {
    super.initState();
    _updateFormattedText();
    // Only start timer if not using a fixed test time
    if (widget.customNow == null) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) {
          final newText = _computeCurrentFormattedText();
          if (newText != _formattedText) {
            setState(() {
              _formattedText = newText;
            });
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant LiveDateTimeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationOffset != widget.locationOffset ||
        oldWidget.locationTimezone != widget.locationTimezone ||
        oldWidget.customNow != widget.customNow ||
        oldWidget.shortFormat != widget.shortFormat) {
      _updateFormattedText();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _computeCurrentFormattedText() {
    final now = widget.customNow ??
        DateTimeGreetingHelper.nowInTimezone(
          locationOffset: widget.locationOffset,
          locationTimezone: widget.locationTimezone,
        );
    return widget.shortFormat
        ? DateTimeGreetingHelper.formatDateTimeShort(now)
        : DateTimeGreetingHelper.formatDateTime(now);
  }

  void _updateFormattedText() {
    _formattedText = _computeCurrentFormattedText();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = widget.style ??
        GoogleFonts.inter(
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF78716C), // Warm slate/stone
          letterSpacing: 0.1,
        );

    final iconColor = widget.iconColor ?? const Color(0xFFC5A880); // Subtle soft gold

    if (!widget.showIcon) {
      return Text(
        _formattedText,
        style: textStyle,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.access_time_rounded,
          size: widget.iconSize,
          color: iconColor,
        ),
        const SizedBox(width: 5.5),
        Text(
          _formattedText,
          style: textStyle,
        ),
      ],
    );
  }
}
