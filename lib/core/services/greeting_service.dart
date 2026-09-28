import 'package:threadstock/features/overview/presentation/helpers/date_time_greeting_helper.dart';

/// App-wide Greeting Service for ThreadStock.
///
/// Encapsulates time-aware greetings and date/time formatting.
class GreetingService {
  const GreetingService._();

  /// Returns time-aware greeting word (Good morning, Good afternoon, Good evening, Good night).
  static String getGreetingWord([DateTime? dateTime]) =>
      DateTimeGreetingHelper.getGreetingWord(dateTime);

  /// Formats the greeting with optional username and emoji wave.
  static String formatGreeting({
    String? userName,
    DateTime? dateTime,
    bool includeWave = true,
  }) =>
      DateTimeGreetingHelper.formatGreeting(
        userName: userName,
        dateTime: dateTime,
        includeWave: includeWave,
      );

  /// Resolves the current DateTime considering location timezone or fallback to device local time.
  static DateTime nowInTimezone({
    Duration? locationOffset,
    String? locationTimezone,
    DateTime? baseUtc,
  }) =>
      DateTimeGreetingHelper.nowInTimezone(
        locationOffset: locationOffset,
        locationTimezone: locationTimezone,
        baseUtc: baseUtc,
      );

  /// Formats date/time string: "Sunday, 28 Sep 2026 • 10:55 PM".
  static String formatDateTime(DateTime dateTime) =>
      DateTimeGreetingHelper.formatDateTime(dateTime);

  /// Formats short date/time string: "28 Sep 2026 • 10:55 PM".
  static String formatDateTimeShort(DateTime dateTime) =>
      DateTimeGreetingHelper.formatDateTimeShort(dateTime);
}
