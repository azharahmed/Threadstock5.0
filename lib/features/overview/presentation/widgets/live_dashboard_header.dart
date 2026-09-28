import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:threadstock/features/overview/presentation/helpers/date_time_greeting_helper.dart';
import 'package:threadstock/features/overview/presentation/widgets/live_date_time_text.dart';

/// Luxury ThreadStock live dashboard header.
///
/// Features:
/// 1. Time-aware greeting:
///    - 5:00 AM – 11:59 AM → Good morning
///    - 12:00 PM – 4:59 PM → Good afternoon
///    - 5:00 PM – 8:59 PM → Good evening
///    - 9:00 PM – 4:59 AM → Good night
/// 2. Live visible date and time:
///    - e.g. "Sunday, 28 Sep 2026 • 10:55 PM"
/// 3. Informative subtitle / operational status
/// 4. Auto-refresh on boundary change without full-page rebuilds
/// 5. Timezone support with fallback to local device time
class LiveDashboardHeader extends StatefulWidget {
  final String? userName;
  final String? businessName;
  final String? locationName;
  final Duration? locationOffset;
  final String? locationTimezone;
  final bool isFreshMode;
  final String? customSubtitle;
  final DateTime? customNow;

  const LiveDashboardHeader({
    super.key,
    this.userName,
    this.businessName,
    this.locationName,
    this.locationOffset,
    this.locationTimezone,
    this.isFreshMode = false,
    this.customSubtitle,
    this.customNow,
  });

  @override
  State<LiveDashboardHeader> createState() => _LiveDashboardHeaderState();
}

class _LiveDashboardHeaderState extends State<LiveDashboardHeader> {
  Timer? _ticker;
  late String _greetingTitle;

  @override
  void initState() {
    super.initState();
    _updateGreeting();
    if (widget.customNow == null) {
      // Check greeting boundary periodically (every 15 seconds)
      _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) {
          final newGreeting = _computeGreeting();
          if (newGreeting != _greetingTitle) {
            setState(() {
              _greetingTitle = newGreeting;
            });
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant LiveDashboardHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userName != widget.userName ||
        oldWidget.locationOffset != widget.locationOffset ||
        oldWidget.locationTimezone != widget.locationTimezone ||
        oldWidget.customNow != widget.customNow) {
      _updateGreeting();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _computeGreeting() {
    final now = widget.customNow ??
        DateTimeGreetingHelper.nowInTimezone(
          locationOffset: widget.locationOffset,
          locationTimezone: widget.locationTimezone,
        );
    return DateTimeGreetingHelper.formatGreeting(
      userName: widget.userName,
      dateTime: now,
      includeWave: true,
    );
  }

  void _updateGreeting() {
    _greetingTitle = _computeGreeting();
  }

  @override
  Widget build(BuildContext context) {
    final cleanBiz = widget.businessName?.trim();
    final bizDisplay = (cleanBiz != null && cleanBiz.isNotEmpty) ? cleanBiz : 'LaunchGrid';

    final cleanLoc = widget.locationName?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Time-aware Greeting
        Text(
          _greetingTitle,
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF181513),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),

        // 2. Visible Current Date & Time
        LiveDateTimeText(
          locationOffset: widget.locationOffset,
          locationTimezone: widget.locationTimezone,
          customNow: widget.customNow,
          iconSize: 13,
          iconColor: const Color(0xFFC5A880),
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF78716C),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),

        // 3. Informative Subtitle
        if (widget.customSubtitle != null)
          Text(
            widget.customSubtitle!,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          )
        else if (widget.isFreshMode)
          Text(
            '$bizDisplay is ready.\nLet’s get your store operational.',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5E574E),
              height: 1.3,
            ),
          )
        else
          Text(
            (cleanLoc != null && cleanLoc.isNotEmpty)
                ? 'Here is your operational update for $cleanLoc.'
                : 'Here is your operational update for $bizDisplay.',
            style: GoogleFonts.inter(
              fontSize: 13.5,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    );
  }
}
