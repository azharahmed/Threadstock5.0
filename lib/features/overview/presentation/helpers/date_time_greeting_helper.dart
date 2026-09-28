import 'package:intl/intl.dart';

/// Reusable helper for ThreadStock time-aware greetings and date/time formatting.
///
/// Greeting rules:
/// - 5:00 AM – 11:59 AM → Good morning
/// - 12:00 PM – 4:59 PM → Good afternoon
/// - 5:00 PM – 8:59 PM → Good evening
/// - 9:00 PM – 4:59 AM → Good night
class DateTimeGreetingHelper {
  const DateTimeGreetingHelper._();

  /// Optional test override for deterministic unit and widget testing.
  static DateTime? testNowOverride;

  /// Returns the greeting word based on the provided [dateTime] (or current time if null).
  static String getGreetingWord([DateTime? dateTime]) {
    final dt = dateTime ?? testNowOverride ?? DateTime.now();
    final hour = dt.hour;

    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good evening';
    } else {
      return 'Good night';
    }
  }

  /// Formats the full greeting with user name if available.
  ///
  /// Examples:
  /// - `Good night, Azhar Ahmed 👋`
  /// - `Good morning, Azhar Ahmed 👋`
  /// - `Good night 👋` (when user name is unavailable)
  static String formatGreeting({
    String? userName,
    DateTime? dateTime,
    bool includeWave = true,
  }) {
    final word = getGreetingWord(dateTime);
    final wave = includeWave ? ' 👋' : '';
    final trimmedName = userName?.trim();

    if (trimmedName != null && trimmedName.isNotEmpty) {
      return '$word, $trimmedName$wave';
    }
    return '$word$wave';
  }

  /// Formats a [DateTime] into a luxury ThreadStock date/time string:
  /// e.g. "Sunday, 28 Sep 2026 • 10:55 PM"
  static String formatDateTime(DateTime dateTime) {
    try {
      final formatter = DateFormat('EEEE, d MMM yyyy • h:mm a', 'en_US');
      return formatter.format(dateTime);
    } catch (_) {
      // Fallback format if intl fails or locale missing
      return _fallbackFormat(dateTime, includeDayOfWeek: true);
    }
  }

  /// Formats a [DateTime] into a short ThreadStock date/time string:
  /// e.g. "28 Sep 2026 • 10:55 PM"
  static String formatDateTimeShort(DateTime dateTime) {
    try {
      final formatter = DateFormat('d MMM yyyy • h:mm a', 'en_US');
      return formatter.format(dateTime);
    } catch (_) {
      return _fallbackFormat(dateTime, includeDayOfWeek: false);
    }
  }

  /// Resolves the current DateTime considering:
  /// 1. Location offset or timezone string if provided
  /// 2. Device local timezone as fallback
  ///
  /// Never directly returns UTC for display.
  static DateTime nowInTimezone({
    Duration? locationOffset,
    String? locationTimezone,
    DateTime? baseUtc,
  }) {
    if (testNowOverride != null) {
      return testNowOverride!;
    }

    final utc = baseUtc ?? DateTime.now().toUtc();

    if (locationOffset != null) {
      return utc.add(locationOffset);
    }

    if (locationTimezone != null && locationTimezone.trim().isNotEmpty) {
      final parsed = parseTimezoneOffset(locationTimezone);
      if (parsed != null) {
        return utc.add(parsed);
      }
    }

    // Fallback: device local time
    return DateTime.now();
  }

  /// Parses timezone strings (e.g. "IST (GMT+5:30)", "UTC+02:00", "GMT-5", etc.) into a Duration offset.
  static Duration? parseTimezoneOffset(String? tzString) {
    if (tzString == null || tzString.trim().isEmpty) return null;
    final trimmed = tzString.trim();

    // Match GMT/UTC/offset pattern: e.g. "GMT+5:30", "UTC+05:30", "GMT-5", "+05:30"
    final regex = RegExp(r'(?:GMT|UTC)?\s*([+-])(\d{1,2})(?::(\d{2}))?', caseSensitive: false);
    final match = regex.firstMatch(trimmed);
    if (match != null) {
      final sign = match.group(1) == '-' ? -1 : 1;
      final hours = int.parse(match.group(2)!);
      final minutes = match.group(3) != null ? int.parse(match.group(3)!) : 0;
      return Duration(minutes: sign * (hours * 60 + minutes));
    }

    final lower = trimmed.toLowerCase();
    if (lower.contains('kolkata') || lower.contains('calcutta') || lower.contains('ist') || lower.contains('india')) {
      return const Duration(hours: 5, minutes: 30);
    }
    if (lower.contains('dubai') || lower.contains('uae') || lower.contains('gst')) {
      return const Duration(hours: 4);
    }
    if (lower.contains('singapore') || lower.contains('sgt')) {
      return const Duration(hours: 8);
    }
    if (lower.contains('london') || lower.contains('gmt') || lower.contains('utc')) {
      return Duration.zero;
    }
    if (lower.contains('johannesburg') || lower.contains('south africa') || lower.contains('sast')) {
      return const Duration(hours: 2);
    }
    if (lower.contains('new york') || lower.contains('est')) {
      return const Duration(hours: -5);
    }
    if (lower.contains('los angeles') || lower.contains('pst')) {
      return const Duration(hours: -8);
    }
    if (lower.contains('chicago') || lower.contains('cst')) {
      return const Duration(hours: -6);
    }
    if (lower.contains('sydney') || lower.contains('aest')) {
      return const Duration(hours: 10);
    }
    return null;
  }

  static String _fallbackFormat(DateTime dt, {required bool includeDayOfWeek}) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    final dayName = days[(dt.weekday - 1).clamp(0, 6)];
    final monthName = months[(dt.month - 1).clamp(0, 11)];
    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final minutePadded = dt.minute.toString().padLeft(2, '0');

    if (includeDayOfWeek) {
      return '$dayName, ${dt.day} $monthName ${dt.year} • $hour12:$minutePadded $period';
    }
    return '${dt.day} $monthName ${dt.year} • $hour12:$minutePadded $period';
  }
}
